!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine phq_readin
  !-----------------------------------------------------------------------
  !
  !    This routine reads the control variables for the program phononq.
  !    from standard input (unit 5).
  !    A second routine readfile reads the variables saved on a file
  !    by the self-consistent program.
  !
#include "machine.h"

  use pwcom
  use parameters, only : DP
  use phcom
  use io
#ifdef __PARA
  use para
#endif
  implicit none
  integer :: ios, ipol, iter, na, it
  ! integer variable for I/O control
  ! counter on polarizations
  ! counter on iterations
  ! counter on atoms
  ! counter on types
  character(len=256) :: outdir
  namelist / inputph / tr2_ph, amass, alpha_mix, niter_ph, nmix_ph, &
       maxirr, nat_todo, iverbosity, outdir, epsil, trans, elph, zue, nrapp, &
       time_max, reduce_io, prefix, fildyn, filelph, fildvscf, fildrho
  ! tr2_ph   : convergence threshold
  ! amass    : atomic masses
  ! alpha_mix: the mixing parameter
  ! niter_ph : maximum number of iterations
  ! nmix_ph  : number of previous iterations used in mixing
  ! maxirr   : the number of irreducible representations
  ! nat_todo : number of atom to be displaced
  ! iverbosity   : verbosity control
  ! outdir   : directory where input, output, temporary files reside
  ! epsil    : if true calculate dielectric constant
  ! trans    : if true calculate phonon
  ! elph     : if true calculate electron-phonon coefficients
  ! zue      : if true calculate effective charges (alternate way)
  ! nrapp    : the representations to do
  ! time_max : maximum cputime for this run
  ! reduce_io: reduce I/O to the strict minimum
  ! prefix   : the prefix of files produced by pwscf
  ! fildyn   : output file for the dynamical matrix
  ! filelph  : output file for electron-phonon coefficients
  ! fildvscf : output file containing deltavsc
  ! fildrho  : output file containing deltarho
#ifdef __PARA

  if (me.ne.1) goto 400
#endif
  !
  !    Read the first line of the input file
  !
  read (5, '(a)', err = 100, iostat = ios) title_ph
  !print*, 'Title -->', title_ph
100 call errore ('phq_readin', 'reading title ', abs (ios) )
  !
  !   set default values for variables in namelist
  !
  tr2_ph = 1.d-10
  amass(:) = 0.d0
  alpha_mix(:) = 0.d0
  alpha_mix (1) = 0.7d0
  niter_ph = maxter
  nmix_ph = 4
  maxirr = 0
  nat_todo = 0
  nrapp = 0
  iverbosity = 0
  trans = .true.
  epsil = .false.
  zue = .false.
  elph = .false.
  time_max = 10000000.d0
  reduce_io = .false.
  outdir = './'
  prefix = 'pwscf'
  filelph = ' '
  fildyn = 'matdyn'
  fildrho = ' '
  fildvscf = ' '
  !
  !     reading the namelist inputph
  !
#ifdef CRAYY
  !   The Cray does not accept "err" and "iostat" together with a namelist
  read (5, inputph)
  ios = 0
#else
  !
  read (5, inputph, err = 200, iostat = ios)
#endif

