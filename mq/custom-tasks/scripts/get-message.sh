set -e

podname=$(oc get pods --selector=app.kubernetes.io/instance=$MQ_RELEASE_NAME -o custom-columns=POD:.metadata.name --no-headers | head -n 1)
echo "podname: $podname"

queue=$QUEUE_NAME
echo "queue name: $QUEUE_NAME"

oc exec $podname  -c qmgr -- /opt/mqm/samp/bin/amqsget $queue > getMessage.txt 2>&1

cat getMessage.txt


if grep -q "$EXPECTED_MESSAGE" getMessage.txt; then
    printf "\nMessage has been found on the queue.\n"
else
    printf "\nError: Message has not been retrieved from the queue.\n"
    exit 1
fi