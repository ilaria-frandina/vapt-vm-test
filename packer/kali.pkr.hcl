packer {
  required_version = ">= 1.10.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

locals {
  vm_name = "vapt-vm-${var.vm_version}"
}

# ── QEMU → QCOW2 (Linux / KVM / Proxmox / GNOME Boxes) ──────────────────────
source "qemu" "qcow2" {
  vm_name = "${local.vm_name}.qcow2"

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  cpus      = var.cpus
  memory    = var.memory
  disk_size = var.disk_size

  format           = "qcow2"
  output_directory = "output/qcow2"

  accelerator    = "kvm"
  headless       = true
  http_directory = "${path.root}/http"

  disk_interface = "virtio"
  net_device     = "virtio-net"

  boot_wait = "15s"
  boot_command = [
    "<down><wait>",
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " hostname=vapt-vm domain=''",
    " --- quiet<enter><wait5>",
    "initrd /install.amd/initrd.gz<enter><wait5>",
    "boot<enter>"
  ]

  ssh_username = var.vm_user
  ssh_password = var.vm_password
  ssh_timeout  = "90m"

  shutdown_command = "echo '${var.vm_password}' | sudo -S shutdown -h now"
}

# ── VirtualBox → OVA (Windows / macOS con VirtualBox o VMware) ───────────────
source "virtualbox-iso" "ova" {
  vm_name = local.vm_name

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  cpus      = var.cpus
  memory    = var.memory
  disk_size = var.disk_size

  guest_os_type    = "Debian_64"
  output_format    = "ova"
  output_directory = "output/ova"

  headless       = true
  http_directory = "${path.root}/http"

  # VirtualBox è lento,arriviamo al GRUB menu verso i 10s
  boot_wait = "10s"
  boot_command = [
    "<down><wait>",
    "c<wait>",
    "linux /install.amd/vmlinuz",
    " auto=true",
    " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " hostname=vapt-vm domain=''",
    " --- quiet<enter><wait5>",
    "initrd /install.amd/initrd.gz<enter><wait5>",
    "boot<enter>"
  ]

  ssh_username = var.vm_user
  ssh_password = var.vm_password
  ssh_timeout  = "150m"

  shutdown_command = "echo '${var.vm_password}' | sudo -S shutdown -h now"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--vram", "64"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
  ]
}

# ── Build QCOW2 ───────────────────────────────────────────────────────────────
build {
  name    = "qcow2"
  sources = ["source.qemu.qcow2"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../stacks/vapt-vm.yml"
    user          = var.vm_user
    extra_arguments = [
      "--extra-vars", "target=all ansible_become=true ansible_become_password=${var.vm_password}",
    ]
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.root}/../ansible.cfg",
      "ANSIBLE_FORCE_COLOR=1",
    ]
  }

  post-processor "manifest" {
    output     = "output/qcow2/manifest.json"
    strip_path = true
  }
}

# ── Build OVA ─────────────────────────────────────────────────────────────────
build {
  name    = "ova"
  sources = ["source.virtualbox-iso.ova"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../stacks/vapt-vm.yml"
    user          = var.vm_user
    extra_arguments = [
      "--extra-vars", "target=all ansible_become=true ansible_become_password=${var.vm_password}",
    ]
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.root}/../ansible.cfg",
      "ANSIBLE_FORCE_COLOR=1",
    ]
  }

  post-processor "manifest" {
    output     = "output/ova/manifest.json"
    strip_path = true
  }
}
