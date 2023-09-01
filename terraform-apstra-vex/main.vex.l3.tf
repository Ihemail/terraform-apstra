terraform {
  required_providers {
    apstra = {
      #source = "registry.terraform.io/Juniper/apstra"
      source = "Juniper/apstra"
      version = "~> 0.20.1"
    }
  }
}

provider "apstra" {
  url = "https://10.220.29.233"              # required
  tls_validation_disabled = true             # optional
  blueprint_mutex_disabled = true            # Don't attempt worry about competing clients
  # export APSTRA_USER="admin" && export APSTRA_PASS="AOSserver@1024"
}

# ASN pools, IPv4 pools and switch devices will be allocated using looping
# resources. These three `local` maps are what we'll loop over.
locals {
  asn_pools = {
    spine_asns = ["Private-64512-65534"]
    leaf_asns  = ["Private-4200000000-4294967294"]
  }
  ipv4_pools = {
    spine_loopback_ips  = ["Private-10_0_0_0-8"]
    leaf_loopback_ips   = ["Private-10_0_0_0-8"]
    spine_leaf_link_ips = ["Private-10_0_0_0-8"]
  }
  switches = {
    spine1               = { management_ip = "10.206.197.61", device_key = "54040ACEC53D", initial_interface_map_id = "Juniper_vQFX__AOS-7x10-Spine", hostname = "spine1" }
    spine2               = { management_ip = "10.206.224.7", device_key = "54040ACEE007", initial_interface_map_id = "Juniper_vQFX__AOS-7x10-Spine", hostname = "spine2" }
    vex_esi_001_leaf1    = { management_ip = "10.206.224.21", device_key = "54040ACEE015", initial_interface_map_id = "Juniper_vQFX__AOS-7x10-Leaf", hostname = "vex-esi-001-leaf1-3" }
    vex_esi_001_leaf2    = { management_ip = "10.206.209.152", device_key = "54040ACED198", initial_interface_map_id = "Juniper_vQFX__AOS-7x10-Leaf", hostname = "vex-esi-001-leaf2-3" }
    vex_std_001_leaf1    = { management_ip = "10.206.206.179", device_key = "54040ACECEB3", initial_interface_map_id = "Juniper_vQFX__AOS-7x10-Leaf", hostname = "vex-std-001-leaf1-3" }
    ## device_key = mac-address of interface "em0"[vqfx-10k] or "fxp0"[vEX-9214]
  }
}

