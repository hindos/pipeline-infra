# Directories

The 'pipeline-infra' repository contains several high level repositories, the important ones are explained in more detail below:

* ace
* admin
* ldap
* mq
* tracing

## [ace](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace "ACE Directory")

### [ace/pipeline](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace/pipeline "ACE Pipeline Directory") 

*Contains the following files:*

* **pipeline-ace-mq.yaml**: describes a Tekton pipeline which deploys an ACE container that also makes use of MQ for messaging
* **pipeline-ace.yaml**: describes Tekton pipeline which deploys an ACE server which does NOT use MQ
* **pipeline_run_template.yaml**: template for creating the pipeline runs for the two pipelines.
* **pipeline_run.yaml**: example pipeline-run file (this is not used)

### [ace/custom-tasks](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace/custom-tasks "ACE Custom Taks")

*Contains the following files:*

* **git-clone**: task to clone the github repo onto the Tekton shared workspace, modified to use a specified ssh deploy key (differing from the git-clone provided by Tekton by default)
* **resolve_props**: task which resolves properties provided by the json properties file included with the ACE source
* **generate_bar**: task which build the ACE bar file using a custom ACE image that includes the ACE Toolkit in headless mode
* **check_queue**: checks for the existance of a queue / clustered queue on the queue manager - queue and queue manager specified in application properties file
* **deploy_config.yaml**: task which deploys ACE configurations such as server.conf.yaml, dbparms, policies. *Note* this does not deploy keystore and truststore ACE configurations which are expected to be deployed before the pipleine runs (avoids keeping ssl certs in git)
* **deploy_is.yaml**: deploys the integrationserver custom resource via processing a template
* **functional_test.yaml (not currently used)**: runs a **newman** functional test against the integration server
* **commit_mqsc (not used)**: this task can be used to commit an mqsc file from the ACE source repo to the MQ source repo.*

### [ace/custom-image](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace/custom-images "ACE Custom Images")

*Contains the following folders:*

* **mqsicreatebar**: contains necessary artefacts to build the ACE image, with Eclipse Toolkit installed in headless mode, that is used by pipeline to create the bar file using *mqsicreatebar* command
* **newman**: contains necessary artefacts to build the container used for running the functional test
* **yq-zip**: contains necessary artefacts to build a container with yq installed. This is used by the **resolve_props** task.

### [ace/roles](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace/roles "ACE pipeline roles")

*Contains the following files:*

* **mq-role.yaml**: configures a role on the mq namespace which allows role-bound service accounts to get, list, exec on pods in the namespace. This is utilised by the *check_queue* task of the pipeline
* **role-binding.yaml**: sets the above role on the *pipeline* service account in the ace namespace


## [admin](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/admin "Pipeline Admin")

*Contains the following files and directories:*

* **ssh-key-secret.yaml**: template file which can be used to add new ssh keys to your OpenShift namespace/project (not used as part of this setup normally, as keys are available on box)
* **tkn-pvc-template.yaml**: template file used by the automation to create a persistent volume claim for each namespace wehere the pipelines are ran, for the pipelines task pods to use as a working directory mount

* **setup.sh**: script that can be used on mac/unix platforms to prepare to run the automation
* **run directory**: provides a dockerised scripting capability to deploy the MQ cluster (and soon the ACE apps) onto OCP

## [ldap](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ldap "ldap")

### [ldap/pipeline](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ldap/pipeline "ldpa pipeline") 

*Contains the following files:*

* **pipeline.yaml**: describes Tekton pipeline which deploys an OpenLDAP server
* **pipeline_run_template.yaml**: template for creating the pipeline runs for the pipeline.

### [ldap/custom-tasks](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ldap/custom-tasks "ldpa pipeline custom tasks")

* **git-clone.yaml**: task to clone the github repo onto the Tekton shared workspace, modified to use a specified ssh deploy key 
* **deploy-ldap.yaml**: task which deploys an OpenLDAP via a hard-coded bash Tekton *step*

## [mq](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/mq "MQ")

### [mq/pipeline](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/mq/pipeline "MQ Pipeline")

*Contains the following files:*

* **pipeline.yaml**: describes the MQ Tekton pipeline.
* **pipeline_run_template.yaml**: which templates the pipeline-run object used to instatiate a run of the afforementioned pipeline
* **pipeline-run.yaml**: an example of a pipeline run that can be applied manually to invoke the pipeline (this is not actually used)

### [mq/custom-tasks](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/mq/custom-tasks "MQ Custom Tasks")

*Contains the following files:*

* **deploy-mq-task.yaml**: Tekton task which deploys MQ custom resource via a Queue Manager Custom Resource template
* **git-clone.yaml**: custom version of the git-clone Tekton task, which has been modified to allow the specification of the correct SSH key to use, when pulling from git repositories. In this implememtation it used to pull down MQ source (mqsc definitions) and MQ infra (template files describing the Queue Manager custom resource) 
* **smoke-test.yaml**: Custom task which runs a put and get of a message to a test queue on the queue manager to validate succesful deployment
* **scripts directory**: contains scripts to put and get message as part of a smoke test, plus script to check if the MQ stateful set has rolled out.

## [tracing](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/tracing "Tracing")

This directory contains a handful of role and role-binding template files. These are not currently is use in the example.

# Next steps

Review the OCP Cluster Pre-requisites [here](pre-reqs.md).