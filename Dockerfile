FROM ubuntu:bionic-20190612

ARG ANACONDA=Anaconda3-2019.03-Linux-x86_64.sh
ARG ANACONDA_ARCHIVES=https://repo.anaconda.com/archive

ARG IN_USER=badc0ded
ARG IN_GROUP=badc0ded
# Set these to the uid/gid of the user running the container
# to be able to easily access files between host and container.
ARG IN_UID=1000
ARG IN_GID=1000

ENV HOME=/home/$IN_USER
ENV COLAB_HOME=/home/$IN_USER/colab
USER root

# Time-zone settings to prevent need for interactivity.
ENV TZ=Europe/Frankfurt
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV DEBIAN_FRONTEND=noninteractive

# apt installation
RUN apt update && apt upgrade -y && apt install -y \
    wget \
    expect \
    bash \
#   Dependencies of pip modules
    libglib2.0-dev \
    pyqt5-dev \
    libmpich-dev \
    r-base \
    libsndfile1-dev \
    libhdf5-dev \
    libcairo2-dev \
    libgdal-dev \
    gobject-introspection \
    libgirepository1.0-dev \
    python3-soundfile \
    python3-cairo-dev \
    cmake

# Create new user inside new group and switch to it.
RUN groupadd $IN_GROUP -g $IN_GID && useradd -d /home/$IN_USER -r -u $IN_UID -g $IN_GROUP -s /usr/bin/bash $IN_USER
RUN mkdir -p $HOME && chown -R $IN_USER:$IN_GROUP $HOME
RUN mkdir -p $COLAB_HOME && chown -R $IN_USER:$IN_GROUP $COLAB_HOME
USER $IN_USER
SHELL ["/bin/bash", "-c"]
WORKDIR $HOME

# Anaconda installation based on expect script.
COPY anaconda.exp $HOME
RUN wget $ANACONDA_ARCHIVES/$ANACONDA \
    && chmod +x ./$ANACONDA \
    && ./anaconda.exp
ENV PATH="${HOME}/anaconda3/bin:${PATH}"
RUN conda init bash

# Install and configure defined pip modules inside conda environment.
COPY pip_modules $HOME/pip_modules
RUN source ~/.bashrc \
    && conda create --name colab python=3.6 \
    && conda activate colab \
    && export CPLUS_INCLUDE_PATH=/usr/include/gdal \
    && export C_INCLUDE_PATH=/usr/include/gdal \
    && pip install pystan==2.19.0.0 \
    && for REQS_FILE in $HOME/pip_modules/*; \
         do pip install -r $REQS_FILE; \
       done \
    && python -m spacy download en_core_web_sm \
    && jupyter nbextension enable --py --sys-prefix ipyleaflet \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Cleanup: use docker build --squash to enable actual removal of below files.
# Needs "experimental": true in /etc/docker/daemon.json.
RUN rm -f $HOME/$ANACONDA \
    && rm -f $HOME/anaconda.exp \
    && rm -rf $HOME/.cache
