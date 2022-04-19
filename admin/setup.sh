#!/bin/bash

# This script will:
# 1. Create a new working directory for your CP4I build in directory in which it is ran
# 2. Copy the scripts in the run directory into the new working directory
# 3. Chmod the scripts in the working directory

#set -e
BASE_DIR=$(dirname $(dirname $(pwd)))

# Check the MQ_INFRA_DIR exists
#if [ -d  $BASE_DIR ]; then
#  echo "Will create working dir in $BASE_DIR"
#else
#  echo "Provide path does not exist $BASE_DIR"
#  echo "Provide a valid path on your workstation"
#  echo "Exiting with non-zero return code"
#  exit 78
#fi

echo "Please provide name for your new working directory... "
read WORK_DIR

# Check the MQ_INFRA_DIR exists
if [ -d  $BASE_DIR/$WORK_DIR ]; then
  echo "Directory $WORK_DIR already exists in $BASE_DIR"
  echo "Please re-run the script and provide a new name"
  exit 78
else
  echo "Creating $BASE_DIR/$WORK_DIR"
  mkdir $BASE_DIR/$WORK_DIR
fi

echo "Copying script assets to your new working directory"

echo "cp run/* $BASE_DIR/$WORK_DIR"
cp -R run/* $BASE_DIR/$WORK_DIR
chmod -R 755 $BASE_DIR/$WORK_DIR/*.sh


# If running on Windows then the contents of the working directory must be 
# converted to have unix line endings, otherwise the bash utility inside the container
# will not be abe to run them
if [[ "$OSTYPE" == "msis" || "$OSTYPE" == "cygwin" ]]
then
  echo "Detected that OSTYPE is $OSTYPE - running on Windows"
  echo "Check if dos2unix available"
  which dos2unix
  if [ $? != 0 ]
  then
    echo "Running on Windows, but dos2unix ultility not available"
    echo "dos2unix required so that scripts can be executed in installer container (which is unix based)"
    echo "Please install the dos2unix utility (find via Google)"
    echo "Exiting"
    exit 78
  fi

  echo "dos2unix available, coverting scripts in $BASE_DIR/$WORK_DIR"
  dos2unix $BASE_DIR/$WORK_DIR/*.sh
fi



echo ""
echo "Your run directory, from which you can deploy the scenario is: $BASE_DIR/$WORK_DIR"
echo "The following scripts are available: "
ls -la $BASE_DIR/$WORK_DIR
echo " "



echo "When you have the repositories pulled down: "
echo " "
echo "Navigate to $BASE_DIR/$WORK_DIR"
echo " "
echo "cd $BASE_DIR/$WORK_DIR"
echo " "
echo " "
echo "Remember to set your properties in your copy of cp4i_props.sh inside echo $BASE_DIR/$WORK_DIR"
echo " "
echo "Build, run and exec into the builder docker container: docker-compose build cp4i-builder ; docker-compose run cp4i-builder bash"
echo " "
echo "Log into your openshift cluster with the oc command, inside the container"
echo "Navigate to $WORK_DIR"
echo " "
echo "Review the documentation before running the remainder of the scripts, be sure to set everything up! "
echo "OCP setup pre-reqs: https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/pre-reqs.md"
echo "Local workstation setup: https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/local-setup.md"
echo "Deploying: https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/deploy.md"
echo " "
echo "Issue ./run.sh or ./run-mq.sh or ./run-ace.sh"
echo " "
echo "Get a cup of tea"
echo "Look at the command line in wonder as it installs"
echo " "