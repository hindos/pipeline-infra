#!/bin/bash
# Generates certificates for MQ, ACE and DataPower, plus a CA


# set -x

ROOT_DIR=$1
CERTS_WORKING_DIR=$2
PATH_TO_CERTGEN=${ROOT_DIR}/ldap-certgen-mongo/cert-generation/
CURRENT_DIR=$(pwd)

source ./cp4i_props.sh


echo " "
echo "#################################################"
echo "###### STARTING generateCerts.sh ##########"
echo "#################################################"
echo " "
echo "Printing input parameters...."
echo " "
echo "ROOT_DIR: $ROOT_DIR"
echo "CERTS_WORKING_DIR: $CERTS_WORKING_DIR"
echo "PATH_TO_CERTGEN: $PATH_TO_CERTGEN"
echo " "



# Check the the PATH_TO_CERTGEN exists
if [ -d  $PATH_TO_CERTGEN ]; then
  echo "Certegen dir is $PATH_TO_CERTGEN"
else
  echo "Certegen dir is $PATH_TO_CERTGEN does not exist"
  echo " You must clone the ldpa-certgen-mongo repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi

# Create the working diretory for making the certs in / check it then exists
mkdir $CERTS_WORKING_DIR
if [ -d  $CERTS_WORKING_DIR ]; then
  echo "Certegen dir is $CERTS_WORKING_DIR"
else
  echo "Certegen dir is $CERTS_WORKING_DIR does not exist"
  echo " You must clone the ldpa-certgen-mongo repositrory from the capt-agile-integration-sample org"
  echo "Exiting with non-zero return code"
  exit 78
fi


# Copy the cert generator to our working directory + check that was OK by seeing if the docker-compose exists
cp -R $PATH_TO_CERTGEN $CERTS_WORKING_DIR/
chmod -R 755 $CERTS_WORKING_DIR/


# List out the certs we have generated
cd $CERTS_WORKING_DIR/cert-generation
make
cd $CURRENT_DIR
pwd
echo "List out certs in directory $CERTS_WORKING_DIR/cert-generation"


ls -la $CERTS_WORKING_DIR/cert-generation

echo " "
exit 0