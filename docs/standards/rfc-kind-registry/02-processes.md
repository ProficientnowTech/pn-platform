```
RFC Kind Registry                                                 Section 2
Category: Standards Track                                        Processes
```

# 2. Kind Management Processes

[← Registry](./01-registry.md) | [Index](./00-index.md) | [Next →](./appendix-a-glossary.md)

---

## 2.1 Adding a New Kind

To propose a new RFC kind:

### Step 1: Draft the Kind RFC

| Requirement | Description |
|-------------|-------------|
| Structure | Follow RFC-RFCSTD-0001 structure |
| Kind | Set Kind: Standards (all Kind RFCs are Standards kind) |
| Identifier | Assign next available RFC-RFCSTD-NNNN |

### Step 2: Define Required Sections

| Requirement | Description |
|-------------|-------------|
| Section Requirements | Specify REQUIRED, RECOMMENDED, OPTIONAL for each section |
| Section Purposes | Define what each section achieves |
| Content Requirements | Specify what must be included |
| Validation Criteria | Define how to verify compliance |

### Step 3: Submit for Review

| Requirement | Description |
|-------------|-------------|
| Review Process | Follow standard RFC review process |
| Approval | Obtain approval from RFC governance body |

### Step 4: Register the Kind

| Action | Details |
|--------|---------|
| Add to registry | Add entry to the Registry table in Section 1.1 |
| Create directory | `docs/standards/rfc-kinds/<kind-name>/` |
| Place RFC | Place the Kind RFC in the new directory |

### Step 5: Update Master Standards

| Action | Details |
|--------|---------|
| Update rfcs.md | Add new kind to Section 2.4 |
| Document relationships | Define how new kind relates to existing kinds |

---

## 2.2 Modifying an Existing Kind

To modify an existing RFC kind:

### Step 1: Create New Version

| Action | Details |
|--------|---------|
| Version increment | MAJOR for breaking changes, MINOR for additions |
| Document changes | Record in Version History section |
| Update content | Make required changes to Kind RFC |

### Step 2: Update Registry

| Action | Details |
|--------|---------|
| Update Version | Change version in Registry table |
| Update Status | If deprecating, change to Deprecated |

### Step 3: Migration Guidance (if breaking changes)

| Action | Details |
|--------|---------|
| Migration guide | Provide guidance for updating existing RFCs |
| Compatibility note | Specify compatibility with existing RFCs |
| Transition period | Define when old version becomes unsupported |

---

## 2.3 Deprecating a Kind

To deprecate an existing kind:

| Step | Action |
|------|--------|
| 1 | Change Status to Deprecated in Registry |
| 2 | Add deprecation notice to Kind RFC |
| 3 | Document replacement kind (if any) |
| 4 | Define migration path for existing RFCs |
| 5 | Set timeline for Retired status |

---

## 2.4 Retiring a Kind

To retire a deprecated kind:

| Step | Action |
|------|--------|
| 1 | Change Status to Retired in Registry |
| 2 | Verify all existing RFCs have been migrated |
| 3 | Archive Kind RFC (do not delete) |
| 4 | Update references in other documents |

---

*End of Section 2 — RFC Kind Registry*
