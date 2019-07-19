# Using Redash with Aether.

- Run `./setup.sh`
- do `docker-compose up -d`
- Goto `http://localhost:5000`
- Create an Admin in the interface.
- Goto sources and create a Postgres source.
  - Host: `db`
  - Port: `5432`
  - User: `readonlyuser`
  - Database Name: `aether`
- Use the settings from the `../.env` file for the `readonlyuser` for postgres credentials.

Every time you do a `docker-compose down`, you'll need to re-run setup to initialize the Redash database.
