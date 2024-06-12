FROM debian:bullseye-slim AS base
ARG BUILD_CPUS=1
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done \
    && apt-get update && apt-get -y --quiet --allow-remove-essential upgrade \
    && apt-get install -y --quiet --no-install-recommends \
    python-is-python3 lsof gcc g++ make build-essential git autoconf automake default-mysql-client redis-tools \
    curl telnet libtool libtool-bin libssl-dev libcurl4-openssl-dev libz-dev liblz4-tool \
    libxtables-dev libip6tc-dev libip4tc-dev  libiptc-dev libavformat-dev liblua5.1-0-dev libavfilter-dev libavcodec-dev libswresample-dev \
    libevent-dev libpcap-dev libxmlrpc-core-c3-dev markdown libjson-glib-dev lsb-release libpq-dev php-dev \
    libhiredis-dev gperf libspandsp-dev default-libmysqlclient-dev htop dnsutils gdb libtcmalloc-minimal4 \
    gnupg2 wget pkg-config ca-certificates libjpeg-dev libsqlite3-dev libpcre3-dev libldns-dev libboost-all-dev \
    libspeex-dev libspeexdsp-dev libedit-dev libtiff-dev yasm libswscale-dev haveged libre2-dev \
    libopus-dev libsndfile-dev libshout3-dev libmpg123-dev libmp3lame-dev libopusfile-dev libgoogle-perftools-dev \
    && git config --global http.postBuffer 524288000  \
  	&& git config --global https.postBuffer 524288000 \
	  && git config --global pull.rebase true

FROM base AS base-cmake
WORKDIR /usr/local/src
# TARGETARCH=x86_64 or aarch64
ARG TARGETARCH=x86_64
RUN export CMAKE_VERSION=3.28.3 \
    && wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${TARGETARCH}.sh \
    && chmod +x cmake-${CMAKE_VERSION}-linux-${TARGETARCH}.sh \
    && ./cmake-${CMAKE_VERSION}-linux-${TARGETARCH}.sh --skip-license --prefix=/usr/local \
    && rm -f cmake-${CMAKE_VERSION}-linux-${TARGETARCH}.sh \
    && cmake --version

FROM base-cmake AS grpc
WORKDIR /usr/local/src
RUN git clone --depth 1 --branch v1.57.0 https://github.com/grpc/grpc && cd grpc \
    && git submodule update --init --recursive
RUN cd grpc \
    && mkdir -p cmake/build \
    && cd cmake/build \
    && cmake -DBUILD_SHARED_LIBS=ON -DgRPC_SSL_PROVIDER=package -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo ../.. \
    && make -j ${BUILD_CPUS} \
    && make install
RUN ldconfig /usr/local/lib

FROM grpc AS grpc-googleapis
WORKDIR /usr/local/src
RUN git clone https://github.com/googleapis/googleapis && cd googleapis && git checkout d81d0b9e6993d6ab425dff4d7c3d05fb2e59fa57 \
    && LANGUAGE=cpp make -j ${BUILD_CPUS}
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

FROM grpc-googleapis AS nuance-asr-grpc-api
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch main https://github.com/drachtio/nuance-asr-grpc-api.git \
    && cd nuance-asr-grpc-api \
    && LANGUAGE=cpp make

FROM grpc-googleapis AS riva-asr-grpc-api
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch main https://github.com/drachtio/riva-asr-grpc-api.git \
    && cd riva-asr-grpc-api \
    && LANGUAGE=cpp make

FROM grpc-googleapis AS soniox-asr-grpc-api
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch main https://github.com/drachtio/soniox-asr-grpc-api.git \
    && cd soniox-asr-grpc-api \
    && LANGUAGE=cpp make

FROM grpc-googleapis AS cobalt-asr-grpc-api
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch main https://github.com/drachtio/cobalt-asr-grpc-api.git \
    && cd cobalt-asr-grpc-api \
    && LANGUAGE=cpp make
        
FROM base-cmake AS websockets
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch v4.3.3 https://github.com/warmcat/libwebsockets.git \
    && cd /usr/local/src/libwebsockets \
    && mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo && make && make install

FROM base AS speechsdk
# TARGETARCH=x86_64 or aarch64
ARG TARGETARCH=x86_64
COPY ./files/SpeechSDK-Linux-1.37.0.tar.gz /tmp/
WORKDIR /tmp
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN tar xvfz SpeechSDK-Linux-1.37.0.tar.gz \
    && cd SpeechSDK-Linux-1.37.0 \
    && cp -r include /usr/local/include/MicrosoftSpeechSDK \
    && cp -r lib/ /usr/local/lib/MicrosoftSpeechSDK \
    && if [ "$TARGETARCH" = "aarch64" ]; then \
           cp /usr/local/lib/MicrosoftSpeechSDK/arm64/libMicrosoft.*.so /usr/local/lib/; \
       else \
           cp /usr/local/lib/MicrosoftSpeechSDK/x64/libMicrosoft.*.so /usr/local/lib/; \
       fi \
    && ls -lrt /usr/local/lib/

