# pipeline-infra

This repository contains OpenShift pipeline artefacts for App Connect Enterprise (Toolkit) and IBM MQ. In future DataPower might also be added.

# What does this deploy?

Running this automation will deploy the following:

* **MongoDB** database
* **OpenLDAP** server
* Five **IBM MQ** Queue Managers in a traditional cluster
* Three **App Connect Enterprise Toolkit** servers

# There are lots of ACE and MQ deployment examples. Why should I care about this one?

The example in this repo and the associated Git org has been used as part of an ACE and MQ MVP for many customers in the UK and Sweden since November 2020. 

The sample is aimed to be more production like than most, as such it has been highly resonant with customers so far. It answers the questions of existing IIB and MQ users, as to "what has changed?" and "what starting points do we need to understand to start working with ACE and MQ on CP4I?". To that end the sample:

* Deploys an LDAP server to allow **CONNAUTH** on MQ
* MQ **Channel Authentication** configured
* **TLS MA** configured on MQ. Certificates and a demo CA are created for you.
* **AUTHRECs** set on Queue Manager and Application Queues

* TLS Configured for ACE/MQ Connectivity
* ACE Authenticates to MQ with username and password validated by ldap
* ACE connects to **MongoDB** using datasources.json file

* Multiple ACE services interact with MQ Cluster to create a more realistic end to end demonstration.
* **All the above deployed via the (semi) automation and the Tekton pipelines!**


# Associated playback resources

This sample is designed to accompany the standard ACE and MQ MVP developed by the former CPAT Team and the MVP Team. It is targetted at customers who are existing users of IIB and MQ on-prem, who want to learn about and see in action ACE and MQ on CP4I to understand how things have updated and changed.

## Typical MVP Structure

Pre-work - build this sample in a new IBM Cloud ROKS cluster. Practice the play back material.

* Playback 1 - Introduction to Containers, Kubernetes, OCP
* Playback 2 - MQ Deep Dive
* Playback 3 - ACE Deep Dive
* Playback 4 - Day 2 Operations (Tracing, Logging, Monitoring and CI/CD Pipelines)

