# *******************************************************************
# * Title:            OCVS Demo Environment
# * Purpose:          This script will deploy OCVS, Bastion, Jumphost
# *                   and all subnets, RTs, NSGs, SLs, GWs, and VLANs.
# * Author:           Ryan Patel
# * Creation Date:    04/05/2021
# * Version:          1.0
# * Update Log:
# *    
# *******************************************************************

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}

# ------ Retrieve Regional / Cloud Data
# -------- Get a list of Availability Domains
data "oci_identity_availability_domains" "AvailabilityDomains" {
    compartment_id = var.tenancy_ocid
}
data "template_file" "AvailabilityDomainNames" {
    count    = length(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains)
    template = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains[count.index]["name"]
}
# -------- Get a list of Fault Domains
data "oci_identity_fault_domains" "FaultDomainsAD1" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
    compartment_id = var.tenancy_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD2" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 1)["name"]
    compartment_id = var.tenancy_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD3" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 2)["name"]
    compartment_id = var.tenancy_ocid
}
# -------- Get Home Region Name
data "oci_identity_region_subscriptions" "RegionSubscriptions" {
    tenancy_id = var.tenancy_ocid
}
locals {
    HomeRegion = [for x in data.oci_identity_region_subscriptions.RegionSubscriptions.region_subscriptions: x if x.is_home_region][0]
}
# ------ Get List Service OCIDs
data "oci_core_services" "RegionServices" {
}
# ------ Get List Images
data "oci_core_images" "InstanceImages" {
    compartment_id           = var.compartment_ocid
}
# ------ Get OCVS Versions
data "oci_ocvp_supported_vmware_software_versions" "ocvs_versions" {
    #Required
    compartment_id = var.compartment_ocid
}

# ------ Create Compartment - Root True
# ------ Root Compartment
locals {
    Mycompartment_id              = var.compartment_ocid
}

output "MycompartmentId" {
    value = local.Mycompartment_id
}

# ------ Create Virtual Cloud Network
resource "oci_core_vcn" "My_Vcn" {
    # Required
    compartment_id = local.Mycompartment_id
    cidr_block     = var.vcn_cidr
    # Optional
    dns_label      = var.vcn_dns
    display_name   = var.vcn_name
}

locals {
    My_Vcn_id                       = oci_core_vcn.My_Vcn.id
    My_Vcn_dhcp_options_id          = oci_core_vcn.My_Vcn.default_dhcp_options_id
    My_Vcn_domain_name              = oci_core_vcn.My_Vcn.vcn_domain_name
    My_Vcn_default_dhcp_options_id  = oci_core_vcn.My_Vcn.default_dhcp_options_id
    My_Vcn_default_security_list_id = oci_core_vcn.My_Vcn.default_security_list_id
    My_Vcn_default_route_table_id   = oci_core_vcn.My_Vcn.default_route_table_id
}


# ------ Create Internet Gateway
resource "oci_core_internet_gateway" "Internet-GW" {
    # Required
    compartment_id = local.Mycompartment_id
    vcn_id         = local.My_Vcn_id
    # Optional
    enabled        = true
    display_name   = "Internet-GW"
}

locals {
    Internet-GW_id = oci_core_internet_gateway.Internet-GW.id
}

# ------ Create NAT Gateway
resource "oci_core_nat_gateway" "NAT-GW" {
    # Required
    compartment_id = local.Mycompartment_id
    vcn_id         = local.My_Vcn_id
    # Optional
    display_name   = "NAT-GW"
    block_traffic  = false
}

locals {
    NAT-GW_id = oci_core_nat_gateway.NAT-GW.id
}

# ------ Create Service Gateway
data "oci_core_services" "Service-GW" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

output "services" {
  value = [data.oci_core_services.Service-GW.services]
}

resource "oci_core_service_gateway" "Service-GW" {
    # Required
    compartment_id = local.Mycompartment_id
	services {
        #Required
        service_id = data.oci_core_services.Service-GW.services.0["id"]
    }
    vcn_id         = local.My_Vcn_id
    # Optional
    display_name   = "Service-GW"
}

locals {
    Service-GW_id = oci_core_service_gateway.Service-GW.id
}

# ------ Create Security List
# ------- Update VCN Default Security List
resource "oci_core_default_security_list" "SL-Public" {
    # Required
    manage_default_resource_id = local.My_Vcn_default_security_list_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        tcp_options {
            min = "22"
            max = "22"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        tcp_options {
            min = "80"
            max = "80"
        }
    }
    # Optional
    display_name   = "SL-Public"
}

