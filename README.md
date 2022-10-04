# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
**Your words here**

### Output
**Your words here**


=================


## Try with Azure CLI
# Create the Policy Definition (Subscription scope)
az policy definition create --name audit-existing-linux-vm-ssh-with-password --display-name "Audit existing Linux VMs that use password for SSH authentication" --description "This policy audits if a password is being used to authentication to a Linux VM" --rules https://raw.githubusercontent.com/thanhbao0390/azure-devops-p1/main/azurepolicy.rules.json --mode All

# Create the Policy Assignment
# Set the scope to a resource group; may also be a subscription or management group
az policy assignment create --name 'audit-existing-linux-vm-ssh-with-password-assignment' --display-name "Audit existing Linux VMs that use password for SSH authentication Assignment" --scope /subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName> --policy /subscriptions/<subscriptionId>/providers/Microsoft.Authorization/policyDefinitions/audit-existing-linux-vm-ssh-with-password


# Create a Terraform configuration. To deploy our configuration, we run the following commands:
terraform plan -out <filename>

terraform apply