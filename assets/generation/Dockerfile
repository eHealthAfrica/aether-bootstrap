FROM python:3.7-slim-stretch

COPY ./ /code
WORKDIR /code

RUN pip install -q --upgrade pip && \
    pip install -q -f /code/pip aether.client

ENTRYPOINT ["/code/entrypoint.sh"]
