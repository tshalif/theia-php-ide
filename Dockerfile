FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
        apt-get -y install build-essential \
        curl \
        git \
        sudo \
        gpg \
        python \
        wget \
        xz-utils \
        nodejs \
        node-gyp \
        make \
        htop

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
        && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
        && apt update \
        && sudo apt install yarn

#Python 2-3
RUN apt-get update \
        && apt-get install -y software-properties-common \
        && add-apt-repository -y ppa:deadsnakes/ppa \
        && apt-get install -y python-dev \
        && apt-get install -y python3.8 python3-dev python3-pip \
        && apt-get remove -y software-properties-common \
        && python3.8 -m pip install --upgrade pip \
        && pip3 install python-language-server flake8 autopep8


#PHP
ARG PHP_VERSION=7.3

RUN apt-get update \
        && apt-get install -y software-properties-common \
        && add-apt-repository -y ppa:ondrej/php \
        && apt-get install -y php$PHP_VERSION php$PHP_VERSION-json php$PHP_VERSION-bcmath php$PHP_VERSION-bz2 php$PHP_VERSION-calendar php$PHP_VERSION-exif php$PHP_VERSION-gd php$PHP_VERSION-gettext php$PHP_VERSION-intl php$PHP_VERSION-mysqli php$PHP_VERSION-soap php$PHP_VERSION-sockets php$PHP_VERSION-sysvmsg php$PHP_VERSION-sysvsem php$PHP_VERSION-sysvshm php$PHP_VERSION-opcache php$PHP_VERSION-zip php$PHP_VERSION-redis php$PHP_VERSION-xsl bash-completion htop && update-alternatives --set php /usr/bin/php$PHP_VERSION \
        && apt-get remove -y software-properties-common \
        && update-alternatives --set php /usr/bin/php$PHP_VERSION

RUN curl -s -o composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

RUN adduser --disabled-password --gecos '' theia && \
    adduser theia sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    mkdir -p /home/theia/.pub-cache/bin && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project

# Theia application
##Needed for node-gyp, nsfw build
RUN apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/cache/apt/* && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/*

USER theia
WORKDIR /home/theia
ADD package.json ./package.json
ARG THEIA_PORT=5000
RUN yarn && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins

EXPOSE $THEIA_PORT
ENV PROJECT_DIR=/app \
        THEIA_RUN_ROOT=1 \
        THEIA_PORT=$THEIA_PORT \
        SHELL=/bin/bash \
        THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

ADD theia-run.sh /home/theia/
ENTRYPOINT /home/theia/theia-run.sh
