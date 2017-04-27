FROM drachtio/drachtio-freeswitch-base:latest

COPY ./entrypoint.sh /

VOLUME ["/usr/local/freeswitch/log","/usr/local/freeswitch/sounds","/usr/local/freeswitch/recordings"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]