200 call errore ('phq_readin', 'reading inputph namelist', abs (ios) )
  !
  !     Check all namelist variables
  !
  if (tr2_ph.le.0.d0) call errore (' phq_readin', ' Wrong tr2_ph ', 1)
  do iter = 1, maxter
     if (alpha_mix (iter) .lt.0.d0.or.alpha_mix (iter) .gt.1.d0) call &
          errore ('phq_readin', ' Wrong alpha_mix ', iter)
  enddo
  if (niter_ph.lt.1.or.niter_ph.gt.maxter) call errore ('phq_readin', &
       ' Wrong niter_ph ', 1)
  if (nmix_ph.lt.1.or.nmix_ph.gt.5) call errore ('phq_readin', ' Wrong &
       &nmix_ph ', 1)
  if (iverbosity.ne.0.and.iverbosity.ne.1) call errore ('phq_readin', &
       &' Wrong  iverbosity ', 1)
  if (fildyn.eq.' ') call errore ('phq_readin', ' Wrong fildyn ', 1)
  if (time_max.lt.1.d0) call errore ('phq_readin', ' Wrong time_max', 1)

  if (nat_todo.ne.0.and.nrapp.ne.0) call errore ('phq_readin', &
       &' incompatible flags', 1)
  !
  !    reads the q point
  !
  read (5, *, err = 300, iostat = ios) (xq (ipol), ipol = 1, 3)
300 call errore ('phq_readin', 'reading xq', abs (ios) )
  lgamma = xq (1) .eq.0.d0.and.xq (2) .eq.0.d0.and.xq (3) .eq.0.d0
  if ( (epsil.or.zue) .and..not.lgamma) call errore ('phq_readin', &
       'gamma is needed for elec.field', 1)
  if (zue.and..not.trans) call errore ('phq_readin', 'trans must be &
       &.t. for Zue calc.', 1)
  tmp_dir = trim(outdir)
#ifdef __PARA
400 continue

  call bcast_ph_input
  call init_pool
#endif
  xqq(:) = xq(:) 
  !
  !   Here we finished the reading of the input file.
  !   Now allocate space for pwscf variables, read and check them.
  !
  call read_file
  !
  if (lgamma) then
     nksq = nks
  else
     nksq = nks / 2
  endif
  !
  if ( (zue) .and.okvan) then
     call errore ('phq_readin', 'No electric field in US case', -1)
     epsil = .false.
     zue = .false.
  endif
  !
  if (elph.and.degauss.eq.0.0) call errore ('phq_readin', 'Electron-&
       &phonon only for metals', 1)
  if (elph.and.lsda) call errore ('phq_readin', 'El-ph and spin not &
       &implemented', 1)
  if (elph.and.fildvscf.eq.' ') call errore ('phq_readin', 'El-ph needs &
       &a DeltaVscf file', 1)
  !
  !   There might be other variables in the input file which describe
  !   partial computation of the dynamical matrix. Read them here
  !
  call allocate_part
#ifdef __PARA

  if (me.ne.1.or.mypool.ne.1) goto 800
#endif
  if (nat_todo.lt.0.or.nat_todo.gt.nat) call errore ('phq_readin', &
       'nat_todo is wrong', 1)
  if (nat_todo.ne.0) then
     read (5, *, err = 600, iostat = ios) (atomo (na), na = 1, &
          nat_todo)
600  call errore ('phq_readin', 'reading atoms', abs (ios) )
  endif
  if (nrapp.lt.0.or.nrapp.gt.3 * nat) call errore ('phq_readin', &
       'nrapp is wrong', 1)
  if (nrapp.ne.0) then
     read (5, *, err = 700, iostat = ios) (list (na), na = 1, nrapp)
700  call errore ('phq_readin', 'reading list', abs (ios) )

  endif
#ifdef __PARA
800 continue
  call bcast_ph_input1
#endif

  if (epsil.and.degauss.ne.0.d0) call errore ('phq_readin', 'no elec. &
       &field with metals', 1)

  if (iswitch.ne. - 2 .and. iswitch.ne. - 3 .and. iswitch.ne. -4 &
       .and. .not.lgamma) call errore ('phq_readin', ' Wrong iswitch ', &
       & 1 + abs (iswitch) )
  do it = 1, ntyp
     if (amass (it) .le.0.d0) call errore ('phq_readin', 'Wrong masses', &
          it)
  enddo

  if (maxirr.lt.0.or.maxirr.gt.3 * nat) call errore ('phq_readin', ' &
       &Wrong maxirr ', abs (maxirr) )
  if (mod (nks, 2) .ne.0.and..not.lgamma) call errore ('phq_readin', &
       'k-points are odd', nks)
  if (iswitch.eq. - 4) then
     nrapp = 1
     nat_todo = 0
     list (1) = modenum
  endif
  return
end subroutine phq_readin
