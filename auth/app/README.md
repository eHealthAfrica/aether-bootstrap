# App

An app represents an application and defines a set of public URLs.
The main difference between an app and a service is that the app cannot be added to a realm.


The expected format for each app file is:

```javascript
{
  // app name (unique among rest of apps and services)
  "name": "app-name",

  // internal host (behind kong)
  "host": "http://my-app:8888",

  // list of regex paths served behind Kong
  // Evaluates a path dynamically based on the following variables
  // using string substitution:
  //    {public_realm} is the kong public realm name,
  //    {name}  is the service name
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
  "regex_priority": 0
}
```

## To add an app in Kong

```bash
docker compose \
    --env-file .env \
    -f auth/docker-compose.yml \
    run --rm \
    gateway-manager \
    add_app "app-name"
```

## To remove an app in Kong

```bash
docker compose \
    --env-file .env \
    -f auth/docker-compose.yml \
    run --rm \
    gateway-manager \
    remove_app "app-name"
```
