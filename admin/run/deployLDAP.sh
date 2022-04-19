#!/bin/bash
# Deploys 5 MQ queue managers for form an MQ cluster
# set -x


#!/bin/bash

WORKING_DIR=$1
THIS_RUN_CERT_DIR=$2
SOURCE_REPO=$3


ACE_SOURCE_SSH_PRIVATE_KEY="${SOURCE_REPO}"
ROOT_DIR=$(dirname $(pwd))
PRODUCT=ldap
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING deployLDAP.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "WORKING_DIR: $WORKING_DIR"
echo "THIS_RUN_CERT_DIR: $THIS_RUN_CERT_DIR"
echo "CERT_PREFIX: $CERT_PREFIX"
echo " "

echo "Printing parameters from properites...."

echo " "

export NAMESPACE_LDAP

export ACE_INFRA_DIR

echo ${ACE_KS_JKS}
echo ${ACE_TS_JKS}
echo ${ACE_KDB}
echo ${ACE_KS_JKS_PATH}
echo ${ACE_TS_JKS_PATH}
echo ${ACE_KDB_PATH}
echo ${ACE_KEYSTORE_SECRET}
echo ${ACE_TRUSTSTORE_SECRET}
echo ${ACE_KDB_SECRET}
echo ${ACE_INFRA_SSH_PRIVATE_KEY}
echo ${ACE_CONFIG_SSH_PRIVATE_KEY}

echo ${ACE_SOURCE_SSH_PRIVATE_KEY}

echo ${ACE_TKN_BUILD_PVC}

echo " "


# Check logged into cluster
oc whoami
if [ $? != 0 ]; then
    echo "Not logged into an OpenShift cluster."
    exit 78;
fi
echo "Logged into OpenShift cluster"

# Check if tkn client available
which tkn
if [ $? != 0 ]; then
    echo "tkn client not found in path. Script will exit"
    exit 78;
fi
echo "tkn available at: $(which tkn)"

# Set ace-infra directory in a variable
LDAP_INFRA_DIR=${ROOT_DIR}/ldap-certgen-mongo

# Check the LDAP_INFRA_DIR exists
if [ -d  $LDAP_INFRA_DIR ]; then
  echo "ldap-infra dir is $LDAP_INFRA_DIR"
else
  echo "ldap-infra dir is $LDAP_INFRA_DIR does not exist"
  echo " You must clone the ldap-infra repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi

echo "CHECKING AND CREATING LDAP SERVICE ACCOUNTS AND PERMISSIONS"

oc get serviceaccount ldapaccount -n ${NAMESPACE_LDAP}
if [ $? != 0 ]; then
    echo "Creating service account for the LDAP deployment"
    oc create serviceaccount ldapaccount -n ${NAMESPACE_LDAP}
fi

oc adm policy who-can use scc privileged -n ldap | grep ldapaccount
if [ $? != 0 ]; then
    echo "Add privileged security context constraint to ldap service account"
    oc adm policy add-scc-to-user privileged system:serviceaccount:ldap:ldapaccount -n ${NAMESPACE_LDAP}
fi

oc adm policy who-can use scc anyuid -n ldap | grep ldapaccount
if [ $? != 0 ]; then
    echo "Add anyuid security context constraint to ldap service account"
    oc adm policy add-scc-to-user anyuid system:serviceaccount:ldap:ldapaccount -n ${NAMESPACE_LDAP}
fi

# Check image stream for custom-ldap exists, create if it does not
oc get imagestream custom-ldap -n ldap
if [ $? != 0 ]; then
    echo "CREATING LDAP IMAGE STREAM"
oc create -f $LDAP_INFRA_DIR/ldap/create-ldap/ldap-image-stream.yaml -n ${NAMESPACE_LDAP}
fi



# Get the LDAP pipeline directory
LDAP_PIPELINE_DIR=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline

# Check the pvc exists for pipeline runs in this namespace
oc get pvc ${LDAP_TKN_BUILD_PVC} -n ${NAMESPACE_LDAP}
if [ $? != 0 ]; then
    echo "PVC ${LDAP_TKN_BUILD_PVC} not found namespace ${NAMESPACE_LDAP}. This is needed for Tekton's working directort. Script will exit"
    exit 78;
fi

# Check that the pipeline service account has the infra and source secrets, plus the entitlement key


# Check the images we need exist

deploy_LDAP_by_pipeline () {


    PIPELINE_TO_USE="custom-ldap"


    echo "Deploying LDAP using pipline $PIPELINE_TO_USE"
    echo "$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline_run_template.yaml"
    
    oc process -f $ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline_run_template.yaml \
    -p NAME=${THIS_PIPELINE_RUN}-ldap \
    -p NAMESPACE=${NAMESPACE_LDAP} \
    -p PIPELINE_REFERENCE=${PIPELINE_TO_USE} \
    -p LDAP_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/ldap-certgen-mongo.git" \
    -p LDAP_SSH_PRIVATE_KEY_SECRET_NAME=${LDAP_INFRA_SSH_PRIVATE_KEY} \
    -p PERSISTENT_VOLUME_CLAIM_NAME=${LDAP_TKN_BUILD_PVC} \
    | oc apply -f -




    count="0"
    maxcount="30"

    echo "Pipelinerun ${THIS_PIPELINE_RUN}-ldap created. Will wait for up to 10 minutes for completion." 
    while [ $count -lt $maxcount ]
    do
        tkn pipelinerun list -n ${NAMESPACE_LDAP} | grep ${THIS_PIPELINE_RUN}-ldap | grep "Succeeded" > /dev/null
        if [ $? != 0 ]; then
            if [ "$count" -eq $(($maxcount -1)) ]
            then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-ldap not completed after 10 minutes."
                echo "Script will exit. Please check OpenShift."
                exit 1
            fi
            tkn pipelinerun describe ${THIS_PIPELINE_RUN}-ldap -n ${NAMESPACE_LDAP} | grep -A3 Taskruns | grep STATUS -A2 | grep -i "Failed"
            if [ $? == 0 ]; then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-ldap has tasks that have failed."
                echo "Script will exit. Please check OpenShift."
                exit 1
            else
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-ldap not completed, sleeping."
            fi
            echo "Current status of current Taskrun: ..."  
            tkn pipelinerun describe ${THIS_PIPELINE_RUN}-ldap -n ${NAMESPACE_LDAP} | grep -A3 Taskruns | grep STATUS -A2 
            sleep 20;
        fi
        count=$[$count+1]
    done 
    echo "Pipeline run completed: ... for release $1"
    tkn pipelinerun list -n ${NAMESPACE_LDAP} | grep ${THIS_PIPELINE_RUN}-ldap | grep "Succeeded"
    echo ""

}

get_pod_name () {
    podname=$(oc get pods -n $NAMESPACE_LDAP --selector=app.kubernetes.io/instance=$1 -o custom-columns=POD:.metadata.name --no-headers | head -n 1)
    echo "$podname"
}


deploy_LDAP_by_pipeline ${SOURCE_REPO}


# Get pod names
#ace_pod=$(get_pod_name "cqm1")


#echo $ace_pod





echo "LDAP deployment completed: "


