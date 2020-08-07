# Aether Bootstrap

> A bootstrap for creating Aether-based solutions

This repo contains a series of docker-compose files and shell scripts that will pull Docker images of the latest version of [Aether](https://github.com/eHealthAfrica/aether) from Docker Hub and start them up.

For more information on Aether, take a look at the [microsite](https://aether.ehealthafrica.org).

## Set-up instructions

First clone this repo:

```bash
git clone https://github.com/eHealthAfrica/aether-bootstrap.git
cd aether-bootstrap
```

If you are starting Aether for the first time, you will need to create some docker resources (networks and volumes) and generate credentials (check generated `.env` file) for all applications:

Take a look at file `options.default`, copy it as `options.txt` and change it with your desired options.

```bash
cp ./options.default ./options.txt
```

After that execute this command:

```bash
./scripts/init.sh
```

If `CKAN` is enabled, you will be prompted for an email address and password to setup an admin account on `CKAN`.

You will also need to add an entry to your `/etc/hosts` or `C:\Windows\System32\Drivers\etc\hosts` file.
It should look something like this:

```text
127.0.0.1  aether.local  # (`LOCAL_HOST` environment variable value)
```

Now you just need to tell Docker to start aether up:

```bash
./scripts/start.sh
```

Once the console output has stopped, you should be able to access the **Aether UI** in your browser at http://aether.local/dev/kernel-ui/ (`http://{LOCAL_HOST}/{realm}/kernel-ui`).

Use these credentials to log in:

- *Username*: **user** (`INITIAL_USER_USERNAME`)
- *Password*: **password** (`INITIAL_USER_PASSWORD`)


# Add tenants

If you want to add more tenants to your installation:

```bash
./scripts/add_tenant.sh "tenant-id" "tenant-theme" "tenant long description"
```

So far, the possible tenant themes are `ehealth` or `aether`.

**IMPORTANT NOTE**

If you enable a service after the tenant was added you **MUST** need to
re-add it again to serve the new service under the tenant endpoint.