resource "null_resource" "hostname_change_with_options" {
  #name = "host-name-update-${each.value.hostname}"
  for_each         = local.switches  
  provisioner "local-exec" {
    command = <<-EOT
     echo '#!/usr/bin/expect --' >> ${each.value.hostname}.exp 
     echo 'spawn ssh root@${each.value.management_ip}' >> ${each.value.hostname}.exp 
     echo 'expect "Password:"' >> ${each.value.hostname}.exp  
     echo 'send "Embe1mpls\r"' >> ${each.value.hostname}.exp  
     echo 'expect "%"' >> ${each.value.hostname}.exp  
     echo 'send "cli\r"' >> ${each.value.hostname}.exp  
     echo 'expect ">"' >> ${each.value.hostname}.exp  
     echo 'send "configure\r"' >> ${each.value.hostname}.exp  
     echo 'expect "#"' >> ${each.value.hostname}.exp  
     echo 'send "set groups member0 system host-name ${each.value.hostname}\r"' >> ${each.value.hostname}.exp  
     echo 'send "set chassis evpn-vxlan-default-switch-support\r"' >> ${each.value.hostname}.exp  
     echo 'send "set system commit synchronize\r"' >> ${each.value.hostname}.exp  
     echo 'send "set system services netconf ssh\r"' >> ${each.value.hostname}.exp  
     echo 'send "delete groups global interfaces lo0\r"' >> ${each.value.hostname}.exp  
     echo 'send "delete groups global routing-options router-id\r"' >> ${each.value.hostname}.exp  
     echo 'expect "#"' >> ${each.value.hostname}.exp  
     echo 'send "commit and-quit\r"' >> ${each.value.hostname}.exp  
     echo 'expect "^commit complete$"' >> ${each.value.hostname}.exp  
     echo 'send "exit\r"' >> ${each.value.hostname}.exp  
     echo 'expect ":~ #"' >> ${each.value.hostname}.exp  
     echo 'send "exit\r"' >> ${each.value.hostname}.exp && echo "Hello World!!"
     EOT
     #command = "echo '#!/usr/bin/expect --' >> ${each.value.hostname}.exp && echo 'spawn ssh root@${each.value.management_ip}' >> ${each.value.hostname}.exp && echo 'expect \"Password:\"' >> ${each.value.hostname}.exp && echo 'send \"Embe1mpls\\r\"' >> ${each.value.hostname}.exp && echo 'expect \"%\"' >> ${each.value.hostname}.exp && echo 'send \"cli\\r\"' >> ${each.value.hostname}.exp && echo 'expect \">\"' >> ${each.value.hostname}.exp && echo 'send \"configure\\r\"' >> ${each.value.hostname}.exp && echo 'expect \"#\"' >> ${each.value.hostname}.exp && echo 'send \"set groups member0 system host-name ${each.value.hostname}\\r\"' >> ${each.value.hostname}.exp && echo 'send \"set chassis evpn-vxlan-default-switch-support\\r\"' >> ${each.value.hostname}.exp &&  echo 'send \"set system commit synchronize\\r\"' >> ${each.value.hostname}.exp && echo 'send \"set system services netconf ssh\\r\"' >> ${each.value.hostname}.exp && echo 'send \"delete groups global interfaces lo0\\r\"' >> ${each.value.hostname}.exp && echo 'send \"delete groups global routing-options router-id\\r\"' >> ${each.value.hostname}.exp && echo 'expect \"#\"' >> ${each.value.hostname}.exp && echo 'send \"commit and-quit\\r\"' >> ${each.value.hostname}.exp && echo 'expect \"^commit complete$\"' >> ${each.value.hostname}.exp && echo 'send \"exit\\r\"' >> ${each.value.hostname}.exp && echo 'expect \":~ #\"' >> ${each.value.hostname}.exp && echo 'send \"exit\\r\"' >> ${each.value.hostname}.exp "
  }
  provisioner "local-exec" {
    command = "chmod +x ${each.value.hostname}.exp && expect ${each.value.hostname}.exp &"
    #& ping 127.0.0.1 -i 1 -c 20 > nul"
  }
}

resource "null_resource" "delete_hostname_scripts" {
  depends_on = [null_resource.hostname_change_with_options]
  provisioner "local-exec" {
    command = " ping 127.0.0.1 -i 1 -c 20 && rm -rf spine*.exp && rm -rf vex*-00*.exp"
  }
}

resource "apstra_ipv4_pool" "lab1" {
  name = "lab_dc1_vex_ip_pool"
  subnets = [
    { network = "10.2.0.0/16" },
  ]
}
resource "apstra_asn_pool" "lab1" {
  name = "lab_dc1_vex_asn_pool"
  ranges = [
    {
      first = 64500
      last = 65500
    },
  ]
}

# Look up details of a preconfigured logical device using its name. We'll use
# data discovered in this lookup in the resource creation below.
resource "apstra_logical_device" "vex_switch" {
  name = "slicer-24x10-1"
  panels = [
    {
      rows = 1
      columns = 10
      port_groups = [
        {
          port_count = 10
          port_speed = "1G"
          port_roles = ["superspine", "spine", "leaf", "access", "peer", "generic"]
        },
        #{
        #  port_count = 10
        #  port_speed = "10G"
        #  port_roles = ["superspine", "spine", "leaf"]
        #},
      ]
    }
  ]
}
data "apstra_logical_device" "lab1_switch" {
  #name = "virtual-7x10-1"
  name = "AOS-7x10-Leaf"
}
data "apstra_logical_device" "lab1_spine_switch" {
  name = "AOS-10x10-Spine"
}

locals {
  servers = {
    #single_homed = "AOS-1x10-1"
    #dual_homed   = "AOS-2x10-1"
    single_homed = "AOS-1x1-1"
    dual_homed   = "AOS-2x1-1"
  }
}
data "apstra_logical_device" "lab1_servers" {
  for_each = local.servers
  name = each.value
}

