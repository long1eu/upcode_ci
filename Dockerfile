FROM debian:stretch

############################################################
# Basic                                                    #
############################################################
RUN apt-get update \
    && apt-get install -y \
        sudo \
        wget \
        zip \
        unzip \
        git \
        openssh-client \
        curl \
        bc \
        gnupg2 \
        software-properties-common \
        build-essential \
        ruby-full \
        ruby-bundler \
        lib32stdc++6 \
        libstdc++6 \
        libpulse0 \
        libglu1-mesa \
        locales \
        lcov \
        libsqlite3-0 \
        apt-transport-https \
        ca-certificates \
        --no-install-recommends

# https://github.com/cirruslabs/docker-images-android/blob/master/sdk/tools/Dockerfile
############################################################
# Install Android tools                                    #
############################################################
ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

# comes from https://developer.android.com/studio/#command-tools
ENV ANDROID_SDK_TOOLS_VERSION 6609375

RUN set -o xtrace \
    && cd /opt \
    && apt-get install -y openjdk-8-jdk \
    # for x86 emulators
    && apt-get install -y libxtst6 libnss3-dev libnspr4 libxss1 libasound2 libatk-bridge2.0-0 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -O android-sdk-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools/ \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools/ \
    && chown -R root:root $ANDROID_HOME \
    && rm android-sdk-tools.zip \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && yes | sdkmanager --licenses \
    && wget -O /usr/bin/android-wait-for-emulator https://raw.githubusercontent.com/travis-ci/travis-cookbooks/master/community-cookbooks/android-sdk/files/default/android-wait-for-emulator \
    && chmod +x /usr/bin/android-wait-for-emulator \
    && touch /root/.android/repositories.cfg \
    && sdkmanager platform-tools \
    && sdkmanager emulator \
    && mkdir -p /root/.android \
    && touch /root/.android/repositories.cfg

# https://github.com/cirruslabs/docker-images-android/blob/master/sdk/30/Dockerfile
############################################################
# Install Android build tools 29                           #
############################################################

ENV ANDROID_PLATFORM_VERSION 29
ENV ANDROID_BUILD_TOOLS_VERSION 29.0.2

RUN yes | sdkmanager \
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"

# https://github.com/cirruslabs/docker-images-flutter/blob/master/sdk/Dockerfile
############################################################
# Install Flutter dev                                      #
############################################################
ENV FLUTTER_HOME=${HOME}/sdks/flutter \
    FLUTTER_VERSION=dev
ENV FLUTTER_ROOT=$FLUTTER_HOME

ENV PATH ${PATH}:${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${HOME}/sdks

RUN git clone --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}

RUN yes | flutter doctor --android-licenses \
    && flutter doctor \
    && flutter precache \
    && chown -R root:root ${FLUTTER_HOME}

############################################################
# Install Dart                                             #
############################################################
RUN sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN apt-get update
RUN apt-get install dart
ENV PATH ${PATH}:/usr/lib/dart/bin

############################################################
# Install Node and Firebase tools                          #
############################################################

# Add nodejs repository to apt sources and install it.
ENV NODEJS_INSTALL="/opt/nodejs_install"
RUN mkdir -p "${NODEJS_INSTALL}"
RUN wget -q https://deb.nodesource.com/setup_12.x -O "${NODEJS_INSTALL}/nodejs_install.sh"
RUN chmod +x "${NODEJS_INSTALL}/nodejs_install.sh"
RUN "${NODEJS_INSTALL}/nodejs_install.sh"
RUN apt-get install -y npm

# Install Firebase
RUN npm install -g firebase-tools

# Install git-crypt
RUN apt-get install -y git-crypt