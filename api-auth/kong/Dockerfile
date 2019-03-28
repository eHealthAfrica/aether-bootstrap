FROM kong:latest

# Kong install dir
ENV KONG_HOME /usr/local/share/lua/5.1/kong

# Install OIDC plugin
RUN apk -U add git unzip gcc libc-dev openssl-dev && \
  git clone https://github.com/eHealthAfrica/kong-oidc-auth.git $KONG_HOME/plugins/kong-oidc-auth && \
  (cd $KONG_HOME/plugins/kong-oidc-auth/ && luarocks make *.rockspec)
