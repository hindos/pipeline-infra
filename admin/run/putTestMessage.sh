#!/bin/bash
#set -e


WORKING_DIR=$1
THIS_RUN_CERT_DIR=$2
QMGR1=$3
PUT_QUEUE=$4


ROOT_DIR=$(dirname $(pwd))
PRODUCT=mq
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING putTestMessage.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "WORKING_DIR: $WORKING_DIR"
echo "THIS_RUN_CERT_DIR: $THIS_RUN_CERT_DIR"
echo " "

echo "Printing parameters from properites...."

echo " "

echo "ROOT_DIR is $ROOT_DIR"
echo "MQ_INFRA_DIR is $MQ_INFRA_DIR"
echo "NAMESPACE_MQ is $NAMESPACE_MQ"
echo "MQ_KEY_CERT_SECRET is $MQ_KEY_CERT_SECRET"
echo "MQ_CA_CERT_SECRET is $MQ_CA_CERT_SECRET"
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

QMGR1_LC=$(echo $QMGR1 | tr A-Z a-z)
HOSTNAME=$(oc get route $QMGR1_LC-ibm-mq-qm -n $NAMESPACE_MQ -o jsonpath='{.spec.host}{"\n"}')


CLIENT_JKS=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep client.jks)
CLIENT_JKS_PATH=$WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation/$CLIENT_JKS

CA_JKS=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep ca.jks)
CA_JKS_PATH=$WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation/$CA_JKS


CA_CRT=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep ca.crt)
CA_CRT_PATH=$WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation/$CA_CRT

CLIENT_CRT=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep client.crt)
CLIENT_CRT_PATH=$WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation/$CLIENT_CRT

CLIENT_KEY=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep client.key)
CLIENT_KEY_PATH=$WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation/$CLIENT_KEY


export QM_NAME=${QMGR1}
export HOST=${HOSTNAME} 
export PORT=443 
export JKS_KEYSTORE_PATH=${CLIENT_JKS_PATH} 
export JKS_TRUSTSTORE_PATH=${CA_JKS_PATH} 
export QUEUE_NAME=${PUT_QUEUE}
export SVRCONN=${EXTERNAL_SVRCONN}

UNIQUE_TIMESTAMP=$(date +%s)
NEW_REQ_FILE_NAME=${UNIQUE_TIMESTAMP}-request.xml

echo " "
echo "Creating file $(pwd)/jms/${NEW_REQ_FILE_NAME}"
cp $(pwd)/jms/request.xml $(pwd)/jms/${NEW_REQ_FILE_NAME}
ls -lrt $(pwd)/jms/${NEW_REQ_FILE_NAME}

export PAYLOAD_PATH=$(pwd)/jms/${NEW_REQ_FILE_NAME}

echo "Upating street number in request"
echo "sed -i \"s/REPLACE_NUMBER/$UNIQUE_TIMESTAMP/g\" $PAYLOAD_PATH"
sed -i "s/REPLACE_NUMBER/$UNIQUE_TIMESTAMP/g" $PAYLOAD_PATH
echo " "
echo "Check the request message..."
cat $PAYLOAD_PATH
echo " "


echo $QM_NAME
echo $HOST
echo $JKS_KEYSTORE_PATH
echo $JKS_TRUSTSTORE_PATH
echo $QUEUE_NAME
echo $PAYLOAD_PATH

cd ${WORKING_DIR}/jms
./gradlew run
cd ${WORKING_DIR}

echo " "
echo " "

echo $CA_CRT_PATH
echo $CLIENT_CRT_PATH
echo $CLIENT_KEY_PATH
echo " "

sleep 5


READ_SERVICE_NAME="readallcustomers"

read_all_customers_route=$(oc -n ${NAMESPACE_ACE} \
                        get routes -l app.kubernetes.io/instance=${READ_SERVICE_NAME} \
                        -o jsonpath='{.items[?(@.spec.port.targetPort=="https")].spec.host}')


echo "curl -s --cacert $CA_CRT_PATH --cert $CLIENT_CRT_PATH --key $CLIENT_KEY_PATH https://${read_all_customers_route}/readallcustomers/v1/customers"
curl -s --cacert $CA_CRT_PATH --cert $CLIENT_CRT_PATH --key $CLIENT_KEY_PATH https://${read_all_customers_route}/readallcustomers/v1/customers | jq -c '.[]' | grep ${UNIQUE_TIMESTAMP}
if [ $? != 0 ]; then
    echo "Failed to find new record with unique idenitier ${UNIQUE_TIMESTAMP} in address field"
    exit 78;
