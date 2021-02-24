#!/usr/bin/env python3

# Copyright (c) 2020 Teradici Corporation
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

CFG_FILE_PATH = 'azure-cloudshell-quickstart.cfg'
TERRAFORM_BIN_PATH = 'terraform'
iso_time = datetime.datetime.utcnow().isoformat(
    timespec='seconds').replace(':', '').replace('-', '') + 'Z'
DEPLOYMENT_NAME = "azure_quickstart_" + iso_time
CONNECTOR_NAME = 'quickstart_cac_' + iso_time

# All of the following paths are relative to the deployment directory, DEPLOYMENT_PATH
TF_VARS_REF_PATH = 'terraform.tfvars.sample'
TF_VARS_PATH = 'terraform.tfvars'
TF_STATE_PATH = 'terraform.tfstate'
TF_STATE_BACKUP_PATH = 'terraform.tfstate.backup'
AZ_KEY_VAULT_DIR = './az-key-vault'
SINGLE_CONNECTOR_DIR = '../../single-connector'

# User entitled to workstations
ENTITLE_USER = 'cam_admin'

# Types of workstations
WS_TYPES = ['scent', 'gcent', 'swin', 'gwin']

def quickstart_config_read(cfg_file):
    cfg_data = {}

    with open(cfg_file, 'r') as f:
        for line in f:
            if line[0] in ('#', '\n'):
                continue

            key, value = map(str.strip, line.split(':'))
            cfg_data[key] = value

    return cfg_data


def terraform_deploy():

    tf_cmd = f'{TERRAFORM_BIN_PATH} init'
    subprocess.run(tf_cmd.split(' '), check=True)

    tf_cmd = f'{TERRAFORM_BIN_PATH} apply -auto-approve'
    subprocess.run(tf_cmd.split(' '), check=True)


def deployment_outputs_get(output_name):

    deployment_outputs = json.loads(subprocess.run(
        ['terraform', 'output', '-json', output_name], capture_output=True, text=True).stdout)

    return deployment_outputs


# Creates a new .tfvar based on the .tfvar.sample file
def tf_vars_create(ref_file_path, tfvar_file_path, settings):

    with open(ref_file_path, 'r') as ref_file, open(tfvar_file_path, 'w') as out_file:
        for line in ref_file:

            # Comments and blank lines are unchanged
            if line[0] in ('#', '\n'):
                out_file.write(line)
                continue

            key = line.split('=')[0].strip()
            try:
                if key in ('workstations, cac_configuration'):
                    out_file.write('{} = {}\n'.format(key, settings[key]))
                    continue

                out_file.write('{} = "{}"\n'.format(key, settings[key]))

            except KeyError:
                # Remove file and error out
                os.remove(tfvar_file_path)
                print('Required value for {} missing. tfvars file {} not created.'.format(
                    key, tfvar_file_path))
                sys.exit(1)


def workstations_config_get(region, ws_count):

    return f'''[
            {{
                prefix           = "",
                location         = "{region}",
                workstation_os   = "linux",
                vm_size          = "Standard_B2ms",
                disk_type        = "Standard_LRS",
                disk_size        = 128,
                count            = {ws_count[0]},
                isGFXHost        = false
            }},
            {{
                prefix           = "",
                location         = "{region}",
                workstation_os   = "linux",
                vm_size          = "Standard_NC4as_T4_v3",
                disk_type        = "Standard_LRS",
                disk_size        = 128,
                count            = {ws_count[1]},
                isGFXHost        = true
            }},
            {{
                prefix           = "",
                location         = "{region}",
                workstation_os   = "windows",
                vm_size          = "Standard_B2ms",
                disk_type        = "Standard_LRS",
                disk_size        = 128,
                count            = {ws_count[2]},
                isGFXHost        = false
            }},
            {{
                prefix           = "",
                location         = "{region}",
                workstation_os   = "windows",
                vm_size          = "Standard_NC4as_T4_v3",
                disk_type        = "Standard_LRS",
                disk_size        = 128,
                count            = {ws_count[3]},
                isGFXHost        = true
            }}
        ]
        '''


