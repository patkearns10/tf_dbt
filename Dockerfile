# dbt Cloud bootstrap — Streamlit app with Terraform (for Render, local Docker, etc.)
FROM python:3.11-slim

# Install Terraform (binary from HashiCorp; not available via pip)
ARG TF_VERSION=1.9.6
ARG TF_ARCH=amd64
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    ca-certificates \
    curl \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${TF_ARCH}.zip" -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && terraform -version \
    && apt-get purge -y unzip curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App and Terraform config (needed so session workspaces can copy these)
COPY app.py .
COPY main.tf tf_dbt.tf variables.tf .terraform.lock.hcl ./

# Streamlit listens on PORT when set (e.g. Render), else 8501 for local docker run
EXPOSE 8501

CMD ["sh", "-c", "streamlit run app.py --server.port=${PORT:-8501} --server.address=0.0.0.0"]
