FROM python:3.6-slim-jessie

################################################################################
## setup container
################################################################################

WORKDIR /code

COPY ./ /code

RUN apt-get update -qq \
    && apt-get -qq --yes --force-yes install gcc \
    && pip install --upgrade pip \
    && pip install -q -f /code/pip/requires -r /code/pip/requirements.txt

################################################################################
## last setup steps
################################################################################

# create user to run container (avoid root user)
RUN useradd -ms /bin/false aether
RUN chown -R aether: /code

ENTRYPOINT ["/code/entrypoint.sh"]