resource "apstra_rack_type" "lab1_single" {
  name                       = "vex-std"
  fabric_connectivity_design = "l3clos"
  leaf_switches = {
    aos-vex-std = {
      #logical_device_id = data.apstra_logical_device.lab1_switch.id
      logical_device_id = apstra_logical_device.vex_switch.id
      spine_link_count  = 1
      spine_link_speed  = "1G"
    }
  }
  generic_systems = {
    single-server = {
      count             = 1
      logical_device_id = data.apstra_logical_device.lab1_servers["single_homed"].id
      links = {
        single-link = {
          target_switch_name = "aos-vex-std"
          links_per_switch   = 1
          speed              = "1G"
        }
      }
    }
  }
}

resource "apstra_rack_type" "lab1_esi" {
  name                       = "vex-esi"
  fabric_connectivity_design = "l3clos"
  leaf_switches = {
    aos-vex-esi = {
      logical_device_id   = apstra_logical_device.vex_switch.id
      spine_link_count    = 1
      spine_link_speed    = "1G"
      redundancy_protocol = "esi"
    }
  }
  generic_systems = {
    dual-server = {
      count             = 1
      logical_device_id = data.apstra_logical_device.lab1_servers["dual_homed"].id
      links = {
        single-link = {
          target_switch_name = "aos-vex-esi"
          links_per_switch   = 1
          speed              = "1G"
          lag_mode           = "lacp_active"
        }
      }
    }
    single-server-1 = {
      count             = 1
      logical_device_id = data.apstra_logical_device.lab1_servers["single_homed"].id
      links = {
        single-link = {
          target_switch_name = "aos-vex-esi"
          links_per_switch   = 1
          speed              = "1G"
          switch_peer        = "first"
        }
      }
    }
    single-server-2 = {
      count             = 1
      logical_device_id = data.apstra_logical_device.lab1_servers["single_homed"].id
      links = {
        single-link = {
          target_switch_name = "aos-vex-esi"
          links_per_switch   = 1
          speed              = "1G"
          switch_peer        = "second"
        }
      }
    }
  }
}

## Create a template using previously looked-up (data) spine info and previously
## created (resource) rack types.
resource "apstra_template_rack_based" "lab1" {
  name                     = "apstra_junos_vex"
  asn_allocation_scheme    = "unique"
  overlay_control_protocol = "evpn"
  spine = {
    count             = 2
    #logical_device_id = data.apstra_logical_device.lab1_spine_switch.id
    #logical_device_id = "AOS-7x10-Spine"
    logical_device_id = apstra_logical_device.vex_switch.id
  }
  rack_infos = {
    (apstra_rack_type.lab1_esi.id)    = { count = 1 }
    (apstra_rack_type.lab1_single.id) = { count = 1 }
  }
}

# Assign interface maps to fabric roles to eliminate build errors so we
# can deploy
resource "apstra_datacenter_device_allocation" "interface_map_assignment" {
  for_each         = local.switches
  blueprint_id     = apstra_datacenter_blueprint.instantiation.id
  node_name        = each.key
  #initial_interface_map_id = each.value["initial_interface_map_id"]
  initial_interface_map_id = apstra_interface_map.vex_int_map.id
}

# Assign ASN pools to fabric roles to eliminate build errors so we
# can deploy
resource "apstra_datacenter_resource_pool_allocation" "asn" {
  for_each     = local.asn_pools
  blueprint_id = apstra_datacenter_blueprint.instantiation.id
  role         = each.key
  pool_ids     = each.value
}

# Assign IPv4 pools to fabric roles to eliminate build errors so we
# can deploy
resource "apstra_datacenter_resource_pool_allocation" "ipv4" {
  for_each     = local.ipv4_pools
  blueprint_id = apstra_datacenter_blueprint.instantiation.id
  role         = each.key
  pool_ids     = each.value
}

## Look up the details of the Agent Profile to which we've added a username and password.
data "apstra_agent_profile" "instantiation" {
  name = "profile_juniper_vqfx"
}
## Onboard each switch. This will be a comparatively long "terraform apply".
resource "apstra_managed_device" "instantiation" {
  depends_on = [null_resource.delete_hostname_scripts]
  for_each         = local.switches
  agent_profile_id = data.apstra_agent_profile.instantiation.id
  management_ip    = each.value.management_ip
  device_key       = each.value.device_key
  off_box          = true
}

