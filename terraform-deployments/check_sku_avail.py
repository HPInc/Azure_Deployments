# HP Teradici Check SKU Availability
#
# This script was made as an additional optional step to help prevent issues regarding SKU availability under
# Microsoft Azure subscriptions resulting in Terraform deployment errors.
#
# This script is meant to be run within the environment of the Azure Cloud Shell, and is not intended to be run
# in a local environment.
#
# TODO: add more flexibiility to CAC and CAS Manager VM checks. Original creation of this script uses 
# CAS Manager SaaS deployment var files.
#
# Last Updated: 07/15/2022

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

# General logging of process
LOG_FILE = "sku_availability_check.log"

# File to collect availability statuses from Azure Cloud Shell commands
VM_AVAILABILITY_FILE = "./current-sku-status.txt"

# Locations to find intended VM sizes for architecture components
DEFAULT_CAC_VM_SIZE_FILE = "./modules/cac/cac-vm/default-vars.tf"
DEFAULT_CASM_VM_SIZE_FILE = "./modules/cas-mgr/vars.tf"
DEFAULT_DC_VM_SIZE_FILE = "./modules/dc/dc-vm/default-vars.tf"

# Locations to update if VM sizes are unavailable
CAC_VM_SIZE_SET_FILE = "./modules/cac/cac-vm/main.tf"
CASM_VM_SIZE_SET_FILE = "./modules/cas-mgr/main.tf"
DC_VM_SIZE_SET_FILE = "./modules/dc/dc-vm/main.tf"

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

def extract_default_sizes(vm_type):
    SIZE_FILE = None
    VAR_LINE = ""

    if vm_type == "CAC":
        SIZE_FILE = DEFAULT_CAC_VM_SIZE_FILE
        VAR_LINE = "variable \"machine_type\""
    if vm_type == "CAS Manager":
        SIZE_FILE = DEFAULT_CASM_VM_SIZE_FILE
        VAR_LINE = "variable \"machine_type\""
    if vm_type == "DC":
        SIZE_FILE = DEFAULT_DC_VM_SIZE_FILE
        VAR_LINE = "variable \"dc_machine_type\""

    default_size_file = open(SIZE_FILE, 'r')
    in_var_block = False
    vm_sizes = []

    for line in default_size_file:
        if line.find(VAR_LINE) != -1:
            in_var_block = True
            continue
        if line.find("default") != -1 and in_var_block and (line.find("#") == -1 or line.find("#") > line.find("default")):
            vm_sizes = line[line.index("[")+1:line.index("]")].replace("[", "").replace("]", "").replace(", ", " ").replace("\"", "").split(" ")
            log("Default values found for " + vm_type + ": " + str(vm_sizes))
            break
        if line.find("\}") != -1 and in_var_block:
            log("Did not find any set values for the " + vm_type + ".")
            raise MissingDefaultSizesError()
    return vm_sizes


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
        for line in sku_file:
            if line.find(vm_sizes[i]) != -1:
                if line.find("NotAvailableForSubscription") != -1:
                    log("SKU size " + vm_sizes[i] + " is not available for this subscription")
                    break
                sku_file.close()
                log("SKU size " + vm_sizes[i] + " is highest priority for " + vm_type + " that is available")
                return i
    
    log("SKU sizes for " + vm_type + " did not return any information. Please check the list of sizes requested for this component or the region to search.")
    raise InvalidSKUSizeError()

def set_sku_size(set_file, idx):
    edit_file = open(set_file, "r")
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
        
    edit_file.close()

    edit_filewrite = open(set_file, "w")
    edit_filewrite.write(replacement)
    edit_filewrite.close()

    log("File edit complete. Changes may be verified in " + set_file)

def main():
    # Define parameters
    # - location (required) : the region in which to check for SKU sizes; this should be specified as the same as the desired workstations' region
    # - no_casm_vm          : whether or not the deployment will include CAS Manager as a separate VM; specify when indicating using CASM SaaS or other
    # - no_ldc              : whether or not the deployment will require a Local Domain Controller; specify when indicating using Azure AD Domain Services

    parser = argparse.ArgumentParser()
    parser.add_argument("-l", "--location", metavar="AAA", choices=REGIONS, required=True, help="Region to check for VM sizes")
    parser.add_argument("--no-casm-vm", default=False, dest="no_casm_vm", 
                        action='store_true', help="Flag for CAS Manager VM; True when using SaaS")
    parser.add_argument("--no-ldc", default=False, dest="no_ldc", action='store_true', help="Flag for DC VM; True when using AADDS")
    args = parser.parse_args()

    open(VM_AVAILABILITY_FILE, "a+").close()

    log("Querying for SKU sizes in location \"" + args.location + "\"")
    # TODO: should be taking from cac/cac-vm/
    # ... this varies depending on the deployment type, should we add a param for deployment types
    log("Finding default SKU sizes for CAC-VM...")
    cac_sizes = extract_default_sizes("CAC")
    log("Checking availability of default CAC VM sizes...")
    check_sku_sizes(cac_sizes, args.location)
    available_sku_idx = determine_sku_size("CAC", cac_sizes)
    log("Setting VM size index for CAC VM...")
    set_sku_size(CAC_VM_SIZE_SET_FILE, available_sku_idx)

    if not args.no_casm_vm:
        # TODO: should be going from modules/cas-mgr-* based on deployment
        log("Finding default SKU sizes for CAS Manager VM...")
        casm_sizes = extract_default_sizes("CAS Manager")
        log("Checking availability of default CAS Manager VM sizes...")
        check_sku_sizes(casm_sizes, args.location)
        available_sku_idx = determine_sku_size("CAS Manager", casm_sizes)
        log("Setting VM size index for CAS Manager VM...")
        set_sku_size(CASM_VM_SIZE_SET_FILE, available_sku_idx)

    if not args.no_ldc:
        log("Finding default SKU sizes for Domain Controller VM...")
        dc_sizes = extract_default_sizes("DC")
        log("Checking availability of default Domain Controller VM sizes...")
        check_sku_sizes(dc_sizes, args.location)
        available_sku_idx = determine_sku_size("DC", dc_sizes)
        log("Setting VM size index for Domain Controller...")
        set_sku_size(DC_VM_SIZE_SET_FILE, available_sku_idx)

    subprocess.run(["rm", VM_AVAILABILITY_FILE])
    log("SKU availability check completed.\n")

if __name__ == "__main__":
    main()