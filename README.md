# Finopay Web Infrastructure 
This is a 2-tier web application infrastructure for the Finopay application. It is hosted on Azure Cloud and the infrastructure is managed using Terraform.


## Architecture Diagram
<p text-align=center>
<img src=./assets/finopay.drawio.png width=90% >
</p>

## Deployment Instructions
### Step 1: *Configure a remote backend*
We could set this up using a separate terraform config or directly on the portal. But for simplicity, I did it on the portal for this POC. Here's how...

In Azure, create a storage account and create a container in the storage account. Then configure the storage account networking settings to meet your access and security needs.

Next, go to [./dev/providers.tf](./dev/providers.tf) and update the backend configuration with the value of your `resource group`, `storage account`, `container` and desired `key` (name of the state file).

Next, go to the [/dev](./dev/) folder and run `terraform init` to ensure the configuration works.

```hcl
terraform {
  ...
  backend "azurerm" {
    resource_group_name  = "<insert_value>"
    storage_account_name = "<insert_value>"
    container_name       = "<insert_value>"
    key                  = "dev/terraform.tfstate"
  }
}
```

### Step 2: *Configure OIDC for GitHub Actions*
We need to configure Open ID Connect (OIDC) to allow our pipelines access our Azure subscripton to create resources.

To do so, [follow this guide here](https://thomasthornton.cloud/2025/02/27/deploying-to-azure-secure-your-github-workflow-with-oidc/).

> Ensure the following secrets are configured...

<p text-align=center>
<img src=./assets/secrets.png width=90% >
</p>


### Step 3: *Deploy Using GitHub Actions*
Once the OIDC is configured, next do a test by manually triggering the `Dev - TF Plan on PR` pipeline in GitHub Actions. If the plan pipeline runs without any errors, we can run the Terrafrom apply pipeline named `Dev - TF Apply`.
It should look something like the following a successful run...

<p text-align=center>
<img src=./assets/pipeline.png width=90% >
</p>

### Step 4: Clean Up
To clean up (or destroy) the infrastructure, run the `Dev - TF Destroy` pipeline. 

We have Azure Recovery Services Vault configured, so you might get an error like this:
```
...unexpected status 400 (400 Bad Request) with error: ServiceResourceNotEmptyWithBackendMessage: Recovery Services vault cannot be deleted as there are backup items still present in soft delete state. Visit the following link for the steps to permanently delete soft deleted items: https://aka.ms/undeletesoftdeleteditems.
...
```

If the service is no longer needed, remove it via the portal and re-run the pipeline.  The pipeline should successfully delete all resources this time.



## Possible Improvements
- Build dependencies (like Terraform and Azure cli) into a custom image to speed up the pipelines.
- Add YouTube walkthrough / Demo video

## Extras
- [OIDC Setup](https://thomasthornton.cloud/2025/02/27/deploying-to-azure-secure-your-github-workflow-with-oidc/)
- See the Terraform docs here: [Terraform Docs](./dev/README.md)
