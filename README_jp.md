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

To use these workflows in your environment several prerequisite steps are required:

1. **Configure Terraform State Location**

    Terraform utilizes a [state file](https://www.terraform.io/language/state) to store information about the current state of your managed infrastructure and associated configuration. This file will need to be persisted between different runs of the workflow. The recommended approach is to store this file within an Azure Storage Account or other similar remote backend. Normally, this storage would be provisioned manually or via a separate workflow. The [Terraform backend block](main.tf#L10-L16) will need updated with your selected storage location (see [here](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm) for documentation).

    GitHub Copilot: アジュールストレージアカウントまたは他の類似のリモートバックエンドにこのファイルを保存することが推奨されているため、Terraformは現在の管理されたインフラストラクチャと関連する構成に関する情報を保存するために[ステートファイル](https://www.terraform.io/language/state)を使用します。通常、このストレージは別のワークフローを介して手動でまたは自動的にプロビジョニングされます。[Terraformバックエンドブロック](main.tf#L10-L16)を選択したストレージ場所に更新する必要があります（ドキュメントについては[こちら](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)を参照してください）。

2. **Create GitHub Environment**

    The workflows utilizes GitHub Environments and Secrets to store the azure identity information and setup an approval process for deployments. Create an environment named `production` by following these [insturctions](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment). On the `production` environment setup a protection rule and add any required approvers you want that need to sign off on production deployments. You can also limit the environment to your main branch. Detailed instructions can be found [here](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules).

   ワークフローは、AzureのID情報を保存し、展開の承認プロセスを設定するために、GitHub EnvironmentsとSecretsを利用しています。[こちらの手順](https://docs.github.com/ja/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment)に従って、`production`という名前の環境を作成してください。`production`環境で保護ルールを設定し、本番展開に署名する必要がある必要な承認者を追加してください。また、環境をメインブランチに制限することもできます。詳細な手順は[こちら](https://docs.github.com/ja/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules)を参照してください。

3. **Setup Azure Identity**: 

    An Azure Active Directory application is required that has permissions to deploy within your Azure subscription. Create a separate application for a `read-only` and `read/write` accounts and give them the appropriate permissions in your Azure subscription. In addition, both roles will also need at least `Reader and Data Access` permissions to the storage account where the Terraform state from step 1 resides. Next, setup the federated credentials to allow GitHub to utilize the identity using OIDC. See the [Azure documentation](https://docs.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#use-the-azure-login-action-with-openid-connect) for detailed instructions. 
    
    For the `read/write` identity create 1 federated credential as follows:
    - Set `Entity Type` to `Environment` and use the `production` environment name.

    For the `read-only` identity create 2 federated credentials as follows:
    - Set `Entity Type` to `Pull Request`.
    - Set `Entity Type` to `Branch` and use the `main` branch name.

    Azureサブスクリプション内で展開するために必要なAzure Active Directoryアプリケーションが必要です。 `読み取り専用` と `読み取り/書き込み` アカウント用に別々のアプリケーションを作成し、Azureサブスクリプションで適切な権限を与えてください。さらに、両方のロールは、ステップ1でTerraformステートが存在するストレージアカウントに対して少なくとも `Reader and Data Access` 権限も必要です。次に、OIDCを使用してアイデンティティを利用するために、GitHubがフェデレーション認証情報を設定する必要があります。詳細な手順については、[Azureドキュメント](https://docs.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#use-the-azure-login-action-with-openid-connect)を参照してください。

    For the `read/write` identity create 1 federated credential as follows:
    - Set `Entity Type` to `Environment` and use the `production` environment name.

    For the `read-only` identity create 2 federated credentials as follows:
    - Set `Entity Type` to `Pull Request`.
    - Set `Entity Type` to `Branch` and use the `main` branch name.

SPの作成
```
az ad app create --display-name terraform-r
az ad sp create --id $appId
az role assignment create --role contributor --subscription $subscriptionId --assignee-object-id  $assigneeObjectId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName
```


フェデレーション資格情報の作成
```
az ad app federated-credential create --id <APPLICATION-OBJECT-ID> --parameters credential.json
("credential.json" contains the following content)
{
    "name": "<CREDENTIAL-NAME>",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:octo-org/octo-repo:environment:Production",
    "description": "Testing",
    "audiences": [
        "api://AzureADTokenExchange"
    ]
}
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
    
GitHub Copilot: _注: AzureのID情報には秘密や資格情報は含まれていませんが、環境ごとにID情報をパラメータ化するためにGitHub Secretsを利用しています。_

以下のシークレットを、`read-only`のID情報を使用してリポジトリに作成してください。

- `AZURE_CLIENT_ID` : Azureでのアプリケーション登録のアプリケーション (クライアント) ID
- `AZURE_TENANT_ID` : アプリケーション登録が定義されているAzure Active DirectoryのテナントID。
- `AZURE_SUBSCRIPTION_ID` : アプリケーション登録が定義されているサブスクリプションID。

リポジトリにシークレットを追加する手順は[こちら](https://docs.github.com/ja/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)を参照してください。

さらに、`read-write`のID情報を使用して、`production`環境に別のシークレットを作成してください。

- `AZURE_CLIENT_ID` : Azureでのアプリケーション登録のアプリケーション (クライアント) ID

環境にシークレットを追加する手順は[こちら](https://docs.github.com/ja/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment)を参照してください。環境シークレットは、昇格された読み取り/書き込み権限が必要な`production`環境へのデプロイステップで、リポジトリシークレットを上書きします。

## Additional Resources

A companion article detailing how to use GitHub Actions to deploy to Azure using IaC can be found at the [DevOps Resource Center](). `TODO: add link`