def cac_connector_config_get(token, region):

    return f'''[
            {{
                cac_token = "{token}",
                location = "{region}"
            }}
        ]
        '''


def az_credential_get(command):
    process = subprocess.Popen(command.split(
        ' '), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = process.communicate()
    az_credential = output.decode('utf-8').strip()
    return az_credential


def deployment_delete():

    try:
        if not os.path.isfile(TF_VARS_PATH):
            print('No existing terraform deployment exists. Did you mean "python azure-cloudshell-quickstart.py"?')
            sys.exit(1)

        app_kv_destroy_cmd = f'{TERRAFORM_BIN_PATH} destroy -force'
        subprocess.run(app_kv_destroy_cmd.split(' '), check=True)

        os.chdir('../single-connector')
        resource_group_name = deployment_outputs_get('resource_group')

        print(f'Deleting resource group {resource_group_name}..')
        tf_destroy_cmd = f'az group delete -n {resource_group_name} --no-wait -y'
        subprocess.run(tf_destroy_cmd.split(' '), check=True)

        for filename in [TF_VARS_PATH, TF_STATE_PATH, TF_STATE_BACKUP_PATH]:
            try:
                os.remove(filename)
            except OSError:
                pass

        os.chdir('../quickstart-single-connector')
        for filename in [TF_VARS_PATH, TF_STATE_PATH, TF_STATE_BACKUP_PATH]:
            try:
                os.remove(filename)
            except OSError:
                pass

        print(f'Log in to https://cam.teradici.com and delete the deployment named azure_quickstart_<timestamp>')
        print('You may close Azure Cloud Shell.')

    except:
        print('There was a problem deleting the deployment.')
        print('Resource groups have been deleted or do not exist.')
        print('Please check for your resource groups on the Azure Portal and delete them manually.')


if __name__ == '__main__':

    if len(sys.argv) > 1 and sys.argv[1] == 'cleanup':
        deployment_delete()
        sys.exit()

    elif len(sys.argv) > 1 and sys.argv[1] != 'cleanup':
        print('Did you mean \'python azure-cloudshell-quickstart.py\' or \'python azure-cloudshell-quickstart.py cleanup\'?')
        print()
        sys.exit()

    cfg_data = quickstart_config_read(CFG_FILE_PATH)

    tf_vars_create(TF_VARS_REF_PATH, TF_VARS_PATH, {
                   'location': cfg_data.get('region')})
    terraform_deploy()
    az_app_outputs = deployment_outputs_get('ids')

    az_email_cmd = 'az ad signed-in-user show --query userPrincipalName -o tsv'
    az_email = az_credential_get(az_email_cmd)

    user_object_id_cmd = f'az ad user show --id {az_email} --query objectId --out tsv'
    user_object_id = az_credential_get(user_object_id_cmd)

    app_object_id_cmd = f'az ad sp list --display-name {az_app_outputs["application_name"]} --query [].objectId --out tsv'
    app_object_id = az_credential_get(app_object_id_cmd)

    subscription_id = az_app_outputs['subscription_id']

    my_cam = cam.CloudAccessManager(cfg_data.get('api_token'))

    print('Creating deployment {}...'.format(DEPLOYMENT_NAME))
    deployment = my_cam.deployment_create(
        DEPLOYMENT_NAME, cfg_data.get('pcoip_registration_code'))

    print('Adding cloud service account...')
    my_cam.deployment_add_azure_account(az_app_outputs, deployment)

    print('Creating connector token...')
    cac_token = my_cam.connector_create(CONNECTOR_NAME, deployment)['token']

    workstations_count = [cfg_data.get('scent'), cfg_data.get(
        'gcent'), cfg_data.get('swin'), cfg_data.get('gwin')]

    # Azure key vault deployment
    os.chdir(AZ_KEY_VAULT_DIR)
    az_key_vault_settings = {
        'object_id':                    user_object_id,
        'app_object_id':                app_object_id,
        'resource_group_name':          az_app_outputs['resource_group_name'],
        'application_name':             az_app_outputs['application_name'],
        'pcoip_registration_code':      cfg_data.get('pcoip_registration_code'),
        'ad_admin_password':            cfg_data.get('ad_admin_password'),
        'safe_mode_admin_password':     cfg_data.get('safe_mode_admin_password'),
        'cac_token':                    cac_token
    }

    tf_vars_create(TF_VARS_REF_PATH, TF_VARS_PATH, az_key_vault_settings)
    terraform_deploy()

    az_vault_outputs = deployment_outputs_get('key-vault-secrets')

    os.chdir(SINGLE_CONNECTOR_DIR)
    single_connector_settings = {
        'workstations':                 workstations_config_get(cfg_data.get('region'), workstations_count),
        'cac_configuration':            cac_connector_config_get(az_vault_outputs['cac_token'], cfg_data.get('region')),
        'pcoip_registration_code':      az_vault_outputs['pcoip_registration_code'],
        'ad_admin_password':            az_vault_outputs['ad_admin_password'],
        'safe_mode_admin_password':     az_vault_outputs['safe_mode_admin_password'],
        'ad_pass_secret_name':          az_vault_outputs['ad_pass_secret_name'],
        'key_vault_id':                 az_vault_outputs['key_vault_id'],
        'application_id':               az_app_outputs['application_id'],
        'aad_client_secret':            az_app_outputs['client_secret'],
        'tenant_id':                    az_app_outputs['tenant_id']
    }

    tf_vars_create('../quickstart-single-connector/single_connector_terraform.tfvars.sample',
                   TF_VARS_PATH, single_connector_settings)

    terraform_deploy()

    cac_public_ip = deployment_outputs_get('cac-vms')[0]['public_ip']
    resource_group_name = deployment_outputs_get('resource_group')
    print('Terraform deployment complete.\n')

    #  Add existing workstations
    for t in WS_TYPES:
        for i in range(int(cfg_data.get(t))):
            hostname = f'{t}-{i}'
            print(f'Adding "{hostname}" to Cloud Access Manager...')
            my_cam.machine_add_existing(
                hostname,
                az_app_outputs['subscription_id'],
                resource_group_name,
                deployment
            )

    # Loop until cam_admin user is found in CAM
    while True:
        entitle_user = my_cam.user_get(ENTITLE_USER, deployment)
        if entitle_user:
            break

        print(
            f'Waiting for user "{ENTITLE_USER}" to be synced. Retrying in 10 seconds...')
        time.sleep(10)

    # Add entitlements for each workstation
    machines_list = my_cam.machines_get(deployment)
    for machine in machines_list:
        print(
            f'Assigning workstation "{machine["machineName"]}" to user "{ENTITLE_USER}"...')
        my_cam.entitlement_add(entitle_user, machine)

    print('\nQuickstart deployment finished.\n')

    print('')
    next_steps = f"""
    Next steps:
    - Connect to a workstation:
    1. From a PCoIP client, connect to the Cloud Access Connector at {cac_public_ip}.
    2. Sign in with the "{ENTITLE_USER}" user credentials.
    3. When connecting to a workstation immediately after this script completes,
        the workstation (especially graphics ones) may still be setting up. Please wait a few
        minutes or reconnect if it times out.

    - Clean up:
    1. Use the command: "python azure-cloudshell-quickstart.py cleanup" to delete all resources.
        -   If an error message shows, manually delete resource groups on the Azure Portal.
    4. Log in to https://cam.teradici.com and delete the deployment named {DEPLOYMENT_NAME}
    """

    print(next_steps)
    print('')
