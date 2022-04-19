#!/bin/bash
# Deploys 5 MQ queue managers for form an MQ cluster
# set -x


#!/bin/bash

WORKING_DIR=$1
THIS_RUN_CERT_DIR=$2
CERT_PREFIX=$3
SOURCE_REPO=$4
USE_MQ=$5

ACE_SOURCE_SSH_PRIVATE_KEY="${SOURCE_REPO}"
ROOT_DIR=$(dirname $(pwd))
PRODUCT=ace
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING deployACE.sh ##########"
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

export NAMESPACE_ACE

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

# Check we have the certs

oc get configuration ${ACE_KEYSTORE_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to find secret ${ACE_KEYSTORE_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_TRUSTSTORE_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to find secret ${ACE_TRUSTSTORE_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_KDB_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to find secret ${ACE_KDB_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi

oc get configuration ${ACE_STASH_SECRET} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
  echo "Failed to find secret ${ACE_STASH_SECRET} in namespace ${NAMESPACE_ACE}"
  exit 78;
fi


# Set ace-infra directory in a variable
ACE_INFRA_DIR=${ROOT_DIR}/ace-infra

# Check the ACE_INFRA_DIR exists
if [ -d  $ACE_INFRA_DIR ]; then
  echo "ace-infra dir is $ACE_INFRA_DIR"
else
  echo "ace-infra dir is $ACE_INFRA_DIR does not exist"
  echo " You must clone the ace-infra repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi


# Set ace-source directory in a variable
ACE_CONFIG_DIR=${ROOT_DIR}/ace-configurations

# Check the ACE_CONFIG_DIR exists
if [ -d  $ACE_CONFIG_DIR ]; then
  echo "ace-config dir is $ACE_CONFIG_DIR"
else
  echo "ace-config dir is $ACE_CONFIG_DIR does not exist"
  echo " You must clone the ace-config repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi

# Set ace-source directory in a variable
ACE_SOURCE_DIR=${ROOT_DIR}/${SOURCE_REPO}

# Check the ACE_SOURCE_DIR exists
if [ -d  $ACE_SOURCE_DIR ]; then
  echo "ace-source dir is $ACE_SOURCE_DIR"
else
  echo "ace-source dir is $ACE_SOURCE_DIR does not exist"
  echo " You must clone the ace-source repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi


# Get the ACE pipeline directory
ACE_PIPELINE_DIR=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline

# Check the pvc exists for pipeline runs in this namespace
oc get pvc ${ACE_TKN_BUILD_PVC} -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
    echo "PVC ${ACE_TKN_BUILD_PVC} not found namespace ${NAMESPACE_ACE}. This is needed for Tekton's working directort. Script will exit"
    exit 78;
fi

# Check that the pipeline service account has the infra and source secrets, plus the entitlement key

# Check if operations dashboard secret exists in the namespace, fail if it does not
oc get secret icp4i-od-store-cred -n ${NAMESPACE_ACE}
if [ $? != 0 ]; then
    echo "Creating empty secret for od store cred"
    oc create secret generic icp4i-od-store-cred \
    --from-literal=icp4i-od-cacert.pem="empty" \
    --from-literal=username="empty" \
    --from-literal=password="empty" \
    --from-literal=tracingUrl="empty" \
    -n ${NAMESPACE_ACE}
    if [ $? != 0 ]; then
        echo "Failed to create secret icp4i-od-store-cred on namespace ${NAMESPACE_ACE}"
        echo "Script will exit"
        exit 78
    fi
fi

# Check the images we need exist

deploy_ACE_by_pipeline () {

    if [ ! -z $USE_MQ ]
    then
      PIPELINE_TO_USE="is-build-with-mq"
    else
      PIPELINE_TO_USE="is-build-ace-only"
    fi

    echo "Deploying $1 using pipline $PIPELINE_TO_USE"

    echo "ACE service is $1"
    oc process -f $ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline_run_template.yaml \
    -p NAME=${THIS_PIPELINE_RUN}-${1} \
    -p NAMESPACE=${NAMESPACE_ACE} \
    -p PIPELINE_REFERENCE=${PIPELINE_TO_USE} \
    -p ACE_INFRA_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/ace-infra.git" \
    -p ACE_APP_SOURCE_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/${SOURCE_REPO}.git" \
    -p ACE_CONFIG_REPO_URL="git@github.ibm.com:cpat-agile-integration-sample/ace-configurations.git" \
    -p MQ_SOURCE_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/mq-source.git" \
    -p ACE_INFRA_SSH_PRIVATE_KEY_SECRET_NAME=${ACE_INFRA_SSH_PRIVATE_KEY} \
    -p ACE_APP_SOURCE_SSH_PRIVATE_KEY_SECRET_NAME=${ACE_SOURCE_SSH_PRIVATE_KEY} \
    -p ACE_CONFIG_SSH_PRIVATE_KEY_SECRET_NAME=${ACE_CONFIG_SSH_PRIVATE_KEY} \
    -p MQ_SOURCE_SSH_PRIVATE_KEY_SECRET_NAME=${MQ_SOURCE_SSH_PRIVATE_KEY} \
    -p PERSISTENT_VOLUME_CLAIM_NAME=${ACE_TKN_BUILD_PVC} \
    | oc apply -f -




    count="0"
    maxcount="30"

    echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} created. Will wait for up to 10 minutes for completion."

    echo "Watch in terminal for status of current running pipeline task (or look on OCP console):"
    echo " "
    # Prints out the column names for the pipeline progress updates - 
    # NAME                                     TASK NAME      STARTED        DURATION   STATUS
    tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_ACE} | grep -A3 Taskruns | grep STATUS -A2 | sed -n 1p

    while [ $count -lt $maxcount ]
    do
        tkn pipelinerun list -n ${NAMESPACE_ACE} | grep ${THIS_PIPELINE_RUN}-${1} | grep "Succeeded" > /dev/null
        if [ $? != 0 ]; then
            if [ "$count" -eq $(($maxcount -1)) ]
            then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} not completed after 10 minutes."
                echo "Script will exit. Please check OpenShift."
                exit 1
            fi
            tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_ACE} | grep -A3 Taskruns | grep STATUS -A2 | grep -i "Failed"
            if [ $? == 0 ]; then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} has tasks that have failed."
                echo "Script will exit. Please check OpenShift."
                exit 1
            else
                tkn_status=$(tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_ACE} | grep -A3 Taskruns | grep STATUS -A2 | sed -n 2p)
                echo -ne "\\r$tkn_status                        "
            fi

            sleep 20;
        fi
        count=$[$count+1]
    done

    echo " "
    echo " "
    echo "Pipeline run completed: ... for release $1"
    tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_ACE} | grep -A25 Taskruns
    echo " "
    tkn pipelinerun list -n ${NAMESPACE_ACE} | grep ${THIS_PIPELINE_RUN}-${1} | grep "Succeeded"
    echo ""

}

get_pod_name () {
    podname=$(oc get pods -n $NAMESPACE_ACE --selector=app.kubernetes.io/instance=$1 -o custom-columns=POD:.metadata.name --no-headers | head -n 1)
    echo "$podname"
}


deploy_ACE_by_pipeline ${SOURCE_REPO}


# Get pod names
#ace_pod=$(get_pod_name "cqm1")


#echo $ace_pod





echo "ACE service deployment completed: "


