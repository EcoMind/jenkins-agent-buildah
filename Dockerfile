FROM quay.io/buildah/stable:v1.30.0

ARG OS=${TARGETOS:-linux}
ARG ARCH=${TARGETARCH:-amd64}
ARG YQ_VERSION="v4.6.0"
ARG YQ_BINARY="yq_${OS}_$ARCH"
RUN curl -L "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/$YQ_BINARY" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

WORKDIR /app

COPY dep-bootstrap.sh .
RUN chmod +x ./dep-bootstrap.sh

ENV USER=1000
USER root
RUN yum install -y git jq shellcheck xmlstarlet && chown 1000 -R /app

ENV JENKINS_USER=1000

RUN mkdir -p /etc/containers/
COPY default-policy.json /etc/containers/policy.json
RUN ["ln", "-sf", "/usr/bin/buildah", "/usr/bin/docker"]

USER 1000

RUN ./dep-bootstrap.sh 0.5.5 install
