# Terraform  - Deploy a DataProc cluster
This project is an implementation of [Terraform Dataproc](https://www.terraform.io/docs/providers/google/r/dataproc_cluster.html)
Layout. Deploys a dataproc cluster and supports installation of additional `Conda` and `Pip` packages.

## How-to
Pre-requisites:
1. Create a Network with firewall rule that allows communication between the cluster nodes on all ports. You can use `terraform-google-network` module.
2. Create a service account with roles `roles/storage.objectViewer`, `roles/dataproc.worker` and `roles/cloudkms.cryptoKeyEncrypterDecrypter` (the latter only if encryption on disk is enabled). Use `terraform-google-service-account` module.

It is also suggested to create a bucket and set it as the staging bucket of the cluster.
### Example
```yaml
terraform {
  backend "gcs" {
    bucket  = "my-foo-bucket-tfstate"
    prefix  = "dataproc"
  }

  required_version = ">= 0.12"
}
provider "google-beta" {
  project = "my-foo-project"
  region  = "europe-west3"
  zone = "europe-west3-c"
}

module "my_foo_cluster" {
  source = "./modules/terraform-google-dataproc"
  cluster_name = "my-cool-cluster"
  cluster_version = "1.4"
  region = "europe-west3"
  master_ha = false
  zone = "europe-west3-c"
  master_instance_type = "n1-standard-4"
  service_account = "my-cool-account@my-cool-project.iam.gserviceaccount.com"
  network = "my-cool-network"
  worker_instance_type = "n1-standard-4"
  conda_packages = "pandas=0.23.4 scikit-learn=0.20.0 pytest=3.8.0 pyyaml=3.13"
  pip_packages = "gensim==3.7.1 logdecorator==2.1"
  staging_bucket = "my-cool-bucket"
}

```

## Initialization scripts
The contents of the `Initialization scripts` has been copied from `GoogleCloudPlatform`. For more information check [dataproc-initialization-actions](https://github.com/GoogleCloudPlatform/dataproc-initialization-actions)

How initialization actions are used

Initialization actions are stored in a [Google Cloud Storage](https://cloud.google.com/storage/) bucket and can be passed as a parameter to the gcloud command or the clusters.create API when creating a Cloud Dataproc cluster. For example, to specify an initialization action when creating a cluster with the gcloud command, you can run:
```
gcloud dataproc clusters create <CLUSTER_NAME> \
  [--initialization-actions [GCS_URI,...]] \
  [--initialization-action-timeout TIMEOUT]
```
Before creating clusters, you need to copy initialization actions to your own GCS bucket. For example:
```
MY_BUCKET=<gcs-bucket>
gsutil cp presto/presto.sh gs://$MY_BUCKET/
gcloud dataproc clusters create my-presto-cluster \
  --initialization-actions gs://$MY_BUCKET/presto.sh
```
You can decide when to sync your copy of the initialization action with any changes to the initialization action that occur in the GitHub repository. This is also useful if you want to modify initialization actions to fit your needs.

## Variables
<table>
<tr>
<td> Variable name </td><td> Type </td><td> Description </td><td> Default value </td></tr>
<tr> <td> project </td><td> string </td><td> The ID of the project the resource belongs </td><td> </td></tr>
<tr> <td> region </td><td> string </td><td> Region </td><td> </td></tr>
<tr> <td> location </td><td> string </td><td> Location of the cluster </td><td> </td></tr>
<tr> <td> labels </td><td> map(string)   </td><td> A set of labels to identify the cluster </td><td> </td></tr>
<tr> <td> cluster_name </td><td> string </td><td> The name of the DataProc cluster to be created </td> <td></td> </tr>
<tr> <td> staging_bucket </td><td> string </td><td> The bucket to be used for staging </td> <td></td> </tr>
<tr> <td> cluster_version </td><td> string </td><td> The image version of DataProc to be used </td> <td> 1.4 </td> </tr>
<tr> <td> kms_key_name </td><td> string </td><td> The Cloud KMS key name to use for PD disk encryption for all instances in the cluster. </td><td>  </td></tr>
<tr> <td> master_instance_type </td><td> string </td><td> The instance type of the master node </td><td> "n1-standard-4 </td></tr>
<tr> <td> master_disk_type </td><td> string </td><td> The disk type of the primary disk attached to each master node. One of 'pd-ssd' or 'pd-standard'. </td><td> "pd-standard </td></tr>
<tr> <td> master_disk_size </td><td> number </td><td> Size of the primary disk attached to each master node, specified in GB. The primary disk contains the boot volume and system libraries, and the smallest allowed disk size is 10GB. GCP will default to a predetermined computed value if not set (currently 500GB). Note: If SSDs are not attached, it also contains the HDFS data blocks and Hadoop working directories. </td><td> 100 </td></tr>
<tr> <td> master_local_ssd </td><td> number </td><td> The amount of local SSD disks that will be attached to each master cluster node. </td><td> 0 </td></tr>
<tr> <td> master_ha </td><td> bool </td><td> Set to 'true' to enable 3 master nodes (HA) or 'false' for only 1 master node </td><td> false </td></tr>
<tr> <td> worker_instance_type </td><td> string </td><td> The instance type of the worker nodes </td><td> "n1-standard-4 </td></tr>
<tr> <td> primary_worker_min_instances </td><td> number </td><td> The minimum number of primary worker instances </td><td> 2 </td></tr>
<tr> <td> primary_worker_max_instances </td><td> number </td><td> The maximum number of primary worker instances </td><td> 10 </td></tr>
<tr> <td> preemptible_worker_instance_type </td><td> string </td><td> The instance type of the secondary worker nodes </td><td> "n1-standard-4 </td></tr>
<tr> <td> preemptible_worker_min_instances </td><td> number </td><td> The minimum number of secondary worker instances </td><td> 2 </td></tr>
<tr> <td> preemptible_worker_max_instances </td><td> number </td><td> The maximum number of secondary worker instances </td><td> 10 </td></tr>
<tr> <td> worker_disk_type </td><td> string </td><td> The disk type of the primary disk attached to each worker node. One of 'pd-ssd' or 'pd-standard'. </td><td> "pd-standard </td></tr>
<tr> <td> worker_disk_size </td><td> number </td><td> Size of the primary disk attached to each worker node, specified in GB. The primary disk contains the boot volume and system libraries, and the smallest allowed disk size is 10GB. GCP will default to a predetermined computed value if not set (currently 500GB). Note: If SSDs are not attached, it also contains the HDFS data blocks and Hadoop working directories. </td><td> 100 </td></tr>
<tr> <td> worker_accelerator </td><td> list(object({ <br> count = number <br> string <br> })) </td><td> The number and type of the accelerator cards exposed to this instance.  </td><td> [] </td></tr>
<tr> <td> worker_local_ssd </td><td> number </td><td> The amount of local SSD disks that will be attached to each worker cluster node. </td><td> 0 </td></tr>
<tr> <td> network </td><td> string </td><td> The name or self_link of the Google Compute Engine network to the cluster will be part of. Conflicts with subnetwork. If neither is specified, this defaults to the 'default' network. </td></tr> 
<tr> <td> service_account </td><td> string </td><td> The service account for the cluster </td><td> </td></tr> 
<tr> <td> zone </td><td> string </td><td> The GCP zone where your data is stored and used </td><td> "europe-west1-b </td></tr> 
<tr> <td> scale_up_factor </td><td> number </td><td> Fraction of average pending memory in the last cooldown period for which to add workers. A scale-up factor of 1.0 will result in scaling up so that there is no pending memory remaining after the update (more aggressive scaling). A scale-up factor closer to 0 will result in a smaller magnitude of scaling up (less aggressive scaling). Bounds: [0.0, 1.0]. </td><td> 0.5 </td></tr> 
<tr> <td> scale_up_min_worker_fraction </td><td> number </td><td>  Minimum scale-up threshold as a fraction of total cluster size before scaling occurs. For example, in a 20-worker cluster, a threshold of 0.1 means the autoscaler must recommend at least a 2-worker scale-up for the cluster to scale. A threshold of 0 means the autoscaler will scale up on any recommended change. Bounds: [0.0, 1.0] </td><td> 0.0 </td></tr> 
<tr> <td> scale_down_factor </td><td> number </td><td> Fraction of average pending memory in the last cooldown period for which to remove workers. A scale-down factor of 1 will result in scaling down so that there is no available memory remaining after the update (more aggressive scaling). A scale-down factor of 0 disables removing workers, which can be beneficial for autoscaling a single job. Bounds: [0.0, 1.0]. </td><td> 1.0 </td></tr> 
<tr> <td> scale_down_min_worker_fraction </td><td> number </td><td> Minimum scale-down threshold as a fraction of total cluster size before scaling occurs. For example, in a 20-worker cluster, a threshold of 0.1 means the autoscaler must recommend at least a 2 worker scale-down for the cluster to scale. A threshold of 0 means the autoscaler will scale down on any recommended change. Bounds: [0.0, 1.0]. </td><td> 0.0 </td></tr> 
<tr> <td> cooldown_period </td><td> string </td><td> Duration between scaling events. A scaling period starts after the update operation from the previous event has completed. Bounds: [2m, 1d]. </td><td> "120s </td></tr> 
<tr> <td> graceful_decommission_timeout </td><td> string </td><td> Timeout for YARN graceful decommissioning of Node Managers. Specifies the duration to wait for jobs to complete before forcefully removing workers (and potentially interrupting jobs). Only applicable to downscaling operations. Bounds: [0s, 1d]. </td><td> "300s </td></tr> 
<tr> <td> conda_packages </td><td> string </td><td> A space separated list of conda packages to be installed </td><td> </td></tr> 
<tr> <td> pip_packages </td><td> string </td><td> A space separated list of pip packages to be installed </td><td> </td></tr> 
<tr> <td> conda_initialization_script </td><td> string </td><td> Location of script in GS used to install conda packages </td><td> "gs://dataproc-initialization-actions/python/conda-install.sh </td></tr> 
<tr> <td> pip_initialization_script </td><td> string </td><td> Location of script in GS used to install pip packages </td><td> "gs://dataproc-initialization-actions/python/pip-install.sh </td></tr> 
<tr> <td> initialization_script </td><td> list(string) </td><td> List of additional initialization scripts </td><td> [] </td></tr> 
<tr> <td> initialization_timeout_sec </td><td> number </td><td> The maximum duration (in seconds) which script is allowed to take to execute its action. </td><td> 300 </td></tr> 
</table>


## Building
### Initialization

```
$ terraform init
```

### Planning

Terraform allows you to "Plan", which allows you to see what it would change
without actually making any changes.

```
$ terraform plan 
```

### Applying

```
$ terraform apply
```

### Modifying

If you want to update the cluster, then edit the `terraform.tfvars` file and run again `terraform apply`
```
$ terraform apply
```

### Destroying
```
$ terraform destroy
```

# Author

Georgios Kasapoglou

https://github.com/GeKasap

# License

Copyright 2019 Georgios Kasapoglou

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
