# Service

A service represents an application and defines a set of public and protected URLs
and the route to access to them.

The expected format for each service file is:

```javascript
{
  // kong service name (unique among rest of services)
  "name": "service-name",

  // internal host (behind kong)
  "host": "http://my-service:8888",

  // list of public regex paths served behind Kong
  // Evaluates a path dynamically based on the following variables
  // using string substitution:
  //    {public_realm} is the kong public realm name,
  //    {name}  is the service name
  // These paths don't depend on the realm and are shared among all realms
  "paths": [
    "/path/to/resource-1",
    "/{public_realm}/path/to/resource-2",
    "/{name}/path/to/resource-3"
  ],

  // [optional] (defaults to "false")
  // https://docs.konghq.com/1.1.x/proxy/
  "strip_path": "true",

  // [optional] (defaults to "0")
  // https://docs.konghq.com/1.1.x/proxy/#evaluation-order
  "regex_priority": 0,

  // list of urls protected by "kong-oidc-auth" plugin
  // all of these urls provide the X-Outh-Token header
  // or are redirected to keycloak to authenticate
  "oidc_endpoints": [
    {
      // endpoint name (unique among rest of OIDC endpoints in this service)
      "name": "protected",

      // list of regex paths
      // Evaluates a path dynamically based on the following variables
      // using string substitution:
      //    {realm} is the realm name,
      //    {name}  is the service name
      "paths": [
        "/{realm}/{name}",
        "/{realm}/{name}-profile/path/to/resource",
        "/{realm}/{name}-version/\\d+/"
      ],

      // [optional] (defaults to "false")
      // https://docs.konghq.com/1.1.x/proxy/
      "strip_path": "false",

      // [optional] (defaults to "0")
      // https://docs.konghq.com/1.1.x/proxy/#evaluation-order
      "regex_priority": 0,

      "oidc_override": {
        // [optional & advanced!]
        // provide overrides to the standard oidc configuration passed to Kong-Oidc
        // Do not use this unless you absolutely have to.
        "config.user_keys": ["preferred_username", "email"]
      }
    },
    // ...
  ],

  // list of urls that are not protected by "kong-oidc-auth" plugin
  // the urls can be open or protected by another authentication method
  // like BASIC authentication, token authentication...
  "public_endpoints": [
    {
      // endpoint name (unique among rest of public endpoints in this service)
      "name": "public",

      // list of regex paths
      // Evaluates a path dynamically based on the following variables
      // using string substitution:
      //    {public_realm} is the kong public realm name (used in public endpoints),
      //    {realm} is the realm name,
      //    {name}  is the service name
      "paths": [
        "/{realm}/{name}/static",
        "/{realm}/{name}/public/endpoint-2/\\d+"
      ],

      // [optional] (defaults to "false")
      // https://docs.konghq.com/1.1.x/proxy/
      "strip_path": "true",

      // [optional] (defaults to "0")
      // https://docs.konghq.com/1.1.x/proxy/#evaluation-order
      "regex_priority": 0
    },
    // ...
  ]
}
```

## To add a service to an existing realm in Kong

```bash
docker-compose \
    -f auth/docker-compose.yml \
    run --rm \
    gateway-manager \
    add_service "service-name" "realm-name" "kong-client-name-in-keycloak"
```

## To remove a service from an existing realm in Kong

```bash
docker-compose \
    -f auth/docker-compose.yml \
    run --rm \
    gateway-manager \
    remove_service "service-name" "realm-name"
```

## To remove a service from ALL existing realms in Kong

```bash
docker-compose \
    -f auth/docker-compose.yml \
    run --rm \
    gateway-manager \
    remove_service "service-name"
```