The generic **presentation decks and some notes** can be found on Box [here](https://ibm.box.com/s/638hwheo4fjdh6wq13qaetvd44hlxa40 "linke to ace/mq ppts"). Each playback lasts between 1.5 - 2 hours depending on the number of questions the customer has. Typically two sessions per week, with at least a day between sessions is a good cadence.


## Example videos (not for share with customers)

You can view the videos [here](https://ibm.box.com/s/zebus2mytnatraqba5tqam7j2wj18xs6 "View link") to see what a playback is typically like.

Note: that these videos are provided here as guidance for what an MVP playback session is like, not for redistribution to other customers (as some customer references can been seen in the slides and examples). As such the permission on the shared link is to **view** only.

## ACE Pipeline Video

The ACE pipelines take some time to run through to completion, making them tricky to present in a short amount of time. We therefore have a video [here](https://ibm.box.com/s/w5qpfov0a38or1seypwkiqrucvpfi568 "ace cicd video") which you can use on your playback (you will need to talk over it), which has certain parts accelerated.


## Architecture Diagrams

### Full Topology

This is the full topology of the deployed architecture (LDAP server omitted). We can see that the left hand side of the architecture takes in a **customer details** SOAP message. This is transformed to JSON by the first flow, then written into the **MongoDB** database by the second flow. On the right hand side of the diagram we can see that an IBM ACE REST service retrieves the contents of **MongoDB** to the caller.

![Full Architecture](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/doc.images/01-Full-arch.png "Full Architecture")

### MQ Cluster Topology

The above diagram ommits three of the IBM MQ Queue Managers for the sake of clarity. In reality there are five Queue Managers Deployed in an MQ Cluster.

![MQ Cluster Topology](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/doc.images/02-MQ-Cluster-Topology.png "MQ Cluster Topology")

### Message flow through MQ Cluster

The below diagram shows the flow of a Customer Details request as it is processed by ACE and routed through the MQ Cluster.

![Message flow through MQ Cluster](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/doc.images/03-MQ-Message-Flow.png "Message flow through MQ Cluster")

# High Level - how does it get deployed?

The automation is ran from inside an *installer* **Docker** container on your workstation. This installer container has several components which help us to kick off the pipelines and perform some validation testing:

* It is built on top of the **IBM MQ for Developers** container, and, as such, it has a copy of the **IBM MQ** Client.
* It contains *yq*
* It containers *OpenSSL* which we use to generate certificates
* It has **Java** installed and this is used to put a test message into the architecture.

# Set of repositories in the cpat-agile-integration-sample org

The artefacts in this **pipeline-infra** repository work in conjunction with the other Git repositories in the [cpat-agile-integration-sample](https://github.ibm.com/cpat-agile-integration-sample) org.

## ace repositories:

* [ace-infra](https://github.ibm.com/cpat-agile-integration-sample/ace-infra)
  Contains infrastucture artefacts, such as Dockerfiles plus IntegrationServer.yaml, plus ACE configuration templates for ACE pipelines.
* [ace-configurations](https://github.ibm.com/cpat-agile-integration-sample/ace-configurations)
* [create-customer-mq-soap-to-mq-json-v1](https://github.ibm.com/cpat-agile-integration-sample/create-customer-mq-soap-to-mq-json-v1)
* [update-datastore-mq-mongo-v1](https://github.ibm.com/cpat-agile-integration-sample/update-datastore-mq-mongo-v1)
* [read-all-customers-rest-v1](https://github.ibm.com/cpat-agile-integration-sample/read-all-customers-rest-v1)


# Get local copies of the repos

## Create empty directory for repos <scenario-directory>

Create a new directory in your file system and clone this repository into it. Keeping this in a new directory, dedicated to running this scenario will make things easier and tidier.

Henceforth this directory shall be reffered to as ``<scenario-directory>``

## Pull down the git repos

Navigate to ``<scenario-directory>`` and issue the commands below to pull the repositories (includes this repository) required for the scenario.

```
git clone https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra.git
git clone https://github.ibm.com/cpat-agile-integration-sample/ldap-certgen-mongo.git
git clone https://github.ibm.com/cpat-agile-integration-sample/mq-source.git
git clone https://github.ibm.com/cpat-agile-integration-sample/mq-infra.git
git clone https://github.ibm.com/cpat-agile-integration-sample/ace-configurations.git
git clone https://github.ibm.com/cpat-agile-integration-sample/update-datastore-mq-mongo-v1.git
git clone https://github.ibm.com/cpat-agile-integration-sample/create-customer-mq-soap-to-mq-json-v1.git
git clone https://github.ibm.com/cpat-agile-integration-sample/ace-infra.git
git clone https://github.ibm.com/cpat-agile-integration-sample/read-all-customers-rest-v1.git
```


# Pre-requisites to run the automation

Before running the automation we need to understand:

* The directories and files inside this repository
* Pre-requisites for setting up the OCP Cluster and Installing Cloud Pak for Integration
* Setting up your workstation environment

Please see the links below to understand these.

## Directories

There are a number of directories within this repo, which contain Tekton pipeline definitions, pipelinerun templates, Tekton custom tasks and other artefacts used by the deployment. 

It is useful to (at least briefly) review the contents so that you understand what is being used and why. It is not necessary to comprehensively read this whole section before proceeding, but do understand it is there as a reference point:

Please review [directories](directories.md)


## Pre-requisites

Before using the automation you need to make sure that the OCP cluster and install of CP4I is setup correctly. Additionally you also need to perform a handful of other pre-reqs.

Please review [pre-reqs](pre-reqs.md) to understand these and setup your OCP cluster accordingly.

## Setting up your workstation environment

Once the OCP cluster is setup appropritely, you need to setup your workstation to run the automation. 

The pipelines and other automation are installed onto OCP from inside a *Docker* container which runs on your workstation.

Please follow the steps in [local-setup](local-setup.md) to set this up on your workstation.


# Running the the automation

## Deploy and run the pipelines onto OCP

There are three steps to deploying onto the OCP cluster:

* Install the ldap and mongodb, plus generate the certificates to be used for the architecture: **run-prereqs.sh**
* Install the MQ Queue Managers: **run-mq.sh**
* Install the ACE (toolkit) integration services: **run-ace.sh**

Please review and follow the steps in [deploy](deploy.md) to kick off the pipelines.
