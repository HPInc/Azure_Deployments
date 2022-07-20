# HP Teradici Check SKU Availability
#
# This script was made as an additional optional step to help prevent issues regarding SKU availability under
# Microsoft Azure subscriptions resulting in Terraform deployment errors.
#
# This script is meant to be run within the environment of the Azure Cloud Shell, and is not intended to be run
# in a local environment.
#
# By default, the program will check for the SKU sizes being selected pertaining to the 
# CAS Manager Single Connector Standalone deployment.
# Other deployment types can be specified on the command line when executing
#
# TODO: add more flexibiility to CAC and CAS Manager VM checks.
#
# Last Updated: 07/20/2022

import subprocess
import time
import re
import argparse

# List of possible regions to search for VM sizes (all possibilities)
REGIONS=["eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
         "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope", "centralus",
         "southafricannorth", "centralindia", "eastasia", "japaneast", "koreacentral", "canadacentral",
         "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "brazilsouth", "eastus2euap",
         "centralusstage", "eastusstage", "eastus2stage", "northcentralusstage", "southcentralusstage",
         "westusstage", "westus2stage", "asia", "asiapacific", "australia", "brazil", "canada", "europe",
         "france", "germany", "global", "india", "japan", "korea", "norway", "singapore", "southafrica",
         "switzerland", "uae", "uk", "unitedstates", "unitedstateseuap", "eastasiastage", "southeastasiastage",
         "northcentralus", "westus", "jioindiawest", "uaenorth", "centraluseuap", "westcentralus", "southafricawest",
         "australiacentral", "australiacentral2", "australiasoutheast", "japanwest", "jioindiacentral", "koreasouth",
         "southindia", "westindia", "canadaeast", "francesouth", "germanynorth", "norwaywest", "switzerlandwest", "ukwest",
         "uaecentral", "brazilsoutheast"]

# List of deployment offerings
DEPLOYMENTS=["cas-mgr-load-balancer-one-ip-nat",
             "cas-mgr-one-ip-traffic-mgr",
             "cas-mgr-single-connector",
             "casm-aadds",
             "casm-aadds-one-ip-lb",
             "casm-aadds-one-ip-traffic-manager",
             "casm-aadds-single-connector",
             "lls-single-connector",
             "load-balancer-one-ip",
             "multi-region-traffic-mgr-one-ip",
             "quickstart-single-connector",
             "single-connector"]

# General logging of process
LOG_FILE = "sku_availability_check.log"

# File to collect availability statuses from Azure Cloud Shell commands
VM_AVAILABILITY_FILE = "./current-sku-status.txt"

# Locations to find intended VM sizes for architecture components
DEFAULT_CAC_VM_SIZE_FILES = ["./modules/cac-regional/vars.tf", "./modules/cac-regional-private/vars.tf"]
DEFAULT_CASM_VM_SIZE_FILES = ["./modules/cas-mgr/vars.tf"]
DEFAULT_DC_VM_SIZE_FILES = ["./modules/dc/dc-vm/default-vars.tf"]

# Locations to update if VM sizes are unavailable
CAC_VM_SIZE_SET_FILES = ["./modules/cac-regional/main.tf", "./modules/cac-regional-private/main.tf"]
CASM_VM_SIZE_SET_FILES = ["./modules/cas-mgr/main.tf"]
DC_VM_SIZE_SET_FILES = ["./modules/dc/dc-vm/main.tf"]

# Priority list of possible SKU sizes for Windows/Linux Standard Workstations (NOTE: prepend selected terraform.tfvars size to this list when checking availability)
STANDARD_SKUS_PRIORITY = ["Standard_B2s", "Standard_B2ms", "Standard_D2s_v3", "Standard_B4ms", "Standard_DS2_v2", "Standard_D4s_v3", "Standard_B8ms", "Standard_DS3_v2"]
GFX_SKUS_PRIORITY = ["Standard_NV4as_v4", "Standard_NV6"]

class MissingLocationError(Exception):
    pass

class MissingDefaultSizesError(Exception):
    pass

class InvalidSKUSizeError(Exception):
    pass

def log(msg):
    temp = open(LOG_FILE, "a")
    temp.write("[" + time.strftime("%Y-%m-%d %H:%M:%S") + "] " + msg + '\n')
    temp.close()
    print(msg)


