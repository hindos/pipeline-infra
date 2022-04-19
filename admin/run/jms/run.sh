#!/bin/bash

set -e

QM_NAME=CQM5 \
  HOST=cqm5-ibm-mq-qm-mq-2.banking-2021-01-3cd0ec11030dfa215f262137faf739f1-0000.eu-gb.containers.appdomain.cloud \
  PORT=443 \
  JKS_KEYSTORE_PATH=/Users/mohammed.miaibm.com/Downloads/cert-generation/tiger-bank-client.jks \
  JKS_TRUSTSTORE_PATH=/Users/mohammed.miaibm.com/Downloads/cert-generation/tiger-bank-ca.jks \
  QUEUE_NAME=CREATE.CUSTOMER.Q.V1 \
  PAYLOAD_PATH=$(pwd)/request.xml \
  ./gradlew run