locals {
    SL-Public_id = oci_core_default_security_list.SL-Public.id
}

# ------ Create Security List
resource "oci_core_security_list" "SL-Private" {
    # Required
    compartment_id = local.Mycompartment_id
    vcn_id         = local.My_Vcn_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = var.vcn_cidr
        # Optional
        source_type  = "CIDR_BLOCK"
        tcp_options {
            min = "22"
            max = "22"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = var.vcn_cidr
        # Optional
        source_type  = "CIDR_BLOCK"
    }
	ingress_security_rules {
        # Required
        protocol    = "6"
        source      = var.vcn_cidr
        # Optional
        source_type  = "CIDR_BLOCK"
        tcp_options {
            min = "3389"
            max = "3389"
        }
    }
    # Optional
    display_name   = "SL-Private"
}

locals {
    SL-Private_id = oci_core_security_list.SL-Private.id
}

# ------ Create Security List
resource oci_core_security_list SL-SDDC {
  compartment_id = local.Mycompartment_id
  vcn_id         = local.My_Vcn_id
  display_name = "SL-SDDC"
  egress_security_rules {
    description      = "Allow all egress traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  ingress_security_rules {
    description = "Allow SSH traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "Allow ICMP traffic"
    protocol    = "1"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Allow HTTP traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "80"
      min = "80"
    }
  }
  ingress_security_rules {
    description = "Allow HTTPS traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    description = "Allow vCenter Server agent to manage ESXi host"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "902"
      min = "902"
    }
  }
  ingress_security_rules {
    description = "Allow vCenter Server agent to manage ESXi host"
    protocol    = "17"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      max = "902"
      min = "902"
    }
  }
  ingress_security_rules {
    description = "Allow vCenter Server agent to manage ESXi host"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "903"
      min = "903"
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Allow DNS traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "53"
      min = "53"
    }
  }
  ingress_security_rules {
    description = "Allow DNS traffic"
    protocol    = "17"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      max = "53"
      min = "53"
    }
  }
  ingress_security_rules {
    description = "Allow VMware license server traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "27010"
      min = "27010"
    }
  }
  ingress_security_rules {
    description = "Allow VMware license server traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "27000"
      min = "27000"
    }
  }
  ingress_security_rules {
    description = "Allow NTP time server traffic"
    protocol    = "17"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      max = "123"
      min = "123"
    }
  }
  ingress_security_rules {
    description = "Allow iSCSI traffic"
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "3260"
      min = "3260"
    }
  }
  ingress_security_rules {
    description = "Allow ingress traffic for VMware inter-process communication"
    protocol    = "all"
    source      = var.sddc_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
}
locals {
    SL-SDDC_id = oci_core_security_list.SL-SDDC.id
}


# ------ Create Route Table
# ------- Update VCN Default Route Table
resource "oci_core_default_route_table" "RT-Public" {
    # Required
    manage_default_resource_id = local.My_Vcn_default_route_table_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = local.Internet-GW_id
        description       = ""
    }
    # Optional
    display_name   = "RT-Public"
}

locals {
    RT-Public_id = oci_core_default_route_table.RT-Public.id
    }

resource "oci_core_route_table" "RT-Private" {
    # Required
    compartment_id = local.Mycompartment_id
    vcn_id         = local.My_Vcn_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = local.NAT-GW_id
        description       = ""
    }
    # Optional
    display_name   = "RT-Private"
}

locals {
    RT-Private_id = oci_core_route_table.RT-Private.id
}

