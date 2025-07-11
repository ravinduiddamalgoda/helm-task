# Test file for database port configurations in NSG rules
# This file tests that the required database and messaging service ports are configured correctly

# terraform {
#   # Point to the network module that creates NSGs
#   source = "."
  
#   required_providers {
#     oci = {
#       source  = "oracle/oci"
#       version = "~> 5.0"
#     }
#   }
# }

# # Provider configuration for testing
# provider "oci" {
#   region = "us-ashburn-1"
#   # For testing, we don't need real credentials
# }

# # Test variables - these would be set by the test runner
# inputs = {
#   # Required variables for the network module
#   compartment_id = "ocid1.compartment.oc1..test"
#   tenancy_ocid = "ocid1.tenancy.oc1..test"
#   vcn_cidr = "10.0.0.0/16"
#   env_name = "test"
#   region = "us-ashburn-1"
  
#   # Minimal subnet configuration for testing
#   subnets = [
#     {
#       name = "cp"
#       newbits = 8
#       netnum = 0
#       gateway_type = "ngw"
#     },
#     {
#       name = "workers"
#       newbits = 8
#       netnum = 1
#       gateway_type = "ngw"
#     },
#     {
#       name = "data"
#       newbits = 8
#       netnum = 2
#       gateway_type = "ngw"
#     }
#   ]
  
#   # Common tags
#   common_tags = {
#     Environment = "test"
#     Project = "koci-test"
#   }
# }

# Test that Workers NSG exists
run "workers_nsg_exists" {
  command = plan

  assert {
    condition = module.nsg["workers"] != null
    error_message = "Workers NSG module does not exist"
  }
}

# Test that Data NSG exists
run "data_nsg_exists" {
  command = plan

  assert {
    condition = module.nsg["data"] != null
    error_message = "Data NSG module does not exist"
  }
}

# Test that Workers NSG has RabbitMQ AMQP port (5672)
run "workers_nsg_has_rabbitmq_amqp_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_rabbitmq_amqp == true
    error_message = "Workers NSG missing RabbitMQ AMQP port 5672"
  }
}

# Test that Workers NSG has RabbitMQ Management port (15672)
run "workers_nsg_has_rabbitmq_mgmt_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_rabbitmq_mgmt == true
    error_message = "Workers NSG missing RabbitMQ Management port 15672"
  }
}

# Test that Workers NSG has MongoDB port (27017)
run "workers_nsg_has_mongodb_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_mongodb == true
    error_message = "Workers NSG missing MongoDB port 27017"
  }
}

# Test that Workers NSG has Redis port (6379)
run "workers_nsg_has_redis_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_redis == true
    error_message = "Workers NSG missing Redis port 6379"
  }
}

# Test that Workers NSG has MySQL HeatWave port (3306)
run "workers_nsg_has_mysql_heatwave_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_mysql == true
    error_message = "Workers NSG missing MySQL HeatWave port 3306"
  }
}

# Test that Workers NSG has Prometheus port (9090)
run "workers_nsg_has_prometheus_port" {
  command = plan

  assert {
    condition = module.nsg["workers"].has_prometheus == true
    error_message = "Workers NSG missing Prometheus port 9090"
  }
}

# Test that Data NSG has RabbitMQ AMQP port (5672)
# run "data_nsg_has_rabbitmq_amqp_port" {
#   command = plan

#   assert {
#     condition = module.nsg["data"].has_rabbitmq_amqp == true
#     error_message = "Data NSG missing RabbitMQ AMQP port 5672"
#   }
# }

# Test that Data NSG has RabbitMQ Management port (15672)
# run "data_nsg_has_rabbitmq_mgmt_port" {
#   command = plan

#   assert {
#     condition = module.nsg["data"].has_rabbitmq_mgmt == true
#     error_message = "Data NSG missing RabbitMQ Management port 15672"
#   }
# }

# Test that Data NSG has MongoDB port (27017)
run "data_nsg_has_mongodb_port" {
  command = plan

  assert {
    condition = module.nsg["data"].has_mongodb == true
    error_message = "Data NSG missing MongoDB port 27017"
  }
}

# Test that Data NSG has Redis port (6379)
# run "data_nsg_has_redis_port" {
#   command = plan

#   assert {
#     condition = module.nsg["data"].has_redis == true
#     error_message = "Data NSG missing Redis port 6379"
#   }
# }

# Test that Data NSG has MySQL HeatWave port (3306)
run "data_nsg_has_mysql_heatwave_port" {
  command = plan

  assert {
    condition = module.nsg["data"].has_mysql == true
    error_message = "Data NSG missing MySQL HeatWave port 3306"
  }
}

# Test that Data NSG has Prometheus port (9090)
# run "data_nsg_has_prometheus_port" {
#   command = plan

#   assert {
#     condition = module.nsg["data"].has_prometheus == true
#     error_message = "Data NSG missing Prometheus port 9090"
#   }
# } 