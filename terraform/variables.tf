variable "container_name" {
  description = "Name of the Asterisk container"
  type        = string
  default     = "asterisk-server"
}

variable "docker_image" {
  description = "Docker image for Asterisk (use local cached image)"
  type        = string
  default     = "asterisk-latest"
}

variable "nginx_image" {
  description = "Docker image for Nginx provisioning server (use local cached image)"
  type        = string
  default     = "nginx-alpine"
}

variable "provisioning_ip" {
  description = "Static IP address for provisioning server"
  type        = string
  default     = "10.100.100.11"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "4"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "4GB"
}

variable "network_subnet" {
  description = "Network subnet for Asterisk network"
  type        = string
  default     = "10.100.100.1/24"
}

variable "asterisk_ip" {
  description = "Static IP address for Asterisk server"
  type        = string
  default     = "10.100.100.10"
}

variable "sip_port" {
  description = "SIP port for Asterisk"
  type        = number
  default     = 5060
}

variable "rtp_port_start" {
  description = "RTP port range start"
  type        = number
  default     = 10000
}

variable "rtp_port_end" {
  description = "RTP port range end"
  type        = number
  default     = 20000
}

variable "provisioning_port" {
  description = "HTTP port for phone provisioning (nginx container uses port 80 internally)"
  type        = number
  default     = 80
}

variable "domain" {
  description = "SIP domain for the Asterisk server"
  type        = string
  default     = "asterisk.local"
}

variable "admin_email" {
  description = "Administrator email for notifications"
  type        = string
  default     = "admin@company.local"
}

# Test client VMs configuration
variable "enable_test_vms" {
  description = "Enable test client VMs with desktop environment"
  type        = bool
  default     = true
}

variable "test_vm_image" {
  description = "Image for test client VMs"
  type        = string
  default     = "images:debian/12"
}

variable "test_vm1_ip" {
  description = "IP address for test VM 1"
  type        = string
  default     = "10.100.100.20"
}

variable "test_vm2_ip" {
  description = "IP address for test VM 2"
  type        = string
  default     = "10.100.100.21"
}

variable "test_vm_cpu" {
  description = "CPU limit for test VMs"
  type        = string
  default     = "2"
}

variable "test_vm_memory" {
  description = "Memory limit for test VMs"
  type        = string
  default     = "2GB"
}

