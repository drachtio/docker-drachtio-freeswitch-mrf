# docker-drachtio-freeswitch-mrf

A slim Freeswitch 1.10 image (~620 MB) designed for use with [drachtio-fsmrf](http://davehorton.github.io/drachtio-fsmrf/), based on the [docker-drachtio-freeswitch-base](https://hub.docker.com/r/drachtio/drachtio-freeswitch-base/) image.

To run with default options:
```bash
docker run -d --rm --name FS1 drachtio/drachtio-freeswitch-mrf freeswitch 
```
To jump in to a running container with a freeswitch console:
```bash
docker exec -ti FS1 fs_cli
```
> Note: you can also jump into the container with `bash` instead of `fs_cli` to get to a shell prompt in the container.

This is a **very** minimal image, with support only for dialplan and event socket (no scripting languages such as lua or javascript are compiled in), no sounds, and a minimal set of modules (see below for the modules.conf.xml showing which modules are being loaded).  As mentioned, it is primarily designed for use with the drachtio-fsrmf framework.

The container exposes the following volumes, which allow you to provide the canned freeswitch sound files from your host machine:
- /usr/local/freeswitch/sounds (to let you provide the canned freeswitch sound files),
- /usr/local/freeswitch/recordings (to let you save recordings to the host filesystem), and
- /usr/local/freeswitch/log (to let you save freeswitch log files)

This container supports the ability to configure the various ports Freeswitch claims, in order to easily run multiple Freeswitch containers on the same host
* --sip-port the sip port to listen on (default: 5080)
* --tls-port the tls port to listen on (default: 5081)
* --event-socket-port the port that Freeswitch event socket listens on (default: 8021)
* --password the event socket password (default: ClueCon)
* --rtp-range-start the starting UDP port for RTP traffic
* --rtp-range-end the ending UDP port for RTP traffic

An example of starting a container with advanced options:
```bash
docker run -d --rm --name FS1 --net=host \
-v /home/deploy/log:/usr/local/freeswitch/log  \
-v /home/deploy/sounds:/usr/local/freeswitch/sounds \
-v /home/deploy/recordings:/usr/local/freeswitch/recordings \
drachtio/drachtio-freeswitch-mrf freeswitch --sip-port 5038 --tls-port 5039 --rtp-range-start 20000 --rtp-range-end 21000
```


### modules.conf.xml
This is the modules.conf.xml file in the image which dictates which modules get loaded.
```xml
<configuration name="modules.conf" description="Modules">
  <modules>
    <!-- Loggers (I'd load these first) -->
    <load module="mod_console"/>
    <!-- <load module="mod_graylog2"/> -->
    <load module="mod_logfile"/>
    <!-- <load module="mod_syslog"/> -->

    <load module="mod_audio_fork"/>

    <!--<load module="mod_yaml"/>-->

    <!-- Multi-Faceted -->
    <!-- mod_enum is a dialplan interface, an application interface and an api command interface -->
    <!-- <load module="mod_enum"/> -->

    <!-- XML Interfaces -->
    <!-- <load module="mod_xml_rpc"/> -->
    <!-- <load module="mod_xml_curl"/> -->
    <!-- <load module="mod_xml_cdr"/> -->
    <!-- <load module="mod_xml_radius"/> -->
    <!-- <load module="mod_xml_scgi"/> -->

    <!-- Event Handlers -->
    <!-- <load module="mod_amqp"/> -->
    <load module="mod_cdr_csv"/>
    <!-- <load module="mod_cdr_sqlite"/> -->
    <!-- <load module="mod_event_multicast"/> -->
    <load module="mod_event_socket"/>
    <!-- <load module="mod_event_zmq"/> -->
    <!-- <load module="mod_zeroconf"/> -->
    <!-- <load module="mod_erlang_event"/> -->
    <!-- <load module="mod_smpp"/> -->
    <!-- <load module="mod_snmp"/> -->

    <!-- Directory Interfaces -->
    <!-- <load module="mod_ldap"/> -->

    <!-- Endpoints -->
    <!-- <load module="mod_dingaling"/> -->
    <!-- <load module="mod_portaudio"/> -->
    <!-- <load module="mod_alsa"/> -->
    <load module="mod_sofia"/>
    <!-- <load module="mod_loopback"/> -->
    <!-- <load module="mod_woomera"/> -->
    <!-- <load module="mod_freetdm"/> -->
    <!-- <load module="mod_unicall"/> -->
    <!-- <load module="mod_skinny"/> -->
    <!-- <load module="mod_khomp"/>   -->
    <!-- <load module="mod_rtc"/> -->
    <!-- <load module="mod_rtmp"/>   -->
    <!-- <load module="mod_verto"/> -->

    <!-- Applications -->
    <load module="mod_commands"/>
    <load module="mod_conference"/>
    <!-- <load module="mod_curl"/> -->
    <!-- <load module="mod_db"/> -->
    <load module="mod_dptools"/>
    <!-- <load module="mod_expr"/> -->
    <!-- <load module="mod_fifo"/> -->
    <!-- <load module="mod_hash"/> -->
    <!--<load module="mod_mongo"/> -->
    <!-- <load module="mod_voicemail"/> -->
    <!--<load module="mod_directory"/>-->
    <!--<load module="mod_distributor"/>-->
    <!--<load module="mod_lcr"/>-->
    <!--<load module="mod_easyroute"/>-->
    <!-- <load module="mod_esf"/> -->
    <!-- <load module="mod_fsv"/> -->
    <!--<load module="mod_cluechoo"/>-->
    <!-- <load module="mod_valet_parking"/> -->
    <!--<load module="mod_fsk"/>-->
    <!--<load module="mod_spy"/>-->
    <!--<load module="mod_sms"/>-->
    <!--<load module="mod_sms_flowroute"/>-->
    <!--<load module="mod_smpp"/>-->
    <!--<load module="mod_random"/>-->
    <load module="mod_httapi"/>
    <!--<load module="mod_translate"/>-->

    <!-- SNOM Module -->
    <!--<load module="mod_snom"/>-->

    <!-- This one only works on Linux for now -->
    <!--<load module="mod_ladspa"/>-->

    <!-- Dialplan Interfaces -->
    <!-- <load module="mod_dialplan_directory"/> -->
    <load module="mod_dialplan_xml"/>
    <!-- <load module="mod_dialplan_asterisk"/> -->

    <!-- Codec Interfaces -->
    <load module="mod_spandsp"/>
    <load module="mod_g723_1"/>
    <load module="mod_g729"/>
    <!-- <load module="mod_amr"/> -->
    <!--<load module="mod_ilbc"/>-->
    <load module="mod_h26x"/>
    <!-- <load module="mod_b64"/> -->
    <!--<load module="mod_siren"/>-->
    <!--<load module="mod_isac"/>-->
    <load module="mod_opus"/>

    <!-- File Format Interfaces -->
    <!--<load module="mod_av"/>-->
    <load module="mod_sndfile"/>
    <load module="mod_native_file"/>
    <!-- <load module="mod_png"/> -->
    <!-- <load module="mod_shell_stream"/> -->
    <!--For icecast/mp3 streams/files-->
    <!--<load module="mod_shout"/>-->
    <!--For local streams (play all the files in a directory)-->
    <load module="mod_local_stream"/>
    <load module="mod_tone_stream"/>

    <!-- Timers -->
    <!-- <load module="mod_timerfd"/> -->
    <!-- <load module="mod_posix_timer"/> -->

    <!-- Languages -->
    <!-- <load module="mod_v8"/> -->
    <!-- <load module="mod_perl"/> -->
    <!-- <load module="mod_python"/> -->
    <!-- <load module="mod_java"/> -->
    <!-- <load module="mod_lua"/> -->

    <!-- ASR /TTS -->
    <!-- <load module="mod_flite"/> -->
    <!-- <load module="mod_pocketsphinx"/> -->
    <!-- <load module="mod_cepstral"/> -->
    <!-- <load module="mod_tts_commandline"/> -->
    <!-- <load module="mod_rss"/> -->

    <!-- Say -->
    <load module="mod_say_en"/>
    <!-- <load module="mod_say_ru"/> -->
    <!-- <load module="mod_say_zh"/> -->
    <!-- <load module="mod_say_sv"/> -->

    <!-- Third party modules -->
    <!--<load module="mod_nibblebill"/>-->
    <!--<load module="mod_callcenter"/>-->

  </modules>
</configuration>
```

# Build image locally

Docker build command does not natively support reading variable from `.env` file. Use the following command to build the docker image locally

```bash
sh build-locally.sh
```
