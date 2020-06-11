# Performance tests

The performance tests are running using [locust](https://docs.locust.io/en/stable/running-locust-docker.html).


## Set-up instructions

Run the script to download the locust image and create the realm for the tests.
The realm is defined in the `.env` file as `TEST_REALM`.

```bash
./_performance_/setup.sh
```


# Run tests

Execute the following command:

```bash
./_performance_/start.sh
```

and open the browser at http://localhost:8089 to run the performance tests.
