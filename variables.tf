# -----------------------------------------------------------------------------
# dbt Cloud account - used by the provider (token stays in DBT_CLOUD_TOKEN env)
# -----------------------------------------------------------------------------

variable "dbt_cloud_account_id" {
  description = "dbt Cloud account ID. Used by the dbtcloud provider; token from DBT_CLOUD_TOKEN env."
  type        = number
}

variable "dbt_cloud_host_url" {
  description = "Optional dbt Cloud API host (e.g. https://cloud.getdbt.com/api). Omit for default US multi-tenant."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Project - use existing by ID or create new
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "Existing dbt Cloud project ID. Set this when the project already exists; leave null to create a new project."
  type        = number
  default     = null
}

variable "project_name" {
  description = "Name of the dbt Cloud project. Required when creating (project_id is null); ignored when using existing project_id."
  type        = string
  default     = null
}

variable "project_description" {
  description = "Short description of the project. Used only when creating a new project."
  type        = string
  default     = ""
}

variable "project_type" {
  description = "Project type (0 = standard/job-based). Used only when creating a new project."
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Connection & credentials (from dbt Cloud: Project Settings → Connection / Credentials)
# -----------------------------------------------------------------------------

variable "connection_id" {
  description = "dbt Cloud connection ID used by all environments. Set to null to create environments without connection (configure in dbt Cloud app)."
  type        = number
  default     = null
}

variable "credential_id" {
  description = "dbt Cloud credential ID for deployment environments (PROD, STAGING, CI). Set to null when connection_id is null."
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------
# Environment defaults
# -----------------------------------------------------------------------------

variable "dbt_version" {
  description = "dbt version for environments (e.g. latest-fusion, 1.7.0)."
  type        = string
  default     = "latest-fusion"
}

variable "staging_branch" {
  description = "Git branch used for staging deployment and CI."
  type        = string
  default     = "staging"
}

# -----------------------------------------------------------------------------
# Job defaults
# -----------------------------------------------------------------------------

variable "schedule_cron" {
  description = "Default cron expression for scheduled jobs (when schedule trigger is enabled)."
  type        = string
  default     = "0 9 * * 1-5" # 9am weekdays; use terraform.tfvars to override
}

variable "num_threads" {
  description = "Default number of threads for jobs."
  type        = number
  default     = 4
}

# -----------------------------------------------------------------------------
# Feature toggles - set to true to disable PR / merge / schedule triggers
# -----------------------------------------------------------------------------

variable "deactivate_jobs_pr" {
  description = "If true, disables PR (webhook) triggers on all jobs."
  type        = bool
  default     = false
}

variable "deactivate_jobs_merge" {
  description = "If true, disables merge triggers on all jobs."
  type        = bool
  default     = false
}

variable "deactivate_jobs_schedule" {
  description = "If true, disables schedule triggers on all jobs."
  type        = bool
  default     = false
}
