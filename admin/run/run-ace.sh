#!/bin/bash

# Get the directories
RUN_DIR=$(pwd)
PARENT_DIR=$(dirname $(pwd))

# Source the properties
source $RUN_DIR/cp4i_props.sh

export CERTS_WORKING_DIR=certs-dir-cp4i

echo "CERTS_WORKING_DIR is: $CERTS_WORKING_DIR"
echo " "


# Check logged into cluster
oc whoami
if [ $? != 0 ]; then
    echo "Not logged into an OpenShift cluster."
    exit 78;
fi
echo "Logged into OpenShift cluster"

####### ACE #######


$RUN_DIR/createACECertSecrets.sh $PARENT_DIR $NAMESPACE_ACE "create-customer"
if [ $? != 0 ]
then
    echo "Script createACECertSecrets.sh failed"
    echo "Script will exit"
    exit 78;
fi

# Install the pipeline for ACE
$RUN_DIR/installPipeline.sh $PARENT_DIR $RUN_DIR "ace" $NAMESPACE_ACE
if [ $? != 0 ]
then
    echo "Script installPipeline.sh failed"
    echo "Script will exit"
    exit 78;
fi

# Run the ACE Deploys
$RUN_DIR/deployACE.sh $RUN_DIR $CERTS_WORKING_DIR $ORG "create-customer-mq-soap-to-mq-json-v1" "mq"
if [ $? != 0 ]
then
    echo "Script deployACE.sh failed"
    echo "Script will exit"
    exit 78;
fi

$RUN_DIR/deployACE.sh $RUN_DIR $CERTS_WORKING_DIR $ORG "update-datastore-mq-mongo-v1" "mq"
if [ $? != 0 ]
then
    echo "Script deployACE.sh failed"
    echo "Script will exit"
    exit 78;
fi

$RUN_DIR/deployACE.sh $RUN_DIR $CERTS_WORKING_DIR $ORG "read-all-customers-rest-v1"
if [ $? != 0 ]
then
    echo "Script deployACE.sh failed"
    echo "Script will exit"
    exit 78;
fi

echo "Sleep 60 seconds for ACE deployment to start"
sleep 60


$RUN_DIR/putTestMessage.sh $RUN_DIR $CERTS_WORKING_DIR CQM5 CREATE.CUSTOMER.Q.V1
if [ $? != 0 ]
then
    echo "Script putTestMessage.sh failed"
    echo "Script will exit"
    exit 78;
fi