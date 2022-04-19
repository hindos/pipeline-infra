#!/bin/bash

source ./cp4i_props.sh
ls -lrt ./cp4i_props.sh

echo " "
echo "######################################################"
echo "###### STARTING installACEPipelineImages.sh ##########"
echo "######################################################"
echo " "

if [ $# -eq 0 ]
  then
    echo "Supply the name of the ACE tar file you have downloaded and put into the mqsicreatebar directory in your local copy of the pipeline-infra repo."
    echo "For example: 11.0.0.11-ACE-LINUX64-DEVELOPER.tar.gz"
fi


# Tar file should be like 11.0.0.11-ACE-LINUX64-DEVELOPER.tar.gz
ACE_TAR=$1





PATH_ACE_PIPELINE_IMAGES=${ROOT_DIR}/pipeline-infra/ace/custom-images
IMAGE_VERSION_TAG="latest"

# Check logged into cluster
oc whoami
if [ $? != 0 ]; then
    echo "Not logged into an OpenShift cluster."
    exit 78;
fi
echo "Logged into OpenShift cluster"

docker_registry_hostname=$(oc get routes -n openshift-image-registry -o=jsonpath='{.items[0].spec.host}')
echo "Docker Registry is: $docker_registry_hostname"
echo "Logging into registry"

docker login $docker_registry_hostname -u $(oc whoami) -p $(oc whoami -t)
if [ $? != 0 ]; then
  echo "Failed to log into docker registry"
  exit 78;
fi

build_and_push_image () {

    image_name=$1

    echo "Building image: $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG"
    echo " "
    docker build --no-cache -t $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG ${PATH_ACE_PIPELINE_IMAGES}/${image_name}/
    if [ $? != 0 ]; then
        echo "Failed to build image"
        exit 78;
    fi


    echo "Pushing image: $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG"
    echo " "
    docker push $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG
    if [ $? != 0 ]; then
        echo "Failed to push image"
        exit 78;
    fi

    echo "Checking image pushed succesfully"

    oc get is $image_name -n ${NAMESPACE_ACE} | grep $image_name | grep $IMAGE_VERSION_TAG
    if [ $? != 0 ]; then
        echo "Cannot find recently pushed image"
        exit 78;
    fi

    echo "succesfully built and puhed image: $image_name:$IMAGE_VERSION_TAG to project ${NAMESPACE_ACE}"

}


build_and_push_ace_image () {

    image_name=$1
    ace_tgz=$2

    cp ${ROOT_DIR}/acedev/${ace_tgz} ${ROOT_DIR}/pipeline-infra/ace/custom-images/mqsicreatebar

    echo "Building image: $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG"
    echo " "
    docker build -t $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG --build-arg ACE_INSTALL=${ace_tgz} ${PATH_ACE_PIPELINE_IMAGES}/${image_name}/
    if [ $? != 0 ]; then
        echo "Failed to build image"
        echo "Remove the ace tar file from the ${ROOT_DIR}/pipeline-infra/ace/custom-images/mqsicreatebar directory"
        rm ${ROOT_DIR}/pipeline-infra/ace/custom-images/mqsicreatebar/${ace_tgz}
        exit 78;
    fi

    echo "Remove the ace tar file ${ace_tgz} from the ${ROOT_DIR}/pipeline-infra/ace/custom-images/mqsicreatebar directory"
    rm ${ROOT_DIR}/pipeline-infra/ace/custom-images/mqsicreatebar/${ace_tgz}



    echo "Pushing image: $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG"
    echo " "
    docker push $docker_registry_hostname/${NAMESPACE_ACE}/$image_name:$IMAGE_VERSION_TAG
    if [ $? != 0 ]; then
        echo "Failed to push image"
        exit 78;
    fi

    echo "Checking image pushed succesfully"

    oc get is $image_name -n ${NAMESPACE_ACE} | grep $image_name | grep $IMAGE_VERSION_TAG
    if [ $? != 0 ]; then
        echo "Cannot find recently pushed image"
        exit 78;
    fi

    echo "succesfully built and puhed image: $image_name:$IMAGE_VERSION_TAG to project ${NAMESPACE_ACE}"

}

build_and_push_image "yq-zip"
build_and_push_image "newman"
build_and_push_ace_image "mqsicreatebar" $ACE_TAR

echo "Images built and pushed" 

