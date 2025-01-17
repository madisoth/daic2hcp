FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update && apt-get install -yq --no-install-recommends \
        apt-utils \
        bc \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        dc \
        dirmngr\
        git \
        gnupg2 \
        graphviz \
        libgomp1 \
        libxmu6 \
        libxt6 \
        libfontconfig1 \
        libfreetype6 \
        libglib2.0.0 \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libgraphviz-dev \
        libice6 \
        libssl1.0.0 \
        libssl-dev \
        libxcursor1 \
        libxft2 \
        libxinerama1 \
        libxrandr2 \
        libxrender1 \
        locales \
        make \
        m4 \
        python-pip \
        python3 \
        python3-dev \
        python3-pip \
        rsync \
        unzip \
        tcsh \
        wget \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip3 install setuptools wheel && \
    pip3 install nipype graphviz pygraphviz pydot && \
    pip install Pillow

# get neurodebian repos
RUN wget -O- http://neuro.debian.net/lists/bionic.us-ca.full >> /etc/apt/sources.list.d/neurodebian.sources.list

RUN apt-key adv --recv-keys --keyserver pgp.mit.edu 0xA5D32F012649A5A9 || apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xA5D32F012649A5A9

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && localedef --force --inputfile=en_US --charmap=UTF-8 C.UTF-8 \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
  .0       && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

# workbench
RUN apt-get update && apt-get install -yq --no-install-recommends \
    ants \

    connectome-workbench \
    fsl-5.0-core \
    fsl-atlases


#-----------------------------------------------------------
# Install FSL v5.0.10
# FSL is non-free. If you are considering commerical use
# of this Docker image, please consult the relevant license:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence
#-----------------------------------------------------------
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc dc libfontconfig1 libfreetype6 libgl1-mesa-dev libglu1-mesa-dev libgomp1 libice6 libxcursor1 libxft2 libxinerama1 libxrandr2 libxrender1 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo "Downloading FSL ..." \
    && curl -sSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-centos6_64.tar.gz \
    | tar zx -C /opt \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT
ENV FSLDIR=/opt/fsl \
    FSL_DIR=/opt/fsl \
    PATH=/opt/fsl/bin:$PATH

RUN echo "Downloading C3D ..." \
    && mkdir /opt/c3d \
    && curl -sSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
    | tar -xzC /opt/c3d \
    --strip-components=1 \
    --exclude=bin/c3d_gui \
    --exclude=bin/c2d \
    --exclude=lib

RUN echo "Downloading FreeSurfer ..." \
    && curl -sSL --retry 5 https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.3.0-HCP/freesurfer-Linux-centos6_x86_64-stable-pub-v5.3.0-HCP.tar.gz \
    | tar xz -C /opt \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/fsaverage5' \
    --exclude='freesurfer/subjects/fsaverage6' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/trctrain' \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT

ENV FREESURFER_HOME=/opt/freesurfer

RUN mkdir -p /opt/dcan-tools /mriproc /boldproc /fsurf /output /app
WORKDIR /opt/dcan-tools
RUN git clone -b 'v2.2.6' --single-branch --depth 1 https://github.com/DCAN-Labs/ExecutiveSummary.git executivesummary
# unzip template file
RUN gunzip /opt/dcan-tools/executivesummary/templates/parasagittal_Tx_169_template.scene.gz

COPY ["app", "/app"]
COPY ["./SetupEnv.sh", "/SetupEnv.sh"]
COPY ["./entrypoint.sh", "/entrypoint.sh"]
COPY ["LICENSE", "/LICENSE"]
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /output
CMD ["--help"]
