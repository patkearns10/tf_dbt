# How to get connection_id, credential_id, and primary_profile_id

Use either the dbt Cloud UI or the API.

---

## In dbt Cloud (UI)

1. **Connection ID** and **Credential ID**
   - Go to **Account Settings** (gear icon) → **Connections**.
   - Connections are account-level; each connection has an ID.
   - Open a connection to see its **Connection ID** (sometimes in the URL, e.g. `.../connections/51284`) or in connection details.
   - Credentials are tied to that connection; the **Credential ID** is usually shown on the same connection page or in the credentials section.

2. **Primary Profile ID**
   - Go to your **Project** → **Environments** → open a deployment environment (e.g. PROD or STAGING).
   - The environment’s **Connection** section shows which connection and **profile** it uses.
   - The profile’s ID is the **Primary Profile ID** (often in the URL when you edit the profile, e.g. `.../profiles/111450`, or listed in the environment/connection UI).

If the UI doesn’t show IDs, use the API below.

---

## Via API

Use your **account ID** and a **token** (e.g. `DBT_CLOUD_TOKEN`). Base URL is `https://cloud.getdbt.com/api` (or your host’s `/api`). Auth header is usually `Authorization: Bearer <token>` or `Authorization: Token <token>` depending on token type.

### 1. List connections (connection_id)

```bash
curl -s -H "Authorization: Bearer $DBT_CLOUD_TOKEN" \
  "https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID/connections/"
```

Response is a list of connections; each has an `id` → that’s **connection_id**.

### 2. Connection details (credential_id and profile info)

Get a single connection (replace `CONNECTION_ID` with an id from step 1):

```bash
curl -s -H "Authorization: Bearer $DBT_CLOUD_TOKEN" \
  "https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID/connections/CONNECTION_ID/"
```

Some APIs return credentials and profile info under the connection; the **credential_id** may be in that payload or under a separate credentials endpoint.

### 3. Profiles (primary_profile_id)

If your API version exposes profiles (v2/v3 differ):

```bash
# Example: profiles under account or under a connection
curl -s -H "Authorization: Bearer $DBT_CLOUD_TOKEN" \
  "https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID/profiles/"
```

Use the profile `id` that your deployment environment uses as **primary_profile_id**.

### 4. From an existing environment

If you already have an environment in the UI, you can read its config via the API and copy IDs from the response:

```bash
# List projects, then environments for a project
curl -s -H "Authorization: Bearer $DBT_CLOUD_TOKEN" \
  "https://cloud.getdbt.com/api/v2/accounts/$DBT_CLOUD_ACCOUNT_ID/projects/PROJECT_ID/environments/"
```

Each environment object may include `connection_id`, `credential_id`, and `definition_id` or profile references you can map to **primary_profile_id**.

---

## Quick reference

| Variable           | Meaning                         | Where to find it                          |
|-------------------|----------------------------------|-------------------------------------------|
| **connection_id** | Account-level warehouse connection | Account Settings → Connections; or API list connections |
| **credential_id** | Credential used for that connection | Same connection page or API connection detail |
| **primary_profile_id** | Profile used by deployment envs | Project → Environment → connection/profile; or API environments/profiles |

If an endpoint returns 404, your dbt Cloud host or API version may use a different path (e.g. v3 instead of v2); check the [dbt Administrative API](https://docs.getdbt.com/docs/dbt-cloud-apis/admin-cloud-api) docs for your version.
