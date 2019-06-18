# Aether Bootstrap

> A bootstrap for creating Aether-based solutions

This repo contains a series of docker-compose files and shell scripts that will pull Docker images of the latest version of [Aether](/ehealthafrica/aether) from Docker Hub and start them up.

For more information on Aether, take a look at the [microsite](https://aether.ehealthafrica.org).

## Set-up instructions

First clone this repo:

```bash
git clone https://github.com/eHealthAfrica/aether-bootstrap.git
cd aether-bootstrap
```

If you are starting Aether for the first time, you will need to create some docker resources (networks and volumes) and generate credentials (check generated `.env` file) for all applications:

```bash
./scripts/initialise_docker_environment.sh
```

You will also need to add `aether.local` (`BASE_DOMAIN` environment variable value)
to your `/etc/hosts` or `C:\Windows\System32\Drivers\etc\hosts` file.
It should look something like this:

```text
127.0.0.1  aether.local
```

Now you just need to tell Docker to start aether up:

```bash
docker-compose up
```

Once the console output has stopped, you should be able to access the Aether UI in your browser at http://aether.local/dev/ui/. Use these credentials to log in:

- *Username*: **user**
- *Password*: **password**
