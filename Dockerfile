FROM debian:12-slim
LABEL maintainer="Diogo Oliveira <diogo0liveira@hotmail.com>"

## Required
SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

## Use unicode support 
RUN apt-get update && apt-get -y install locales
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure locales
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US:en"

## Install dependencies
RUN apt-get install --no-install-recommends -y \
  openjdk-17-jdk \
  git \
  wget \
  unzip \
  ssh \
  ## Fastlane dependencies
  libcurl4 \
  libcurl4-openssl-dev \
  ## ruby dependencies
  autoconf \
  patch \
  rustc \
  build-essential \ 
  libssl-dev \
  libyaml-dev \
  libgmp-dev \
  libgdbm-dev \
  libffi-dev \
  libdb-dev \
  libreadline6-dev \
  libncurses5-dev \
  zlib1g-dev \
  libgdbm6 \
  uuid-dev

## Clean dependencies
RUN apt clean
RUN rm -rf /var/lib/apt/lists/*

## Install rbenv
ENV RBENV_ROOT="/root/.rbenv"
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
ENV PATH="$PATH:$RBENV_ROOT/bin"
ENV PATH="$PATH:$RBENV_ROOT/shims"
RUN $RBENV_ROOT/bin/rbenv init -

## Install jenv
ENV JENV_ROOT="/root/.jenv"
RUN git clone https://github.com/jenv/jenv.git $JENV_ROOT
ENV PATH="$PATH:$JENV_ROOT/bin"
RUN mkdir $JENV_ROOT/versions
ENV JDK_ROOT="/usr/lib/jvm/"
RUN jenv add ${JDK_ROOT}/java-17-openjdk-amd64
RUN echo 'export PATH="$JENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(jenv init -)"' >> ~/.bashrc

## Install ruby-build (rbenv plugin)
RUN mkdir -p "$RBENV_ROOT"/plugins
RUN git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT"/plugins/ruby-build

## Install ruby envs
ARG ruby_version=3.3.6
RUN echo “install: --no-document” > ~/.gemrc
ENV RUBY_CONFIGURE_OPTS=--disable-install-doc
RUN rbenv install ${ruby_version}

## Setup default ruby env
RUN rbenv global ${ruby_version}
RUN gem install bundler:2.6.0

## Install Android SDK
ARG sdk_version=commandlinetools-linux-11076708_latest.zip
ARG android_home=/opt/android/sdk
ARG android_api=android-35
ARG android_build_tools=35.0.0

RUN mkdir -p ${android_home} && \
  wget --quiet --output-document=/tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
  unzip -q /tmp/${sdk_version} -d ${android_home} && \
  mv ${android_home}/cmdline-tools ${android_home}/tools && \
  rm /tmp/${sdk_version}

## Set environmental variables
ENV ANDROID_HOME=${android_home}
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
RUN sdkmanager --sdk_root=$ANDROID_HOME --install \
  "platform-tools" \
  "build-tools;${android_build_tools}" \
  "platforms;${android_api}"

CMD ["/bin/bash"]