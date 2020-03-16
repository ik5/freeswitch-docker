# based on https://github.com/signalwire/freeswitch/blob/master/docker/release/Dockerfile
FROM debian:buster

ARG TZ=Etc/UTC

RUN rm -f /etc/timezone && \
      echo "${TZ}" > /etc/timezone && \
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
      dpkg-reconfigure -f noninteractive tzdata

RUN groupadd -r freeswitch --gid=999 && useradd -r -g freeswitch --uid=999 freeswitch
RUN groupadd -r share && useradd -m -g share share

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates tzdata
RUN echo "deb https://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y dialog apt-utils \
      && DEBIAN_FRONTEND=noninteractive apt-get install -y wget lsb-release locales gnupg2
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN sed -i "s/buster main/buster main contrib non-free/" /etc/apt/sources.list

RUN apt-get update

ARG use_mariadb=false
RUN if [ "${use_mariadb}" = "true" ] ; then \
      wget -O - 'https://mariadb.org/mariadb_release_signing_key.asc' | apt-key add - ; \
      echo 'deb [arch=amd64] http://mirrors.coreix.net/mariadb/repo/10.4/debian buster main' > /etc/apt/sources.list.d/marida-db.list \
      ; apt-get update \
      ; apt-get install -y mariadb-client-10.4 libmariadb-dev libmysqlclient18 \
      ; fi

ARG use_postgre=false
RUN if [ "${use_postgre}" = "true" ] ; then \
      wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - ; \
      echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
      ; apt-get update \
      ; apt-get install -y pgdg-keyring postgresql-client-11 libpq-dev \
      ; fi


RUN  wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add - \
      && echo "deb https://files.freeswitch.org/repo/deb/freeswitch_1.8 buster main" > /etc/apt/sources.list.d/freeswitch.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y gosu certbot \
      && DEBIAN_FRONTEND=noninteractive \
      apt-get install -y \
      freeswitch-meta-bare freeswitch-conf-vanilla \
      freeswitch-meta-codecs \
      freeswitch-mod-python freeswitch-mod-v8 \
      freeswitch-mod-verto freeswitch-mod-esf freeswitch-mod-lua \
      freeswitch-mod-rtc freeswitch-mod-verto freeswitch-mod-esf \
      freeswitch-mod-sofia freeswitch-mod-ssml freeswitch-conf-curl \
      freeswitch-lang-en freeswitch-mod-cdr-csv freeswitch-mod-commands \
      freeswitch-mod-conference freeswitch-mod-console freeswitch-mod-curl \
      freeswitch-mod-dialplan-directory freeswitch-mod-dialplan-xml \
      freeswitch-mod-directory freeswitch-mod-dptools freeswitch-mod-esl \
      freeswitch-mod-event-multicast freeswitch-mod-event-socket  \
      freeswitch-mod-expr freeswitch-mod-fifo freeswitch-mod-format-cdr \
      freeswitch-mod-fsk freeswitch-mod-hash freeswitch-mod-redis \
      freeswitch-mod-isac freeswitch-mod-json-cdr freeswitch-mod-local-stream \
      freeswitch-mod-loopback freeswitch-mod-native-file freeswitch-mod-odbc-cdr \
      freeswitch-mod-opus freeswitch-mod-opusfile freeswitch-mod-random \
      freeswitch-mod-rtmp freeswitch-mod-say-en freeswitch-mod-shell-stream \
      freeswitch-mod-shout freeswitch-mod-sndfile freeswitch-mod-spy \
      freeswitch-mod-syslog freeswitch-mod-xml-cdr freeswitch-mod-tone-stream \
      freeswitch-sounds-en-us-callie freeswitch-mod-unimrcp freeswitch-mod-enum \
      freeswitch-mod-translate

RUN if [ "${use_mariadb}" = "true" ] ; then apt-get install -y freeswitch-mod-mariadb ; fi
RUN if [ "${use_postgre}" = "true" ] ; then \
      apt-get install -y \
      freeswitch-mod-cdr-pg-csv freeswitch-mod-pgsql \
      ; fi

RUN apt-get remove -y freeswitch-mod-kazoo freeswitch-mod-signalwire
RUN apt-get update && apt-get autoclean -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

RUN mkdir -p /etc/freeswitch
RUN cp -varf /usr/share/freeswitch/conf/vanilla/* /etc/freeswitch/
RUN rm /etc/freeswitch/autoload_configs/modules.conf.xml \
      /etc/freeswitch/autoload_configs/switch.conf.xml \
      /etc/freeswitch/autoload_configs/verto.conf.xml \
      /etc/freeswitch/directory/default/*xml \
      /etc/freeswitch/vars.xml \
      /etc/freeswitch/sip_profiles/external.xml \
      /etc/freeswitch/sip_profiles/external-ipv6.xml \
      /etc/freeswitch/sip_profiles/internal.xml \
      /etc/freeswitch/sip_profiles/internal-ipv6.xml
COPY conf/modules.conf.xml conf/switch.conf.xml conf/verto.conf.xml \
  /etc/freeswitch/autoload_configs/
COPY conf/vars.xml /etc/freeswitch/
COPY conf/external.xml conf/external-ipv6.xml /etc/freeswitch/sip_profiles/
COPY conf/internal.xml conf/internal-ipv6.xml /etc/freeswitch/sip_profiles/

RUN rm -f /root/.bashrc
COPY bashrc /root/.bashrc

## Ports
# Open the container up to the world.
### 8021 fs_cli, 5060 5061 5080 5081 sip and sips, 5000-32000 rtp
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 5066/tcp
EXPOSE 5001/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
EXPOSE 5000-32000/udp
EXPOSE 1935/udp 1935/tcp
# WebRTC (verto) Ports:
EXPOSE 8081/tcp 8082/tcp
EXPOSE 7443/tcp
EXPOSE 1337/tcp 1337/udp
EXPOSE 443/tcp

# Volumes
## Freeswitch Configuration
VOLUME ["/etc/freeswitch"]
## Tmp so we can get core dumps out
VOLUME ["/tmp"]
## Allow to share content
VOLUME ["/home/share"]

# Limits Configuration
COPY freeswitch.limits.conf /etc/security/limits.d/
COPY generate_users.sh /home/share
RUN /home/share/generate_users.sh

SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli -x status | grep -q ^UP || exit 1

WORKDIR /home/share
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]

# vim:set ft=dockesfile:
