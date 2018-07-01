FROM alpine:3.7 as builder
MAINTAINER capnis

RUN apk update && apk add cmake g++ make git autoconf automake libtool boost-dev boost-thread boost-system boost-regex boost-program_options ncurses-dev libpcap-dev
RUN git clone https://github.com/pavel-odintsov/fastnetmon
RUN cd / && wget --no-check-certificate https://sourceforge.net/projects/log4cpp/files/log4cpp-1.1.x%20%28new%29/log4cpp-1.1/log4cpp-1.1.1.tar.gz/download -O /log4cpp-1.1.1.tar.gz && tar zxvf /log4cpp-1.1.1.tar.gz && rm /log4cpp-1.1.1.tar.gz && cd /log4cpp && ./configure --prefix=/opt/log4cpp1.1.1 && make && make install
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
    cd /fastnetmon_src/src
#tar zxf /build.tgz && \
RUN mkdir -p /configs && \
cp /fastnetmon_src/src/fastnetmon.conf /configs/fastnetmon.conf && \
echo -e "192.168.0.0/16\n172.16.0.0/12\n10.0.0.0/8" > /configs/networks_list && \
cp /fastnetmon_src/src/notify_about_attack.sh /configs && \
chmod 755 /configs/notify_about_attack.sh && \
echo -e "Starting fastnetmon\n/fastnetmon --log_file /dev/stdout" > /start.sh && \
    cp /opt/json-c-0.13/lib/libjson-c.so* /usr/lib/ && \
    cp /opt/ndpi/lib/libndpi.so* /usr/lib/ && \
    cp /opt/log4cpp1.1.1/lib/liblog4cpp.so* /usr/lib/ && \
    cp /fastnetmon_src/src/fastnetmon.conf /etc/fastnetmon.conf && \
    cp /fastnetmon_src/src/build/fastnetmon / && \
    cp /fastnetmon_src/src/build/fastnetmon_client / && \
    tar czf /build.tgz /usr/lib/libjson-c.so* /usr/lib/libndpi.so* /usr/lib/liblog4cpp.so* /fastnetmon_client /fastnetmon /configs/*

FROM alpine:3.7
RUN apk update && apk add boost-thread boost-system boost-regex boost-program_options libpcap libstdc++ ncurses
COPY --from=builder /build.tgz /start.sh /
RUN tar zxf /build.tgz && \
ln -s /configs/fastnetmon.conf /etc/fastnetmon.conf && \
ln -s /configs/networks_list /etc/networks_list && \
ln -s /configs/notify_about_attack.sh /usr/local/bin/notify_about_attack.sh
VOLUME ["/configs"]
CMD ["/bin/sh", "/start.sh"]
