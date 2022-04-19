#!/bin/bash
# Deploys 5 MQ queue managers for form an MQ cluster
# set -x


#!/bin/bash

WORKING_DIR=$1
THIS_RUN_CERT_DIR=$2
CERT_PREFIX=$3
QMGR_TO_BUILD=$4

ROOT_DIR=$(dirname $(pwd))
PRODUCT=mq
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING deployMQ.sh ##########"
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

echo "ROOT_DIR is $ROOT_DIR"
echo "MQ_INFRA_DIR is $MQ_INFRA_DIR"
echo "NAMESPACE_MQ is $NAMESPACE_MQ"
echo "MQ_INFRA_SSH_PRIVATE_KEY is $MQ_INFRA_SSH_PRIVATE_KEY"
echo "MQ_SOURCE_SSH_PRIVATE_KEY is $MQ_SOURCE_SSH_PRIVATE_KEY"
echo "THIS_PIPELINE_RUN is $THIS_PIPELINE_RUN"
echo "TEST_QUEUE is $TEST_QUEUE"
echo "MQ_TKN_BUILD_PVC= is $MQ_TKN_BUILD_PVC"
echo "CA_CERT_SECRET_NAME is $CA_CERT_SECRET_NAME"
echo "MQ_SERVER_KEY_CERT_SECRET_NAME is $MQ_SERVER_KEY_CERT_SECRET_NAME"
echo "MQ_SERVER_KEY_KEY_VALUE is $MQ_SERVER_KEY_KEY_VALUE"
echo "MQ_SERVER_CERT_KEY_VALUE is $MQ_SERVER_CERT_KEY_VALUE"
echo "CA_CERT_KEY_VALUE is $CA_CERT_KEY_VALUE"
echo "PATH_TO_DOCKER_TEST is $PATH_TO_DOCKER_TEST"

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

oc get secret ${MQ_SERVER_KEY_CERT_SECRET_NAME} -n ${NAMESPACE_MQ}
if [ $? != 0 ]; then
  echo "Failed to find secret ${MQ_SERVER_KEY_CERT_SECRET_NAME} in namespace ${NAMESPACE_MQ}"
  exit 78;
fi

oc get secret ${CA_CERT_SECRET_NAME} -n ${NAMESPACE_MQ}
if [ $? != 0 ]; then
  echo "Failed to find secret ${CA_CERT_SECRET_NAME} in namespace ${NAMESPACE_MQ}"
  exit 78;
fi


# Set mq-infra directory in a variable
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

# Set mq-source directory in a variable
MQ_SOURCE_DIR=${ROOT_DIR}/mq-source

# Check the MQ_SOURCE_DIR exists
if [ -d  $MQ_SOURCE_DIR ]; then
  echo "Certegen dir is $MQ_SOURCE_DIR"
else
  echo "Certegen dir is $MQ_SOURCE_DIR does not exist"
  echo " You must clone the mq-source repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi

# Get the MQ pipeline directory
MQ_PIPELINE_DIR=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline

# Check the pvc exists for pipeline runs in this namespace
oc get pvc ${MQ_TKN_BUILD_PVC} -n ${NAMESPACE_MQ}
if [ $? != 0 ]; then
    echo "PVC ${MQ_TKN_BUILD_PVC} not found namespace ${NAMESPACE_MQ}. This is needed for Tekton's working directort. Script will exit"
    exit 78;
fi

# Check that the pipeline service account has the infra and source secrets, plus the entitlement key

# Check if operations dashboard secret exists in the namespace, fail if it does not
oc get secret icp4i-od-store-cred -n ${NAMESPACE_MQ}


