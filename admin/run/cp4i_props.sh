#!/bin/bash

echo "Export properties to environment.... "

# Generic
export ROOT_DIR=$(dirname $(pwd))
export THIS_PIPELINE_RUN=$(date +%s)-run
export PATH_TO_DOCKER_TEST=${ROOT_DIR}/ldap-certgen-mongo/mq-test-via-route
export TRACING_NS="tracing"
export WORKING_DIR=$(pwd)


# Certificate values
export ORG="arab-bank"
export COMMON_NAME="*.eu-gb.containers.appdomain.cloud"
# Example SAN_DNS would be "*.banking-2021-01-3cd0ec11030dfa215f262137faf739f1-0000.eu-gb.containers.appdomain.cloud"

export SAN_DNS="itzroks-55000169bx-4qbrcj-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud"
#export SAN_DNS="*.<your-clusters-load-balancer-address-replace-me>"
export ORGANISATION="ARAB_BANK"
export ORGANISATION_UNIT_CA="CA_${ORGANISATION}_INFRA"
export ORGANISATION_UNIT_MQ="${ORGANISATION}_MQ"
export ORGANISATION_UNIT_ACE="${ORGANISATION}_ACE"
export ORGANISATION_UNIT_DATAPOWER="${ORGANISATION}_DP"
export ORGANISATION_UNIT_CLIENT="${ORGANISATION}_CLIENT"
export COUNTRY="UK"
export LOCALITY="Croydon"
export STATE="UnitedKingdom"

# LDAP variables
NAMESPACE_LDAP="ldap"
LDAP_TKN_BUILD_PVC=pipeline-pvc-${NAMESPACE_LDAP}
LDAP_INFRA_SSH_PRIVATE_KEY="ldap-certgen-mongo"

# Mongo Variables

MONGO_INSTANCE="mongodb"
MONGO_USER="admin"
MONGO_PWD="passw0rd"
MONGO_DBNAME="customer_updates"
MONGO_ADMIN_PWD="passw0rd"
NAMESPACE_MONGO="mongodb-dev"


# MQ variables
export NAMESPACE_MQ="mq-dev"

export MQ_INFRA_DIR=${ROOT_DIR}/mq-infra

export MQ_INFRA_SSH_PRIVATE_KEY="mq-infra"
export MQ_SOURCE_SSH_PRIVATE_KEY="mq-source"
export TEST_QUEUE="TEST.QUEUE.V1"
export MQ_TKN_BUILD_PVC=pipeline-pvc-${NAMESPACE_MQ}
export CA_CERT_SECRET_NAME="${ORG}-ca-cert"
export MQ_SERVER_KEY_CERT_SECRET_NAME="${ORG}-mq-key-cert"
export MQ_SERVER_KEY_KEY_VALUE="${ORG}-mq-server.key"
export MQ_SERVER_CERT_KEY_VALUE="${ORG}-mq-server.crt"
export CA_CERT_KEY_VALUE="${ORG}-ca.crt"
export EXTERNAL_SVRCONN="DEV.APP.SVRCONN"

# ACE variables
export NAMESPACE_ACE="ace-dev"

export ACE_INFRA_DIR=${ROOT_DIR}/ace-infra
# Removed ls to get the below names to avoid props script ls errors before certificates are created
export ACE_KS_JKS=${ORG}-ace-server.jks
export ACE_TS_JKS=${ORG}-ca.jks
export ACE_KDB=${ORG}-ace-server.kdb
export ACE_STASH=${ORG}-ace-server.sth
export ACE_KS_JKS_PATH=$WORKING_DIR/$CERTS_WORKING_DIR/cert-generation/${ACE_KS_JKS}
export ACE_TS_JKS_PATH=$WORKING_DIR/$CERTS_WORKING_DIR/cert-generation/${ACE_TS_JKS}
export ACE_KDB_PATH=$WORKING_DIR/$CERTS_WORKING_DIR/cert-generation/${ACE_KDB}
export ACE_STASH_PATH=$WORKING_DIR/$CERTS_WORKING_DIR/cert-generation/${ACE_STASH}
# Note the secret names for ACE TLS configs are the same as the jks / kdb / sth names
# Keeping in separate variable for flexibility
export ACE_KEYSTORE_SECRET="${ORG}-ace-server-keystore.jks"
export ACE_TRUSTSTORE_SECRET="${ORG}-ace-server-truststore.jks"
export ACE_KDB_SECRET="${ORG}-ace-server.kdb"
export ACE_STASH_SECRET="${ORG}-ace-server.sth"

export ACE_INFRA_SSH_PRIVATE_KEY="ace-infra"
export ACE_CONFIG_SSH_PRIVATE_KEY="ace-config"
# ace source ssh key depends on service being built

export ACE_TKN_BUILD_PVC=pipeline-pvc-${NAMESPACE_ACE}
