FROM    debian:latest

LABEL   version="qe:latest-debian-atlas-mpich"

ENV     QE_HOME /home/qe
ENV     RUNDIR /home/rundir

# dependencies here: https://packages.debian.org/buster/quantum-espresso
RUN     apt-get update \
        && apt-get install -y \
            libatlas-base-dev \
            libatlas3-base \
            libfftw3-double3 \
            libfftw3-dev \
            libmpich-dev \
            make \
            wget \
            python2

# -l = --no-log-init: do not lastlog and faillog user
# -U = create a group named [user], add user to it
RUN     ["/bin/bash", "-c", \
         "useradd -lmU -s /bin/bash -u 1001 qe"]

USER    qe
        
WORKDIR "${QE_HOME}"

# TODO: install all QE components of interest (other than pw.x)
COPY    --chown=qe:qe . "${QE_HOME}"
RUN     ./configure \
        && make pw

ENV     PATH "$PATH:/home/qe/bin"

COPY    --chown=qe:qe wrap.sh "${QE_HOME}"
RUN     chmod u+x "${QE_HOME}/wrap.sh"

WORKDIR "${RUNDIR}"

ENTRYPOINT  ["/bin/bash", "-c", "${QE_HOME}/wrap.sh"]

CMD     []