FROM base AS freeswitch-modules
WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/jambonz/freeswitch-modules.git -b 1.2.15

FROM base AS spandsp
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone https://github.com/freeswitch/spandsp.git && cd spandsp && git checkout 0d2e6ac \
    && ./bootstrap.sh && ./configure && make -j ${BUILD_CPUS} && make install

FROM base AS sofia-sip
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch master https://github.com/freeswitch/sofia-sip.git \
    && cd sofia-sip \
    && ./bootstrap.sh && ./configure && make -j ${BUILD_CPUS} && make install

FROM base AS libfvad
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 https://github.com/dpirch/libfvad.git \
    && cd libfvad \
    && autoreconf -i && ./configure && make -j ${BUILD_CPUS} && make install

FROM base-cmake AS aws-sdk-cpp
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch 1.11.283 https://github.com/aws/aws-sdk-cpp.git \
    && cd aws-sdk-cpp \
    && git submodule update --init --recursive
RUN cd /usr/local/src/aws-sdk-cpp \
    && mkdir -p build && cd build \
    && cmake .. -DBUILD_ONLY="lexv2-runtime;transcribestreaming" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=ON -DCMAKE_CXX_FLAGS="-Wno-unused-parameter -Wno-error=nonnull -Wno-error=deprecated-declarations -Wno-error=uninitialized -Wno-error=maybe-uninitialized" \
    && make -j ${BUILD_CPUS} && make install \
    && mkdir -p /usr/local/lib/pkgconfig \
    && find /usr/local/src/aws-sdk-cpp/ -type f -name "*.pc" | xargs cp -t /usr/local/lib/pkgconfig/

FROM base-cmake AS aws-c-common
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 https://github.com/awslabs/aws-c-common.git \
    && cd aws-c-common \
    && mkdir -p build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS="-Wno-unused-parameter" \
    && make -j ${BUILD_CPUS} && make install

FROM base AS freeswitch
COPY ./files/ /tmp/
COPY --from=aws-c-common /usr/local/include/ /usr/local/include/
COPY --from=aws-c-common /usr/local/lib/ /usr/local/lib/
COPY --from=aws-sdk-cpp /usr/local/include/ /usr/local/include/
COPY --from=aws-sdk-cpp /usr/local/lib/ /usr/local/lib/
COPY --from=grpc /usr/local/include/ /usr/local/include/
COPY --from=grpc /usr/local/lib/ /usr/local/lib/
COPY --from=libfvad /usr/local/include/ /usr/local/include/
COPY --from=libfvad /usr/local/lib/ /usr/local/lib/
COPY --from=sofia-sip /usr/local/bin/ /usr/local/bin/
COPY --from=sofia-sip /usr/local/include/ /usr/local/include/
COPY --from=sofia-sip /usr/local/lib/ /usr/local/lib/
COPY --from=sofia-sip /usr/local/share/sofia-sip/ /usr/local/share/sofia-sip/
COPY --from=spandsp /usr/local/include/ /usr/local/include/
COPY --from=spandsp /usr/local/lib/ /usr/local/lib/
COPY --from=speechsdk /usr/local/include/ /usr/local/include/
COPY --from=speechsdk /usr/local/lib/ /usr/local/lib/
COPY --from=websockets /usr/local/include/ /usr/local/include/
COPY --from=websockets /usr/local/lib/ /usr/local/lib/
WORKDIR /usr/local/src
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN git clone --depth 1 --branch v1.10.10 https://github.com/signalwire/freeswitch.git
COPY --from=freeswitch-modules /usr/local/src/freeswitch-modules/ /usr/local/src/freeswitch/src/mod/applications/
COPY --from=nuance-asr-grpc-api /usr/local/src/nuance-asr-grpc-api /usr/local/src/freeswitch/libs/nuance-asr-grpc-api
COPY --from=riva-asr-grpc-api /usr/local/src/riva-asr-grpc-api /usr/local/src/freeswitch/libs/riva-asr-grpc-api
COPY --from=soniox-asr-grpc-api /usr/local/src/soniox-asr-grpc-api /usr/local/src/freeswitch/libs/soniox-asr-grpc-api
COPY --from=cobalt-asr-grpc-api /usr/local/src/cobalt-asr-grpc-api /usr/local/src/freeswitch/libs/cobalt-asr-grpc-api
COPY --from=grpc-googleapis /usr/local/src/googleapis /usr/local/src/freeswitch/libs/googleapis
RUN cp /tmp/configure.ac.extra /usr/local/src/freeswitch/configure.ac \
    && cp /tmp/Makefile.am.extra /usr/local/src/freeswitch/Makefile.am \
    && cp /tmp/ax_check_compile_flag.m4 /usr/local/src/freeswitch/ax_check_compile_flag.m4 \
    && cp /tmp/modules.conf.in.extra /usr/local/src/freeswitch/build/modules.conf.in \
    && cp /tmp/modules.conf.vanilla.xml.extra /usr/local/src/freeswitch/conf/vanilla/autoload_configs/modules.conf.xml \
    && cp /tmp/avmd.conf.xml /usr/local/src/freeswitch/conf/vanilla/autoload_configs/avmd_conf.xml \
    && cp /tmp/switch_core_media.c.patch /usr/local/src/freeswitch/src \
    && cp /tmp/switch_rtp.c.patch /usr/local/src/freeswitch/src  \
    && cp /tmp/mod_avmd.c.patch /usr/local/src/freeswitch/src/mod/applications/mod_avmd \
    && cp /tmp/mod_httapi.c.patch /usr/local/src/freeswitch/src/mod/applications/mod_httapi \
    && cd /usr/local/src/freeswitch/src \
    && patch < switch_core_media.c.patch \
    && patch < switch_rtp.c.patch \
    && cd /usr/local/src/freeswitch/src/mod/applications/mod_avmd \
    && patch < mod_avmd.c.patch \
    && cd /usr/local/src/freeswitch/src/mod/applications/mod_httapi \
    && patch < mod_httapi.c.patch \
    && cd /usr/local/src/freeswitch/src \
    && cp /tmp/switch_event.c . \
    && cp /tmp/mod_conference.h /usr/local/src/freeswitch/src/mod/applications/mod_conference \
    && cp /tmp/conference_api.c /usr/local/src/freeswitch/src/mod/applications/mod_conference \
    && sed -i '/#ifndef cJSON_AS4CPP__h/i #ifndef cJSON__h\n#define cJSON__h' /usr/local/include/aws/core/external/cjson/cJSON.h \
    && echo '#endif' >> /usr/local/include/aws/core/external/cjson/cJSON.h \
    && cd /usr/local/src/freeswitch \
    && ./bootstrap.sh -j \
    && ./configure --enable-tcmalloc=yes --with-lws=yes --with-extra=yes --with-aws=yes
