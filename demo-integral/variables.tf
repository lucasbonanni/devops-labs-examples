variable "cluster_name" {
  default = "demo-eks-cluster"
}

variable "app_image_name" {
  default = "demo-app:local"
}

variable "enable_monitoring" {
  type    = bool
  default = false
}