deploy_mq_by_pipeline () {
    echo "Queue Manager is $1"
    oc process -f $ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline_run_template.yaml \
    -p NAME=${THIS_PIPELINE_RUN}-${1} \
    -p NAMESPACE=${NAMESPACE_MQ} \
    -p PIPELINE_REFERENCE="mq-build" \
    -p INFRA_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/mq-infra.git" \
    -p SOURCE_GIT_URL="git@github.ibm.com:cpat-agile-integration-sample/mq-source.git" \
    -p INFRA_SSH_PRIVATE_KEY_SECRET_NAME=${MQ_INFRA_SSH_PRIVATE_KEY} \
    -p SOURCE_SSH_PRIVATE_KEY_SECRET_NAME=${MQ_SOURCE_SSH_PRIVATE_KEY} \
    -p QUEUE_NAME=${TEST_QUEUE} \
    -p CA_CERT_SECRET=${CA_CERT_SECRET_NAME} \
    -p MQ_SERVER_KEY_CERT_SECRET=${MQ_SERVER_KEY_CERT_SECRET_NAME} \
    -p MQ_SERVER_CERT_KEY=${MQ_SERVER_CERT_KEY_VALUE} \
    -p MQ_SERVER_KEY_KEY=${MQ_SERVER_KEY_KEY_VALUE} \
    -p CA_CERT_KEY=${CA_CERT_KEY_VALUE} \
    -p PERSISTENT_VOLUME_CLAIM_NAME=${MQ_TKN_BUILD_PVC} \
    -p CONTEXT=/workspace/source/source/${1}/mqsc \
    -p DEPLOYMENT_PROPERTIES_PATH=/workspace/source/source/${1}/deployment-properties/deployment.properties \
    -p TRACING_NS=${TRACING_NS} \
    | oc apply -f -


    count="0"
    maxcount="60"

    echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} created. Will wait for up to 10 minutes for completion." 
    while [ $count -lt $maxcount ]
    do
        tkn pipelinerun list -n ${NAMESPACE_MQ} | grep ${THIS_PIPELINE_RUN}-${1} | grep "Succeeded" > /dev/null
        if [ $? != 0 ]; then
            if [ "$count" -eq $(($maxcount -1)) ]
            then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} not completed after 10 minutes."
                echo "Script will exit. Please check OpenShift."
                exit 1
            fi
            tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_MQ} | grep -A3 Taskruns | grep STATUS -A2 | grep -i "Failed"
            if [ $? == 0 ]; then
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} has tasks that have failed."
                echo "Script will exit. Please check OpenShift."
                exit 1
            else
                echo "Pipelinerun ${THIS_PIPELINE_RUN}-${1} not completed, sleeping."
            fi
            echo "Current status of current Taskrun: ..."  
            tkn pipelinerun describe ${THIS_PIPELINE_RUN}-${1} -n ${NAMESPACE_MQ} | grep -A3 Taskruns | grep STATUS -A2 
            sleep 20;
        else
            break
        fi
        count=$[$count+1]
    done

    echo "Pipeline run completed: ... for release $1"
    tkn pipelinerun list -n ${NAMESPACE_MQ} | grep ${THIS_PIPELINE_RUN}-${1} | grep "Succeeded"
    echo ""

}

get_pod_name () {
    podname=$(oc get pods -n $NAMESPACE_MQ --selector=app.kubernetes.io/instance=$1 -o custom-columns=POD:.metadata.name --no-headers | head -n 1)
    echo "$podname"
}


check_runmqsc () {
    qmgr_pod=$1
    temp_file_name=check_$2_runmqsc_$THIS_PIPELINE_RUN.txt
    mqsc_command=$3
    failure_condition=$4
    echo $failure_condition
    oc exec $qmgr_pod -c qmgr -n $NAMESPACE_MQ -- /bin/bash -c "echo \"${mqsc_command}\" | runmqsc" > $temp_file_name 2>&1
    cat $temp_file_name
    if [ ! -z "$failure_condition" ]
    then
        cat $temp_file_name | grep -i $failure_condition
        if [ $? == 0 ]
        then
            echo "Failure detected when running mqsc command: "
            echo "$mqsc_command"
            echo "State $failure_condition detected on Queue Manager pod $qmgr_pod"
            echo "Script will exit"
            exit 78
        fi
    fi
    rm $temp_file_name
    echo " "
}





list_qmgr () {
    qmgr1=$1
    qmgr_pod_1=$(get_pod_name "$qmgr1")
    temp_file_name=check_$1_dspmq_$THIS_PIPELINE_RUN.txt
    oc exec $qmgr_pod_1 -c qmgr -n $NAMESPACE_MQ -- /bin/bash -c "dspmq" > $temp_file_name 2>&1
    echo "Release name: $qmgr1"
    echo "Pod name: $qmgr_pod_1"
    echo "Namespace: $NAMESPACE_MQ"
    cat $temp_file_name
    rm $temp_file_name
    echo " "
}

add_external_route () {
    qmgr1=$1
    echo "Apply route in namespace $NAMESPACE_MQ for queue manager $qmgr1"
    oc apply -f $MQ_SOURCE_DIR/$qmgr1/route.yaml -n $NAMESPACE_MQ
    echo " "
}




deploy_mq_by_pipeline $QMGR_TO_BUILD


# Get pod names
qm_pod=$(get_pod_name "${QMGR_TO_BUILD}")


echo $qm_pod


# Need to add in configuration of inbound route
add_external_route "${QMGR_TO_BUILD}"

list_qmgr "${QMGR_TO_BUILD}"

echo " "

echo "MQ cluster deployment completed: "


