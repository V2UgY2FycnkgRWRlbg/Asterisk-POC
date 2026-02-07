# Asterisk POC Configuration
# Customize these values for your deployment

container_name    = "asterisk-server"
cpu_limit         = "4"
memory_limit      = "4GB"
network_subnet    = "10.100.100.1/24"
asterisk_ip       = "10.100.100.10"
provisioning_ip   = "10.100.100.11"
sip_port          = 5060
rtp_port_start    = 10000
rtp_port_end      = 20000
provisioning_port = 80
domain            = "asterisk.local"
admin_email       = "admin@company.local"

enable_test_vms = true
