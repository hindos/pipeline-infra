#!/bin/bash

CERT_WORKING_DIR=$1
ROOT_DIR=$2
NAMESPACE_MQ=$3

source ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING createMQCertSecrets.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "CERT_WORKING_DIR: $CERT_WORKING_DIR"
echo "ROOT_DIR: $ROOT_DIR"
echo "NAMESPACE_MQ: $NAMESPACE_MQ"
echo " "

# Apply MQ secret

# Get the cert names we need
MQ_SERVER_KEY=$(ls $WORKING_DIR/$CERT_WORKING_DIR/cert-generation | grep mq-server.crt)
MQ_SERVER_CERT_PATH=$WORKING_DIR/$CERT_WORKING_DIR/cert-generation/$MQ_SERVER_KEY

MQ_SERVER_CERT=$(ls $WORKING_DIR/$CERT_WORKING_DIR/cert-generation | grep mq-server.key)
MQ_SERVER_KEY_PATH=$WORKING_DIR/$CERT_WORKING_DIR/cert-generation/$MQ_SERVER_CERT

CA_CERT=$(ls $WORKING_DIR/$CERT_WORKING_DIR/cert-generation | grep ca.crt)
CA_CERT_PATH=$WORKING_DIR/$CERT_WORKING_DIR/cert-generation/$CA_CERT

PREFIX=$(ls $WORKING_DIR/$CERT_WORKING_DIR/cert-generation | grep ca.crt | awk -F '-ca.crt' '{print $1}')


# Get the secret template from mq-infra directory
MQ_INFRA_DIR=${ROOT_DIR}/mq-infra

# Check the MQ_INFRA_DIR exists
if [ -d  $MQ_INFRA_DIR ]; then
  echo "Certegen dir is $MQ_INFRA_DIR"
else
  echo "Certegen dir is $MQ_INFRA_DIR does not exist"
  echo " You must clone the mq-infra repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi


echo $MQ_SERVER_KEY
echo $MQ_SERVER_CERT
echo $CA_CERT
echo $MQ_SERVER_KEY_PATH
echo $MQ_SERVER_CERT_PATH
echo $CA_CERT_PATH
echo $PREFIX

# base64 -b 0 is for mac base64 -w 0 for ubuntu linux

oc process -f $MQ_INFRA_DIR/templates/secret-template.yaml \
    -p NAMESPACE=${NAMESPACE_MQ} \
    -p PREFIX=${PREFIX} \
    -p MQ_SERVER_CERT=$(base64 -w 0 ${MQ_SERVER_CERT_PATH}) \
    -p MQ_SERVER_KEY=$(base64 -w 0 ${MQ_SERVER_KEY_PATH}) \
    -p CA_CERT=$(base64 -w 0 ${CA_CERT_PATH}) \
    | oc apply -f -

oc get secret ${PREFIX}-mq-key-cert -n ${NAMESPACE_MQ}
if [ $? != 0 ]; then
  echo "Failed to create secret ${PREFIX}-mq-key-cert in namespace ${NAMESPACE_MQ}"
  exit 78;
fi

oc get secret ${PREFIX}-ca-cert -n ${NAMESPACE_MQ}
if [ $? != 0 ]; then
  echo "Failed to create secret ${PREFIX}-ca-cert in namespace ${NAMESPACE_MQ}"
  exit 78;
fi

echo "Finished creating MQ key-cert and ca-cert secrets"
exit 0

