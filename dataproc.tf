resource "google_dataproc_cluster" "dp_cluster" {
  name   = var.cluster_name
  provider = "google-beta"
  region = var.region

  labels = var.labels

  cluster_config {
    staging_bucket = var.staging_bucket
    software_config {
      image_version = var.cluster_version
    }

    dynamic "encryption_config" {
      for_each = list(var.kms_key_name)
      content {
        kms_key_name = encryption_config.value
      }
    }

    initialization_action {
      script = var.conda_initialization_script
      timeout_sec = var.initialization_timeout_sec
    }

    initialization_action {
      script = var.pip_initialization_script
      timeout_sec = var.initialization_timeout_sec
    }

    dynamic "initialization_action" {
      for_each = [for script in var.initialization_script: {
        script = script
      }]
      content {
        script = initialization_action.value.script
        timeout_sec = var.initialization_timeout_sec
      }
    }

    gce_cluster_config {
      network = var.network
      service_account = var.service_account
      tags = [var.cluster_name]
      zone = var.zone
      metadata = {
        CONDA_PACKAGES = var.conda_packages
        PIP_PACKAGES = var.pip_packages
      }
    }
    master_config {
      num_instances = var.master_ha ? 3 : 1
      machine_type = var.master_instance_type
      disk_config {
        boot_disk_type = var.master_disk_type
        boot_disk_size_gb = var.master_disk_size
        num_local_ssds = var.master_local_ssd
      }
    }

    worker_config {
      machine_type = var.worker_instance_type
      disk_config {
        boot_disk_type = var.worker_disk_type
        boot_disk_size_gb = var.worker_disk_size
        num_local_ssds = var.worker_local_ssd
      }
      dynamic "accelerators" {
        for_each = var.worker_accelerator
        content {
          accelerator_count = accelerators.value.worker_accelerator.count
          accelerator_type = accelerators.value.worker_accelerator.type
        }
      }
    }
    preemptible_worker_config {
      num_instances = var.preemptible_worker_min_instances
    }
    autoscaling_config {
      policy_uri = google_dataproc_autoscaling_policy.asp.name
    }
  }
}


resource "google_dataproc_autoscaling_policy" "asp" {
  provider = "google-beta"
  policy_id = "${var.cluster_name}-policy"
  location = var.region


  worker_config {
    min_instances = var.primary_worker_min_instances
    max_instances = var.primary_worker_max_instances
    weight = 1
  }

  secondary_worker_config {
    min_instances = var.preemptible_worker_min_instances
    max_instances = var.preemptible_worker_max_instances
    weight = 3
  }

  basic_algorithm {
    cooldown_period = var.cooldown_period
    yarn_config {
      graceful_decommission_timeout = var.graceful_decommission_timeout

      scale_up_factor   = var.scale_up_factor
      scale_up_min_worker_fraction = var.scale_up_min_worker_fraction
      scale_down_factor = var.scale_down_factor
      scale_down_min_worker_fraction = var.scale_down_min_worker_fraction
    }
  }
}