FROM codercom/enterprise-minimal

USER root

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get upgrade --yes && \
    apt-get install --yes gh jq locales man nano python3 python3-pip vim wget unzip

USER coder

WORKDIR /home/coder