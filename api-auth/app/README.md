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

  // list of endpoints served behind kong
  "paths": [
    "/path/to/resource-1",
    "/path/to/resource-2",
    "/path/to/resource-3"
  ]
}
```

## To add an app in Kong

```bash
docker-compose \
    -f docker-compose-generation.yml \
    run --rm \
    auth \
    add_app "app-name"
```

## To remove an app in Kong

```bash
docker-compose \
    -f docker-compose-generation.yml \
    run --rm \
    auth \
    remove_app "app-name"
```