RUN cd /usr/local/src/freeswitch \
    && make -j ${BUILD_CPUS} \
    && make install
RUN cd /usr/local/src/freeswitch \
    && cp /tmp/acl.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/event_socket.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/switch.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/conference.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && rm -Rf /usr/local/freeswitch/conf/dialplan/* \
    && rm -Rf /usr/local/freeswitch/conf/sip_profiles/* \
    && cp /tmp/dialplan/* /usr/local/freeswitch/conf/dialplan/ \
    && cp /tmp/sip_profiles/* /usr/local/freeswitch/conf/sip_profiles/ \
    && cp /usr/local/src/freeswitch/conf/vanilla/autoload_configs/modules.conf.xml /usr/local/freeswitch/conf/autoload_configs \
	  && sed -i -e 's/global_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8/global_codec_prefs=PCMU,PCMA,OPUS,G722/g' /usr/local/freeswitch/conf/vars.xml \
	  && sed -i -e 's/outbound_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8/outbound_codec_prefs=PCMU,PCMA,OPUS,G722/g' /usr/local/freeswitch/conf/vars.xml

FROM debian:bullseye-slim AS final
# TARGETARCH=x86_64 or aarch64
ARG TARGETARCH=x86_64
ENV LIB_DIR=/usr/lib/${TARGETARCH}-linux-gnu
COPY --from=freeswitch /usr/local/freeswitch/ /usr/local/freeswitch/
COPY --from=freeswitch /usr/local/bin/ /usr/local/bin/
COPY --from=freeswitch /usr/local/lib/ /usr/local/lib/
COPY --from=freeswitch /usr/lib/${TARGETARCH}-linux-gnu/ /usr/lib/
RUN apt update && apt install -y --quiet --no-install-recommends ca-certificates libsqlite3-0 libcurl4 libpcre3 libspeex1 libspeexdsp1 libedit2 libtiff5 libopus0 libsndfile1 libshout3 \
    && ldconfig && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/freeswitch/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

COPY ./entrypoint.sh /entrypoint.sh
COPY ./vars_diff.xml  /usr/local/freeswitch/conf/vars_diff.xml
COPY ./freeswitch.xml /usr/local/freeswitch/conf/freeswitch.xml

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["freeswitch"]

# Volumes for persistent data
VOLUME ["/usr/local/freeswitch/log", "/usr/local/freeswitch/recordings", "/usr/local/freeswitch/sounds"]
