#FROM alpine

#RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
#RUN apk update && apk del yq && apk --no-cache add --update zip sed yq bash coreutils

#FROM alpine@sha256:08d6ca16c60fe7490c03d10dc339d9fd8ea67c6466dea8d558526b1330a85930
#RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
#RUN apk update && apk del yq && apk --no-cache add --update zip sed yq=4.4.1-r0 bash coreutils


#FROM ubuntu
##RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
#RUN apt -y update
#RUN apt -y install snapd
#RUN snap install yq
#RUN snap install coreutils
#RUN snap install bash
#RUN snap install zip
#RUN apk update && apk del yq && apk --no-cache add --update zip sed yq=4.4.1-r0 bash coreutils

FROM alpine@sha256:08d6ca16c60fe7490c03d10dc339d9fd8ea67c6466dea8d558526b1330a85930
RUN apk update && apk del yq && apk --no-cache add --update zip sed bash coreutils
COPY yq_linux_amd64.tar.gz /tmp
RUN tar zxvf /tmp/yq_linux_amd64.tar.gz -C /tmp
RUN mv /tmp/yq_linux_amd64 /usr/bin/yq