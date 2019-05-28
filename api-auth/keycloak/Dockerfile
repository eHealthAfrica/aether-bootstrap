# This is required to run Keycloak behind KONG @ /keycloak/
# We just edit the default standalone configs from the base image.

FROM jboss/keycloak:6.0.1
USER jboss

RUN sed -i -e \
    's/<web-context>auth<\/web-context>/<web-context>keycloak\/auth<\/web-context>/' \
    /opt/jboss/keycloak/standalone/configuration/standalone.xml \
    /opt/jboss/keycloak/standalone/configuration/standalone-ha.xml