def extract_default_sizes(vm_type, extract_file):
    VAR_LINES = []

    if vm_type == "CAC":
        VAR_LINES = ["variable \"machine_type\"", "variable \"cac_machine_type\""]
    if vm_type == "CAS Manager":
        VAR_LINES = ["variable \"machine_type\""]
    if vm_type == "DC":
        VAR_LINES = ["variable \"dc_machine_type\""]

    default_size_file = open(extract_file, 'r')
    in_var_block = False
    vm_sizes = []

    for line in default_size_file:
        if line.find("default") != -1 and in_var_block and (line.find("#") == -1 or line.find("#") > line.find("default")):
            vm_sizes = line[line.index("[")+1:line.index("]")].replace("[", "").replace("]", "").replace(", ", " ").replace("\"", "").split(" ")
            log("Default values found for " + vm_type + ": " + str(vm_sizes))
            break
        if line.find("\}") != -1 and in_var_block:
            log("Did not find any set values for the " + vm_type + ".")
            raise MissingDefaultSizesError()

        if not in_var_block:
            for i in range(len(VAR_LINES)):
                if line.find(VAR_LINES[i]) != -1:
                    in_var_block = True
                    break
    return vm_sizes


def update_sku_selection(vm_type, location, extract_file, edit_file):
    log("Finding default SKU sizes for " + vm_type + " VM...")
    sizes = extract_default_sizes(vm_type, extract_file)
    log("Checking availability of default " + vm_type + " VM sizes...")
    check_sku_sizes(sizes, location)
    available_sku_idx = determine_sku_size(vm_type, sizes)
    log("Setting VM size index for " + vm_type + " VM...")
    set_sku_size(edit_file, available_sku_idx)


def check_sku_sizes(vm_sizes, location):
    sku_file = open(VM_AVAILABILITY_FILE, "w")
    for i in range(len(vm_sizes)):
        log("-- Checking availability of VM size " + vm_sizes[i])
        sku_file.write(str(subprocess.check_output(["az", "vm", "list-skus", "--location", location, 
                                                                             "--size", vm_sizes[i], 
                                                                             "--all", 
                                                                             "--output", "table"])).replace("\\n", '\n'))
        # Separate the output of one command from the next
        sku_file.write('\n')
    sku_file.close()


def determine_sku_size(vm_type, vm_sizes):
    sku_file = open(VM_AVAILABILITY_FILE, "r")

    log("Determining available size for " + vm_type + " under current Azure subscription...")
    for i in range(len(vm_sizes)):
        sku_file.seek(0)
        for line in sku_file:
            if line.find(vm_sizes[i]) != -1:
                if line.find("NotAvailableForSubscription") != -1:
                    log("SKU size " + vm_sizes[i] + " is not available for this subscription in the current location")
                    break
                sku_file.close()
                log("SKU size " + vm_sizes[i] + " is highest priority for " + vm_type + " that is available")
                return i
    
    log("SKU sizes for " + vm_type + " did not return any information. Please check the list of sizes requested for this component or the region to search.")
    sku_file.close()
    raise InvalidSKUSizeError()


def set_sku_size(set_file, idx):
    edit_file = open(set_file, "r+")
    replacement = ""

    for line in edit_file:
        changes = re.sub('var.machine_type\[[0-9]*\]', 'var.machine_type[' + str(idx) + ']', line)
        changes_cac = re.sub('var.cac_machine_type\[[0-9]*\]', 'var.cac_machine_type[' + str(idx) + ']', line)
        changes_dc = re.sub('var.dc_machine_type\[[0-9]*\]', 'var.dc_machine_type[' + str(idx) + ']', line)

        if line != changes_cac:
            replacement += changes_cac
            continue
        if line != changes_dc:
            replacement += changes_dc
            continue
        replacement += changes
        
    edit_file.seek(0)
    edit_file.write(replacement)
    edit_file.close()

    log("File edit complete. Changes may be verified in " + set_file)

def check_workstations_for_deployment(deployment):
    tfvars_file = open("./deployments/" + deployment + "/terraform.tfvars", "r")

    tfvars_file.close()

