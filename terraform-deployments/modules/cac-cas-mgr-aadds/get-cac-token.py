#!/usr/bin/env python3

# Copyright (c) 2021 Teradici Corporation
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import datetime
import json
import requests


def create_connector_name():
    """A function to create a custom connector name

    Uses metadata server to access instance data, which is used to create the connector name.

    Returns:
        string: a string for the connector name
    """

    imds_server_base_url = "http://169.254.169.254"
    instance_api_version = "2019-03-11"

    instance_endpoint = imds_server_base_url + \
        "/metadata/instance?api-version=" + instance_api_version

    proxies = {
        "http": None,
        "https": None
    }
    headers = {'Metadata': 'True'}

    iso_time = datetime.datetime.utcnow().isoformat(
        timespec='seconds').replace(':', '').replace('-', '') + 'Z'

    response = requests.get(
        instance_endpoint, headers=headers, proxies=proxies).json()

    location = response['compute']['location']
    name = response['compute']['resourceGroupName']

    connector_name = f"{location}-{name}-{iso_time}"

    return connector_name


def load_service_account_key(path):
    print(f"Loading CAS Manager deployment service account key from {path}...")

    with open(path) as f:
        dsa_key = json.load(f)

    return dsa_key


def cas_mgr_login(key):
    print(f"Signing in to CAS Manager with key {key['keyName']}...")

    payload = {
        'username': key['username'],
        'password': key['apiKey'],
    }
    resp = session.post(
        f"{cas_mgr_api_url}/auth/signin",
        json=payload,
        verify=False
    )

    resp.raise_for_status()

    token = resp.json()['data']['token']
    session.headers.update({"Authorization": token})


def get_cac_token(key, connector_name):
    print(f"Creating a CAC token in deployment {key['deploymentId']}...")

    payload = {
        'deploymentId': key['deploymentId'],
        'connectorName': connector_name,
    }
    resp = session.post(
        f"{cas_mgr_api_url}/auth/tokens/connector",
        json=payload,
    )
    resp.raise_for_status()

    return resp.json()['data']['token']


def token_write(token, path):
    print(f"Writing CAC token to {path}...")
    with open(path, 'w') as f:
        f.write(token)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="This script uses CAS Manager Deployment Service Account JSON file to create a new CAC token.")

    parser.add_argument(
        "cas_mgr", help="specify the path to CAS Manager Deployment Service Account JSON file")
    parser.add_argument("--out", required=True,
                        help="File to write the CAC token")
    parser.add_argument(
        "--url", default="https://cas.teradici.com", help="specify the api url")
    parser.add_argument("--insecure", action="store_true",
                        help="Allow unverified HTTPS connection to CAS Manager")

    args = parser.parse_args()

    cas_mgr_api_url = f"{args.url}/api/v1"

    # Set up session to be used for all subsequent calls to CAS Manager
    session = requests.Session()
    if args.insecure:
        session.verify = False

    dsa_key = load_service_account_key(args.cas_mgr)
    cas_mgr_login(dsa_key)
    connector_name = create_connector_name()
    cac_token = get_cac_token(dsa_key, connector_name)
    token_write(cac_token, args.out)
