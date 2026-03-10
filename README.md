# dbt Cloud project bootstrap

This Terraform stack **automates the initial setup** of dbt Cloud projects so you don’t have to manually create environments and jobs for each customer or project.

## Why this exists

- **Avoid manual setup** — No more clicking through the UI to create DEV, PROD, STAGING, CI environments and standard jobs for every new project.
- **Consistent, best-practice layout** — Every project gets the same environment and job structure (development, production, staging, merge jobs, parse jobs, CI jobs) in one apply.
- **One-time use** — Run it once to populate a project. You do **not** need to use Terraform for ongoing maintenance; after the first apply, manage environments and jobs in the dbt Cloud app as usual.

## What it creates

- **Environments:** DEV (development), PROD, STAGING, Staging CI, Prod CI, with branch and deployment settings.
- **Jobs:** Prod and staging build jobs, merge jobs, parse jobs, and CI jobs, with triggers and steps aligned to common dbt workflows.

You provide the project (by ID or by creating a new one), connection, and credentials; Terraform does the rest.

## Quick start

### Option A: Streamlit app (UI)

**Local run**

1. Install: `pip install -r requirements.txt`
2. Install [Terraform](https://developer.hashicorp.com/terraform/install) and ensure it’s on your PATH (Terraform is not a pip package).
3. Run: `streamlit run app.py`
4. Enter your **DBT_CLOUD_TOKEN** and the rest of the options in the form.
5. Use **Init** → **Plan** → **Apply** (or **Destroy** to tear down). State is session-only; close the browser and it’s gone.

**Public deploy (Render)**

1. Push this repo to GitHub and connect it in [Render](https://render.com).
2. Create a **Web Service**, use the repo (set **Root Directory** to `tf_dbt` if the app lives in a subfolder).
3. Render will detect the Dockerfile, build the image (includes Terraform), and run the app. The container listens on `PORT` automatically.
4. Deploy; users get a public URL and Terraform works in-browser.

**Local Docker:** `docker build -t tf-dbt-app . && docker run -p 8501:8501 tf-dbt-app`

### Option B: Terraform CLI

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set your account ID, project ID (or project name to create one), and connection/credential IDs.
2. Set the `DBT_CLOUD_TOKEN` environment variable.
3. Run `terraform plan` then `terraform apply`.

See **[SETUP.md](SETUP.md)** for step-by-step instructions and troubleshooting.
