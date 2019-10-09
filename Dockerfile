FROM drachtio/drachtio-freeswitch-base:1.8.5-v0.2.4

COPY ./entrypoint.sh /
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml

VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]
