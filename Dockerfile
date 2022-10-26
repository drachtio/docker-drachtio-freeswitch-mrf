FROM lylepratt/drachtio-freeswitch-base:latest

ENV MNT_POINT /var/s3fs
ENV COPY_POINT /var/pres3fs
ENV S3_BUCKET vidamedia

RUN apt-get update && apt-get install -y --quiet s3fs awscli incron rsyslog

RUN mkdir -p "$MNT_POINT"
RUN mkdir -p "$COPY_POINT"
RUN rm /etc/incron.allow
ADD incron.conf /var/monitor_incron.conf
RUN incrontab /var/monitor_incron.conf


COPY ./entrypoint.sh /
COPY ./vars_diff.xml  /usr/local/freeswitch/conf/vars_diff.xml
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml
COPY ./autoload_configs/conference.conf.xml /usr/local/freeswitch/conf/autoload_configs/conference.conf.xml
COPY ./autoload_configs/conference_layouts.conf.xml /usr/local/freeswitch/conf/autoload_configs/conference_layouts.conf.xml

VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]
