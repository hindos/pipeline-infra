set -e

podname=$(oc get pods --selector=app.kubernetes.io/instance=$MQ_RELEASE_NAME -o custom-columns=POD:.metadata.name --no-headers | head -n 1)
echo "podname: $podname"

queue=$QUEUE_NAME
echo "queue name: $QUEUE_NAME"

oc exec $podname -- /bin/bash -c "echo \"hello-world\" | /opt/mqm/samp/bin/amqsput $queue" > putMessage.txt 2>&1

cat putMessage.txt

echo "----------"

fail="reason code"

if grep -q "$fail" putMessage.txt; then
    exit 1
else
    printf "\nMessage has been successfully put the queue.\n"
fi
