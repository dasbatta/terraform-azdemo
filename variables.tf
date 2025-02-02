variable "prefix" {
  description = "A prefix for resource names"
  default     = "demo"
}

variable "location" {
  description = "Azure location for the resources"
  default     = "East US"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  default     = 2
}

variable "public_ip_address" {
  description = "Your public IP address for ssh access to the VM"
  type        = string
  default     = "71.238.40.155"
}