resource oci_core_route_table RT_Demo-sddc {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-vSphere"
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.NAT-GW_id
  }
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-Provisioning-Net {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-Provisioning Net"
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-Replication-Net {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-Replication Net"
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-HCX {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-HCX"
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-vMotion {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-vMotion"
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-Subnet-Demo-sddc {
  compartment_id = local.Mycompartment_id
  display_name = "RT-Subnet-Demo-sddc"
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-NSX-Edge-Uplink-1 {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-NSX Edge Uplink 1"
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.NAT-GW_id
  }
  vcn_id = local.My_Vcn_id
}

resource oci_core_route_table Route-Table-for-VLAN-Demo-sddc-NSX-Edge-Uplink-2 {
  compartment_id = local.Mycompartment_id
  display_name = "RT-VLAN-Demo-sddc-NSX Edge Uplink 2"
  vcn_id = local.My_Vcn_id
}

# ------ Create Subnets
resource "oci_core_subnet" "Subnet-Public" {
    # Required
    compartment_id             = local.Mycompartment_id
    vcn_id                     = local.My_Vcn_id
    cidr_block                 = var.pub_cidr
    # Optional
    display_name               = "Subnet-Public"
    dns_label                  = "sn001"
    security_list_ids          = [local.SL-Public_id]
    route_table_id             = local.RT-Public_id
    dhcp_options_id            = local.My_Vcn_dhcp_options_id
    prohibit_public_ip_on_vnic = false
}

locals {
    Subnet-Public_id              = oci_core_subnet.Subnet-Public.id
    Subnet-Public_domain_name     = oci_core_subnet.Subnet-Public.subnet_domain_name
}

resource "oci_core_subnet" "Subnet-Private" {
    # Required
    compartment_id             = local.Mycompartment_id
    vcn_id                     = local.My_Vcn_id
    cidr_block                 = var.priv_cidr
    # Optional
    display_name               = "Subnet-Private"
    dns_label                  = "sn002"
    security_list_ids          = [local.SL-Private_id]
    route_table_id             = local.RT-Private_id
    dhcp_options_id            = local.My_Vcn_dhcp_options_id
    prohibit_public_ip_on_vnic = true
}

locals {
    Subnet-Private_id              = oci_core_subnet.Subnet-Private.id
    Subnet-Private_domain_name     = oci_core_subnet.Subnet-Private.subnet_domain_name
}

resource "oci_core_subnet" "Subnet-Provisioning" {
  cidr_block                 = var.provision_cidr
  compartment_id             = local.Mycompartment_id
  dhcp_options_id            = local.My_Vcn_dhcp_options_id
  display_name               = "Subnet-Provisioning"
  dns_label                  = "provisioningsub"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.RT-Private.id
  security_list_ids          = [oci_core_security_list.SL-SDDC.id]
  vcn_id                     = local.My_Vcn_id
}

# ------ Create Bastion
resource "oci_core_instance" "Bastion" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "OS Management Service Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Custom Logs Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Run Command"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
	}
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
	compartment_id = local.Mycompartment_id
	create_vnic_details {
		assign_public_ip = "true"
		subnet_id = oci_core_subnet.Subnet-Public.id
	}
	display_name = "Bastion"
	instance_options {
		are_legacy_imds_endpoints_disabled = "false"
	}
	metadata = {
		"ssh_authorized_keys" = var.ssh_auth_keys
	}
	shape = "VM.Standard.E3.Flex"
	shape_config {
		memory_in_gbs = "16"
		ocpus = "1"
	}
	source_details {
		source_id = var.bastion_image[var.region]
		source_type = "image"
	}
}

resource "oci_core_instance" "Jumpbox" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "OS Management Service Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Custom Logs Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Run Command"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
	}
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
	compartment_id = local.Mycompartment_id
	create_vnic_details {
		assign_public_ip = "false"
		subnet_id = oci_core_subnet.Subnet-Private.id
	}
	display_name = "Jumphost"
	instance_options {
		are_legacy_imds_endpoints_disabled = "false"
	}
	shape = "VM.Standard.E3.Flex"
	shape_config {
		memory_in_gbs = "32"
		ocpus = "2"
	}
	source_details {
		source_id = var.jumphost_image[var.region]
		source_type = "image"
	}
}

