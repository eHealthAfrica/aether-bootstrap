# Demo set up

Execute `demo/init.sh` to create the default demo `options.txt` file.
Change the default values with your requirements, like `LOCAL_HOST`, `BASE_PROTOCOL`, user credentials...

To prepare the environment for the first time execute:

```bash
# pulls the containers, creates the needed databases, volumes, the initial tenants...
scripts/init.sh
```

To update your installation with new releases and upgrades execute:

```bash
# pulls last releases
scripts/pull.sh
# stops running containers
scripts/stop.sh
# starts the services indicated in `options.txt` file
scritps.start.sh
```

To add new tenants execute:

```bash
# adds the tenant in the services indicated in `options.txt` file
scripts/add_tenant.sh "new-tenant-id" "theme" "tenant name"
```
