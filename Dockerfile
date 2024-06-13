FROM python:3.11.8-bookworm as base

ENV PKGS_DIR=/install
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PIP_DEFAULT_TIMEOUT=100

FROM base as builder
RUN apt update
RUN apt install -y gcc g++
RUN pip install --upgrade pip

RUN mkdir $PKGS_DIR
RUN mkdir /code

WORKDIR /code

COPY requirements.txt /code/

# Install dependencies to local folder
RUN pip install --no-cache-dir --target=$PKGS_DIR -r ./requirements.txt
RUN pip install --no-cache-dir --target=$PKGS_DIR gunicorn

# Main image with service
FROM base
ARG SRC_PATH=./devops

ENV PYTHONPATH=/usr/local
COPY --from=builder $PKGS_DIR /usr/local

RUN mkdir -p /app/

COPY $SRC_PATH /app/
WORKDIR /app

ENV SERVICE_DEBUG=False
ENV SERVICE_DB_PATH=/data
ENV SERVICE_HOST="0.0.0.0"
ENV SERVICE_PORT=8000

# Run service
CMD python manage.py migrate && gunicorn --workers=1 --bind $SERVICE_HOST:$SERVICE_PORT devops.wsgi

COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
