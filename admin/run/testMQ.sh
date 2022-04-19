#!/bin/bash
# Deploys 5 MQ queue managers for form an MQ cluster
# set -x


#!/bin/bash

WORKING_DIR=$1
THIS_RUN_CERT_DIR=$2
CERT_PREFIX=$3
TEST_CLUSTER=$4
# Leave us with a list of queue managers
shift 4
echo $@

ROOT_DIR=$(dirname $(pwd))
PRODUCT=mq
source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "#################################################"
echo "###### STARTING testMQ.sh ##########"
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

put_message () {
    qmgr_pod=$1
    temp_file_name=check_$2_put_$THIS_PIPELINE_RUN.txt
    queue=$3
    message=$4
    echo "message is $message"
    echo "queue is $queue"
    oc exec $qmgr_pod -c qmgr -n $NAMESPACE_MQ -- /bin/bash -c "echo \"${message}\" | /opt/mqm/samp/bin/amqsput $queue" > $temp_file_name 2>&1
    cat $temp_file_name
    rm $temp_file_name
    echo "Put message complete"
    echo " "
}


get_message () {
    qmgr_pod=$1
    temp_file_name=check_$2_get_$THIS_PIPELINE_RUN.txt
    queue=$3
    message=$4

    echo "Getting message from queue $queue on qmgr pod $qmgr_pod..."
    echo "Please wait for amqsget sample to finish"
    oc exec $qmgr_pod -c qmgr -n $NAMESPACE_MQ -- /opt/mqm/samp/bin/amqsget $queue > $temp_file_name 2>&1
    cat $temp_file_name

    if grep -q "$message" $temp_file_name 
    then
        echo "Message has been found on the queue."
    else
        echo "Error: Message has not been retrieved from the queue."
        exit 78
    fi
    rm $temp_file_name
    echo " "
}

