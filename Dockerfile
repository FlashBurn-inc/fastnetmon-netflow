FROM alpine:3.7 as builder
MAINTAINER kolychevoleg

RUN apk update && apk add cmake g++ make git autoconf automake libtool boost-dev boost-thread boost-system boost-regex boost-program_options ncurses-dev libpcap-dev
RUN git clone https://github.com/pavel-odintsov/fastnetmon
RUN cd / && wget https://sourceforge.net/projects/log4cpp/files/log4cpp-1.1.x%20%28new%29/log4cpp-1.1/log4cpp-1.1.1.tar.gz/download -O /log4cpp-1.1.1.tar.gz && tar zxvf /log4cpp-1.1.1.tar.gz && rm /log4cpp-1.1.1.tar.gz && cd /log4cpp && ./configure --prefix=/opt/log4cpp1.1.1 && make && make install
RUN cd / && git clone -b json-c-0.13 https://github.com/json-c/json-c.git && cd /json-c && ./autogen.sh && ./configure --prefix=/opt/json-c-0.13 && touch aclocal.m4 Makefile.in && make && make install
RUN cd / && git clone -b 2.2.2-stable https://github.com/ntop/nDPI.git && cd /nDPI && ./autogen.sh && ./configure --prefix=/opt/ndpi && make && make install
RUN mv /fastnetmon /fastnetmon_src && \
    mkdir -p /fastnetmon_src/src/build && \
    cd /fastnetmon_src/src/build && \
# Build with fresh release of libndpi
    sed -i 's/\/opt\/ndpi\/include\/libndpi\-1.7.1/\/opt\/ndpi\/include\/libndpi\-2.2.2/' ../CMakeLists.txt && \
# Build with fresh release of json-c
    sed -i 's/\/opt\/json\-c\-0.12/\/opt\/json\-c\-0.13/' ../CMakeLists.txt && \
# Hack to disable AF_PACKET support, it builds with error and we don't need it for NetFlow anyway
    sed -i 's/if\s*(ENABLE_AFPACKET_SUPPORT)/set (ENABLE_AFPACKET_SUPPORT OFF)\nif (ENABLE_AFPACKET_SUPPORT)/' ../CMakeLists.txt && \
    cmake .. -DDISABLE_PF_RING_SUPPORT=ON -DDISABLE_NETMAP_SUPPORT=ON -DENABLE_LUA_SUPPORT=NO && \
    make && \
    cd /fastnetmon_src/src && \
# Remove all comment lines in config
    sed -i '/^[[:blank:]]*#/d;s/#.*//' fastnetmon.conf && \
# Disable ban, monitor only
    sed -i 's/enable_ban\s*=.*/enable_ban = off/' fastnetmon.conf && \
# Enable graphite
    sed -i 's/graphite\s*=.*/graphite = on/' fastnetmon.conf && \
    echo $'\
tar zxf /build.tgz && \
GRAPHITE_IP=`getent hosts $GRAPHITE | awk \'{ print $1 }\'` && \
AVERAGE_CALCULATION_TIME=${AVERAGE_CALCULATION_TIME:-1} && \
sed -i "s/graphite_host = 127.0.0.1/graphite_host = ${GRAPHITE_IP:-graphite_env_not_set}/" /etc/fastnetmon.conf && \
sed -i "s/average_calculation_time\s*=.*/average_calculation_time = $AVERAGE_CALCULATION_TIME/" /etc/fastnetmon.conf && \
echo "$LOCAL_NETWORKS" > /etc/networks_list && \
echo "Starting fastnetmon with config:" && \
cat /etc/fastnetmon.conf && \
/fastnetmon --log_file /dev/stdout\
' >/start.sh && \
    cp /opt/json-c-0.13/lib/libjson-c.so* /usr/lib/ && \
    cp /opt/ndpi/lib/libndpi.so* /usr/lib/ && \
    cp /opt/log4cpp1.1.1/lib/liblog4cpp.so* /usr/lib/ && \
    cp /fastnetmon_src/src/fastnetmon.conf /etc/fastnetmon.conf && \
    cp /fastnetmon_src/src/build/fastnetmon / && \
    cp /fastnetmon_src/src/build/fastnetmon_client / && \
    tar czf /build.tgz /usr/lib/libjson-c.so* /usr/lib/libndpi.so* /usr/lib/liblog4cpp.so* /etc/fastnetmon.conf /fastnetmon_client /fastnetmon

FROM alpine:3.7
RUN apk update && apk add boost-thread boost-system boost-regex boost-program_options libpcap libstdc++ ncurses
COPY --from=builder /build.tgz /start.sh /
CMD ["/bin/sh", "/start.sh"]
