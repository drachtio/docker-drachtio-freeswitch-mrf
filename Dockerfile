FROM lylepratt/drachtio-freeswitch-base:latest

ENV MNT_POINT /var/s3fs
ENV COPY_POINT /var/pres3fs
ENV S3_BUCKET vidamedia
ENV NODE_VERSION=18
ENV NVM_DIR=/root/.nvm
ENV NODE_PATH /root/.nvm/versions/node/v${NODE_VERSION}/lib/node_modules

# Install necessary packages, Node.js, axios, and verify installations
RUN apt-get update && apt-get install -y --quiet s3fs awscli rsyslog inotify-tools curl && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    nvm install ${NODE_VERSION} && \
    nvm use v${NODE_VERSION} && \
    nvm alias default v${NODE_VERSION} && \
    node --version && \
    npm --version && \
    npm install axios@^1.5.0 -g

# Directory setup
RUN mkdir -p "$MNT_POINT" && \
    mkdir -p "$COPY_POINT"

# Copy scripts and configs
ADD monitorPres3fs.sh /
RUN chmod 775 /monitorPres3fs.sh

COPY ./entrypoint.sh /
COPY ./vars_diff.xml  /usr/local/freeswitch/conf/vars_diff.xml
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml
COPY ./autoload_configs/conference.conf.xml /usr/local/freeswitch/conf/autoload_configs/conference.conf.xml
COPY ./autoload_configs/conference_layouts.conf.xml /usr/local/freeswitch/conf/autoload_configs/conference_layouts.conf.xml
COPY ./autoload_configs/av.conf.xml /usr/local/freeswitch/conf/autoload_configs/av.conf.xml
COPY ./autoload_configs/tts_commandline.conf.xml /usr/local/freeswitch/conf/autoload_configs/tts_commandline.conf.xml

VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]
