# GitHub Actions Workflows for Terraform

This is a sample repository that shows how to use GitHub Actions workflows to manage Azure infrastructure with Terraform. 

## Architecture

<img width="2159" alt="GitHub Actions CICD for Terraform" src="https://user-images.githubusercontent.com/1248896/189254453-439dd558-fc6c-4377-b01c-d5e54cc49403.png">

## Dataflow

1. Create a new branch and check in the needed Terraform code modifications.
2. Create a Pull Request (PR) in GitHub once you're ready to merge your changes into your environment.
3. A GitHub Actions workflow will trigger to ensure your code is well formatted, internally consistent, and produces secure infrastructure. In addition, a Terraform plan will run to generate a preview of the changes that will happen in your Azure environment.
4. Once appropriately reviewed, the PR can be merged into your main branch.
5. Another GitHub Actions workflow will trigger from the main branch and execute the changes using Terraform.
6. A regularly scheduled GitHub Action workflow should also run to look for any configuration drift in your environment and create a new issue if changes are detected.

## Workflows

1. [**Terraform Unit Tests**](.github/workflows/tf-unit-tests.yml)

    This workflow runs on every commit and is composed of a set of unit tests on the infrastructure code. It runs [terraform fmt]( https://www.terraform.io/cli/commands/fmt) to ensure the code is properly linted and follows terraform best practices. Next it performs [terraform validate](https://www.terraform.io/cli/commands/validate) to check that the code is syntactically correct and internally consistent. Lastly, [checkov](https://github.com/bridgecrewio/checkov), an open source static code analysis tool for IaC, will run to detect security and compliance issues. If the repository is utilizing GitHub Advanced Security (GHAS), the results will be uploaded to GitHub.

2. [**Terraform Plan / Apply**](.github/workflows/tf-plan-apply.yml)

    This workflow runs on every pull request and on each commit to the main branch. The plan stage of the workflow is used to understand the impact of the IaC changes on the Azure environment by running [terraform plan](https://www.terraform.io/cli/commands/plan). This report is then attached to the PR for easy review. The apply stage runs after the plan when the workflow is triggered by a push to the main branch. This stage will take the plan document and [apply](https://www.terraform.io/cli/commands/apply) the changes after a manual review has signed off if there are any pending changes to the environment.

3. [**Terraform Drift Detection**](.github/workflows/tf-drift.yml)

    This workflow runs on a periodic basis to scan your environment for any configuration drift or changes made outside of terraform. If any drift is detected, a GitHub Issue is raised to alert the maintainers of the project.

## Getting Started

To use these workflows in your environment some prerequisite steps are required. Ensure to be in the Azure subscription/tenant where you want to deploy your infrastructure before going through the following steps.

```bash
    # Retrieve the available Azure subscriptions and tenants ID
    $ az account list
    $ az account tenant list

    # Set the wanted subscription and tenant ID
    az account set --subscription <AZURE_SUBSCRIPTION>
```

1. **Configure Terraform State Location**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within an Azure Storage Account or other similar remote backend. Normally, this storage would be provisioned manually or via a separate workflow. The [Terraform backend block](main.tf#L10-L16) will need updated with your selected storage location (see [here](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm) for documentation).

    The following commands can be used to create the required Azure resources:
    ```bash
    $ az group create -n rg-terraform-github-actions-state
    $ az storage account create -n terraformgithubactions --resource-group rg-terraform-github-actions-state
    $ az storage container create --name tfstate --account-name terraformgithubactions    
    ```

2. **Create GitHub Environment**

    The workflows utilizes GitHub Environments and Secrets to store the azure identity information and setup an approval process for deployments. Create an environment named `production` by following these [instructions](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment). On the `production` environment setup a protection rule and add any required approvers you want that need to sign off on production deployments. You can also limit the environment to your main branch. Detailed instructions can be found [here](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules).

3. **Setup Azure Identity**: 

    An Azure Active Directory application is required that has permissions to deploy within your Azure subscription. Create a separate application for a `read-only` and `read/write` accounts and give them the appropriate permissions in your Azure subscription. In addition, both roles will also need at least `Reader and Data Access` permissions to the storage account where the Terraform state from step 1 resides. Next, setup the federated credentials to allow GitHub to utilize the identity using OIDC. See the [Azure documentation](https://docs.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#use-the-azure-login-action-with-openid-connect) for detailed instructions. 
    
    For the `read/write` identity create 1 federated credential as follows:
    - Set `Entity Type` to `Environment` and use the `production` environment name.

    For the `read-only` identity create 2 federated credentials as follows:
    - Set `Entity Type` to `Pull Request`.
    - Set `Entity Type` to `Branch` and use the `main` branch name.

    You can run the following commands to create and configure the read-write Azure identity (named `terraform-azure-rw-identity` below):
    ```bash
    # Create the SP
    $ az ad app create --display-name terraform-azure-rw-identity
    $ APPLICATION_ID=$(az ad app list --all --query "[?displayName=='terraform-azure-rw-identity'].appId" --output tsv)
    $ az ad sp create --id $APPLICATION_ID

    # Assign roles to the SP
    $ az role assignment create --assignee $APPLICATION_ID --role "Contributor"
    $ az role assignment create --assignee $APPLICATION_ID --role "Reader and Data Access"

    # Create the only OIDC credentials for that SP (for GitHub Actions "production" environment)
    # Be sure to replace <ORGANIZATION> and <REPOSITORY> with your GitHub organization and repository name
    $ cat <<EOF > oidc.json
    {
      "audiences": [
        "api://AzureADTokenExchange"
      ],
      "description": "",
      "issuer": "https://token.actions.githubusercontent.com",
      "name": "production-env-oidc",
      "subject": "repo:<ORGANIZATION>/<REPOSITORY>:environment:production"
    }
    EOF
    $ az ad app federated-credential create --id $APPLICATION_ID --parameters oidc.json
    ```

    You can run the following commands to create and configure the read-only Azure identity (named `terraform-azure-ro-identity` below):
    ```bash
    # Create the SP
    $ az ad app create --display-name terraform-azure-ro-identity
    $ APPLICATION_ID=$(az ad app list --all --query "[?displayName=='terraform-azure-ro-identity'].appId" --output tsv)
    $ az ad sp create --id $APPLICATION_ID

    # Assign roles to the SP
    $ az role assignment create --assignee $APPLICATION_ID --role "Reader"
    $ az role assignment create --assignee $APPLICATION_ID --role "Reader and Data Access"

    # Create the first OIDC credentials for that SP (for GitHub actions on pull requests)
    # Be sure to replace <ORGANIZATION> and <REPOSITORY> with your GitHub organization and repository name
    $ cat <<EOF > oidc.json
    {
      "audiences": [
        "api://AzureADTokenExchange"
      ],
      "description": "Pull-Request OIDC for GHES Azure Terraform Reader app",
      "issuer": "https://token.actions.githubusercontent.com",
      "name": "pr-oidc",
      "subject": "repo:ghsioux-octodemo/ghes-deploy-terraform-azure:pull_request"
    }
    EOF
    $ az ad app federated-credential create --id $APPLICATION_ID --parameters oidc.json

    # Create the second OIDC credentials for that SP (for GitHub actions on the main branch)
    # Be sure to replace <ORGANIZATION> and <REPOSITORY> with your GitHub organization and repository name
    $ cat <<EOF > oidc.json
    {
      "audiences": [
        "api://AzureADTokenExchange"
      ],
      "description": "Main branch OIDC for GHES Azure Terraform Reader app",
      "issuer": "https://token.actions.githubusercontent.com",
      "name": "main-oidc",
      "subject": "repo:ghsioux-octodemo/ghes-deploy-terraform-azure:ref:refs/heads/main"
    }
    EOF
    $ az ad app federated-credential create --id $APPLICATION_ID --parameters oidc.json
    ```

4. **Add GitHub Secrets**

    _Note: While none of the data about the Azure identities contain any secrets or credentials we still utilize GitHub Secrets as a convenient means to parameterize the identity information per environment._

    Create the following secrets on the repository using the `read-only` identity:

    - `AZURE_CLIENT_ID` : The application (client) ID of the app registration in Azure
    - `AZURE_TENANT_ID` : The tenant ID of Azure Active Directory where the app registration is defined.
    - `AZURE_SUBSCRIPTION_ID` : The subscription ID where the app registration is defined.
    
    Instructions to add the secrets to the repository can be found [here](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository).
    
    Additionally create an additional secret on the `production` environment using the `read-write` identity:
    
    - `AZURE_CLIENT_ID` : The application (client) ID of the app registration in Azure

    Instructions to add the secrets to the environment can be found [here](https://docs.github.com/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment). The environment secret will override the repository secret when doing the deploy step to the `production` environment when elevated read/write permissions are required.

    The following commands can be used to set up the above GitHub Secrets:
    ```bash
    # Switch to the repo's directory
    $ cd terraform-github-actions

    # Set repository default secrets
    # Be sure to replace <AZURE_SUBSCRIPTION> with the name of your Azure subscription
    $ AZURE_CLIENT_ID=$(az ad app list --all --query "[?displayName=='terraform-azure-ro-identity'].appId" --output tsv)
    $ AZURE_TENANT_ID=$(az account list --all --query "[?name=='<AZURE_SUBSCRIPTION>'].tenantId" --output tsv)
    $ AZURE_SUBSCRIPTION_ID=$(az account list --all --query "[?name=='<AZURE_SUBSCRIPTION>'].id" --output tsv)
    $ gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID"
    $ gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID"
    $ gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"

    # Set secret for the production environment
    $ AZURE_CLIENT_ID=$(az ad app list --all --query "[?displayName=='terraform-azure-rw-identity'].appId" --output tsv)
    $ gh secret set AZURE_CLIENT_ID --body "$AZURE_CLIENT_ID" --env production
    ```
    
## Additional Resources

A companion article detailing how to use GitHub Actions to deploy to Azure using IaC can be found at the [DevOps Resource Center](). `TODO: add link`
