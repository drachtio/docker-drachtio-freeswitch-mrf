FROM drachtio/drachtio-freeswitch-base:latest

ENV USERNAME=freeSwitch
ENV PASSWORD=ClueCon
ENV EVENT_SOCKET_PORT=8021
ENV SIP_PORT=5080
ENV TLS_PORT=5081
ENV RTP_RANGE_START=16384
ENV RTP_RANGE_END=32767

COPY ./entrypoint.sh /
COPY ./sip_profiles/mrf.xml /usr/local/freeswitch/conf/sip_profiles/mrf.xml
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml

VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]

ENV PATH="/usr/local/freeswitch/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]

CMD ["freeswitch"]