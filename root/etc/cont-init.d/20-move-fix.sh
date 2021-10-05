#!/usr/bin/with-contenv sh

if [ -d "/bitnami/tomcat/webapps/guacamole" ]; then
  mv /bitnami/tomcat/webapps/guacamole/* /app/guacamole
  rm -rf /bitnami/tomcat/webapps/guacamole
fi