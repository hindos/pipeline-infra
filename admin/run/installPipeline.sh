#!/bin/bash

ROOT_DIR=$1
WORK_DIR=$2
PRODUCT=$3
NAMESPACE=$4


source ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING installPipeline.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "ROOT_DIR: $ROOT_DIR"
echo "PRODUCT: $PRODUCT"
echo "NAMESPACE: $NAMESPACE"
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

# check are all repos pulled down

# install the custom tasks

CUSTOM_TASKS=$(ls $ROOT_DIR/pipeline-infra/$PRODUCT/custom-tasks/*.yaml)

for TASK in $CUSTOM_TASKS
do
    echo "Installing task $TASK in namespace $NAMESPACE"
    oc apply -f $TASK -n $NAMESPACE
    if [ $? == 0 ]; then
        echo "Installed task $TASK."
    else
        echo "Failed to install task $TASK. Script will exit"
        exit 78
    fi
done

echo "Completed task install. Installed tasks: "
tkn task list -n $NAMESPACE

if [[  "${PRODUCT}" =~ "ace" ]]
then
    # install the pipeline files 
    PIPELINE_FILE=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline-ace.yaml
    echo "Installing the pipeline file $PIPELINE_FILE for $PRODUCT in namespace $NAMESPACE"
    oc apply -f $PIPELINE_FILE -n $NAMESPACE
    if [ $? == 0 ]; then
        echo "Installed pipeline $PIPELINE_FILE."
    else
        echo "Failed to install pipeline $PIPELINE_FILE. Script will exit"
        exit 78
    fi

    PIPELINE_FILE=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline-ace-mq.yaml
    echo "Installing the pipeline file $PIPELINE_FILE for $PRODUCT in namespace $NAMESPACE"
    oc apply -f $PIPELINE_FILE -n $NAMESPACE
    if [ $? == 0 ]; then
        echo "Installed pipeline $PIPELINE_FILE."
    else
        echo "Failed to install pipeline $PIPELINE_FILE. Script will exit"
        exit 78
    fi
elif [[ "${PRODUCT}" =~ "mq" ]]
then
    PIPELINE_FILE=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline.yaml
    echo "Installing the pipeline file $PIPELINE_FILE for $PRODUCT in namespace $NAMESPACE"
    oc apply -f $PIPELINE_FILE -n $NAMESPACE
    if [ $? == 0 ]; then
        echo "Installed pipeline $PIPELINE_FILE."
    else
        echo "Failed to install pipeline $PIPELINE_FILE. Script will exit"
        exit 78
    fi
elif [[ "${PRODUCT}" =~ "ldap" ]]
then
    PIPELINE_FILE=$ROOT_DIR/pipeline-infra/$PRODUCT/pipeline/pipeline.yaml
    echo "Installing the pipeline file $PIPELINE_FILE for $PRODUCT in namespace $NAMESPACE"
    oc apply -f $PIPELINE_FILE -n $NAMESPACE
    if [ $? == 0 ]; then
        echo "Installed pipeline $PIPELINE_FILE."
    else
        echo "Failed to install pipeline $PIPELINE_FILE. Script will exit"
        exit 78
    fi
fi

echo "Completed pipeline install. Installed pipeline: "
tkn pipelines list -n $NAMESPACE
echo " "

echo "Check PVC for this pipeline exists"
echo "Pipeline expects PVC to be available matching pipeline-pvc-${NAMESPACE}"
echo " "

oc get pvc pipeline-pvc-$NAMESPACE -n $NAMESPACE
if [ $? == 0 ]; then
    echo "PVC available for pipeline in namespace $NAMESPACE"
else
    echo "PVC for pipeline not found in namespace $NAMESPACE. Will create now ..."
    oc process -f $ROOT_DIR/pipeline-infra/admin/tkn-pvc-template.yaml \
    -p NAME=pipeline-pvc-$NAMESPACE \
    -p ACCESS_MODE=ReadWriteMany \
    -p STORAGE_CLASS=ibmc-file-gold-gid \
    | oc apply -n $NAMESPACE  -f -
    echo ""
    echo "Sleep for 3 minutes to allow PVC to bind"
    echo ""
    sleep 180
    oc get pvc pipeline-pvc-$NAMESPACE -n $NAMESPACE | grep "Bound"
    if [ $? != 0 ]; then
        echo "Still waiting for PVC pipeline-pvc-$NAMESPACE to bind"
        echo "Check on this before proceeding with capability deployment"
        echo " "
        exit 78
    fi
fi

echo "Complete"
exit 0
