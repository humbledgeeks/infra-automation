# Veeam — Ansible

Ansible playbooks for Veeam Backup & Replication automation via the **Veeam REST API** (port 9419) using the `uri` module. No dedicated Ansible collection is required — all playbooks communicate with the VBR REST API introduced in VBR v11.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| Veeam B&R | 11 (REST API introduced) | 12 (latest) |
| OS (Ansible control node) | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |
| Network | HTTPS to VBR server port 9419 | — |

> **No additional Ansible collections are required.** The `uri` module is bundled with core Ansible (`ansible.builtin.uri`).

---

## Installation

### Step 1 — Install Python and pip

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# macOS
brew install python@3.11

# Verify
python3 --version && pip3 --version
```

### Step 2 — Create a virtual environment (recommended)

```bash
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
```

### Step 3 — Install Ansible

```bash
pip install ansible
ansible --version
```

### Step 4 — Verify VBR REST API is reachable

```bash
# Test HTTPS connectivity to VBR on port 9419
curl -k https://vbr01.lab.local:9419/api/v1/token --head

# Or via PowerShell from the VBR server
Test-NetConnection -ComputerName localhost -Port 9419
```

---

## Credential Setup — Ansible Vault

**Never store credentials in plain text.**

```bash
# Create encrypted vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`:

```yaml
vault_vbr_server:   vbr01.lab.local
vault_vbr_username: administrator
vault_vbr_password: YourVBRPassword
```

```bash
# Edit vault later
ansible-vault edit group_vars/all/vault.yml

# View without editing
ansible-vault view group_vars/all/vault.yml
```

Reference in playbooks:

```yaml
vars:
  vbr_server:   "{{ vault_vbr_server }}"
  vbr_username: "{{ vault_vbr_username }}"
  vbr_password: "{{ vault_vbr_password }}"
  vbr_api_base: "https://{{ vault_vbr_server }}:9419/api/v1"
```

---

## Inventory Setup

Veeam playbooks run from **localhost** using `connection: local` — all API calls go to the VBR server via HTTPS on port 9419.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `veeam-job-status.yml` | Authenticates to VBR REST API; retrieves job list and last 25 sessions with result counts; ends with assertion validation |

---

## How to Run

### veeam-job-status.yml

Queries the VBR REST API for job definitions and recent session results.

```bash
# Syntax check first (no execution)
ansible-playbook veeam-job-status.yml --syntax-check

# Run with vault password prompt
ansible-playbook veeam-job-status.yml --ask-vault-pass

# Run with vault password file (CI/CD or automation)
echo "YourVaultPassword" > ~/.vault_pass && chmod 600 ~/.vault_pass
ansible-playbook veeam-job-status.yml --vault-password-file ~/.vault_pass

# Verbose output for troubleshooting
ansible-playbook veeam-job-status.yml -vvv --ask-vault-pass
```

---

## VBR REST API Authentication Pattern

All playbooks use OAuth2 password grant with `no_log: true` to protect credentials in logs:

```yaml
- name: Authenticate to VBR REST API
  uri:
    url: "{{ vbr_api_base }}/token"
    method: POST
    body_format: form-urlencoded
    body:
      grant_type: password
      username:   "{{ vbr_username }}"
      password:   "{{ vbr_password }}"
    validate_certs: false   # Set true in production with valid certs
    status_code: 200
  register: vbr_auth
  no_log: true   # Prevent credentials appearing in logs

- name: Set VBR auth token
  set_fact:
    vbr_headers:
      Authorization: "Bearer {{ vbr_auth.json.access_token }}"
      x-api-version: "1.1-rev0"
```

---

## Common VBR REST API Endpoints

```yaml
# List all jobs
- uri:
    url: "{{ vbr_api_base }}/jobs"
    headers: "{{ vbr_headers }}"
    validate_certs: false

# List recent sessions (last 25, newest first)
- uri:
    url: "{{ vbr_api_base }}/sessions?limit=25&orderColumn=CreationTime&orderAsc=false"
    headers: "{{ vbr_headers }}"
    validate_certs: false

# List repositories
- uri:
    url: "{{ vbr_api_base }}/backupInfrastructure/repositories"
    headers: "{{ vbr_headers }}"
    validate_certs: false

# Start a specific job
- uri:
    url: "{{ vbr_api_base }}/jobs/{{ job_id }}/start"
    method: POST
    headers: "{{ vbr_headers }}"
    validate_certs: false
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint veeam-job-status.yml
ansible-playbook veeam-job-status.yml --syntax-check
```

---

## References

- [Veeam REST API Documentation (VBR 12)](https://helpcenter.veeam.com/docs/backup/vbr_rest/overview.html)
- [Veeam REST API Swagger UI](https://vbr-server:9419/api/swagger) (on your VBR server)
- [Ansible uri module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
