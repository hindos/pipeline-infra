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


# Prompt the user to check they have:
# Ran keygen.sh and uploaded keys to github repos as per Sa'ads document and created the mq-infra and mq-source secrets on the namespace where MQ will be deployed
# Created the PVC for the pipeline run
# Created one MQ manually, with tracing enabled and completed the registration process on the operations dashboard

# Setup roles and role bindings for pipeline SA to list od pods
$RUN_DIR/setRoles.sh $PARENT_DIR
if [ $? != 0 ]
then
    echo "Script setRoles.sh failed"
    echo "Script will exit"
    exit 78;
fi


# Run the cert generation
$RUN_DIR/generateCerts.sh $PARENT_DIR $CERTS_WORKING_DIR
if [ $? != 0 ]
then
    echo "Script generateCerts.sh failed"
    echo "Script will exit"
    exit 78;
fi

#CERTS_WORKING_DIR=1612556297_createcerts

###### LDAP ######
./installPipeline.sh $PARENT_DIR $RUN_DIR "ldap" $NAMESPACE_LDAP
if [ $? != 0 ]
then
    echo "Script installPipeline.sh failed"
    echo "Script will exit"
    exit 78;
fi

./deployLDAP.sh $RUN_DIR $CERTS_WORKING_DIR "ldap-certgen-mongo"
if [ $? != 0 ]
then
    echo "Script deployLDAP.sh failed"
    echo "Script will exit"
    exit 78;
fi

####### Mongo #######

./deployMongo.sh 
if [ $? != 0 ]
then
    echo "Script deployMongo.sh failed"
    echo "Script will exit"
    exit 78;
fi

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

#
####### ACE #######


$RUN_DIR/createACECertSecrets.sh $CERTS_WORKING_DIR $PARENT_DIR $NAMESPACE_ACE "create-customer"
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