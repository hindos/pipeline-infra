#!/bin/bash
# Creates the ssh key for each repository then adds the private key to a secret of the same name in the mq or ace namespace
# Setting test namespaces of ace-2 and mq-2

oc whoami
if [ $? != 0 ]; then
  echo "Not logged into an OpenShift cluster."
  exit 78;
fi
echo "Logged into OpenShift cluster"

echo "################################# "
echo " "
echo "Please provide namespace in which to create the ssh key secrets... "
echo "...."
read NAMESPACE



for REPO in $@
do
    echo "create ssh keys for repo cpat-agile-integration-sample/$REPO"
	ssh-keygen -C "cpat-agile-integration-sample/$REPO@github.ibm.com" -f $REPO -N ''
    ls -lrt | grep $REPO

    #echo $REPO | grep "mq"
    #if [ $? == 0 ];
    #then
    #    NAMESPACE=mq-2
    #    echo "Namespace is mq"
    #else
    #    NAMESPACE=ace-2
    #    echo "Namespace is ace"
    #fi

    oc process -f ssh-key-secret.yaml \
    -p NAME=${REPO} \
    -p PRIVATE_KEY=$(base64 ${REPO}) \
    -p KNOWN_HOSTS=$(ssh-keyscan github.ibm.com | base64) | oc -n $NAMESPACE apply -f -
    echo " "
    oc get secret $REPO -n $NAMESPACE
    if [ $? != 0 ]
    then
        echo "Failed to create secret $REPO in namespace $NAMESPACE"
        echo "Script will exit"
        exit 78;
    fi
    echo " "
done
