FROM k0d3r1s/alpine:unstable as builder

USER root

ENV REDIS_VERSION dev-main
ENV KEYDB_PRO_DIRECTORY=/usr/local/bin/

COPY ./KeyDB/ /usr/src/keydb 
COPY docker-entrypoint.sh /usr/local/bin/

WORKDIR /usr/src/keydb 

RUN set -eux; \
	\
	apk upgrade --no-cache --update --no-progress --available -X https://dl-cdn.alpinelinux.org/alpine/edge/testing \
&&	apk add --no-cache --update --upgrade -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libuuid libunwind libgcc libstdc++ gcc linux-headers make musl-dev g++ libunwind-dev tcl tcl-dev util-linux-dev curl-dev coreutils openssl openssl-dev perl \
&&	make -j "$(expr $(nproc) / 3)" CFLAGS="-DUSE_PROCESSOR_CLOCK" \
&&	mkdir --parents /usr/local/bin \
&&	cp ./src/keydb-* /usr/local/bin/ \
&&	mkdir /data && chown vairogs:vairogs /data \
&& 	mkdir /flash && chown vairogs:vairogs /flash \
&&	chmod +x /usr/local/bin/docker-entrypoint.sh \
&&	mkdir -p /etc/keydb \
&&	mv -f *.conf /etc/keydb \
&&	cd /usr/local/bin \
&&	sed -i 's/^\(daemonize .*\)$/# \1/' /etc/keydb/keydb.conf \
&&	sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/keydb/keydb.conf \
&&	sed -i 's/^\(logfile .*\)$/# \1/' /etc/keydb/keydb.conf \
&&	sed -i 's/protected-mode yes/protected-mode no/g' /etc/keydb/keydb.conf \
&&	sed -i 's/server-threads 2/server-threads 4/g' /etc/keydb/keydb.conf \
&&	sed -i 's/bind 127.0.0.1 -::1/bind 0.0.0.0/g' /etc/keydb/keydb.conf \
&&	sed -i 's/#   save ""/save ""/g' /etc/keydb/keydb.conf \
&&	sed -i 's/save 900 1/# save 900 1/g' /etc/keydb/keydb.conf \
&&	sed -i 's/save 300 10/# save 300 10/g' /etc/keydb/keydb.conf \
&&	sed -i 's/save 60 10000/# save 60 10000/g' /etc/keydb/keydb.conf \
&&	sed -i 's/stop-writes-on-bgsave-error yes/stop-writes-on-bgsave-error no/g' /etc/keydb/keydb.conf \
&&	grep -o '^[^#]*' /etc/keydb/keydb.conf > /etc/keydb/nkeydb.conf \
&&	sort /etc/keydb/nkeydb.conf > /etc/keydb/keydb.conf \
&&	rm -rf \
		/var/cache/* \
		/tmp/* \
		/usr/share/man \
		/usr/src/keydb \
		/usr/local/bin/keydb-diagnostic-tool.cpp \
		/usr/local/bin/keydb-diagnostic-tool.o \
		/usr/local/bin/keydb-diagnostic-tool.d \
		/usr/local/bin/keydb-diagnostic-tool \
		/usr/local/bin/keydb-check-aof \
		/usr/local/bin/keydb-check-rdb \
		/usr/local/bin/keydb-benchmark \
		/usr/local/bin/keydb-sentinel \
		/etc/keydb/nkeydb.conf \
&&	apk del --purge --no-cache gcc linux-headers make musl-dev openssl-dev g++ tcl-dev util-linux-dev curl-dev libunwind-dev liburing-dev openssl-dev perl coreutils \
&&	chown -R vairogs:vairogs /data

FROM	scratch

COPY 	--from=builder / /

ENV 	REDIS_VERSION dev-main
ENV 	KEYDB_PRO_DIRECTORY=/usr/local/bin/

WORKDIR /data

ENTRYPOINT ["docker-entrypoint.sh"]

USER 	vairogs

EXPOSE 	6379

CMD 	["keydb-server", "/etc/keydb/keydb.conf"]
