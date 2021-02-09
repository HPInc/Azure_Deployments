# Teradici CAS Deployments on Azure
Teradici is the creator of the PCoIP remoting protocol technology and Cloud Access Software. Teradici's Cloud Access Software enables highly-scalable and cost-effective deployments by managing cloud compute costs and brokering PCoIP connections to remote Windows or Linux workstations. The Cloud Access Manager solution is comprised of two main components – the CAS Manager service, which is a service offered by Teradici to manage Cloud Access Manager deployments, and the Cloud Access Connector, which is the portion of the Cloud Access Manager solution that resides in the customer environment.  To learn more about Cloud Access Manager, visit https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/

This repository contains a collection of Terraform scripts for demonstrating how to deploy Cloud Access Connectors in a user's Azure cloud environments. __Note: These scripts are suitable for creating reference deployments for demonstration, evaluation, or development purposes. The infrastructure created may not meet the reliability, availability, or security requirements of your organization.__

# Documentation
- **Microsoft Azure:**
  - [Single-Connector Deployment](https://github.com/teradici/Azure_Deployments/blob/master/terraform-deployments/docs/README-azure-single-deployment.md)
  - [Load Balancer (Multi-connector) Deployment](https://github.com/teradici/Azure_Deployments/blob/master/terraform-deployments/docs/README-azure-load-balancer.md)
- [Amazon Web Services](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [Google Cloud Platform](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)

# Directory structure
## deployments/
The top level terraform scripts that create specific deployments.

## docs/
Description and instructions for different deployments and architectures.

## modules/
The building blocks of deployments, e.g. a Domain Controller, a Cloud Access
Connector, a Workstation, etc.


# Maintainer
If any security issues or bugs are found, or if there are feature requests, please contact Bob Ljujic at bljujic@teradici.com
