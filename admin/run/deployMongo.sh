#!/bin/bash
# Deploys MongoDB
# set -x


#!/bin/bash

WORKING_DIR=$1


ROOT_DIR=$(dirname $(pwd))
PRODUCT=mongo
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING deployMongo.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "WORKING_DIR: $WORKING_DIR"
echo " "

echo "Printing parameters from properites...."

echo " "


echo "MONGO_INSTANCE is: ${MONGO_INSTANCE}"
echo "MONGO_USER is ${MONGO_USER}"        
echo "MONGO_PWD is ${MONGO_PWD}"
echo "MONGO_DBNAME is ${MONGO_DBNAME}"
echo "MONGO_ADMIN_PWD is ${MONGO_ADMIN_PWD}"
echo "NAMESPACE_MONGO is ${NAMESPACE_MONGO}"        

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




# Set mq-infra directory in a variable
MONGO_INFRA_DIR=${ROOT_DIR}/ldap-certgen-mongo/mongo/

# Check the MONGO_INFRA_DIR exists
if [ -d  $MONGO_INFRA_DIR ]; then
  echo "Certegen dir is $MONGO_INFRA_DIR"
else
  echo "Certegen dir is $MONGO_INFRA_DIR does not exist"
  echo " You must clone the ldap-certgen-mongo repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi



deploy_mongo () {
    oc process -f ${MONGO_INFRA_DIR}/mongo-openshift.yaml \
        -p DATABASE_SERVICE_NAME=${MONGO_INSTANCE} \
        -p MONGODB_USER=${MONGO_USER} \
        -p MONGODB_PASSWORD=${MONGO_PWD} \
        -p MONGODB_DATABASE=${MONGO_DBNAME} \
        -p MONGODB_ADMIN_PASSWORD=${MONGO_ADMIN_PWD}  \
        | oc -n ${NAMESPACE_MONGO} apply -f -

}


check_mongo () {

    count="0"
    maxcount="30"

    while [ $count -lt $maxcount ]
    do
        echo "oc -n ${NAMESPACE_MONGO} get pod -l name=${MONGO_INSTANCE} -o jsonpath='{$.items[*].status.phase}'"

        mongo_status=$(oc -n ${NAMESPACE_MONGO} get pod -l name=${MONGO_INSTANCE} -o jsonpath='{$.items[*].status.phase}' | grep Running)
        if [ $? != 0 ]; then
            if [ "$count" -eq $(($maxcount -1)) ]
            then
                echo "MongoDB pod ${mongo_pod} not Running after 5 minutes."
                echo "Script will exit. Please check OpenShift."
                exit 1
            else
                echo "MongoDB pod ${mongo_pod} not Running yet, will sleep and check again."
                sleep 10
            fi
            echo "Current status of MongoDB pod ${mongo_pod}: ... ${mongo_status}"
        else
            echo "Current status of MongoDB pod ${mongo_pod}: ... ${mongo_status}"
            break
        fi
        count=$[$count+1]
    done

    echo "Sleep whilst collection is setup on Mongo"
    sleep 20

    echo "oc -n ${NAMESPACE_MONGO} get pod -l name=${MONGO_INSTANCE} -o jsonpath=\'{$.items[*].metadata.name}\'"
    mongo_pod=$(oc -n ${NAMESPACE_MONGO} get pod -l name=${MONGO_INSTANCE} -o jsonpath='{$.items[*].metadata.name}')
    echo $mongo_pod

    echo "oc -n ${NAMESPACE_MONGO} exec -ti ${mongo_pod} -- mongo -u ${MONGO_USER} -p ${MONGO_PWD} ${MONGO_DBNAME} --eval \"db.showCollection\""

    mongo_ready=$(oc -n ${NAMESPACE_MONGO} exec -ti ${mongo_pod} -- mongo -u ${MONGO_USER} -p ${MONGO_PWD} ${MONGO_DBNAME} --eval "db.showCollection")
    echo "Collection setup: ${mongo_ready}"

}

# Run the deploy and then check 

deploy_mongo

check_mongo

echo "Mongo deployment completed. "