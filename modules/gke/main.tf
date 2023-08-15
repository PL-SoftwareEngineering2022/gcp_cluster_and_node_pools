data "google_project" "project" {}

locals {
  workload_identity_nodepools_enabled_calculated = var.workload_identity_nodepools_enabled == "" ? var.workload_identity_enabled : var.workload_identity_nodepools_enabled
}

resource "google_container_cluster" "gke" {
  name    = var.gke_cluster_name
  project = var.gcp_project

  resource_labels = {
    billing-tag               = var.gke_cluster_name
    billing-container-cluster = var.gke_cluster_name
    gke-cluster               = var.gke_cluster_name
    team                      = var.team
  }

  location = var.gke_zone

  network = "projects/${var.gcp_project}/global/networks/${var.vpc_network}"

  dynamic "workload_identity_config" {
    for_each = var.workload_identity_enabled == true ? [1] : []
    content {
      workload_pool = "${var.gcp_project}.svc.id.goog"
    }
  }

  release_channel {
    channel = var.channel_type
  }

  logging_service = "logging.googleapis.com/kubernetes"

  monitoring_service = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "06:00"
    }
  }

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  timeouts {
    create = "64m"
    delete = "64m"
    update = "256m"
  }

  notification_config {
    pubsub {
      enabled = var.enable_pubsub_notify
      topic   = var.pubsub_topic_id
    }
  }

  dynamic "resource_usage_export_config" {
    for_each = var.resource_usage_export_enabled == true ? [1] : []
    content {
      enable_network_egress_metering       = false
      enable_resource_consumption_metering = true
      bigquery_destination {
        dataset_id = google_bigquery_dataset.gke_metering[0].dataset_id
      }
    }
  }

  initial_node_count = 1

  remove_default_node_pool = true

  enable_shielded_nodes = var.enable_shielded_nodes
}

resource "google_bigquery_dataset" "gke_metering" {
  count      = var.resource_usage_export_enabled == true ? 1 : 0
  dataset_id = "gke_metering"
  location   = "US"
}

resource "google_bigquery_dataset_iam_member" "gke_metering_reader" {
  count      = google_bigquery_dataset.gke_metering == 1 ? 1 : 0
  dataset_id = google_bigquery_dataset.gke_metering[0].dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_container_node_pool" "preemptible_nodes" {
  name     = var.preemptible_nodepool_name
  location = var.gke_zone
  cluster  = google_container_cluster.gke.name
  project  = var.gcp_project

  initial_node_count = var.preemptible_initial_node_count

  dynamic "autoscaling" {
    for_each = var.preemptible_autoscaling ? [1] : []
    content {
      min_node_count = var.preemptible_min_node_count
      max_node_count = var.preemptible_max_node_count
    }
  }

  node_config {
    preemptible  = true
    machine_type = var.preemptible_machine_type
    image_type   = var.image_type

    labels = {
      billing-tag               = var.gke_cluster_name
      billing-container-cluster = var.gke_cluster_name
      gke-cluster               = var.gke_cluster_name
      environment               = var.gcp_env
      team                      = var.gcp_team
      auth-scope                = "gke-preemptible"
    }

    oauth_scopes = var.oauth_scopes

    //In the future this might error out, if it does then we need to switch from node_metadata to mode or just add the mode config
    //Example:
    //    workload_metadata_config {
    //      mode          = "GKE_METADATA"
    //      node_metadata = "GKE_METADATA_SERVER"
    //    }

    dynamic "workload_metadata_config" {
      for_each = local.workload_identity_nodepools_enabled_calculated == true ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    dynamic "taint" {
      for_each = var.taints_added == true ? [1] : []
      content {
        effect = "NO_SCHEDULE"
        key    = "cloud.google.com/gke-preemptible"
        value  = "true"
      }
    }

    tags = [
      var.gke_cluster_name,
    ]

    service_account = var.gke_service_account
  }
}
resource "google_container_node_pool" "non_preemptible_nodes" {
  name     = var.non_preemptible_nodepool_name
  location = var.gke_zone
  cluster  = var.gke_cluster_name
  project  = var.gcp_project

  initial_node_count = var.non_preemptible_initial_node_count

  dynamic "autoscaling" {
    for_each = var.non_preemptible_autoscaling ? [1] : []
    content {
      min_node_count = var.non_preemptible_min_node_count
      max_node_count = var.non_preemptible_max_node_count
    }
  }

  depends_on = [
    google_container_cluster.gke,
  ]

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = var.non_preemptible_machine_type
    image_type   = var.image_type

    labels = {
      billing-tag               = var.gke_cluster_name
      billing-container-cluster = var.gke_cluster_name
      gke-cluster               = var.gke_cluster_name
      environment               = var.gcp_env
      team                      = var.gcp_team
      auth-scope                = "gke-non-preemptible"
    }

    oauth_scopes = var.oauth_scopes

    //In the future this might error out, if it does then we need to switch from node_metadata to mode or just add the mode config
    //Example:
    //    workload_metadata_config {
    //      mode          = "GKE_METADATA"
    //      node_metadata = "GKE_METADATA_SERVER"
    //    }
    dynamic "workload_metadata_config" {
      for_each = local.workload_identity_nodepools_enabled_calculated == true ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    tags = [
      var.gke_cluster_name,
    ]

    service_account = var.gke_service_account
  }


}