## Instantiate a blueprint from the previously-created template
resource "apstra_datacenter_blueprint" "instantiation" {
  name        = "apstra-vex-pod1"
  template_id = apstra_template_rack_based.lab1.id
}

# Discover details (we need the ID) of an interface map using the name supplied
# in the lab guide.
resource "apstra_interface_map" "vex_int_map" {
  name = "Juniper_vEX__slicer-24x10-1"
  #logical_device_id = data.apstra_logical_device.lab1_spine_switch.id
  logical_device_id = apstra_logical_device.vex_switch.id
  device_profile_id = "Juniper_vEX"
  #device_profile_id = "d620a8af-de0b-4863-bf50-dd4071b8827a"
  interfaces = [
    {  logical_device_port     = "1/1"
       physical_interface_name = "ge-0/0/0"    },
    {  logical_device_port     = "1/2"
       physical_interface_name = "ge-0/0/1"    },
    {  logical_device_port     = "1/3"
       physical_interface_name = "ge-0/0/2"    },
    {  logical_device_port     = "1/4"
       physical_interface_name = "ge-0/0/3"    },
    {  logical_device_port     = "1/5"
       physical_interface_name = "ge-0/0/4"    },
    {  logical_device_port     = "1/6"
       physical_interface_name = "ge-0/0/5"    },
    {  logical_device_port     = "1/7"
       physical_interface_name = "ge-0/0/6"    },
    {  logical_device_port     = "1/8"
       physical_interface_name = "ge-0/0/7"    },
    {  logical_device_port     = "1/9"
       physical_interface_name = "ge-0/0/8"    },
    {  logical_device_port     = "1/10"
       physical_interface_name = "ge-0/0/9"    },
    #{  logical_device_port     = "1/11"
    #   physical_interface_name = "ge-0/1/0"    },
    #{  logical_device_port     = "1/12"
    #   physical_interface_name = "ge-0/1/1"   },
    #{  logical_device_port     = "1/13"
    #   physical_interface_name = "ge-0/1/2"   },
    #{  logical_device_port     = "1/14"
    #   physical_interface_name = "ge-0/1/3"   },
    #{  logical_device_port     = "1/15"
    #   physical_interface_name = "ge-0/1/4"   },
    #{  logical_device_port     = "1/16"
    #   physical_interface_name = "ge-0/1/5"   },
    #{  logical_device_port     = "1/17"
    #   physical_interface_name = "ge-0/1/6"   },
    #{  logical_device_port     = "1/18"
    #   physical_interface_name = "ge-0/1/7"   },
    #{  logical_device_port     = "1/19"
    #   physical_interface_name = "ge-0/1/8"   },
    #{  logical_device_port     = "1/20"
    #   physical_interface_name = "ge-0/1/9"   },
    #{  logical_device_port     = "1/21"
    #   physical_interface_name = "xe-0/2/0"   },
    #{  logical_device_port     = "1/22"
    #   physical_interface_name = "xe-0/2/1"   },
    #{  logical_device_port     = "1/23"
    #   physical_interface_name = "xe-0/3/0"   },
    #{  logical_device_port     = "1/24"
    #   physical_interface_name = "xe-0/3/1"   },
  ]
}

## Assign interface map and system IDs using the map we created earlier
resource "apstra_datacenter_device_allocation" "lab1" {
  depends_on = [apstra_managed_device.instantiation]
  for_each         = local.switches
  blueprint_id     = apstra_datacenter_blueprint.instantiation.id
  #initial_interface_map_id = each.value.initial_interface_map_id
  initial_interface_map_id = apstra_interface_map.vex_int_map.id
  node_name        = each.key
  device_key       = each.value.device_key
  deploy_mode      = "deploy"
}

## Deploy the blueprint.
resource "apstra_blueprint_deployment" "deploy" {
  blueprint_id = apstra_datacenter_blueprint.instantiation.id
  depends_on = [
    apstra_datacenter_device_allocation.lab1,
    #apstra_datacenter_resource_pool_allocation.lab1_asn,
    #apstra_datacenter_resource_pool_allocation.lab1_ipv4,
    apstra_datacenter_resource_pool_allocation.asn,
    apstra_datacenter_resource_pool_allocation.ipv4,
  ]

  comment      = "Deployment by Terraform {{.TerraformVersion}}, Apstra provider {{.ProviderVersion}}, User $USER."
}


