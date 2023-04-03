FROM python:3.10-slim

COPY ./pip /code/pip
WORKDIR /code

RUN pip install -q --upgrade pip && \
    pip install -q -f /code/pip aether.client

COPY ./ /code

ENTRYPOINT ["/code/entrypoint.sh"]
