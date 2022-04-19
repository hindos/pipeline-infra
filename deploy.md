# Run the scripting to install components of the architecture

There are three steps to deploying onto the OCP cluster:

* Install the ldap and mongodb, plus generate the certificates to be used for the architecture: **run-prereqs.sh**
* Install the MQ Queue Managers: **run-mq.sh**
* Install the ACE (toolkit) integration services: **run-ace.sh**

## Log into OCP from within the container

As your terminal is now inside the container, you will have to log in again. 

Get a login key from OCP and run this inside the container.

## Navigate to your test directory

The *docker-compose run* command will put you into the *run* directory (ie: back one directory from where you were outside of the docker *installer* container). You will therefore need to navigate back to your test directory you created as part of the *setup.sh*.

**Note** it is very important to cd into the directory and execute the ``./run-prereqs.sh`` /  ``./run-mq.sh`` / ``./run-ace.sh`` scripts from within that (its local) directory - so that the pathing inside the scripting works correctly (this is not production level code).

``cd <your_test_dir>``

## Double chck you have set up your [cp4i_props.sh](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/run/cp4i_props.sh "cp4i props files") file

Easy to forget to do this! Just double check you have done this!

## Install the pre-reqs, create certificates, install mongoDB, install LDAP

Issue the command ``./run-prereqs.sh``

[This](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/run/run-prereqs.sh "run-prereqs.sh") script will run the following:

* generateCerts.sh - uses a makefile from the *ldap-certgen-mongo* directory to create all the required certificates for the scenario, inluding a CA
* installPipeline.sh - install a pipeline for installing the *OpenLDAP* server
* deployLDAP.sh - runs the LDAP pipeline, installing the LDAP into a project/namespace called *ldap*
* deployMongo.sh - deploys MongoDB instance into the project/namespace specified inside the cp4i_props.sh file (note this is not deployed via a pipeline)

**Note** - when you run this for the first time on a given OCP cluster there will be a three minute sleep whilst the PVC for the LDAP pipeline workspace is created.

## Install the IBM MQ Queue Managers and run verification tests

Issue the command ``./run-mq.sh``

[This](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/run/run-mq.sh "run-mq.sh") script will run the following:

* createMQCertSecrets.sh - creates the key-cert and ca secrets in the namespace for MQ
* installPipeline.sh - installs the pipeline.yaml and custom tasks in the namepace for MQ
* deployMQ.sh - 
    * invokes the pipeline for X number queue managers, by default we specify *CQM1* - *CQM5* 
    * applies a route for a single Queue Manager (by default we specify cqm5) to be contactible externally, va sni
* testMQ.sh - performs a series of checks on the deployed MQ Queue Managers
    * check cluster queue manager
    * check channel status
    * check clustered queue availability
    * optionally:
        * send messages across the cluster using amqsput and amqsget samples

**Note** - when you run this for the first time on a given OCP cluster there will be a three minute sleep whilst the PVC for the MQ pipeline workspace is created.

## Install the IBM ACE (tookit) Integration Servers and run verification tests

Issue the command ``./run-ace.sh``

[This](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/run/run-ace.sh "run-ace.sh") script will run the following:

* createACECertSecrets.sh - creates the ACE Configuration Objects for TLS keystores and truststore which use secrets
* installPipeline.sh - installs the pipeline.yaml and custom tasks in the namepace for ACE
* deployACE.sh - runs the pipeline to deploy ACE toolkit flow for a given application (runs for each integration, three times in this example)
* putTestMessage.sh - Performs an end to end test of the ACE/MQ scenario:
    * Puts a test message into the MQ cluster (to cqm5) - to add a customer record into the MongoDB
    * Uses *curl* to retrieve the information of the customer from the MongoDB, via the readAllCustomers ACE service
    * Prints out the certificates needed to use RFHUtil and Postman

**Note** - when you run this for the first time on a given OCP cluster there will be a three minute sleep whilst the PVC for the ACE pipeline workspace is created.

## Cleaning up Tekton Task pods after the pipelines have run

Optionally you may want to remove the Task containers that have completed, this will give you a cleaner project/namespace for when you demonstrate to customers.

Adapt the following command with your namespace to remove the succeeded containers:

```
oc -n ace-tb1 delete pods --field-selector=status.phase=Succeeded
oc -n mq-tb1 delete pods --field-selector=status.phase=Succeeded
oc -n ace-tb1 delete pods --field-selector=status.phase=Succeeded
oc -n ldap delete pods --field-selector=status.phase=Succeeded
```

