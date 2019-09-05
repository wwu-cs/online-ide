FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

ARG GITHUB_TOKEN
ARG NODE_VERSION=10.15.3
ENV NODE_VERSION $NODE_VERSION
ENV YARN_VERSION 1.13.0

# Optionally build a striped Theia application with no map file or .ts sources.
# Makes image ~150MB smaller when enabled
ARG strip=true
ENV strip=$strip

# place holder for real LDAPUNAME environment
ENV LDAPUNAME=nobody

#Common deps
RUN apt-get update && \
    apt-get -y install build-essential \
                       curl \
                       git \
                       gpg \
                       python \
                       wget \
                       sudo \
                       xz-utils && \
    rm -rf /var/lib/apt/lists/* 

#Install node and yarn
#From: https://github.com/nodejs/docker-node/blob/6b8d86d6ad59e0d1e7a94cec2e909cad137a028f/8/Dockerfile

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
    && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs


RUN set -ex \
    && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt/yarn \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
    && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

#C/C++ Developer tools

# install clangd and clang-tidy from the public LLVM PPA (nightly build / development version)
# and also the GDB debugger, cmake from the Ubuntu repos
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y cmake \
                       clang-tools-8 \
                       clang-tidy-8 \
                       clang-format-8 \
                       gdb && \
    ln -s /usr/bin/clangd-8 /usr/bin/clangd && \
    ln -s /usr/bin/clang-tidy-8 /usr/bin/clang-tidy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

## User account and plugins directory
RUN adduser --disabled-password --gecos '' --uid 800 theia && \
    mkdir /home/theia/plugins

# Add all files
ADD settings.json /home/theia/.theia/
ADD package.json /home/theia/package.json
ADD workspace.patch /home/theia/workspace.patch
ADD plugins/* /home/theia/plugins/
ADD uids.sh /usr/local/bin/uids.sh
ADD uname_fix.sh /usr/local/bin/uname_fix.sh
ADD start.sh /usr/local/bin/start.sh

# run commands to set permissions and edit passwd file
RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project && \
    chmod 755 /usr/local/bin/uname_fix.sh && \
    chmod 755 /usr/local/bin/start.sh && \
    /usr/local/bin/uids.sh >> /etc/passwd && \
    rm /usr/local/bin/uids.sh && \
    echo 'ALL ALL=(ALL) NOPASSWD:SETENV: /usr/local/bin/uname_fix.sh' >> /etc/sudoers

# Theia application
USER theia
WORKDIR /home/theia

RUN if [ "$strip" = "true" ]; then \
yarn --pure-lockfile && \
    patch node_modules/@theia/workspace/lib/browser/workspace-frontend-contribution.js workspace.patch && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean \
;else \
yarn --cache-folder ./ycache && rm -rf ./ycache && \
     NODE_OPTIONS="--max_old_space_size=4096" yarn theia build \
;fi

# reset permissions so any user can use theia application
#RUN find /home/theia -type d -exec chmod 777 {} \; && \
#    find /home/theia -type f -exec chmod 666 {} \;

EXPOSE 3000
ENV SHELL /bin/bash
ENV THEIA_DEFAULT_PLUGINS=local-dir:/home/project/.theia/plugins

ENTRYPOINT ["/usr/local/bin/start.sh"]
# ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0" ]
# ENTRYPOINT [ "yarn", "theia", "start", "/home/project", "--hostname=0.0.0.0" ] 
