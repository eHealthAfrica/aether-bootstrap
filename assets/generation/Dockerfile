FROM python:3.7-slim-stretch

WORKDIR /code
COPY ./ /code

RUN apt-get update -qq && \
    apt-get -qq \
        --yes \
        --allow-downgrades \
        --allow-remove-essential \
        --allow-change-held-packages \
        install gcc && \
    pip install --upgrade pip && \
    pip install -q -f /code/pip/requires -r /code/pip/requirements.txt

ENTRYPOINT ["/code/entrypoint.sh"]
