#!/usr/bin/env python3

# Copyright (c) 2022 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import datetime
import json
import os
import re
import subprocess
import sys
import time
import cam
import textwrap
import getpass

DEFAULT_REGION      = "westus2"
DEFAULT_NUMBEROF_WS = "0"
DEFAULT_PREFIX      = "quick"

def configurations_get(ws_types, username):

    def reg_code_get(order_number):
        print(f"{order_number}.  Please enter your PCoIP Registration Code.")
        print("    If you don't have one, visit: https://www.teradici.com/compare-plans.")
        while True:
                pcoip_registration_code = input("pcoip_registration_code: ").strip()
                if re.search(r"^[0-9A-Z]{12}@([0-9A-F]{4}-){3}[0-9A-F]{4}$", pcoip_registration_code, re.IGNORECASE):
                    return pcoip_registration_code
                print("Invalid PCoIP Registration Code format (Ex. ABCDEFGHIJKL@0123-4567-89AB-CDEF). Please try again.")

    def api_token_get(order_number):
            print(f"{order_number}.  Please enter the CAS Manager API token.")
            print("    Log into https://cas.teradici.com, click on your email address on the top right and select \"Get API token\".")
            while True:
                api_token = input("api_token: ").strip()
                mycasmgr = cam.CloudAccessManager(api_token)
                print("Validating API token with CAS Manager...", end="")
                if (mycasmgr.auth_token_validate()):
                    print("Yes")
                    return api_token
                print("\nInvalid CAS Manager API token. Please try again.")

    def answer_is_yes(prompt):
            while True:
                response = input(prompt).lower()
                if response in ('y', 'yes'):
                    return True
                if response in ('n', 'no'):
                    return False

    def numberof_ws_get(machine):
        while True:
            try:
                number = int(input(f"       Number of ({machine}): ").strip() or DEFAULT_NUMBEROF_WS)
                if (number < 0):
                    raise ValueError
                return str(number)
            except ValueError:
                print("       Invalid number input. ", end="")
            print("Please try again.")

    def ad_password_get(username):
            txt = r'''
            Please enter a password for the Active Directory Administrator.
            Note Windows passwords must be at least 7 characters long and meet complexity
            requirements:
            1. Must not contain user's account name or display name
            2. Must have 3 of the following categories:
            - a-z
            - A-Z
            - 0-9
            - special characters: ~!@#$%^&*_-+=`|\(){}[]:;"'<>,.?/
            - unicode characters
            See: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
            '''
            print(textwrap.dedent(txt))

            while True:
                password1 = getpass.getpass('Enter a password: ').strip()
                if not ad_password_validate(password1, username):
                    print("Please try again.")
                    continue
                password2 = getpass.getpass('Re-enter the password: ').strip()
                if password1 == password2:
                    break
                print(f'The passwords do not match. Please try again.')
            print('')

            return password1

    def ad_password_validate(password, username):
            # delimeters are specified in the microsoft documentation
            username_parsed = re.split("[—,.\-\_#\s\t]", username)
            for u in username_parsed:
                if len(u) < 3:
                    continue
                if re.search(u, password, re.IGNORECASE):
                    print("Password cannot contain username.", end=' ')
                    return False

            if len(password) < 7:
                print("Password must be at least 7 characters long.", end=' ')
                return False

            count = 0

            # check lowercase, uppercase, digits, special characters
            checks = ["[a-z]", "[A-Z]", "\d", "[@$!%*#?&]"]
            for regex in checks:
                if re.search(regex, password):
                    count += 1

            # check unicode: if the password contains unicode characters, 
            # it will change when encoded to utf-8 to one of [\u00d8-\u00f6]
            if f'b\'{password}\'' != f'{password.encode("utf-8")}':
                count += 1

            if (count > 2):
                return True
            print("Password does not meet the complexity requirements.", end=' ')
            return False

    # Print options 1,2,3... and ask for a number input
    def number_option_get(options, text):
        for i in range(len(options)):
            print("       ", options[i][0])
        while True:
            try:
                selection = int(input(f"        {text}: ").strip())
                if selection > 0:
                    return options[selection-1][1]  
                raise IndexError
            except (ValueError, IndexError):
                print(f"       Please enter a valid option (Ex. 1).")

    def region_get(order_number):
        regions_list = [("1. West US","westus"), ("2. West US 2","westus2"), ("3. West US 3","westus3"), ("4. East US","eastus"), ("5. East US 2","eastus2"), ("6. North Central US", "northcentralus"), ("7. South Central US", "southcentralus"), ("8. West Central US","westcentralus")]
        print(f"    {order_number}. Please enter the region to deploy in.")
        return number_option_get(regions_list, "Azure_region")
        
    while True:
        cfg_data = {}
        ws_count = 0 # Variable to keep track of workstations count

        cfg_data['pcoip_registration_code'] = reg_code_get("1")
        print("\n")

        cfg_data['api_token'] = api_token_get("2")
        print("\n")

        print(f"3.  The default region is {DEFAULT_REGION}.")
        customize = not answer_is_yes("    Would you like to continue with the default selections (y/n)? ")
        while True:
            if customize:
                print("    Getting Azure regions list...")
                print("")
                cfg_data['region'] = region_get("3.1")
                break
            else:
                cfg_data['region'] = DEFAULT_REGION
                break

        print("\n")
        print(f"4.  Please enter the number of remote workstations to create (Default: {DEFAULT_NUMBEROF_WS}).")
        for machine in ws_types:
            print("")
            cfg_data[machine] = numberof_ws_get(machine)


        print("#######################################")
        print("# Please review your selections below #")
        print("#######################################")
        print("{:<10} {:<10}".format('VARIABLE', 'VALUE'))
        for variable, value in cfg_data.items():
            print("{:<10} {:<10}".format(variable, value))

        if not answer_is_yes("\nWould you like to proceed with your selections (y/n)? "):
            print("\n") 
            continue # back to the beginning of the get configurations while loop
            
        print("")
        cfg_data['ad_admin_password'] = ad_password_get(username)
        cfg_data['safe_mode_admin_password'] = cfg_data['ad_admin_password']
        return cfg_data # Return to quickstart executable script