
terraform {
  required_version = ">= 0.13"
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.5"
    }
    ansible = {
      source = "ansible/ansible"
      version = "~> 1.0"
    }
  }
}

provider "esxi" {
  esxi_hostname      = "esxi"  #192.168.0.52"
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = "root"
  esxi_password      = "contrail@123"
}
provider "ansible" {}

provider "proxmox" {
  #pm_api_url = "https://192.168.0.54:8006/api2/json"
  pm_api_url = "https://172.16.10.162:8006/api2/json"
  pm_api_token_id = "root@pam!terraform"
  pm_api_token_secret = "863ca02e-7549-4b9a-aa48-80ec7b4579e9"
  pm_tls_insecure = true
  #pm_debug = true
  #pm_log_enable = true
  #pm_log_file   = "terraform-plugin-proxmox.log"
  #pm_debug      = true
  #pm_log_levels = {
  #  _default    = "debug"
  #  _capturelog = ""
  #}
}

##resource "esxi_guest" "esxi-cpe1" {
##  guest_name         = "esxi-cpe1"
##  disk_store         = "Datastore1"
##  memsize            = "128m"
##  notes              = "terraform - Host deployment vCPE_1 : esxi provider"
##  numvcpus           = "1"
##  ovf_source         = "LEDE3.ova"
##  network_interfaces {
##    virtual_network = "VM Network"
##  }
##  network_interfaces {
##    virtual_network = "VM Network-1"
##  }
##}

##resource "null_resource" "before" {
##}
##resource "null_resource" "delay" {
##  provisioner "local-exec" {
##    command = "sleep 10"
##  }
##  triggers = {
##    "before" = "${null_resource.before.id}"
##  }
##}
##resource "null_resource" "after" {
##  depends_on = ["null_resource.delay"]
##}

resource "proxmox_vm_qemu" "lede-171-vCPE1" {
  name = "lede-171-vCPE1" 
  desc = "vCPE - LEDE v17.01.07 - SSH-Tunnel_62"
  target_node = "Proxmox-54"
  clone = "lede-17.1-host-only"
  full_clone = true
  vmid = "40001"
  agent = 0
  os_type = "cloud-init"
  cores = 1
  sockets = 1
  cpu = ""
  memory = 128
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    slot = 0
    size = "276M"
    type = "scsi"
    storage = "thin-lvm"
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
    #macaddr = "00:50:56:33:33:33"
  }
  network {
    model = "virtio"
    bridge = "vmbr2"
    macaddr = "00:50:56:33:33:33"
  }
  network {
    model = "virtio"
    bridge = "vmbr3"
  }
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
  ipconfig0 = "ip=10.98.1.91/24,gw=10.98.1.1"
  provisioner "local-exec" {
    command = "echo vCPE1 Start Date: %date%  Time: %time% && ping 127.0.0.1 -n 40 > nul"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = ""
    host     = "192.168.97.61"
    #script_path = "/root/boot.sh"
  }

  provisioner "file" {
    source  = "vCPE62/system_1"
    destination  = "/etc/config/system"
  }  
  provisioner "file" {
    source  = "vCPE62/interfaces_1"
    destination  = "/etc/config/network"
  }  
  #provisioner "file" {
  #  #source  = "vCPE62/boot.sh"
  #  #destination  = "/root/boot.sh"
  #  source  = "vCPE62/fifo.sh"
  #  destination  = "/root/fifo.sh"
  #}  
  provisioner "file" {
    source      = "C:/Users/ihazra/.ssh/id_rsa.pub"
    destination = "/etc/dropbear/authorized_keys"
  }
    provisioner "file" {
    source  = "vCPE62/etc.rc.local_1"
    destination  = "/etc/rc.local"
  }
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 chmod 644 /etc/rc.local && ssh root@192.168.97.61 chmod 700 /etc/dropbear && ssh root@192.168.97.61 chmod 600 /etc/dropbear/authorized_keys && ssh root@192.168.97.61 mkdir /root/.ssh && ssh root@192.168.97.61 chmod 700 /root/.ssh"
  }
  provisioner "file" {
    source      = "C:/Users/ihazra/.ssh/id_rsa.pub"
    destination = "/root/.ssh/id_rsa.pub"
  }
  provisioner "file" {
    source      = "C:/Users/ihazra/.ssh/id_rsa"
    destination = "/root/.ssh/id_rsa"
  }
  provisioner "file" {
    source      = "vCPE1/ssh/known_hosts"
    destination = "/root/.ssh/known_hosts"
  }
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 opkg update && ssh root@192.168.97.61 opkg install luci-proto-wireguard luci-app-wireguard wireguard kmod-wireguard wireguard-tools ethtool tcpdump gre kmod-gre nano sshtunnel socat openssh-server && ping 127.0.0.1 -n 60 > nul"    ## openssh-server 
  }
  provisioner "file" {
    source  = "vCPE62/sshtunnel_1"
    destination  = "/etc/config/sshtunnel"
  }  
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 chmod 600 /root/.ssh/id_rsa && ssh root@192.168.97.61 reboot"
  }
  provisioner "local-exec" {
    command = "ping 127.0.0.1 -n 60 > nul && ping 192.168.97.10 -n 10 && echo vCPE1 Prov. End Date: %date%  Time: %time%"
    # && ssh root@192.168.97.10 sh fifo.sh"
    # ssh root@192.168.97.10 ssh -NL 53800:localhost:53800 ihazra@10.32.192.47 | socat UDP4-LISTEN:51840,fork TCP4:localhost:53800 &"
  }
  provisioner "local-exec" {
    command = "ssh ihazra@10.32.192.47 sh fifo_53800.sh && echo Start ssh-tunnel provisioning @css-lnx02 Date: %date%  Time: %time%"
    # && ssh root@192.168.97.10 sh fifo.sh"
    # ssh root@192.168.97.10 ssh -NL 53800:localhost:53800 ihazra@10.32.192.47 | socat UDP4-LISTEN:51840,fork TCP4:localhost:53800 &"
  }

  #provisioner "remote-exec" {
  #  inline = [
  #    "echo 'Hello World!!!'",
  #    "echo 'Hello World!!!!!!!!!!!!!!'",
  #    "reboot"
  #  ]
  #}
}

