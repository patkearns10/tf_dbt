terraform {
  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = "~> 1.8"
    }
  }
}

provider "dbtcloud" {
  account_id = var.dbt_cloud_account_id
  host_url   = var.dbt_cloud_host_url
}
