output "nsg_id" {
  description = "The OCID of the Network Security Group."
  value       = oci_core_network_security_group.this.id
} 

output "nsg_rules" {
  description = "Flattened NSG rule values for test validation"
  value = [
    for rule in oci_core_network_security_group_security_rule.rules :
    {
      description = rule.description
      protocol    = rule.protocol
      direction   = rule.direction
      source      = rule.source
      source_type = rule.source_type
      destination = rule.destination
      destination_type = rule.destination_type
      stateless   = rule.stateless
      tcp_options = rule.tcp_options
      udp_options = rule.udp_options
      icmp_options = rule.icmp_options
    }
  ]
}


# Test-friendly outputs for database port validation
output "tcp_ports" {
  description = "List of TCP ports configured in NSG rules for easy testing"
  value = flatten([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && rule.tcp_options != null ? [
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null ? [
        for port_range in tcp_opt.destination_port_range :
        {
          port = port_range.min
          protocol = rule.protocol
          direction = rule.direction
          description = rule.description
        }
      ] : []
    ] : []
  ])
}

output "has_rabbitmq_amqp" {
  description = "Whether NSG has RabbitMQ AMQP port (5672)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 5672 && port_range.max == 5672
      ])
    ])
  ])
}

output "has_rabbitmq_mgmt" {
  description = "Whether NSG has RabbitMQ Management port (15672)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 15672 && port_range.max == 15672
      ])
    ])
  ])
}

output "has_mongodb" {
  description = "Whether NSG has MongoDB port (27017)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 27017 && port_range.max == 27017
      ])
    ])
  ])
}

output "has_redis" {
  description = "Whether NSG has Redis port (6379)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 6379 && port_range.max == 6379
      ])
    ])
  ])
}

output "has_mysql" {
  description = "Whether NSG has MySQL port (3306)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 3306 && port_range.max == 3306
      ])
    ])
  ])
}

output "has_prometheus" {
  description = "Whether NSG has Prometheus port (9090)"
  value = anytrue([
    for rule in oci_core_network_security_group_security_rule.rules :
    rule.protocol == "6" && 
    rule.tcp_options != null &&
    anytrue([
      for tcp_opt in rule.tcp_options :
      tcp_opt.destination_port_range != null &&
      anytrue([
        for port_range in tcp_opt.destination_port_range :
        port_range.min == 9090 && port_range.max == 9090
      ])
    ])
  ])
}