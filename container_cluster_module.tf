module "vpc_backend_dev_cluster" {
  source                              = "./terraform/modules/gke"
  gke_cluster_name                    = var.GKE_CLUSTER
  gke_zone                            = var.GKE_ZONE
  gcp_project                         = var.GCP_PROJECT
  gcp_env                             = var.GCP_ENV
  gcp_team                            = var.GCP_TEAM
  image_type                          = "COS_CONTAINERD"
  preemptible_initial_node_count      = 0
  preemptible_min_node_count          = 1
  preemptible_max_node_count          = 6
  preemptible_machine_type            = "e2-highmem-8"
  non_preemptible_initial_node_count  = 5
  non_preemptible_min_node_count      = 1
  non_preemptible_max_node_count      = 15
  non_preemptible_machine_type        = "e2-standard-8"
  taints_added                        = true
  workload_identity_enabled           = true
  workload_identity_nodepools_enabled = true
  enable_shielded_nodes               = true
  oauth_scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
  resource_usage_export_enabled = true
}
