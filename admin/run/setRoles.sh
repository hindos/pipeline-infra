#!/bin/bash
# Sets the roles and role bindings to allow the pipeline service account
# to list the operations dashboard pods
# set -x


#!/bin/bash



ROOT_DIR=$(dirname $(pwd))

source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING deployMongo.sh ##########"
echo "#################################################"
echo " "


echo "Printing parameters from properites...."

echo " "

echo "TRACING_NS is: ${TRACING_NS}"
echo "NAMESPACE_MQ is: ${NAMESPACE_MQ}"
echo "NAMESPACE_ACE is: ${NAMESPACE_ACE}"

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




# Set pipeline-infra tracing directory in a variable
PL_TRC_INFRA_DIR=${ROOT_DIR}/pipeline-infra/tracing/

# Check the PL_TRC_INFRA_DIR exists
if [ -d  $PL_TRC_INFRA_DIR ]; then
  echo "Certegen dir is $PL_TRC_INFRA_DIR"
else
  echo "Certegen dir is $PL_TRC_INFRA_DIR does not exist"
  echo " You must clone the pipeline-infra repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi



apply_role () {
    oc process -f ${PL_TRC_INFRA_DIR}/podlist-role-template.yaml \
        -p NAMESPACE_OD="${TRACING_NS}" \
        | oc apply -f -

        if [ $? != 0 ]; then
            echo "Apply role for pipeline SA to list OD pods failed."
            echo "Script will exit"
            exit 78
        fi
        oc get role tracing-podlist-role -n ${TRACING_NS} 
}

apply_rolebinding () {
    oc process -f ${PL_TRC_INFRA_DIR}/list-od-role-binding-template.yaml \
        -p NAMESPACE_OD="${TRACING_NS}" \
        -p NAMESPACE_MQ="${NAMESPACE_MQ}" \
        -p NAMESPACE_ACE="${NAMESPACE_ACE}" \
        | oc apply -f -

        if [ $? != 0 ]; then
            echo "Apply role binding for pipeline SA to list OD pods failed."
            echo "Script will exit"
            exit 78
        fi

        oc get rolebinding tracing-list-rolebinding  -n ${TRACING_NS}
}





apply_role

apply_rolebinding

echo "Roles and rolebindings for  pipeline SA to list OD pods completed. "