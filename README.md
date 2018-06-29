# Gather

> Survey collection and analytics

## Table of contents

- [Table of contents](#table-of-contents)
- [Setup](#Setup)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
    - [Gather](#gather)
- [Usage](#usage)
  - [Users & Authentication](#users--authentication)
    - [UMS settings for local development](#ums-settings-for-local-development)
    - [Token Authentication](#token-authentication)
- [Development](#development)
- [Deployment](#deployment)
- [Containers and services](#containers-and-services)
- [Run commands in the containers](#run-commands-in-the-containers)
  - [Run tests](#run-tests)
  - [Upgrade python dependencies](#upgrade-python-dependencies)
    - [Check outdated dependencies](#check-outdated-dependencies)
    - [Update requirements file](#update-requirements-file)


## Setup

### Dependencies

- git
- [docker-compose](https://docs.docker.com/compose/)
- Permission to the eHealthAfrica DockerHub repository - contact eHA DevOps

*[Return to TOC](#table-of-contents)*

### Installation

```bash
git clone git@github.com:eHealthAfrica/{repository-name}.git
cd {repository-name}

docker-compose build

```

Include this entry in your `/etc/hosts` file:

```
127.0.0.1    kernel.aether.local odk.aether.local gather.local
```

*[Return to TOC](#table-of-contents)*

### Environment Variables

Most of the environment variables are set to default values. This is the short list
of the most common ones with non default values. For more info take a look at the file
[docker-compose-base.yml](docker-compose-base.yml)


#### Gather

- Gather specific:
  - `INSTANCE_NAME`: `Gather on Aether` identifies the current instance among others.
- CSV export:
  - `CSV_MAX_ROWS_SIZE`: `1048575` indicates the maximum number of rows to include in the CSV file.
  - `CSV_HEADER_RULES`: `remove-prefix;payload.,remove-prefix;None.,replace;.;:;`
    CSV header labels parser rules, transforms header from `payload.None.a.b.c` to `a:b:c`.
    Default rules are `remove-prefix;payload.,remove-prefix;None.,`, removes `payload.None.` prefixes.
  - `CSV_HEADER_RULES_SEP`: `;` rules divider. Default `:`. Include it if any of the rules uses `:`.
    See more in `aether.common.drf.renderers.CustomCSVRenderer`.
- Authentication (UMS):
  - `CAS_SERVER_URL`: `https://ums-dev.ehealthafrica.org`.
  - `HOSTNAME`: `gather.local`.
- Django specific:
  - `RDS_DB_NAME`: `gather` Postgres database name.
  - `WEB_SERVER_PORT`: `8080` Web server port.
- Aether specific:
  - `AETHER_MODULES`: `odk,` Comma separated list with the available modules.
    To avoid confusion, the values will match the container name, `odk`.
  - Aether Kernel:
    - `AETHER_KERNEL_TOKEN`: `a2d6bc20ad16ec8e715f2f42f54eb00cbbea2d24` Token to connect to Aether Kernel Server.
    - `AETHER_KERNEL_URL`: `http://kernel:8001` Aether Kernel Server url.
    - `AETHER_KERNEL_URL_TEST`: `http://kernel-test:9001` Aether Kernel Testing Server url.
  - Aether ODK:
    - `AETHER_ODK_TOKEN`: `d5184a044bb5acff89a76ec4e67d0fcddd5cd3a1` Token to connect to Aether ODK Server.
    - `AETHER_ODK_URL`: `http://odk:8443` Aether ODK Server url.
    - `AETHER_ODK_URL_TEST`: `http://odk-test:9002` Aether ODK Testing Server url.


## Usage

```bash
docker-compose up --build    # this will update the cointainers if needed
```

_If you get errors like:_
```ERROR: pull access denied for <foo> repository does not exist or may require 'docker login' ```
_verify you are logged into docker and have permission to the repository._

This will start:

- **gather** on `http://gather.local:8000`
  and create a superuser `admin-gather`.

- **aether-kernel** on `http://kernel.aether.local:8001`
  and create a superuser `admin-kernel` with the needed TOKEN.

- **aether-odk** on `http://odk.aether.local:8443`
  and create a superuser `admin-odk` with the needed TOKEN.


All the created superusers have password `adminadmin` in each container.

If the `nginx` container is also started the url ports can be removed.
- `http://gather.local`
- `http://kernel.aether.local`
- `http://odk.aether.local`


*[Return to TOC](#table-of-contents)*

### Users & Authentication

The app defers part of the users management to
[eHA UMS tool](https://github.com/eHealthAfrica/ums).

Set the `HOSTNAME` and `CAS_SERVER_URL` environment variables if you want to
activate the UMS integration in each container.


#### UMS settings for local development

The project is `gather-aether` **Gather&Aether**.

The client services are:

  - **Gather & Aether (local)**  for `gather.local`.


Other options are to log in via token, via basic authentication or via the
standard django authentication process in the admin section.
The available options depend on each container.

*[Return to TOC](#table-of-contents)*

#### Token Authentication

The communication between the servers is done via
[token authentication](http://www.django-rest-framework.org/api-guide/authentication/#tokenauthentication).

In `gather` there are tokens per user to connect to other servers.
This means that every time a logged in user tries to visit any page that requires
to fetch data from any of the other apps, `aether-kernel` and/or `aether-odk`,
the system will verify that the user token for that app is valid or will request
a new one using the global tokens, `AETHER_KERNEL_TOKEN` and/or `AETHER_ODK_TOKEN`;
that's going to be used for all requests and will allow the system to better
track the user actions.

*[Return to TOC](#table-of-contents)*


## Development

All development should be tested within the container, but developed in the host folder.
Read the [docker-compose-base.yml](docker-compose-base.yml) file to see how it's mounted.

*[Return to TOC](#table-of-contents)*


## Deployment

Set the `HOSTNAME` and `CAS_SERVER_URL` environment variables if you want to
activate the UMS integration in each container.

If a valid `AETHER_KERNEL_TOKEN` and `AETHER_KERNEL_URL` combination is not set,
the server will still start, but all connections to Aether Kernel Server will fail.

This also applies to Aether ODK module.

*[Return to TOC](#table-of-contents)*


## Containers and services

The list of the main containers:


| Container         | Description                                                     |
| ----------------- | --------------------------------------------------------------- |
| db                | [PostgreSQL](https://www.postgresql.org/) database              |
| **kernel**        | Aether Kernel app                                               |
| **odk**           | Aether ODK Collect Adapter app (imports data from ODK Collect)  |
| **gather**        | Gather app                                                      |
| kernel-test       | Aether Kernel TESTING app (used only in e2e testss)             |
| odk-test          | Aether ODK TESTING app (used only in e2e testss)                |


All of the containers definition for development can be found in the
[docker-compose-base.yml](docker-compose-base.yml) file.

*[Return to TOC](#table-of-contents)*


## Run commands in the containers

The [entrypoint.sh](app/entrypoint.sh)
script offers a range of commands to start services or run commands.
The full list of commands can be seen in the script file.

The pattern to run a command is always
``docker-compose run <container-name> <entrypoint-command> <...args>``

*[Return to TOC](#table-of-contents)*


### Run tests

This will stop ALL running containers and execute `gather` tests.

```bash
./scripts/test_gather.sh
```

or

```bash
docker-compose run gather test

```

or

```bash
docker-compose run gather test_lint
docker-compose run gather test_js
docker-compose run gather test_coverage
```

The e2e tests are run against different containers, the config file used
for them is [docker-compose-test.yml](docker-compose-test.yml).

Before running `gather` tests you should start the dependencies test containers.

```bash
docker-compose -f docker-compose-test.yml up -d <container-name>-test
```

**WARNING**

Never run `gather` tests against any PRODUCTION server.
The tests clean up will **DELETE ALL PROJECTS!!!**

Look into [docker-compose-base.yml](docker-compose-base.yml), the variable
`AETHER_KERNEL_URL_TEST` indicates the Aether Kernel Server used in tests.

*[Return to TOC](#table-of-contents)*


### Upgrade python dependencies

#### Check outdated dependencies

```bash
docker-compose run gather eval pip list --outdated
```

#### Update requirements file

```bash
docker-compose run gather pip_freeze
```

*[Return to TOC](#table-of-contents)*
