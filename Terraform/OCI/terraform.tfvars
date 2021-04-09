# Enter your Tenancy OCID
tenancy_ocid = "XXX"

# Enter your Compartment OCID
compartment_ocid = "XXX"

# Region to Deploy
# Get the Region Identifier - https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
region = "XXX"

# SSH Key Pair (Public Key)
ssh_auth_keys = "Enter your Public SSH Key Here"

# VCN Config
vcn_name = "v7-Demo"
vcn_dns = "v7Demo"
vcn_cidr = "172.16.0.0/16"
pub_cidr = "172.16.10.0/24"
priv_cidr = "172.16.11.0/24"
provision_cidr = "172.16.0.0/25"

# SDDC Config
sddc_cidr = "172.16.0.0/21"
sddc_display_name = "Demo-SDDC-v7"
sddc_esxi_hosts_count = "3"
sddc_is_hcx_enabled = "true"
sddc_workload_network_cidr = "172.20.0.0/24"
sddc_instance_display_name_prefix = "sddc-ESXI"
sddc_repl_cidr = "172.16.4.0/25"
sddc_nsxEdgeUplink1_cidr = "172.16.0.128/25"
sddc_nsxEdgeUplink2_cidr = "172.16.1.0/25"
sddc_vSAN_cidr = "172.16.3.0/25"
sddc_vMotion_cidr = "172.16.2.128/25"
sddc_provision_cidr = "172.16.4.128/25"
sddc_HCX_cidr = "172.16.3.192/26"
sddc_NSX-VTEP_cidr = "172.16.2.0/25"
sddc_vSphere_cidr = "172.16.3.128/26"
sddc_NSX-Edge-VTEP_cidr = "172.16.1.128/25"

# VMware Software Version - The version being deployed should not have "#"
sddc_version = "7.0 update 1"
#sddc_version = "6.7 update 3"
#sddc_version = "6.5 update 3"
