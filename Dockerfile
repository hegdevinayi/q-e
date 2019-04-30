FROM debian:latest

 RUN apt-get update && apt-get install -y --fix-missing \
  fftw3-dev \
  gfortran \
  g++ \
  liblapack-dev \
  libmpich-dev \
  make

WORKDIR /home/qe
# ADD Makefile .
# ADD configure .
# ADD PW PW
# ADD Modules Modules
# ADD install install
# ADD include include
# ADD FFTXlib FFTXlib
# ADD LAXlib LAXlib
# ADD archive archive
# ADD clib clib

# ADD UtilXlib UtilXlib
# ADD KS_Solvers KS_Solvers
ADD . .
RUN ./configure
RUN make pw
ADD wrap.sh wrap.sh

 WORKDIR /home/rundir

 ENV PATH=/home/rundir/:${PATH}

 # ENTRYPOINT ["/bin/sh", "/home/rundir/wrap.sh", "/home/qe/bin/pw.x"]
ENTRYPOINT ["/home/qe/wrap.sh", "/home/qe/bin/pw.x"]
CMD ["-i run.in"]
