FROM lylepratt/drachtio-freeswitch-base:latest

ENV MNT_POINT /var/s3fs
ENV COPY_POINT /var/pres3fs
ENV S3_BUCKET vidamedia

RUN apt-get update && apt-get install -y --quiet s3fs awscli rsyslog inotify-tools

ENV NODE_VERSION=18
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN mkdir -p "$MNT_POINT"
RUN mkdir -p "$COPY_POINT"

ADD monitorPres3fs.sh /
RUN chmod 775 /monitorPres3fs.sh
#RUN /monitorPres3fs.sh

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