# ------ Create Network Security Groups
resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-HCX {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-HCX"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-vSphere {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-vSphere"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-Provisioning-Net {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-Provisioning Net"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-Replication-Net {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-Replication Net"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-vSAN {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-vSAN"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-vMotion {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-vMotion"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-NSX-VTEP {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-NSX VTEP"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-VLAN-Demo-sddc-NSX Edge VTEP"
  vcn_id = local.My_Vcn_id
}

resource oci_core_network_security_group NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc {
  compartment_id = local.Mycompartment_id
  display_name = "NSG-NSX Edge Uplink VLANs in Demo-sddc"
  vcn_id = local.My_Vcn_id
}

# ------ Create Network Security Group Rules
resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_2 {
  description = "Allow HCX bulk migration traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "31031"
      min = "31031"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_3 {
  description = "Allow HCX X-cloud vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_4 {
  description = "Allow HCX X-cloud control traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_5 {
  description = "Allow HCX REST API traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_6 {
  description = "Allow HCX cold migration traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_7 {
  description = "Allow OVF import traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-HCX_network_security_group_security_rule_8 {
  description = "Allow HCX WAN transport traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "4500"
      min = "4500"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_2 {
  description = "Allow NTP port traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "123"
      min = "123"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_3 {
  description = "Allow SSH traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_4 {
  description = "Allow traffic for NSX messaging channel to NSX Manager"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1234"
      min = "1234"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_5 {
  description = "Allow traffic for vSAN Cluster Monitoring, Membership, and Directory Service"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "12345"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_6 {
  description = "Allow Unicast agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_7 {
  description = "Allow NestDB traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2480"
      min = "2480"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_8 {
  description = "Allow iSCSI traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3260"
      min = "3260"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_9 {
  description = "Allow BFD traffic between nodes"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_10 {
  description = "Allow Edge HA traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "50263"
      min = "50263"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_11 {
  description = "Allow NSX Agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5555"
      min = "5555"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_12 {
  description = "Allow AMQP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5671"
      min = "5671"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_13 {
  description = "Allow NSX messaging traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1235"
      min = "1234"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_14 {
  description = "Allow HTTP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8080"
      min = "8080"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_15 {
  description = "Allow RFB protocol traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5964"
      min = "5900"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_16 {
  description = "Allow ESXi dump collector traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_17 {
  description = "Allow ESXi dump collector traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_18 {
  description = "Allow NSX Edge communication traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6666"
      min = "6666"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_19 {
  description = "Allow NSX DLR traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6999"
      min = "6999"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_20 {
  description = "Allow vSphere fault tolerance traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_21 {
  description = "Allow vSphere fault tolerance traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_22 {
  description = "Allow vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_23 {
  description = "Allow vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_24 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8010"
      min = "8010"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_25 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_26 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_27 {
  description = "Allow traffic to DVSSync port to enable fault tolerance"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8302"
      min = "8301"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_28 {
  description = "Allow Web Services Management traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8889"
      min = "8889"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_29 {
  description = "Allow Distributed Data Store traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_30 {
  description = "Allow Distributed Data Store traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_31 {
  description = "Allow vCenter Server to manage ESXi hosts"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_32 {
  description = "Allow Server Agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_33 {
  description = "Allow I/O Filter traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_34 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_35 {
  description = "Allow RDT traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_36 {
  description = "Allow CIM client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_37 {
  description = "Allow CIM client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_38 {
  description = "Allow HTTPS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_39 {
  description = "Allow DNS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_40 {
  description = "Allow DNS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_41 {
  description = "Allow systemd-resolve traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "5355"
      min = "5355"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_42 {
  description = "Allow appliance management traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5480"
      min = "5480"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_43 {
  description = "Allow CIM traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5989"
      min = "5988"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_44 {
  description = "Allow HTTP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_45 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_46 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_47 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_48 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_49 {
  description = "Allow traffic to TCP ports for VMware cluster"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSphere_network_security_group_security_rule_50 {
  description = "Allow traffic to UDP ports for VMware cluster"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_2 {
  description = "Allow NTP port traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "123"
      min = "123"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_3 {
  description = "Allow SSH traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_4 {
  description = "Allow traffic for NSX messaging channel to NSX Manager"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1234"
      min = "1234"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_5 {
  description = "Allow traffic for vSAN Cluster Monitoring, Membership, and Directory Service"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "12345"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_6 {
  description = "Allow Unicast agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_7 {
  description = "Allow NestDB traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2480"
      min = "2480"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_8 {
  description = "Allow iSCSI traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3260"
      min = "3260"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_9 {
  description = "Allow BFD traffic between nodes"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_10 {
  description = "Allow Edge HA traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "50263"
      min = "50263"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_11 {
  description = "Allow NSX Agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5555"
      min = "5555"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_12 {
  description = "Allow AMQP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5671"
      min = "5671"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_13 {
  description = "Allow NSX messaging traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1235"
      min = "1234"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_14 {
  description = "Allow HTTP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8080"
      min = "8080"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_15 {
  description = "Allow RFB protocol traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5964"
      min = "5900"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_16 {
  description = "Allow ESXi dump collector traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_17 {
  description = "Allow ESXi dump collector traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_18 {
  description = "Allow NSX Edge communication traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6666"
      min = "6666"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_19 {
  description = "Allow NSX DLR traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6999"
      min = "6999"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_20 {
  description = "Allow vSphere fault tolerance traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_21 {
  description = "Allow vSphere fault tolerance traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_22 {
  description = "Allow vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_23 {
  description = "Allow vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_24 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8010"
      min = "8010"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_25 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_26 {
  description = "Allow vSAN health traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_27 {
  description = "Allow traffic to DVSSync port to enable fault tolerance"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8302"
      min = "8301"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_28 {
  description = "Allow Web Services Management traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8889"
      min = "8889"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_29 {
  description = "Allow Distributed Data Store traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_30 {
  description = "Allow Distributed Data Store traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_31 {
  description = "Allow vCenter Server to manage ESXi hosts"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_32 {
  description = "Allow Server Agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_33 {
  description = "Allow I/O Filter traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_34 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_35 {
  description = "Allow RDT traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_36 {
  description = "Allow CIM client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_37 {
  description = "Allow CIM client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_38 {
  description = "Allow HTTPS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_39 {
  description = "Allow DNS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_40 {
  description = "Allow DNS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_41 {
  description = "Allow systemd-resolve traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "5355"
      min = "5355"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_42 {
  description = "Allow appliance management traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5480"
      min = "5480"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_43 {
  description = "Allow CIM traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5989"
      min = "5988"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_44 {
  description = "Allow HTTP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_45 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_46 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_47 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_48 {
  description = "Allow vSphere Web Client traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_49 {
  description = "Allow traffic to TCP ports for VMware cluster"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Provisioning-Net_network_security_group_security_rule_50 {
  description = "Allow traffic to UDP ports for VMware cluster"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_2 {
  description = "SSH for VCHA replication and communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_3 {
  description = "Ongoing replication traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "31031"
      min = "31031"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_4 {
  description = "Ongoing replication traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "44046"
      min = "44046"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_5 {
  description = "Monitoring and health pre-checks"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "0"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_6 {
  description = "Monitoring and health pre-checks"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "8"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_7 {
  description = "Traceroute diagnostic traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "11"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_8 {
  description = "Path MTU discovery traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "4"
    type = "3"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-Replication-Net_network_security_group_security_rule_9 {
  description = "vSphere replication communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_2 {
  description = "Allow traffic used for Virtual SAN health monitoring"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_3 {
  description = "Allow traffic used for Virtual SAN health monitoring"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_4 {
  description = "Allow vSAN HTTP traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_5 {
  description = "Allow vSAN Transport traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_6 {
  description = "Allow vSAN Clustering Service traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12345"
      min = "12345"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_7 {
  description = "Allow Unicast agent traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_8 {
  description = "Allow vSAN Clustering Service traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "23451"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vSAN_network_security_group_security_rule_9 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vMotion_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vMotion_network_security_group_security_rule_2 {
  description = "Allow HTTPS traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vMotion_network_security_group_security_rule_3 {
  description = "Allow vMotion traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vMotion_network_security_group_security_rule_4 {
  description = "Allow ESXi NFC traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-vMotion_network_security_group_security_rule_5 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-VTEP_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-VTEP.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-VTEP_network_security_group_security_rule_2 {
  description = "Allow traffic for GENEVE Termination End Point (TEP) Transport N/W"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-VTEP.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6081"
      min = "6081"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-VTEP_network_security_group_security_rule_3 {
  description = "Allow traffic for BFD Session between TEPs"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-VTEP.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-VTEP_network_security_group_security_rule_4 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-VTEP.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP_network_security_group_security_rule_2 {
  description = "Allow traffic for GENEVE Termination End Point (TEP) Transport N/W"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6081"
      min = "6081"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP_network_security_group_security_rule_3 {
  description = "Allow traffic for BFD Session between TEPs"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP.id
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP_network_security_group_security_rule_4 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc_network_security_group_security_rule_1 {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id
  protocol                  = "all"
  #source = <<Optional value not found in discovery>>
  source_type = ""
  stateless   = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc_network_security_group_security_rule_2 {
  description = "Allow SSH traffic"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
    #source_port_range = <<Optional value not found in discovery>>
  }
}

resource oci_core_network_security_group_security_rule NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc_network_security_group_security_rule_3 {
  description = "ICMP traffic for: 3, 4 Destination Unreachable: Fragmentation Needed and Don't Fragment was Set"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "4"
    type = "3"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc_network_security_group_security_rule_4 {
  description = "ICMP traffic for: 3 Destination Unreachable"
  #destination = <<Optional value not found in discovery>>
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "-1"
    type = "3"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

resource oci_core_network_security_group_security_rule NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc_network_security_group_security_rule_5 {
  description = "Allow ingress traffic for VMware inter-process communication"
  #destination = <<Optional value not found in discovery>>
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id
  protocol                  = "all"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}

# ------ Create VLANS
# ------ Create VLANS
resource oci_core_vlan VLAN-Demo-sddc-Replication-Net {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_repl_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-Replication Net"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Replication-Net.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-Replication-Net.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "2439"
}

resource oci_core_vlan VLAN-Demo-sddc-NSX-Edge-Uplink-1 {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_nsxEdgeUplink1_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-NSX Edge Uplink 1"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-NSX-Edge-Uplink-1.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "2580"
}

resource oci_core_vlan VLAN-Demo-sddc-vSAN {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_vSAN_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-vSAN"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSAN.id,
  ]
  route_table_id = oci_core_route_table.RT-Private.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3262"
}

resource oci_core_vlan VLAN-Demo-sddc-vMotion {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_vMotion_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-vMotion"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vMotion.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-vMotion.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3368"
}

resource oci_core_vlan VLAN-Demo-sddc-Provisioning-Net {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_provision_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-Provisioning Net"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-Provisioning-Net.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-Provisioning-Net.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "1478"
}

resource oci_core_vlan VLAN-Demo-sddc-HCX {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_HCX_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-HCX"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-HCX.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-HCX.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3488"
}

resource oci_core_vlan VLAN-Demo-sddc-NSX-VTEP {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_NSX-VTEP_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-NSX VTEP"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-VTEP.id,
  ]
  route_table_id = oci_core_route_table.RT-Private.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3588"
}

resource oci_core_vlan VLAN-Demo-sddc-vSphere {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_vSphere_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-vSphere"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-vSphere.id,
  ]
  route_table_id = oci_core_route_table.RT_Demo-sddc.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "1659"
}

resource oci_core_vlan VLAN-Demo-sddc-NSX-Edge-VTEP {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_NSX-Edge-VTEP_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-NSX Edge VTEP"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-VLAN-Demo-sddc-NSX-Edge-VTEP.id,
  ]
  route_table_id = oci_core_route_table.RT-Private.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3989"
}

resource oci_core_vlan VLAN-Demo-sddc-NSX-Edge-Uplink-2 {
  availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
  cidr_block          = var.sddc_nsxEdgeUplink2_cidr
  compartment_id      = local.Mycompartment_id
  display_name = "VLAN-Demo-sddc-NSX Edge Uplink 2"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-VLANs-in-Demo-sddc.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-VLAN-Demo-sddc-NSX-Edge-Uplink-2.id
  vcn_id         = local.My_Vcn_id
  vlan_tag       = "3132"
}

# ------ Create SDDC
resource "oci_ocvp_sddc" "Demo-sddc" {
    #Required
    compartment_id = local.Mycompartment_id
    compute_availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
    esxi_hosts_count = var.sddc_esxi_hosts_count
    nsx_edge_uplink1vlan_id = oci_core_vlan.VLAN-Demo-sddc-NSX-Edge-Uplink-1.id
    nsx_edge_uplink2vlan_id = oci_core_vlan.VLAN-Demo-sddc-NSX-Edge-Uplink-2.id
    nsx_edge_vtep_vlan_id = oci_core_vlan.VLAN-Demo-sddc-NSX-Edge-VTEP.id
    nsx_vtep_vlan_id = oci_core_vlan.VLAN-Demo-sddc-NSX-VTEP.id
    provisioning_subnet_id = oci_core_subnet.Subnet-Provisioning.id
    provisioning_vlan_id = oci_core_vlan.VLAN-Demo-sddc-Provisioning-Net.id
    replication_vlan_id = oci_core_vlan.VLAN-Demo-sddc-Replication-Net.id
    ssh_authorized_keys = var.ssh_auth_keys
    vmotion_vlan_id = oci_core_vlan.VLAN-Demo-sddc-vMotion.id
    vmware_software_version = var.sddc_version
    vsan_vlan_id = oci_core_vlan.VLAN-Demo-sddc-vSAN.id
    vsphere_vlan_id = oci_core_vlan.VLAN-Demo-sddc-vSphere.id

    #Optional
    display_name = var.sddc_display_name
    hcx_vlan_id = oci_core_vlan.VLAN-Demo-sddc-HCX.id
    instance_display_name_prefix = var.sddc_instance_display_name_prefix
    is_hcx_enabled = var.sddc_is_hcx_enabled
    workload_network_cidr = var.sddc_workload_network_cidr
}