# TODO: set files to edit
def assign_filenames(deployment):
    global DEFAULT_CAC_VM_SIZE_FILES
    global DEFAULT_CASM_VM_SIZE_FILES
    global DEFAULT_DC_VM_SIZE_FILES

    global CAC_VM_SIZE_SET_FILES
    global CASM_VM_SIZE_SET_FILES
    global DC_VM_SIZE_SET_FILES

    if deployment == "cas-mgr-single-connector":
        # DEFAULT_CAC and CAC_VM should be checked
        DEFAULT_CAC_VM_SIZE_FILES = ["./modules/cac-regional/vars.tf", "./modules/cac-regional-private/vars.tf"]
        CAC_VM_SIZE_SET_FILES = ["./modules/cac-regional/main.tf", "./modules/cac-regional-private/main.tf"]

        DEFAULT_CASM_VM_SIZE_FILES = ["./modules/cas-mgr/vars.tf"]
        CASM_VM_SIZE_SET_FILES = ["./modules/cas-mgr/main.tf"]

        DEFAULT_DC_VM_SIZE_FILES = ["./modules/dc/dc-vm/default-vars.tf"]
        DC_VM_SIZE_SET_FILES = ["./modules/dc/dc-vm/main.tf"]
    if deployment == "cas-mgr-load-balancer-one-ip-nat":
        pass
    if deployment == "cas-mgr-one-ip-traffic-mgr":
        pass
    if deployment == "casm-aadds":
        pass
    if deployment == "casm-aadds-one-ip-lb":
        pass
    if deployment == "casm-aadds-one-ip-traffic-manager":
        pass
    if deployment == "casm-aadds-single-connector":
        pass
    if deployment == "lls-single-connector":
        pass
    if deployment == "load-balancer-one-ip":
        pass
    if deployment == "multi-region-traffic-mgr-one-ip":
        pass
    if deployment == "quickstart-single-connector":
        pass
    if deployment == "single-connector":
        pass


def main():
    # Define parameters
    # - location (required) : the region in which to check for SKU sizes; this should be specified as the same as the desired workstations' region
    # - no_casm_vm          : whether or not the deployment will include CAS Manager as a separate VM; specify when indicating using CASM SaaS or other
    # - no_ldc              : whether or not the deployment will require a Local Domain Controller; specify when indicating using Azure AD Domain Services
    # - deployment          : the specific deployment type intended to be checked for future use; overrides no_casm_vm and no_ldc variables

    parser = argparse.ArgumentParser()
    parser.add_argument("-l", "--location", metavar="AAA", choices=REGIONS, required=True, help="Region to check for VM sizes")
    parser.add_argument("--no-casm-vm", default=False, dest="no_casm_vm", 
                        action='store_true', help="Flag for CAS Manager VM; True when using SaaS")
    parser.add_argument("--no-ldc", default=False, dest="no_ldc", action='store_true', help="Flag for DC VM; True when using AADDS")
    parser.add_argument("-d", "--deployment", default="cas-mgr-single-connector", dest="deployment", metavar="BBB", choices=DEPLOYMENTS, help="Specific deployment option, overrides --no-casm-vm and --no-ldc")
    args = parser.parse_args()

    assign_filenames(args.deployment)

    open(VM_AVAILABILITY_FILE, "a+").close()

    log("Querying for SKU sizes in location \"" + args.location + "\"")
    log("Selected deployment type: " + args.deployment)
    
    # TODO: should be taking from cac/cac-vm/
    # ... this varies depending on the deployment type, should we add a param for deployment types
    for a in range(len(DEFAULT_CAC_VM_SIZE_FILES)):
        update_sku_selection("CAC", args.location, DEFAULT_CAC_VM_SIZE_FILES[a], CAC_VM_SIZE_SET_FILES[a])

    if args.deployment in ["cas-mgr-single-connector", "cas-mgr-load-balancer-one-ip-nat", "cas-mgr-one-ip-traffic-mgr", 
                           "casm-aadds-single-connector", "casm-aadds-one-ip-lb", "casm-aadds-one-ip-traffic-manager"]:
        if not args.no_casm_vm:
            # TODO: should be going from modules/cas-mgr-* based on deployment
            for b in range(len(DEFAULT_CASM_VM_SIZE_FILES)):
                update_sku_selection("CAS Manager", args.location, DEFAULT_CASM_VM_SIZE_FILES[b], CASM_VM_SIZE_SET_FILES[b])

    if args.deployment in ["cas-mgr-single-connector", "cas-mgr-load-balancer-one-ip-nat", "cas-mgr-one-ip-traffic-mgr",
                           "lls-single-connector", "load-balancer-one-ip", "multi-region-traffic-mgr-one-ip", "quickstart-single-connector",
                           "single-connector"]:
        if not args.no_ldc:
            for c in range(len(DEFAULT_DC_VM_SIZE_FILES)):
                update_sku_selection("DC", args.location, DEFAULT_DC_VM_SIZE_FILES[c], DC_VM_SIZE_SET_FILES[c])

    # Time to check the terraform.tfvars of the deployment to check for workstation-selected SKUs
    log("Determining selected workstation SKUs for your deployment. Corresponding directory must contain a terraform.tfvars file and it should be renamed to remove the .sample extension.")
    check_workstations_for_deployment(args.deployment)


    subprocess.run(["rm", VM_AVAILABILITY_FILE])
    log("SKU availability check completed.\n")

if __name__ == "__main__":
    main()