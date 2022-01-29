FROM lylepratt/drachtio-freeswitch-base:latest

ENV MNT_POINT /var/s3fs
ENV S3_BUCKET vidamail

RUN apt-get update && apt-get install -y --quiet s3fs awscli

RUN mkdir -p "$MNT_POINT"

COPY ./entrypoint.sh /
COPY ./vars_diff.xml  /usr/local/freeswitch/conf/vars_diff.xml
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml

VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]