else
    echo " "
    echo "Found new record with unique idenitier ${UNIQUE_TIMESTAMP} in address field inside Mongo DB"
    echo " "
fi


echo "Successfully tested ACE and MQ deployments securely."

# Zip up the certificates
zip -r ./${PWD##*/}.$THIS_RUN_CERT_DIR.zip $WORKING_DIR/$THIS_RUN_CERT_DIR/cert-generation
ls ./${PWD##*/}.$THIS_RUN_CERT_DIR.zip
echo "Certs created for this demo available in this zip file: ./${PWD##*/}.$THIS_RUN_CERT_DIR.zip"

# Explain setup for MQ Clients

CLIENT_KDB=$(ls $THIS_RUN_CERT_DIR/cert-generation | grep ace-server.kdb | cut -d'.' -f1)

echo " "
echo "##############################################"
echo "Setup for putting your own test messages to MQ"
echo "##############################################"
echo " "
echo "To connect to CQM5 via an MQ C based client such as rfhutilc you will need the following..."
echo " "
echo "MQSERVER variable: "
echo " "
echo "Windows: "
echo "SET MQSERVER=$SVRCONN/TCP/$HOST(443)"
echo " "
echo "Unix: "
echo "export MQSERVER=$SVRCONN/TCP/$HOST(443)"
echo " "
echo " "
echo "Set up certificates..."
echo " "
echo "Take the zip file $WORKING_DIR/$THIS_RUN_CERT_DIR.zip and expand on your test server"
echo " "
echo "Set certificate as:"
echo "<path-to-unzipped-folder/$CLIENT_KDB"
echo "Note that on IBM MQ C clients the '.kdb' extension is not required."
echo " "
echo "Set the username and password for the connection to 'app' and 'app'"
echo " "
echo "Cipher: set the cipher used by the client to: ECDHE_RSA_AES_256_CBC_SHA384 "
echo "The cipher was set on the channel in the config.mqsc of the CQM5 queue manager in the mq-source repo"
echo " "
echo "The above settings can be configured on rfhutilc on the 'Set Conn ID' panel"
echo "Be sure to check the 'SSL' and 'Use CSP' tickboxes".
echo " "
echo "For regular MQ client application setup please review the documentation on the the following variables: "
echo "MQSERVER"
echo "MQSSLKEYR"
echo "MQSAMP_USER_ID"
echo "Note - I did not add links here as I don't want them to be broken in the future. Paste these into Google and you will be fine"
echo " "
echo " "
echo " "
echo "The queue name to PUT your message to is: CREATE.CUSTOMER.Q.V1"
echo " "
echo "Sample message... "
echo " "
echo "The sample message can be found here: $PAYLOAD_PATH"
echo " "
cat $PAYLOAD_PATH
echo " "


echo " "
echo "##############################################"
echo "Setup for reading back messages via Postman"
echo "##############################################"
echo " "
echo "In your Postman session you will need to click on the cog icon on the top right and select 'settings'."
echo "Next select 'Certificates' and under 'Client Certificates' click 'Add Certificate'"
echo " "
echo "For the hostname put: $SAN_DNS"
echo "For the CRT file put: <path-to-unzipped-folder>/$CLIENT_CRT "
echo "For the KEY file put: <path-to-unzipped-folder>/$CLIENT_KEY "
echo "Note that on Windows the '.crt' extension might not show in the Windows explorer."
echo "Nothing more is required on that panel, so just click 'Add'"
echo " "
echo "Back on the Settings Panel, Certificates tab you must add the CA"
echo "Under 'CA Certificates', next to 'PEM File' click 'Select File'"
echo "The CA file to add is: $CA_CRT"
echo "Note that on Windows the '.crt' extension might not show in the Windows explorer."
echo " "
echo "Back on the 'General' tab select 'SSL certificate verification'. This will ensure a mutually authenticated connection to ACE."
echo "The demo will work regardless of whether this is selected, but a TLS warning will be shown if it is not enabled."
echo " "
echo "Setup your request: "
echo " "
echo "Request type must be: 'GET'"
echo "Hostname to use: https://${read_all_customers_route}/readallcustomers/v1/customers"
echo " "
echo "With these instuctions you will be able to add new customers via MQ and read them back via the ACE REST service"
