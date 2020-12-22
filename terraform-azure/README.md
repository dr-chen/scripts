# Terraform Azure Demo

This currently contians a demo of setting up a VM in Azure with an attached data disk. Variables/settings can be modified in the Terraform (tf) files in this repository.

## Install Terraform on Mac
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew upgrade hashicorp/tap/terraform
```

## Initiate Terraform
```
terraform init
```

## Install Azure CLI 
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum

## On Mac, install via brew
```
brew update && brew install azure-cli
```

## Create an Azure subscription 
Log into your Microsoft Azure account with a web browser at portal.azure.com and create a subscription manually. Once created, click on the subscription name and inside the 'Overview' blade, there should be Subscription ID and Parent Management Group. Copy the Parent Management Group and use below for the --tenant argument.

Use the following commands to log into Azure and see your subscriptions:
```
az login --tenant (PARENT MANAGEMENT GROUP ID HERE)

az account list --all
```

## View Terraform's Planned Changes
```
terraform plan
```

If you have NOT logged in with the 'az login' command listed above, you will get an error like:

```
Error: Error building AzureRM Client: obtain subscription() from Azure CLI: Error parsing json result from the Azure CLI: Error waiting for the Azure CLI: exit status 1
```

Terraform plan will allow you to see what changes Terraform plans to make. Before running an apply (pushing your plan up to the cloud provider), make sure to go through main.tf and change disk_size_gb = 2000 or more for 2TB+ attached data disk.

Also, consider changing the vm_size in variables.tf with one of the VM Sizes from this link: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable?toc=/azure/virtual-machines/linux/toc.json&bc=/azure/virtual-machines/linux/breadcrumb/toc.json

Something like 'Standard_B4ms' or 'Standard_B8ms' depending on what you want to deploy in this demo. Make sure to update the vm_size value in variables.tf to reflect your changes.

In the main.tf a script is also called for setup.sh, feel free to modify this to run scripts if necessary.

## Confirm and Run Deployment
```
terraform apply
```

Terraform will begin the deployment and at the end it will output whatever fields wanted from 'outputs.tf'.

VM should be availble through the public DNS name, so you can access it with: ssh azadm@(PUBLIC DNS NAME HERE)

## Destroy Deployment
```
terraform destroy -force
```

This command will remove everything deployed but I've noticed that a 'NetworkWatcherRG' Resource Group is automatically created for the VM and may need to be removed after the fact. We should probably automate this.

Any questions? Feel free to contact me@me.com

## Misc Info

Terraform can generate a graphic that shows all the relationships between the variables.

Install Graphviz
http://www.graphviz.org/download/

Mac Users:
```
brew install graphviz
```

Once installed, you can run this command to generate a graph.
```
terraform graph | dot -Tsvg > graph.svg
```