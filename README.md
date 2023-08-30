# terraform-apstra
Juniper Astra deployment along with DC fabric Infra via terraform

# terraform-provider-apstra

This is a [Terraform](https://www.terraform.io)
[provider](https://developer.hashicorp.com/terraform/language/providers?page=providers)
for Juniper Apstra. It relies on a Go client library at https://github.com/Juniper/apstra-go-sdk

## Getting Started

### Install Terraform

Instructions for popular operating systems can be found [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

### Create a Terraform configuration

The terraform configuration must:
- be named with a `.tf` file extension.
- reference this provider by its global address.
  *registry.terraform.io/Juniper/apstra* or just: *Juniper/apstra*.
- include a provider configuration block which tells the provider where to
find the Apstra service.

```hcl
terraform {
  required_providers {
    apstra = {
      source = "Juniper/apstra"
    }
  }
}

provider "apstra" {
  url = "<apstra-server-url>"
}
```

### Terraform Init

Run the following at a command prompt while in the same directory as the
configuration file to fetch the Apstra provider plugin.
```shell
terraform init
```

### Supply Apstra credentials
Apstra credentials can be supplied through environment variables:
```shell
export APSTRA_USER=<username>
export APSTRA_PASS=<password>
```

Alternatively, credentials can be embedded in the URL using HTTP basic
authentication format (we don't actually *do* basic authentication, but the
format is: `https://user:password@host`). Any special characters in the username
and password must be URL-encoded when using this approach.

### Start configuring resources

Full documentation for provider, resources and data sources can be found
[here](https://registry.terraform.io/providers/Juniper/apstra/latest/docs).

# Apstra VMM Lab Guide Demo
This directory contains an example project which follows the [Apstra Lab Guide](https://cloudlabs.apstra.com/labguide/Cloudlabs/4.1.2/lab1-junos/lab1-junos-0_intro.html)
currently published with the v4.1.2. Apstra CloudLabs "Juniper Customer Lab".

### Launch a VMM Lab Instance
This demo is tested against Apstra 4.1.2. 
The VMM Lab config/template is attched in the project folder. The Terraform plugin works with Apstra 4.1.2, but some of the baked-in object names (logical devices, interface maps) changed between
revisions of, so it's smoother sailing with the 4.1.2 revision of the lab topology. Lab Node used:

vEX(EX9214) version: 22.2R2.10 / 22.3R2-S2.6

AOS version: 4.1.2

vQFX(QFX10K) version: 20.2R2-S3.5  pfe:20.2R1.10

### VMM Lab Topology L2 Virtual (vEX-9214/vQFX10k)
```
--------------------mgmt. Network(switch:em0/fxp0)-------------------[AOS Server]

              spine1                            spine2             
             [Spine1]                          [Spine2]
              / \   \                           /   / \
             /   \   \-----------------------------\   \
            /     \                           /   / \   \
           /   /-----------------------------/   /   \   \
          /   /     \                           /     \   \
         /   /       \-------\         /-------/       \   \
        /   /                 \       /                 \   \
       /   /                   \     /                   \   \
     [Leaf1]                   [leaf2]                   [Leaf3]
  std-001-leaf1             std-002-leaf1             std-003-leaf1
        |                         |                         | 
        |                         |                         |
 Single-Server-1           Single-Server-2           Single-Server-3
 (std-001-sys001)          (std-002-sys001)          (std-003-sys001)
```

### VMM Lab Topology L3 ESI (vEX-9214/vQFX10k)
```
--------------------mgmt. Network(switch:em0/fxp0)-------------------[AOS Server]

              spine1                            spine2             
             [Spine1]                          [Spine2]
              / \   \                           /   / \
             /   \   \                         /   /   \			  
            /     \   \-----------------------------\   \
           /       \                         /   /   \   \
          /   /-----------------------------/   /     \   \
         /   /       \                         /       \   \
        /   /         \------\         /------/         \   \
       /   /                  \       /                  \   \
      /   /                    \     /                    \   \
    [Leaf1]                    [leaf2]                    [Leaf3]
 esi-001-leaf1              esi-001-leaf2              std-001-leaf1
   |      \                     /     |                       | 
   |       \-----\ (LACP) /----/      |                       | 
   |              \      /            |                       | 
   |               \    /             |                       |
Single-Server-1   Dual-Server-1     Single-Server-2    Single-Server-3
(esi-001-sys001)  (esi-001-sys002)  (esi-001-sys003)   (std-001-sys001)
```

### Install the Provider
Refer to the project's [main README](../README.md) to get the provider installed
on your system or to the centos_1 server as below.
Update the main.tf with the Switch details(mgmt. IP & Device_Key).

### Copy the main.tf file from local system to centos_1 server in the ~/terraform directory
This might be the easiest way:
```shell
laptop:github\terraform\terraform-apstra> scp main.tf root@centos1:terraform/

Centos1:> yum install -y yum-utils
Centos1:> yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
Centos1:> yum -y install terraform expect
Centos1:> yum update
Centos1:> mkdir terraform
Centos1:> cd terraform
Centos1:> terraform init
Centos1:> terraform validate
Centos1:> terraform plan
Centos1:> terraform apply -auto-approve
Centos1:> terraform destroy -auto-approve

```

### Before applying terraform script update the base cofnig in vEX / vQFX-10K via cli
### (Specific to VMM Environment and already in-buit into the terraform scripts)
```
vEX-9214> cli
  configure
  set groups member0 system host-name <switch-host-name>
  set chassis evpn-vxlan-default-switch-support
  set system commit synchronize 
  set system services netconf ssh 
  delete groups global interfaces lo0 
  delete groups global routing-options router-id 
  commit and-quit
  show chassis hardware
  show interfaces fxp0 | grep Hardware 
 
vQFX-10K> cli
  configure
  set groups member0 system host-name <switch-host-name>
  set system services netconf ssh 
  delete groups global interfaces lo0 
  delete groups global routing-options router-id 
  commit and-quit
  show chassis hardware
  show interfaces em0 | grep Hardware

```
### Create Agent Profile "profile_juniper_vqfx" from Apstra Web UI with login credential of vEX/vQFX switches
Login to Apstra Web UI: 
1. Create Agent Profile named "profile_juniper_vqfx" with login credential of vEX/vQFX switches before executing the terraform script.

### Work through the files in numerical order for further customization
Each terraform configuration file after provider config is 100% customizable. Work through the file main.tf in order, un-commenting/commenting one `resource` or
`data`(source) at a time. Compare the results with the lab guide and with the
Apstra web UI.

### Work through the files in numerical order for further customization
Each terraform configuration file after provider config is 100% customizable. Work through the file main.tf in order, un-commenting/commenting one `resource` or
`data`(source) at a time. Compare the results with the lab guide and with the
Apstra web UI.
