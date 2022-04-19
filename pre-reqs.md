# Pre-requisites

### OpenShift and CP4I

It is assumed in this example that you have an OpenShift cluster on 4.5 or above available, with Cloud Pak for Integration 2020.3.1 or higher installed.

This automation has most recently been tested on **OCP 4.6** with **CP4I 2020.4** using all long term support releases (eus).

### ROKS Cluster Sizing

A four worker node cluster on ROKS, with 16cpu/32GB memory is sufficient to run this sample and have head room for other demo deployments. A sample sizing can be found [here](https://ibm.box.com/s/cmaiffkjy7muf8nqueeiltztq7so7gr9).


### OCP Project / K8s Namespace creation

You can customise the scripting and various properties files to use OCP Projects of you choice, however, for simplicity, the following convention is suggested:

* mq-tb1
* ace-tb1
* tracing
* cp4i
* mongodb-tb1
* ldap

If you wish to choose alternative namespace names then these will need to be reflected in your local copy of **cp4i_props.sh** (you will edit this a bit later, learn more [here](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/local-setup.md#modify-your-cp4i_propssh-properties-file "update properties file" ).

You will also need to fork your own copies of the repositories below and edit the namespaces in the files specied:

* **read-all-customers-rest-v1 repository**
  * update *tracingNS* parameter in **pipeline_properties.yaml**
* **update-datastore-mq-mongo-v1 repository**
  * update *tracingNS* parameter in **pipeline_properties.yaml**
* **create-customer-mq-soap-to-mq-json-v1 repository**
  * update *tracingNS* parameter in **pipeline_properties.yaml**
* **ace-configurations repository**
  * update the namespace suffix of the *queueManagerHostname* parameters in **CQM3.policyxml** and **CQM4.policyxml** files under *DefaultPolicies* (\<queueManagerHostname>cqm3-ibm-mq.**mq-tb1**\</queueManagerHostname>)
  * update the namespace suffix in the *host* parameter of *datasources.json* ("host": "mongodb.**mongodb-tb1**")
* **pipeline-infra repository**
  * update the namespaces for ACE and MQ in the *mq-role.yaml* and *role-bindings.yaml* files 

If you fork the repositories you will have to update these in your local copies of **deployMQ.sh** and **DeployACE.sh**. Eventually these will be added as parameters in the properties file **cp4i_props.sh**. Additionally you will need to set up your own **Github Deploy Keys** using *ssh-keygen*, adding the public certificate to Github and the private key to a secret on the K8s namespace. See how to set this up here: https://www.openshift.com/blog/private-git-repositories-part-2a-repository-ssh-keys.

If you have not pulled down the other respositories in the *cpat-agile-integration-sample* org yet, fear not. This will be covered at a [later stage](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/blob/master/local-setup.md#pull-down-the-remaining-git-repos "pull down repos" ) of this documentation.


### Installation of Cloud Pak Capabilities

This scenario requires that you have already installed the following capability Operators:

* *CP4I Platform Navigator and Common Services* -> all namepaces
* *Operations Dashboard* -> installed cluster wide
* *IBM MQ* ->  in your *mq* namespace
* *IBM App Connect* ->  in your *ace* namespace
* *OpenShift Pipelines* -> Automatically installs in all namespaces


**Note** here that only the CP4I Platform Navigator and Common services are installed cluster wide, the remaining capabilities are installed on a per-namespace basis. This gives more control to have different versions of operators installed in different namespaces in future, if you want to test upgrades.

**Note** here that it is recommended to install your operators to have manual acceptance of updates. If you use automatic then the operators will update automatically when the labs release new versions, this can sometimes cause errors on a Friday!

**Note** Common Services operator will automatically be installed when you install the Platform Navigator operator. **Even if you select manual updates for the Platform Navigator operator, the Common Services operator will be set to automatic. You can navigate to the installed Common Services operator and change it to manual afterwards.**

### Installation of cluster logging

Since CP4I 2020.4, we have moved over to using the OpenShift Elastic Search and OpenShift Cluster Logging Operators. The instructions for this can be found here:

https://docs.openshift.com/container-platform/4.6/logging/cluster-logging-deploying.html

In my experiements with this install I installed the operator via the *"Installing cluster logging using the CLI"* (not via the gui) and edited the subscription objects to have 'manual' **installPlanApproval**.

In testing we have found that the custom resource for the ClusterServiceVersion instance needs to be further modified with the following annotation:

```
olm.skipRange: '>=4.4.0-0 <4.6.0-202103010126.p0'
```

The resulting CR should begin looking something like this:

```
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
    olm.skipRange: '>=4.4.0-0 <4.6.0-202103010126.p0'
```

This value should replace the current annotation of the same name and result in a back-level fix of the CR being applied. In our testing the latest version failed to parse when applied on the namespace.


### Dashboard creation

You will need to create instances on the following Dashboards, via the Platform Navigator:

* Operations Dashboard instance -> in the *tracing* namespace
* App Connect Dashboard -> in your deisgnation namespace for App Connect (*ace-tb1*)

### Expose the Docker registry as a route

Openshift does not normally expose the internal docker registry on a route by default. You will need to set this up before running the scripts

```
$ oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
```

Check it is exposed using this command:

```
$ oc get routes -n openshift-image-registry -o=jsonpath='{.items[0].spec.host}{"\n"}'
```

The expected output should look like this

```
default-route-openshift-image-registry.cp4i-intcp-43-3cd0ec11030dfa215f262137faf739f1-0000.eu-gb.containers.appdomain.cloud
```

### Entitlement Key

Make sure that the **ibm-entitlement-key** is applied in all the namespaces where you want to deploy.

You can use the following commmand to copy the entitlement key from one namespace to another (note that while --export is now deprecated, it avoids you having to have jq installed):

* ``oc get secret ibm-entitlement-key -n <first-namespace> --export -o yaml | oc apply -n <second-namespace> -f -``


### Create dummy instances of ACE and MQ to force tracing dashboard registration

When using the Operations Dashboard with ACE and MQ, we need to register the namespaces for ACE and MQ on the Operations Dashboard, and then apply a secret provided by the Operations Dashboard to each namespace.

**Note**: Operations Dashbord 2020.4 does have the ability to accept process registration requests programtically, via the use of an *Operations Dashboard Service Binding* object. However during testing with the **IBM MQ** eus operator, this was found not to work. Consequently this feature is currently ommited from this example.

We can force registration by deploying a dummy instance of ACE and MQ with tracing specified, and then navigating to the Operations Dashboard to accept the request.

Upon accepting the registration request on the Operations Dashboard, you will be given an ``oc`` command to copy and paste into you terminal. This will create the secret in the corresponding namepace.

**Note** this is a **one time** action per namespace. Once the secret is created in a given namespace you will not have to do this again.

**Bar file for dummy ACE deployment:**

A bar file called *serverPing* is availble for you to deploy a sample ACE Toolkit flow for this purpose. This can be found in the [**ace**](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace "server-ping bar") folder of this repo.

### Setup ssh key secrets

Each of the *source*, *infra* and *config* git repositories used in this sample are already configured with a **read only** deploy key. This avoids the requirement for IBMer's w3 credentials to be stored on OCP to allow the pipeline to authenticate with github.ibm.com

To avoid numerous people requiring admin access to these repositories, in order to add their own deploy keys to the git repo, the private keys are availble in a Box folder: https://ibm.ent.box.com/folder/131505816380

Navigate to this directory and download the secret definitions. 

Apply the secret definitions to the relevant namespace:

* mq-infra and mq-source to the namepace where you are deploying IBM MQ
* ldap-certgen-mongo-ssh to the 'ldap' namespace (this is hardcoded in the yaml file)
* all remaining files to the namepace in which you are deploying ACE

``oc apply -f <file-name> -n <namespace>``


### Configure the pipeline service account with the ssh key and entitlement key secrets

Openshift pipelines run using a 'Service Account' that needs to be given access to the various secrets we have configured above.

You can edit the service account on the OCP console by navigating as follows:

* *User Management* -> *Service Accounts* 
* Click on the **pipeline** service account and click **yaml**
* Under the *secrets* stanza in the yaml, add the secret names for the entitlement key, plus the ssh keys for the git repos and click **Save**

The stanza in the **pipeline** service account defintion on the **mq-tb1** namespace will look something like this:

```
secrets:
  - name: pipeline-token-fhq2t
  - name: pipeline-dockercfg-mhxqj
  - name: mq-infra
  - name: mq-source
  - name: ibm-entitlement-key
```

The stanza in the **pipeline** service account defintion on the **ace-tb1** namespace will look something like this:

```
secrets:
  - name: pipeline-token-5ffvt
  - name: pipeline-dockercfg-qg74f
  - name: create-customer-mq-soap-to-mq-json-v1
  - name: update-datastore-mq-mongo-v1
  - name: read-all-customers-rest-v1
  - name: ibm-entitlement-key
  - name: ace-infra
  - name: ace-config
```

The stanza in the **pipeline** service account defintion on the **ldap*** namespace will look something like this:

```
secrets:
  - name: pipeline-token-7hm5j
  - name: pipeline-dockercfg-hhggq
  - name: ldap-certgen-mongo
```

### Setup roles and role-bindings on the mq namespace, so that ace pipeline can access MQ pods

The ACE with MQ pipeline checks whether the queue used by the given ACE application exists prior to deploying the integration server.

To enable this the *pipeline* service account in your ACE namespace (by default *ace-tb1*) needs some permissions on the MQ namespace (by default *mq-tb1*) to list pods, exec into them (to check the queue) etc.

You must apply the role and role-binding files in [pipeline-infra/ace/roles](https://github.ibm.com/cpat-agile-integration-sample/pipeline-infra/tree/master/ace/roles "ace roles and role bindings on mq ns") to make sure this is available:

```
oc apply -f <path-to-directory>/pipeline-infra/ace/roles/mq-role.yaml
oc apply -f <path-to-directory>/pipeline-infra/ace/roles/role-binding.yaml
```

This role and the role bindings will be applied in the **mq-tb1** namespace.

# Next steps

Review the steps in [local-setup](local-setup.md) to set up the build environment on your workstation.