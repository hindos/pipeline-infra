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


####### MQ #######


# Run the Apply of MQ certs to secrets
$RUN_DIR/createMQCertSecrets.sh $CERTS_WORKING_DIR $PARENT_DIR $NAMESPACE_MQ 
if [ $? != 0 ]
then
    echo "Script reateMQCertSecrets.sh failed"
    echo "Script will exit"
    exit 78;
fi

# Install the pipeline for MQ
$RUN_DIR/installPipeline.sh $PARENT_DIR $RUN_DIR "mq" $NAMESPACE_MQ
if [ $? != 0 ]
then
    echo "Script installPipeline.sh failed"
    echo "Script will exit"
    exit 78;
fi


# Run the MQ Deploy.
$RUN_DIR/deployMQ.sh $RUN_DIR $CERTS_WORKING_DIR $ORG "cqm5" "cqm1" "cqm2" "cqm3" "cqm4" "cqm5"
if [ $? != 0 ]
then
    echo "Script deployMQ.sh failed"
    echo "Script will exit"
    exit 78;
fi

# Test the MQ Deploy.
$RUN_DIR/testMQ.sh $RUN_DIR $CERTS_WORKING_DIR $ORG "true" "cqm1" "cqm2" "cqm3" "cqm4" "cqm5"
if [ $? != 0 ]
then
    echo "Script deployMQ.sh failed"
    echo "Script will exit"
    exit 78;
fi
