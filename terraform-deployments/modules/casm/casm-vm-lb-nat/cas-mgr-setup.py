#!/usr/bin/env python3

# Copyright (c) 2021 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import json
import requests
import time

CAS_API_URL = "https://localhost/api/v1"
ADMIN_USER = "adminUser"


def cas_login(username, password):
    retries = 300
    i = 0
    while (i < retries):
        payload = {
            'username': username,
            'password': password,
        }
        resp = session.post(
            f"{CAS_API_URL}/auth/ad/login",
            json=payload,
        )
        if (resp.status_code == 200):
            token = resp.json()['data']['token']
            session.headers.update({"Authorization": token})
            break
        i += 1
        time.sleep(10)
        print("Retry Attempt #" + str(i))
    resp.raise_for_status()
    

def deployment_create(name, reg_code):
    payload = {
        'deploymentName':   name,
        'registrationCode': reg_code,
    }
    resp = session.post(
        f"{CAS_API_URL}/deployments",
        json=payload,
    )
    resp.raise_for_status()

    return resp.json()['data']


def deployment_key_create(deployment, name):
    payload = {
        'deploymentId': deployment['deploymentId'],
        'keyName': name
    }
    resp = session.post(
        f"{CAS_API_URL}/auth/keys",
        json=payload,
    )
    resp.raise_for_status()

    return resp.json()['data']


def deployment_key_write(deployment_key, path):
    with open(path, 'w') as f:
        json.dump(deployment_key, f)


def get_azure_sa_key(path):
    with open(path) as f:
        key = json.load(f)

    return key


def validate_azure_sa(key):
    payload = {
        'provider': 'azure',
        'credential': {
            'clientId': key['application_id'],
            'clientSecret': key['client_secret'],
            'tenantId': key['tenant_id']
        },
    }
    resp = session.post(
        f"{CAS_API_URL}/auth/users/cloudServiceAccount/validate",
        json=payload,
    )

    try:
        resp.raise_for_status()
        return True

    except requests.exceptions.HTTPError as e:
        # Not failing because Azure service account is optional
        print("Error validating Azure Service Account key.")
        print(e)

        if resp.status_code == 400:
            print(
                "ERROR: Azure Service Account key provided has insufficient permissions.")
            print(resp.json()['data'])

        return False


def deployment_add_azure_account(self, key, deployment):
    credentials = {
        'clientId': key['application_id'],
        'clientSecret': key['client_secret'],
        'tenantId': key['tenant_id']
    }

    payload = {
        'deploymentId': deployment['deploymentId'],
        'provider':     'azure',
        'credential':   credentials,
    }
    resp = session.post(
        f"{CAS_API_URL}/auth/users/cloudServiceAccount",
        json=payload,
    )

    try:
        resp.raise_for_status()

    except requests.exceptions.HTTPError as e:
        # Not failing because Azure service account is optional
        print("Error adding Azure Service Account to deployment.")
        print(e)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="This script updates the password for the Anyware Manager Admin user.")

    parser.add_argument("--deployment_name", required=True,
                        help="Anyware Manager deployment to create")
    parser.add_argument("--key_file", required=True,
                        help="path to write Deployment Service Account key JSON file")
    parser.add_argument("--key_name", required=True,
                        help="name of Anyware Manager Deployment Service Account key")
    parser.add_argument("--password", required=True,
                        help="new Anyware Manager administrator password")
    parser.add_argument("--reg_code", required=True,
                        help="PCoIP registration code")
    parser.add_argument(
        "--azure_key", help="Azure Service Account credential key path")

    args = parser.parse_args()

    # Set up session to be used for all subsequent calls to CAS Manager
    session = requests.Session()
    session.verify = False

    print("Creating Anyware Manager deployment...")
    cas_login(ADMIN_USER, args.password)
    deployment = deployment_create(args.deployment_name, args.reg_code)
    cas_deployment_key = deployment_key_create(deployment, args.key_name)
    deployment_key_write(cas_deployment_key, args.key_file)

    if args.azure_key:
        azure_sa_key = get_azure_sa_key(args.azure_key)

        print("Validating Azure credentials with Anyware Manager...")
        valid = validate_azure_sa(azure_sa_key)

        if valid:
            print("Adding Azure credentials to Anyware Manager deployment...")
            deployment_add_azure_account(azure_sa_key, deployment)
        else:
            print(
                "WARNING: Azure credentials validation failed. Skip adding Azure credentials to Anyware Manager deployment.")
