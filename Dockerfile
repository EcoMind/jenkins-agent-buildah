FROM alpine:3.18.2 as curl

WORKDIR /

RUN apk add curl

FROM curl as yq-downloader

ARG OS=${TARGETOS:-linux}
ARG ARCH=${TARGETARCH:-amd64}
ARG YQ_VERSION="v4.6.0"
ARG YQ_BINARY="yq_${OS}_$ARCH"
RUN wget "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/$YQ_BINARY" -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

FROM ubuntu:kinetic-20230605

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64 && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    jq \
    uidmap \
    shellcheck \
    libseccomp-dev \
    xmlstarlet \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY dep-bootstrap.sh .
RUN chmod +x ./dep-bootstrap.sh

ENV USER=jenkins
USER root
RUN useradd -u 1000 -s /bin/bash jenkins
RUN mkdir -p /home/jenkins
RUN chown 1000:1000 /home/jenkins
RUN export IMG_DISABLE_EMBEDDED_RUNC=1 \
    && chmod u-s /usr/bin/newuidmap /usr/bin/newgidmap \
    && echo "jenkins:100000:65536" > /etc/subgid \
    && echo "jenkins:100000:65536" > /etc/subuid \
    && setcap cap_setuid+ep /usr/bin/newuidmap \
    && setcap cap_setgid+ep /usr/bin/newgidmap \
    && mkdir -p /run/runc && chmod 777 /run/runc

ENV JENKINS_USER=jenkins

COPY --from=yq-downloader --chown=1000:1000 /usr/local/bin/yq /usr/local/bin/yq
COPY --from=buildah/buildah:959e6da7f52b27f8d7a6e39c884f700bce7ab5cb --chown=1000:1000 /usr/local/bin /usr/local/bin

USER 1000

RUN ./dep-bootstrap.sh 0.5.5 install
