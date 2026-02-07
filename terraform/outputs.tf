output "asterisk_container_name" {
  description = "Name of the Asterisk container"
  value       = incus_instance.asterisk_server.name
}

output "asterisk_ip_address" {
  description = "IP address of the Asterisk server"
  value       = var.asterisk_ip
}

output "provisioning_server_name" {
  description = "Name of the provisioning server container"
  value       = incus_instance.provisioning_server.name
}

output "provisioning_ip_address" {
  description = "IP address of the provisioning server"
  value       = var.provisioning_ip
}

output "asterisk_network" {
  description = "Network name for Asterisk"
  value       = incus_network.asterisk_network.name
}

output "sip_uri" {
  description = "SIP URI for the server"
  value       = "sip:${var.asterisk_ip}:${var.sip_port}"
}

output "provisioning_url" {
  description = "URL for phone provisioning"
  value       = "http://${var.provisioning_ip}"
}

output "connection_info" {
  description = "Connection information for the Asterisk server"
  value = {
    asterisk_container     = incus_instance.asterisk_server.name
    asterisk_ip           = var.asterisk_ip
    provisioning_container = incus_instance.provisioning_server.name
    provisioning_ip       = var.provisioning_ip
    sip_port              = var.sip_port
    rtp_port_range        = "${var.rtp_port_start}-${var.rtp_port_end}"
    provisioning_url      = "http://${var.provisioning_ip}"
    asterisk_console      = "incus exec ${incus_instance.asterisk_server.name} -- asterisk -rvvv"
    asterisk_logs         = "incus exec ${incus_instance.asterisk_server.name} -- tail -f /var/log/asterisk/messages"
  }
}

output "quick_start_commands" {
  description = "Quick start commands"
  value = <<-EOT
    # Connect to Asterisk console
    incus exec ${incus_instance.asterisk_server.name} -- asterisk -rvvv
    
    # View Asterisk logs
    incus exec ${incus_instance.asterisk_server.name} -- tail -f /var/log/asterisk/messages
    
    # Check endpoints
    incus exec ${incus_instance.asterisk_server.name} -- asterisk -rx "pjsip show endpoints"
    
    # Access provisioning server
    curl http://${var.provisioning_ip}
    
    # Restart Asterisk
    incus restart ${incus_instance.asterisk_server.name}
    
    # Restart provisioning server
    incus restart ${incus_instance.provisioning_server.name}
  EOT
}

