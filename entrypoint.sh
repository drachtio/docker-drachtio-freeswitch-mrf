#!/bin/bash
set -e

# listen on all interfaces, allow connections from anywhere
sed -i -e "s/name=\"listen-ip\" value=\".*\"/name=\"listen-ip\" value=\"0.0.0.0\"/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
sed -i -e "s/<\!--<param name=\"apply-inbound-acl\" value=\"loopback.auto\"\/>-->/<param name=\"apply-inbound-acl\" value=\"socket_acl\"\/>/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
sed -i -e "s/<\/network-lists>/<list name=\"socket_acl\" default=\"deny\"><node type=\"allow\" cidr=\"0.0.0.0\/0\"\/><\/list><\/network-lists>/g" /usr/local/freeswitch/conf/autoload_configs/acl.conf.xml

sed -i -e "s/sip_port=[[:digit:]]\+/sip_port=$SIP_PORT/g" /usr/local/freeswitch/conf/vars_diff.xml
sed -i -e "s/tls_port=[[:digit:]]\+/tls_port=$TLS_PORT/g" /usr/local/freeswitch/conf/vars_diff.xml
sed -i -e "s/name=\"listen-port\" value=\"8021\"/name=\"listen-port\" value=\"$EVENT_SOCKET_PORT\"/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
sed -i -e "s/name=\"password\" value=\"ClueCon\"/name=\"password\" value=\"$PASSWORD\"/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
sed -i -e "s/name=\"rtp-start-port\" value=\"16384\"/name=\"rtp-start-port\" value=\"$RTP_RANGE_START\"/g" /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
sed -i -e "s/name=\"rtp-end-port\" value=\"32768\"/name=\"rtp-end-port\" value=\"$RTP_RANGE_END\"/g" /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
sed -i -e "s/name=\"username\" value=\"freeSwitch\"/name=\"username\" value=\"$USERNAME\"/g" /usr/local/freeswitch/conf/sip_profiles/mrf.xml

if [ "$1" = 'freeswitch' ]; then
  shift

  while :; do
    case $1 in
    -g | --g711-only)
      sed -i -e "s/global_codec_prefs=.*\"/global_codec_prefs=PCMU,PCMA\"/g" /usr/local/freeswitch/conf/vars.xml
      sed -i -e "s/outbound_codec_prefs=.*\"/outbound_codec_prefs=PCMU,PCMA\"/g" /usr/local/freeswitch/conf/vars.xml
      shift
      ;;

    -s | --sip-port)
      if [ -n "$2" ]; then
        sed -i -e "s/sip_port=[[:digit:]]\+/sip_port=$2/g" /usr/local/freeswitch/conf/vars_diff.xml
      fi
      shift
      shift
      ;;

    -t | --tls-port)
      if [ -n "$2" ]; then
        sed -i -e "s/tls_port=[[:digit:]]\+/tls_port=$2/g" /usr/local/freeswitch/conf/vars_diff.xml
      fi
      shift
      shift
      ;;

    -e | --event-socket-port)
      if [ -n "$2" ]; then
        sed -i -e "s/name=\"listen-port\" value=\"8021\"/name=\"listen-port\" value=\"$2\"/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
      fi
      shift
      shift
      ;;

    -a | --rtp-range-start)
      if [ -n "$2" ]; then
        sed -i -e "s/name=\"rtp-start-port\" value=\"16384\"/name=\"rtp-start-port\" value=\"$2\"/g" /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
      fi
      shift
      shift
      ;;

    -z | --rtp-range-end)
      if [ -n "$2" ]; then
        sed -i -e "s/name=\"rtp-end-port\" value=\"32768\"/name=\"rtp-end-port\" value=\"$2\"/g" /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
      fi
      shift
      shift
      ;;

    --ext-rtp-ip)
      if [ -n "$2" ]; then
        sed -i -e "s/ext_rtp_ip=.*\"/ext_rtp_ip=$2\"/g" /usr/local/freeswitch/conf/vars_diff.xml
      fi
      shift
      shift
      ;;

    --ext-sip-ip)
      if [ -n "$2" ]; then
        sed -i -e "s/ext_sip_ip=.*\"/ext_sip_ip=$2\"/g" /usr/local/freeswitch/conf/vars_diff.xml
      fi
      shift
      shift
      ;;

    -u | --username)
      if [ -n "$2" ]; then
        sed -i -e "s/name=\"username\" value=\"freeSwitch\"/name=\"username\" value=\"$2\"/g" /usr/local/freeswitch/conf/sip_profiles/mrf.xml
      fi
      shift
      shift
      ;;

    -p | --password)
      if [ -n "$2" ]; then
        sed -i -e "s/name=\"password\" value=\"ClueCon\"/name=\"password\" value=\"$2\"/g" /usr/local/freeswitch/conf/autoload_configs/event_socket.conf.xml
      fi
      shift
      shift
      ;;

    --)
      shift
      break
      ;;

    *)
      break
      ;;
    esac

  done
  exec freeswitch "$@"
fi

exec "$@"