#resource "time_sleep" "wait_300_seconds" {      ##default: all resources run in parallel
#  create_duration = "300s"
#  provisioner "local-exec" {
#    command = "ping 127.0.0.1 -n 10 > nul"
#  }
#}

resource "proxmox_vm_qemu" "lede-171-vCPE2" {
#  depends_on = [time_sleep.wait_300_seconds]
  depends_on = [proxmox_vm_qemu.lede-171-vCPE1]
  name = "lede-171-vCPE2" 
  desc = "vCPE - LEDE v17.01.07 - SSH-wg0_61"
  target_node = "Proxmox-54"
  clone = "lede-17.1-host-only"
  full_clone = true
  vmid = "40002"
  agent = 0
  os_type = "cloud-init"
  cores = 1
  sockets = 1
  cpu = ""
  memory = 128
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    slot = 0
    size = "276M"
    type = "scsi"
    storage = "thin-lvm"
  }
  
  network {
    model = "virtio"
    bridge = "vmbr0"
    #macaddr = "00:50:56:00:00:55"
  }
  network {
    model = "virtio"
    bridge = "vmbr2"
    macaddr = "00:50:56:00:00:55"
  }
  network {
    model = "virtio"
    bridge = "vmbr3"
    macaddr = "00:50:57:00:00:55"
  }  
  network {
    model = "e1000"
    bridge = "vmbr4"
  }  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
  ipconfig0 = "ip=10.98.1.91/24,gw=10.98.1.1"    #ignore: for openWRT vCPE
  provisioner "local-exec" {
    command = "echo vCPE2 Start Date: %date%  Time: %time% && ping 127.0.0.1 -n 40 > nul"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = ""
    host     = "192.168.97.61"
  }

  provisioner "file" {
    source  = "vCPE61/system_1"
    destination  = "/etc/config/system"
  }  
  provisioner "file" {
    source  = "vCPE61/interfaces_1"
    destination  = "/etc/config/network"
  }  
  provisioner "file" {
    source      = "C:/Users/ihazra/.ssh/id_rsa.pub"
    destination = "/etc/dropbear/authorized_keys"
  }
  provisioner "file" {
    #source  = "vCPE61/boot.sh"
    #destination  = "/root/boot.sh"
    source  = "vCPE61/gre_client.sh"
    destination  = "/root/gre.sh"
  }
  provisioner "file" {
    source  = "vCPE61/etc.rc.local_1"
    destination  = "/etc/rc.local"
  }
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 chmod 644 /etc/rc.local && ssh root@192.168.97.61 chmod 700 /etc/dropbear && ssh root@192.168.97.61 chmod 600 /etc/dropbear/authorized_keys"
  }
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 opkg update && ssh root@192.168.97.61 opkg install luci-proto-wireguard luci-app-wireguard wireguard kmod-wireguard wireguard-tools ethtool tcpdump gre kmod-gre nano sshtunnel socat && ping 127.0.0.1 -n 90 > nul"
  }
  provisioner "local-exec" {
    command = "ssh root@192.168.97.61 reboot && echo vCPE2 Prov. End Date: %date%  Time: %time%"
  }
  #provisioner "local-exec" {
  #  command = "ping 127.0.0.1 -n 10 > nul && echo vCPE2 Prov. End Date: %date%  Time: %time%"
  #} 
}



