# [SUBAGENT] Ansible Playbook Linter

> **⚠️ SUBAGENT — This command is designed to be called by other agents, not directly by users.**
> Primarily used by `/health-check`, `/netapp-sme`, `/vmware-sme`, `/cisco-sme`, and `/infra-orchestrate` to validate Ansible playbooks before delivery or commit.

## How to invoke directly
```
/_sub-ansible-lint <path-to-playbook-or-folder>
```

## How it is called by other agents
```
Run /_sub-ansible-lint on <playbook> before presenting it to the user.
```

---

## Your Task

Lint and validate this Ansible content: **$ARGUMENTS**

---

## Lint Process

### Step 1 — Structure validation

Check the YAML structure of the playbook:

| Check | Pass Criteria |
|-------|--------------|
| Valid YAML | No syntax errors (indentation, colons, quotes) |
| Starts with `---` | YAML document start marker present |
| `hosts:` defined | Targets are specified (not empty) |
| `name:` on all plays | Every play has a descriptive name |
| `name:` on all tasks | Every task has a descriptive name |
| No bare `True`/`False` | Use `true`/`false` (lowercase) per YAML 1.1 |
| Consistent indentation | 2-space indentation throughout |

### Step 2 — Collection and module validation

| Check | Pass Criteria |
|-------|--------------|
| Collection declared | `collections:` block present or FQCN used |
| FQCN for modules | Modules use fully qualified collection name (e.g., `community.vmware.vmware_cluster_ha`) OR collection is declared |
| Correct collection for platform | NetApp → `netapp.ontap`; VMware → `community.vmware`; Cisco → `cisco.ucs`; StorageGRID → `netapp.storagegrid` |
| No deprecated modules | Flag any modules known to be deprecated |

### Step 3 — Security checks

| Check | Pass Criteria |
|-------|--------------|
| No plaintext passwords | `password:` values are `{{ vault_... }}` or variables |
| No plaintext usernames hardcoded | Usernames are parameterized |
| `no_log: true` on sensitive tasks | Tasks registering auth responses should have no_log |
| `validate_certs` justified | If `false`, a comment explains why |

### Step 4 — Best practice checks

| Check | Pass Criteria |
|-------|--------------|
| Idempotent tasks | Tasks should be safe to run multiple times |
| `state:` explicit | Modules that support `state:` have it defined |
| `when:` conditions valid | Conditions use proper Jinja2 syntax |
| Variables use `{{ }}` | Jinja2 templating for all variable references |
| Handler names match | If `notify:` is used, handler name matches exactly |
| Tags applied | Tasks have appropriate `tags:` for selective runs |
| No `shell:` when module exists | Prefer Ansible modules over `shell:` commands |
| Register + use pattern | If `register:` is used, the variable is referenced later |

### Step 5 — Header compliance (from `_sub-script-validate` context)

| Check | Pass Criteria |
|-------|--------------|
| Header block present | `# ====` comment block at top |
| Author field | `humbledgeeks-allen` |
| Date field | Date documented |
| Collection field | Collection documented |

---

## Scoring

- 9–10: **READY TO COMMIT**
- 7–8.9: **MINOR ISSUES** — acceptable with warnings noted
- 5–6.9: **NEEDS REVISION** — fix before committing
- Below 5: **BLOCKED** — significant issues

---

## Output format

```
## Ansible Lint Report
File: <path>
Checks run: <count>
Score: <X>/10

### YAML Structure
✅ | ❌ | ⚠️  <check> — <detail>

### Collections & Modules
✅ | ❌ | ⚠️  <check> — <detail>

### Security
✅ | ❌ | ⚠️  <check> — <detail>

### Best Practices
✅ | ❌ | ⚠️  <check> — <detail>

### Verdict: READY TO COMMIT | MINOR ISSUES | NEEDS REVISION | BLOCKED

### Fixes required:
- <specific fix>
```

---

## Return value (when called as subagent)

```
ANSIBLE_LINT_RESULT:
status: READY | MINOR_ISSUES | NEEDS_REVISION | BLOCKED
score: <float 0-10>
fail_count: <number>
warn_count: <number>
blocking: true | false
fixes: [list of specific fixes needed]
```
