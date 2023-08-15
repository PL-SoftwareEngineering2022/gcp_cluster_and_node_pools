variable "preemptible_autoscaling" {
  type    = bool
  default = true
}

variable "taints_added" {
  default = true
}

variable "non_preemptible_autoscaling" {
  type    = bool
  default = true
}

variable "preemptible_nodepool_name" {
  default = "preemptible-nodepool"
}
variable "non_preemptible_nodepool_name" {
  default = "non-preemptible-nodepool"
}
variable "preemptible_min_node_count" {}
variable "preemptible_max_node_count" {}

variable "non_preemptible_min_node_count" {}
variable "non_preemptible_max_node_count" {}

variable "preemptible_machine_type" {
  default = "n1-standard-8"
}

variable "non_preemptible_machine_type" {
  default = "n1-highmem-2"
}

variable "channel_type" {
  default = "REGULAR"
}

variable "vpc_network" {
  default = "default"
}

variable "oauth_scopes" {
  type = list(string)
  default = [
  "https://www.googleapis.com/auth/cloud-platform", ]

}

variable "gke_service_account" {
  default = "default"
}

variable "workload_identity_enabled" {
  default = false
}

variable "workload_identity_nodepools_enabled" {
  default = ""
}

variable "preemptible_initial_node_count" {
  default = 1
}

variable "non_preemptible_initial_node_count" {
  default = 1
}

variable "gke_cluster_name" {}

variable "gke_zone" {}

variable "gcp_project" {}

variable "gcp_team" {}

variable "gcp_env" {}

variable "enable_shielded_nodes" {
  default = false
}

variable "enable_pubsub_notify" {
  default = false
}
variable "pubsub_topic_id" {
  default = null
}

variable "image_type" {}

variable "team" {
  default = ""
}

variable "resource_usage_export_enabled" {
  default = false
}
