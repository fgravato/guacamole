FROM tomcat:9.0-jdk11-openjdk-slim-bullseye
LABEL maintainer="gregg@largenut.com"
LABEL guacamole-version="1.4.0"
LABEL pgmajor-version="11"
USER root

ENV ARCH=amd64 \
  GUAC_VER=1.4.0 \
  GUACAMOLE_HOME=/app/guacamole \
  PG_MAJOR=11 \
  PGDATA=/config/postgres \
  POSTGRES_USER=guacamole \
  POSTGRES_DB=guacamole_db \
  S6_OVERLAY_VERSION=2.2.0.3 \
  CATALINA_HOME=/usr/local/tomcat

### S6-Overlay - multiarch
## Requires buildkit or buildx for TARGETARCH

ARG TARGETARCH

RUN \
    apt-get update \
    && apt-get install -y curl

RUN [ "$TARGETARCH" = "arm64" ] && cd /tmp && curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.gz" || exit 0

RUN [ "$TARGETARCH" = "amd64" ] && cd /tmp && curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" || exit 0

RUN \
 cd /tmp && \
 tar xzf s6-overlay-*.tar.gz -C / && \
 tar -xzf s6-overlay-*.tar.gz -C /usr ./bin && \
 rm s6-overlay-*.tar.gz

### S6-Overlay - multiarch


# Create initial guac directories
RUN \
    mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

# set workdir
WORKDIR ${GUACAMOLE_HOME}

# Install dependencies
RUN \
    apt-get update \
    && apt-get install -y ca-certificates gnupg \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && echo "deb http://http.us.debian.org/debian/ testing non-free contrib main" > /etc/apt/sources.list.d/debian-testing.list \
    && apt-get update \
    && apt-get install -y \
    build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev \
    libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
    libpango1.0-dev libvncserver-dev libtelnet-dev \
    libssl-dev libvorbis-dev libwebp-dev libpulse-dev freerdp2-dev \
    ghostscript postgresql-${PG_MAJOR} \
    && apt-get install -y -t testing libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
RUN curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure --with-init-dir=/etc/init.d \
  && make \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.1.4.jar "https://jdbc.postgresql.org/download/postgresql-42.1.4.jar" \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# Add optional extensions
RUN set -xe \
  && mkdir ${GUACAMOLE_HOME}/extensions-available \
  && for i in auth-ldap auth-duo auth-cas auth-openid auth-quickconnect auth-totp auth-saml auth-header; do \
    echo "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_VER}/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

ENV PATH="/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH"
ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

EXPOSE 8080

ENTRYPOINT [ "/init" ]
