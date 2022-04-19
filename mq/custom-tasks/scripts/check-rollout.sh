#!/bin/bash

set -e

pass="roll out complete"
count=0

while :
do
    statefulset_name=`oc get StatefulSet --selector=app.kubernetes.io/instance=${MQ_RELEASE_NAME} -o custom-columns=:metadata.name --no-headers`
    echo "statefulset name : $statefulset_name"

    status=`oc rollout status StatefulSet $statefulset_name | tr -d \"`

    if [[ "$status" == *"$pass"* ]]
    then
        printf "Pods are deployed.\n\n"
        break
    elif [ "$count" -eq "6" ]
    then
        printf "Pods failed to deploy after 5 minutes.\n\n"
        exit 1
    else
        printf "Trying again\n\n"
        sleep 10
    fi

    count=$(($count + 1))

done