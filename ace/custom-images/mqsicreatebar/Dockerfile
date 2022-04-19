FROM golang:latest as builder

ARG ACE_INSTALL
WORKDIR /opt/ibm
COPY $ACE_INSTALL .

RUN mkdir ace-11
RUN tar -xzf $ACE_INSTALL --absolute-names \
    --exclude ace-11.\*/server/bin/TADataCollector.sh \
    --exclude ace-11.\*/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components 1 \
    --directory /opt/ibm/ace-11

FROM centos:7

WORKDIR /opt/ibm

RUN yum -y update && \
    yum install -y xorg-x11-server-Xvfb gtk2 libXtst && \
    yum clean all

COPY --from=builder /opt/ibm/ace-11 /opt/ibm/ace-11

RUN /opt/ibm/ace-11/ace make registry global accept license silently 

COPY mqsicreatebar.sh /usr/bin/mqsicreatebar.sh

ENTRYPOINT [ "/usr/bin/mqsicreatebar.sh" ]