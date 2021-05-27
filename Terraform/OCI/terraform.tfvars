# Enter your Tenancy OCID
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaarjmezrk7x6sdytr4qbpp36qulkilvvjjsmjod7tgnjzaqaxekkva"

# Enter your Compartment OCID
compartment_ocid = "XXX"

# Region to Deploy
# Get the Region Identifier - https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
region = "us-phoenix-1"

# SSH Key Pair (Public Key)
ssh_auth_keys = "Enter your Public SSH Key Here"

# Assign Private IPs
bastionIP = "172.16.10.10"
jumphostIP = "172.16.11.11"

# VCN Config
vcn_name = "labESXi7"
vcn_dns = "labESXi7"
vcn_cidr = "172.16.0.0/16"
pub_cidr = "172.16.10.0/24"
priv_cidr = "172.16.11.0/24"
provision_cidr = "172.16.0.0/25"

# SDDC Config
sddc_cidr = "172.16.0.0/21"
sddc_display_name = "labESXi7"
sddc_esxi_hosts_count = "3"
sddc_is_hcx_enabled = "true"
sddc_workload_network_cidr = "172.20.0.0/24"
sddc_instance_display_name_prefix = "labESXi7"
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

# Billing SKU
#sddc_initial_sku = "HOUR"
sddc_initial_sku = "MONTH"
#sddc_initial_sku = "ONE_YEAR"
#sddc_initial_sku = "THREE_YEARS"

# VMware Software Version - The version being deployed should not have "#"
sddc_version = "7.0 update 1"
#sddc_version = "6.7 update 3"
#sddc_version = "6.5 update 3"
