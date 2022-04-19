# Local Setup

# If not done already: Create empty directory for repos <scenario-directory>

Create a new directory in your file system and clone this repository into it. Keeping this in a new directory, dedicated to running this scenario will make things easier and tidier.

Henceforth this directory shall be reffered to as ``<scenario-directory>``

# Unix and mac, Windows Gitbash: setup.sh

This [script](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/setup.sh "setup.sh") is located in the [admin](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/admin "admin dir") directory of this repo and it will do the following:

* Ask you to input a name for a new working directory. Input something like ``test1`` (ie: not a fully qualified path, just a name)
* It will create this new directory at ``<scenario-directory>/test1``
* Copies the contents of the ``run`` directory into this new directory - this means that you don't run the build from inside your git repo!
* Provides some (arguably) helpful advice on what steps to do next

Run the setup.sh script:

1. Navigate to the ``<scenario-directory>/pipeline-infra/admin``: ``cd <scenario-directory>/pipeline-infra/admin``
2. Execute the script from within that directory: ``./setup.sh``
3. Provide the folder name for it to create: for example ``test1``


# If not done already: Pull down the remaining git repos

Navigate to ``<scenario-directory>`` and issue the commands below to pull the repositories required for the scenario.

```
git clone https://github.ibm.com/cpat-agile-integration-sample/ldap-certgen-mongo.git
git clone https://github.ibm.com/cpat-agile-integration-sample/mq-source.git
git clone https://github.ibm.com/cpat-agile-integration-sample/mq-infra.git
git clone https://github.ibm.com/cpat-agile-integration-sample/ace-configurations.git
git clone https://github.ibm.com/cpat-agile-integration-sample/update-datastore-mq-mongo-v1.git
git clone https://github.ibm.com/cpat-agile-integration-sample/create-customer-mq-soap-to-mq-json-v1.git
git clone https://github.ibm.com/cpat-agile-integration-sample/ace-infra.git
git clone https://github.ibm.com/cpat-agile-integration-sample/read-all-customers-rest-v1.git
```

**Note** - obviously some of these repos will be different if you have forked any of the repos so that you could change namespace names. Change these as appropriate for you!

### Modify your cp4i_props.sh properties file

In your ``<scenario-directory>/test1`` directory you will now have copies of all the scripts required to run the pipeline deploys.

The **[cp4i_props.sh](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/admin/run/cp4i_props.sh "cp4i props files")** contains the various properties that can be configured for the run. The key properties to pay attention to are:

You need to definitely make sure these are correct:

* **COMMON_NAME** - the hostname of your cluster provide. We have set to the eu IBM cloud value **.eu-gb.containers.appdomain.cloud*
* **SAN_DNS** - this is the full hostname of your cluster load balancer and can be found in your OCP browser session. This is required for TLS mutual authentication between ACE and Postman. On an IBM Cloud ROKS cluster the **SAN_DNS** value should look something like this:

```
*.<your-cluster-name>-<random-alpha-numeric-string>.eu-gb.containers.appdomain.cloud
```

Don't change these unless you have decided to use your own namespace names and have setup the various other properties files correctly in your forked repos:

* **NAMESPACE_MQ** - the namespace where IBM MQ will deployed
* **NAMESPACE_ACE** - the namespace where App Connect Enterprise will deployed
* **NAMESPACE_LDAP** - the namespace where OpenLDAP will deployed
* **NAMESPACE_MONGO** - the namespace where MongoDB will deployed
* **TRACING_NS** - the namespace where the Operations Dashboard instance is deployed

Certificate values properties:

You will notice that the scenario use the name of a fictional company called **Tiger Bank**. It is recommended to keep this as it is, unless you have forked the ACE application repositories and can change the properies files and the [server.conf.yaml](https://github.ibm.com/cpat-agile-integration-sample/ace-configurations/blob/master/serverconf.yaml "svrconf") in the [ace-configurations](https://github.ibm.com/cpat-agile-integration-sample/ace-configurations "ace configs") repo.

* **ORG** set to *tiger bank*
* **ORGANISTAION** set to *TIGER_BANK*

These two properties are used in the setup of the certificates and the in the creation of the jks and kdb keystores / truststores for the deployment.


### ACE: Build and push the custom images used for the ACE pipeline

The ACE pipeline requires three container images to be built and pushed to your cluster's internal registry:

* **yq-zip** - allows the pipeline to use yq and zip, this is needed for creating certain types of ACE configurations
* **newman** - this is used to run unit tests against ACE REST or SOAP web services flows
* **mqsicreatebar** - this is used to build bar files using the *mqsicreatebar* command. The image includes a headless installation of the eclipse Toolkit, which the regular ACE container does not have. The *mqsicreatebar* command allows the pipeline to build bars where the compilation of Java and/or message sets is required and it is therefore perferable to using the standard ACE container and the *mqsipackagebar* command


**IMPORTANT!** 

Before you run this script you must download the ACE for Developers binary and put it in your filesystem at:

``pipeline-infra/ace/custom-images/mqsicreatebar``

Download the ACE for Developer binaries from [here](https://www.ibm.com/marketing/iwm/iwm/web/pick.do?source=swg-wmbfd "ACE 4 Devs") and place in the above folder.

Once you have completed this step you can proceed to build and push these images by runing the script from inside your ``cd <scenario-directory>/test1`` directory, providing the tar.gz name:

* ``./installACEPipelineImages.sh 11.0.0.11-ACE-LINUX64-DEVELOPER.tar.gz``



This might take a few minutes to complete. Go get a cup of tea.


## Build and run the docker container

### Make sure you are in the correct directory

``cd <scenario-directory>/test1``

**Why do I need to be in the correct directory?**

The scripts are ran using a local docker container ran on your workstation. The conatiner is a modified MQ container, which has been augmented with some extra packages to allow it to run the scripts. The scriping uses some MQ facilities, such as the **runmqakm** program, as part of setup.

The container is invoked using a *docker-compose.yaml* file, which mounts in the directory ``<scenario-directory>/test1`` as a volume. This means that, from inside of the container, it has access to all the local git repos required to run the configuration on OCP.

### Build and run the Docker Installer Container

To build and run the container, run the following command:

* ``docker-compose build cp4i-builder ; docker-compose run cp4i-builder bash``

This might take some minutes to pull the various packages down. The result will be that your terminal will be exec'd into the running container at the location ``/run``.

# Next steps

Please review and follow the steps in [deploy](deploy.md) to kick off the pipelines.