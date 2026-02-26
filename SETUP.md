# Setup (first-time)

This Terraform creates the **project** (optional), **environments**, and **jobs**. Set `connection_id` and `credential_id` in `terraform.tfvars` (from dbt Cloud → Project Settings → Connection / Credentials) so environments are created with the correct connection.

## 1. Configure and apply

- Copy `terraform.tfvars.example` to `terraform.tfvars` and set `dbt_cloud_account_id`, `project_id` (or `project_name` to create a new project), `connection_id`, and `credential_id`.
- Set `DBT_CLOUD_TOKEN` in your environment.
- Run:

```bash
terraform plan
terraform apply
```

Terraform will create the five environments (DEV, PROD, STAGING, Staging CI, Prod CI) and the jobs, using the connection and credential from your tfvars.

---

## If apply fails with "Provider produced inconsistent result after apply"

The dbt Cloud provider sometimes errors when it creates environments (it compares `connection_id` before/after and fails). You can:

1. **Sync state and retry** (if the environments were actually created):
   ```bash
   terraform apply -refresh-only
   terraform apply
   ```

2. **Create environments in the UI and import** (if the above still fails). Create the five environments in dbt Cloud (same names/types as in Terraform), get each environment ID, then:

   ```bash
   # Import ID format: project_id:environment_id
   terraform import 'dbtcloud_environment.dev'        <project_id>:<dev_environment_id>
   terraform import 'dbtcloud_environment.prod'         <project_id>:<prod_environment_id>
   terraform import 'dbtcloud_environment.staging'     <project_id>:<staging_environment_id>
   terraform import 'dbtcloud_environment.staging_ci'  <project_id>:<staging_ci_environment_id>
   terraform import 'dbtcloud_environment.prod_ci'     <project_id>:<prod_ci_environment_id>
   terraform apply
   ```

   Environment IDs are in the dbt Cloud URL when you open an environment, or from the [environments API](https://cloud.getdbt.com/api/v2/accounts/<account_id>/projects/<project_id>/environments/).
