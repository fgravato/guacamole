**:warning: The original creator abandoned this, so I reworked a few things rebased it with bitnami/tomcat and brought all packages current.**

Project: https://git.largenut.com/unsafetypin/docker-guacamole

Dockerhub: https://hub.docker.com/r/unsafetypin/guacamole

# Versions
```
Debian: 10
Guacamole: 1.3.0
Postgresql: 11
S6-overlay: 2.2.0.3
freerdp: 2.3.0 via debian-buster-backports
```

# Docker Guacamole

A Docker Container for [Apache Guacamole](https://guacamole.apache.org/), a client-less remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH over HTML5.

This container runs the guacamole web client, the guacd server and a postgres database.

## Usage

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  registry.largenut.com/unsafetypin/docker-guacamole/docker-guacamole
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.

* `-p 8080:8080` - Binds the service to port 8080 on the Docker host, **required**
* `-v /config` - The config and database location, **required**
* `-e EXTENSIONS` - See below for details.

## Enabling Extensions

Extensions can be enabled using the `-e EXTENSIONS` variable. Multiple extensions can be enabled using a comma separated list without spaces.

For example:

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  -e "EXTENSIONS=auth-ldap,auth-duo"
  oznu/guacamole
```

Currently the available extensions are:

* auth-ldap - [LDAP Authentication](https://guacamole.apache.org/doc/gug/ldap-auth.html)
* auth-duo - [Duo two-factor authentication](https://guacamole.apache.org/doc/gug/duo-auth.html)
* auth-header - [HTTP header authentication](https://guacamole.apache.org/doc/gug/header-auth.html)
* auth-cas - [CAS Authentication](https://guacamole.apache.org/doc/gug/cas-auth.html)
* auth-openid - [OpenID Connect authentication](https://guacamole.apache.org/doc/gug/openid-auth.html)
* auth-totp - [TOTP two-factor authentication](https://guacamole.apache.org/doc/gug/totp-auth.html)
* auth-quickconnect - [Ad-hoc connections extension](https://guacamole.apache.org/doc/gug/adhoc-connections.html)

You should only enable the extensions you require, if an extensions is not configured correctly in the `guacamole.properties` file it may prevent the system from loading. See the [official documentation](https://guacamole.apache.org/doc/gug/) for more details.

## Default User

The default username is `guacadmin` with password `guacadmin`.

## Windows-based Docker Hosts

Mapped volumes behave differently when running Docker for Windows and you may encounter some issues with PostgreSQL file system permissions. To avoid these issues, and still retain your config between container upgrades and recreation, you can use the local volume driver, as shown in the `docker-compose.yml` example below. When using this setup be careful to gracefully stop the container or data may be lost.

```yml
version: "2"
services:
  guacamole:
    image: registry.largenut.com/unsafetypin/docker-guacamole/docker-guacamole
    container_name: guacamole
    volumes:
      - postgres:/config
    ports:
      - 8080:8080
volumes:
  postgres:
    driver: local
```
