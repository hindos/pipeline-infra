#!/bin/bash

# Script takes in one ACE service name an

ROOT_DIR=$1
NAMESPACE_ACE=$2



source ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING createACECertSecrets.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "ROOT_DIR: $ROOT_DIR"
echo "NAMESPACE_ACE: $NAMESPACE_ACE"
echo " "

TEMPLATE_PATH=${ROOT_DIR}/ace-infra

# Apply ACE secret

# Get the cert names we need

# Get the prefix name of the certificates. This should match the ORG value in the properties file
# But just in case we can get this from the actual files themselves
#PREFIX=$(ls $WORKING_DIR/cert-generation | grep ca.jks | awk -F '-ca.jks' '{print $1}')
#
#ACE_KS_JKS=$(ls $WORKING_DIR/cert-generation | grep ${PREFIX}-ace-server.jks)
#ACE_TS_JKS=$(ls $WORKING_DIR/cert-generation | grep ${PREFIX}-ca.jks)
#ACE_KDB=$(ls $WORKING_DIR/cert-generation | grep ${PREFIX}-ace-server.kdb)
#
#ACE_KS_JKS_PATH=$WORKING_DIR/cert-generation/${ACE_KS_JKS}
#ACE_TS_JKS_PATH=$WORKING_DIR/cert-generation/${ACE_TS_JKS}
#ACE_KDB_PATH=$WORKING_DIR/cert-generation/${ACE_KDB}



# Get the secret template from mq-infra directory
#ACE_INFRA_DIR=${ROOT_DIR}/ace-infra

# Check the MQ_INFRA_DIR exists
if [ -d  $ACE_INFRA_DIR ]; then
  echo "Certegen dir is $ACE_INFRA_DIR"
else
  echo "Certegen dir is $ACE_INFRA_DIR does not exist"
  echo " You must clone the mq-infra repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi

# Get the secret template from mq-infra directory
#ACE_INFRA_DIR=${ROOT_DIR}/ace-infra


echo ${PREFIX}
echo ${ACE_KS_JKS}
echo ${ACE_TS_JKS}
echo ${ACE_KDB}
echo ${ACE_KS_JKS_PATH}
echo ${ACE_TS_JKS_PATH}
echo ${ACE_KDB_PATH}
echo ${ACE_KEYSTORE_SECRET}
echo ${ACE_TRUSTSTORE_SECRET}
echo ${ACE_KDB_SECRET}

echo $ACE_INFRA_DIR/templates/secret-template.yaml


echo "oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml -p NAME=${ACE_KEYSTORE_SECRET} -p TYPE=keystore -p CONTENTS=$(base64 -w 0 ${ACE_KS_JKS_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -"


echo " "
ls -lrt ${ACE_KS_JKS_PATH}
echo " "
oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml \
   -p NAME=${ACE_KEYSTORE_SECRET} \
   -p TYPE=keystore \
   -p CONTENTS=$(base64 -w 0 ${ACE_KS_JKS_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -


echo "oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml -p NAME=${ACE_TRUSTSTORE_SECRET} -p TYPE=keystore -p CONTENTS=$(base64 -w 0 ${ACE_TS_JKS_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -"

oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml \
   -p NAME=${ACE_TRUSTSTORE_SECRET} \
   -p TYPE=truststore \
   -p CONTENTS=$(base64 -w 0 ${ACE_TS_JKS_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -


echo "oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml -p NAME=${ACE_KDB_SECRET} -p TYPE=keystore -p CONTENTS=$(base64 -w 0 ${ACE_KDB_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -"

oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml \
   -p NAME=${ACE_KDB_SECRET} \
   -p TYPE=keystore \
   -p CONTENTS=$(base64 -w 0 ${ACE_KDB_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -



echo "oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml -p NAME=${ACE_STASH_SECRET} -p TYPE=keystore -p CONTENTS=$(base64 -w 0 ${ACE_STASH_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -"

oc process -f ${TEMPLATE_PATH}/templates/configuration.yaml \
   -p NAME=${ACE_STASH_SECRET} \
   -p TYPE=keystore \
   -p CONTENTS=$(base64 -w 0 ${ACE_STASH_PATH}) | oc apply -n=${NAMESPACE_ACE} -f -







oc get configuration ${ACE_KEYSTORE_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to create secret ${ACE_KEYSTORE_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_TRUSTSTORE_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to create secret ${ACE_TRUSTSTORE_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_KDB_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to create secret ${ACE_KDB_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_STASH_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to create secret ${ACE_STASH_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi


echo "Finished creating MQ key-cert and ca-cert secrets"
exit 0

