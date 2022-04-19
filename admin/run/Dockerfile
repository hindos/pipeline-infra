FROM ibmcom/mq
USER root
RUN microdnf install --nodocs java-1.8.0-openjdk-headless openssl make \
  && microdnf clean all
RUN curl -sSLo /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.5/linux/oc.tar.gz
RUN tar -zxvf /tmp/oc.tar.gz -C /usr/local/bin oc
RUN curl -LO https://github.com/tektoncd/cli/releases/download/v0.16.0/tkn_0.16.0_Linux_x86_64.tar.gz
# Extract tkn to your PATH (e.g. /usr/local/bin)
RUN tar xvzf tkn_0.16.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
RUN microdnf install yum && microdnf install zip
RUN yum -y update && yum -y install which && yum -y install java-1.8.0-openjdk-devel && yum install -y jq && yum clean all
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN mv kubectl /usr/local/bin/ && chmod 755 /usr/local/bin/kubectl

ENTRYPOINT []
