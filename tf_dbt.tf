# -----------------------------------------------------------------------------
# Project - create new or use existing by ID
# -----------------------------------------------------------------------------

resource "dbtcloud_project" "this" {
  count       = var.project_id == null ? 1 : 0
  name        = var.project_name
  description = var.project_description
  type        = var.project_type

  lifecycle {
    precondition {
      condition     = var.project_id != null || (var.project_name != null && var.project_name != "")
      error_message = "When creating a new project (project_id is null), project_name must be set. When using an existing project_id, project_name is ignored."
    }
  }
}

locals {
  # Use existing project_id or the ID of the project we just created
  project_id    = var.project_id != null ? var.project_id : dbtcloud_project.this[0].id
  connection_id = var.connection_id
  credential_id = var.credential_id
}

# -----------------------------------------------------------------------------
# Environments — Terraform creates these with connection_id/credential_id from vars.
# -----------------------------------------------------------------------------

resource "dbtcloud_environment" "dev" {
  name                       = "DEV"
  project_id                 = local.project_id
  type                       = "development"
  connection_id              = local.connection_id
  dbt_version                = var.dbt_version
  use_custom_branch          = false
  enable_model_query_history = false
}

resource "dbtcloud_environment" "prod" {
  name                       = "PROD"
  project_id                 = local.project_id
  type                       = "deployment"
  deployment_type            = "production"
  connection_id              = local.connection_id
  credential_id              = local.credential_id
  dbt_version                = var.dbt_version
  use_custom_branch          = false
  enable_model_query_history = true
}

resource "dbtcloud_environment" "staging" {
  name                       = "STAGING"
  project_id                 = local.project_id
  type                       = "deployment"
  deployment_type            = "staging"
  connection_id              = local.connection_id
  credential_id              = local.credential_id
  dbt_version                = var.dbt_version
  use_custom_branch          = true
  custom_branch              = var.staging_branch
  enable_model_query_history = false
}

resource "dbtcloud_environment" "staging_ci" {
  name                       = "Staging CI"
  project_id                 = local.project_id
  type                       = "deployment"
  connection_id              = local.connection_id
  credential_id              = local.credential_id
  dbt_version                = var.dbt_version
  use_custom_branch          = true
  custom_branch              = var.staging_branch
  enable_model_query_history = false
}

resource "dbtcloud_environment" "prod_ci" {
  name                       = "Prod CI"
  project_id                 = local.project_id
  type                       = "deployment"
  connection_id              = local.connection_id
  credential_id              = local.credential_id
  dbt_version                = var.dbt_version
  use_custom_branch          = false
  enable_model_query_history = false
}

# -----------------------------------------------------------------------------
# Jobs - Prod
# -----------------------------------------------------------------------------

resource "dbtcloud_job" "prod_build" {
  name                   = "dbt build"
  project_id             = local.project_id
  environment_id         = dbtcloud_environment.prod.environment_id
  job_type               = "other"
  execute_steps          = ["dbt build"]
  target_name            = "default"
  num_threads            = var.num_threads
  compare_changes_flags  = "--select state:modified"
  run_compare_changes    = false
  run_generate_sources   = true
  run_lint               = false
  generate_docs          = true
  errors_on_lint_failure = true
  force_node_selection   = false
  triggers_on_draft_pr   = false
  description            = "Nightly batch job that refreshes all seeds, snapshots, models, and tests in the prod environment"
  schedule_type          = "custom_cron"
  schedule_cron          = var.schedule_cron
  execution              = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : false
    schedule             = false
  }

  lifecycle {
    ignore_changes = [job_type]
  }
}

resource "dbtcloud_job" "prod_merge_job" {
  name                     = "Merge Job"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.prod.environment_id
  deferring_environment_id = dbtcloud_environment.prod.environment_id
  job_type                 = "merge"
  execute_steps            = ["dbt build --select state:modified+"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Runs when you merge a pull request into the prod branch."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : true
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}

resource "dbtcloud_job" "prod_parse" {
  name                     = "Prod dbt Parse"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.prod.environment_id
  deferring_environment_id = dbtcloud_environment.prod.environment_id
  job_type                 = "merge"
  execute_steps            = ["dbt parse"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Invoked when you merge to prod; updates manifest for other PRs."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : true
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}

# -----------------------------------------------------------------------------
# Jobs - Staging
# -----------------------------------------------------------------------------

resource "dbtcloud_job" "staging_nightly_build" {
  name                   = "Staging Nightly Build"
  project_id             = local.project_id
  environment_id         = dbtcloud_environment.staging.environment_id
  job_type               = "other"
  execute_steps          = ["dbt build"]
  target_name            = "default"
  num_threads            = var.num_threads
  compare_changes_flags  = "--select state:modified"
  run_compare_changes    = false
  run_generate_sources   = false
  run_lint               = false
  generate_docs          = false
  errors_on_lint_failure = true
  force_node_selection   = false
  triggers_on_draft_pr   = false
  description            = "Nightly batch job for the staging environment."
  schedule_type          = "custom_cron"
  schedule_cron          = var.schedule_cron
  execution              = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : false
    schedule             = false
  }

  lifecycle {
    ignore_changes = [job_type]
  }
}

resource "dbtcloud_job" "staging_merge_job" {
  name                     = "Staging Merge Job"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.staging.environment_id
  deferring_environment_id = dbtcloud_environment.staging.environment_id
  job_type                 = "merge"
  execute_steps            = ["dbt build --select state:modified+"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Runs when you merge a pull request into the staging branch."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : true
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}

resource "dbtcloud_job" "staging_ci_job" {
  name                     = "Staging CI Job"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.staging_ci.environment_id
  deferring_environment_id = dbtcloud_environment.staging.environment_id
  job_type                 = "ci"
  execute_steps            = ["dbt build --select state:modified+"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Runs on PR to staging or on new commits to an open PR."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : true
    on_merge             = var.deactivate_jobs_merge ? false : false
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}

resource "dbtcloud_job" "staging_parse" {
  name                     = "Staging dbt Parse"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.staging.environment_id
  deferring_environment_id = dbtcloud_environment.staging.environment_id
  job_type                 = "merge"
  execute_steps            = ["dbt parse"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Invoked when you merge to staging; updates manifest for other PRs."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : false
    on_merge             = var.deactivate_jobs_merge ? false : true
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}

# -----------------------------------------------------------------------------
# Jobs - Prod CI (PRs against main/master)
# -----------------------------------------------------------------------------

resource "dbtcloud_job" "prod_ci_job" {
  name                     = "Prod CI Job"
  project_id               = local.project_id
  environment_id           = dbtcloud_environment.prod_ci.environment_id
  deferring_environment_id = dbtcloud_environment.prod.environment_id
  job_type                 = "ci"
  execute_steps            = ["dbt build --select state:modified+"]
  target_name              = "default"
  num_threads              = var.num_threads
  compare_changes_flags    = "--select state:modified"
  run_compare_changes      = false
  run_generate_sources     = false
  run_lint                 = false
  generate_docs            = false
  errors_on_lint_failure   = true
  force_node_selection     = true
  triggers_on_draft_pr     = false
  description              = "Runs on PR to main/master or on new commits to an open PR."
  schedule_type            = "custom_cron"
  schedule_cron            = var.schedule_cron
  execution                = { timeout_seconds = 0 }
  triggers = {
    git_provider_webhook = var.deactivate_jobs_pr ? false : false
    github_webhook       = var.deactivate_jobs_pr ? false : true
    on_merge             = var.deactivate_jobs_merge ? false : false
    schedule             = var.deactivate_jobs_schedule ? false : false
  }
}