test_cluster_message () {
    qmgr1=$1
    qmgr2=$2
    the_queue=$3
    the_message=$4
    qmgr_pod_1=$(get_pod_name "$qmgr1")
    qmgr_pod_2=$(get_pod_name "$qmgr2")

    put_message "$qmgr_pod_1" "$qmgr1" "$the_queue" "$the_message"
    
    sleep 10
    get_message "$qmgr_pod_2" "$qmgr2" "$the_queue" "$the_message"
    echo "Test of cluster queue $the_queue completed"
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

test_via_route () {
    echo $test | tr a-z A-Z
    qmgr1=$1
    qmgr2=$2
    qmgr1_uc=$(echo $qmgr1 | tr a-z A-Z)
    qmgr2_uc=$(echo $qmgr2 | tr a-z A-Z)
    the_queue=$3
    the_message=$4
    test_dir=$THIS_RUN_CERT_DIR/mq-test-via-route
    client_cert=$THIS_RUN_CERT_DIR/cert-generation/$CERT_PREFIX-ace-server.kdb
    client_stash=$THIS_RUN_CERT_DIR/cert-generation/$CERT_PREFIX-ace-server.sth
    ca_cert=$THIS_RUN_CERT_DIR/$CERT_PREFIX-ca.crt

    # Check in this $THIS_RUN_CERT_DIR to 
    if [ ! -d $test_dir ]
    then
        mkdir $test_dir
        echo "Created directory for testing MQ via external route: $test_dir"
    else
        echo "Test dir $test_dir exists"
    fi

    # Copy artefacts for testing mq from ldap-certgen-mongo repo 
    cp -R $PATH_TO_DOCKER_TEST/client-volume $test_dir/
    cp $PATH_TO_DOCKER_TEST/docker-compose.yaml $test_dir/
    cp $PATH_TO_DOCKER_TEST/docker-compose-override-env.yaml $test_dir/
    cp $PATH_TO_DOCKER_TEST/Dockerfile $test_dir/
    ls -lrt $test_dir
    chmod -R 755 $test_dir/client-volume
    ls -la $test_dir/client-volume

    # Copy in kdb and stn file to test directory
    cp $client_cert $test_dir/client-volume
    cp $client_stash $test_dir/client-volume
    ls -la $test_dir/client-volume

    # modify the ccdt to point at our cluster

    # get the hostname of the ingress
    hostname=$(oc get route $qmgr1-ibm-mq-qm -n mq-2 -o jsonpath='{.spec.host}{"\n"}')
    ccdt_file=$test_dir/client-volume/ccdt.json
    # See if the hostname is already in the ccdt
    echo "hostname is: $hostname"
    cat $ccdt_file | grep $hostname
    if [ $? != 0 ]; then
        # use sed to replace hostname
        # removed '' after -i on sed command. This was required for mac, but now running
        # in CentOS container
        echo "Editing ccdt file $ccdt_file with hostname $hostname"
        sed -i "s/REPLACE_HOST/$hostname/g" $ccdt_file
    fi
    cat $ccdt_file

    
    # Create docker-compose override file for put
    # Note that REPLACE_QMGR_GET is not actually used in this function, as we get the message by execing into the container of qmgr2
    # This is because we only have a route for CQM5's sni
    docker_compose_override_file=$test_dir/docker-compose-override-env.yaml
    sed -i "s/REPLACE_TARGET_Q/$the_queue/g" $docker_compose_override_file
    sed -i "s/REPLACE_QMGR_GET/$qmgr2_uc/g" $docker_compose_override_file
    sed -i "s/REPLACE_QMGR_PUT/$qmgr1_uc/g" $docker_compose_override_file
    sed -i "s/REPLACE_TEST_MESSAGE/$the_message/g" $docker_compose_override_file
    sed -i "s/REPLACE_KDB/$CERT_PREFIX-ace-server/g" $docker_compose_override_file



    echo "Edited environment overrides for docker-compose"
    cat $docker_compose_override_file
    echo " "

    echo "docker-compose -f $test_dir/docker-compose.yaml -f $docker_compose_override_file run mq-client bash"

    #invoke put 
    echo "./sendMessage.sh" | docker-compose -f $test_dir/docker-compose.yaml -f $docker_compose_override_file run mq-client bash

    # We will get the message locally, not remotely - hence below line is commented
    #echo "./receiveMessage.sh" | docker-compose -f $test_dir/docker-compose.yaml -f $docker_compose_override_file run mq-client bash

    # Get the pod name
    qmgr_pod_2=$(get_pod_name "$qmgr2")
    echo "qmgr_pod_2 is: $qmgr_pod_2"
    
    # Get the test message
    get_message "$qmgr_pod_2" "$qmgr2" "$the_queue" "$the_message"

    echo "Successful PUT and GET test completed."
    echo "Test message: $the_message"
    echo "Put via external route to Queue Manager: $qmgr1_uc"
    echo "Get via oc exec from Queue Manager: $qmgr2_uc"
    echo " "
}

# Check the Queue Managers that can be seen in the cluster
for QMGR in $@
do
    echo "Running cluster queue manager checks for $QMGR in namespace $NAMESPACE_MQ"
    this_pod_name=$(get_pod_name "$QMGR")
    echo "Pod name for queue manager $QMGR is: $this_pod_name"
    check_runmqsc "$this_pod_name" "$QMGR" "DISPLAY CLUSQMGR(*)"
done

## Check the Channel Statuses for SSLPEER 
for QMGR in $@
do
    echo "Running channel status checks for $QMGR in namespace $NAMESPACE_MQ"
    this_pod_name=$(get_pod_name "$QMGR")
    echo "Pod name for queue manager $QMGR is: $this_pod_name"
    check_runmqsc "$this_pod_name" "$QMGR" "DISPLAY CHSTATUS(*) SSLPEER"
done

## Check the MQ Cluster Queues that can be seen on each queue manager
for QMGR in $@
do
    echo "Running channel status checks for $QMGR in namespace $NAMESPACE_MQ"
    this_pod_name=$(get_pod_name "$QMGR")
    echo "Pod name for queue manager $QMGR is: $this_pod_name"
    check_runmqsc "$this_pod_name" "$QMGR" "DISPLAY QCLUSTER(*)"
done

# Check cluster is working
if [ $TEST_CLUSTER == "true" ]; then
    test_cluster_message "cqm5" "cqm3" "CREATE.CUSTOMER.Q.V1" "Test message from $THIS_PIPELINE_RUN"
    test_cluster_message "cqm3" "cqm4" "UPDATE.DATASTORE.Q.V1" "Test message from $THIS_PIPELINE_RUN"

    # Send message via external container to each cluster queue, via cqm5 to test route
    #test_via_route "cqm5" "cqm3" "CREATE.CUSTOMER.Q.V1" "Test-message-from-$THIS_PIPELINE_RUN"
fi

# List the queue managers out before finishing
for QMGR in $@
do
    echo "List out MQ Queue Manager $QMGR in namespace $NAMESPACE_MQ"
    list_qmgr "$QMGR"
done


echo " "

echo "MQ cluster deployment completed: "


