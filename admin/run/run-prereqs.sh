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

# Commenting out the below - as the OD automatic registration does not work with the Long Term support version of CP4I
# Setup roles and role bindings for pipeline SA to list od pods
#$RUN_DIR/setRoles.sh $PARENT_DIR
#if [ $? != 0 ]
#then
#    echo "Script setRoles.sh failed"
#    echo "Script will exit"
#    exit 78;
#fi


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





