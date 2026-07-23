## 1. Terminology Updates

### 1.1 Global Terminology Changes
- [ ] 1.1.1 Replace "Platform Application" with "Infrastructure Provider" or "Platform Consumer" as appropriate
- [ ] 1.1.2 Add "Tenant Application" as subset of Platform Consumer
- [ ] 1.1.3 Remove any "layer" or "phase" terminology
- [ ] 1.1.4 Update Glossary (Appendix A) with new terms

## 2. Section Updates

### 2.1 Section 02 - Design Principles
- [ ] 2.1.1 Add principle: binary categorization (Infrastructure Provider vs Platform Consumer)
- [ ] 2.1.2 Add principle: DAG-based dependency resolution (cycles rejected at declaration)
- [ ] 2.1.3 Add principle: base chart boundary (Platform Consumers only)
- [ ] 2.1.4 Remove any language implying sequential phases or layers

### 2.2 Section 03 - Architecture Overview
- [ ] 2.2.1 Add binary categorization decision tree
- [ ] 2.2.2 List Infrastructure Providers with reasons why they don't use base chart
- [ ] 2.2.3 List Platform Consumers with reasons why they must use base chart
- [ ] 2.2.4 Update component interaction to show DAG-based resolution

### 2.3 Section 04 - Component Categories
- [ ] 2.3.1 Rename section to "Binary Component Categorization"
- [ ] 2.3.2 Define Infrastructure Provider category with decision criteria
- [ ] 2.3.3 Define Platform Consumer category with decision criteria
- [ ] 2.3.4 Add the binary test: "Does base chart depend on this component's capability?"
- [ ] 2.3.5 Provide complete component classification table

### 2.4 Section 05 - Capability Orchestration
- [ ] 2.4.1 Clarify DAG-based dependency resolution model
- [ ] 2.4.2 Document cycle rejection at declaration time
- [ ] 2.4.3 Describe resolution rules (deploy when ALL requirements satisfied)
- [ ] 2.4.4 Add statement that implementation details are in RFC-DEPLOY-0001
- [ ] 2.4.5 Update formal algorithm notation to reflect DAG model

### 2.5 Section 06 - Shared Infrastructure
- [ ] 2.5.1 Classify infrastructure operators as Infrastructure Providers
- [ ] 2.5.2 Classify operator-managed instances as Platform Consumers (when using base chart claims)
- [ ] 2.5.3 Document capability-based provisioning pattern
- [ ] 2.5.4 Document Crossplane claim-based provisioning via base chart

### 2.6 Section 07 - Application Model
- [ ] 2.6.1 Document base chart as library chart for Platform Consumers ONLY
- [ ] 2.6.2 Document why Infrastructure Providers cannot use base chart (circular dependency)
- [ ] 2.6.3 List all base chart template categories with consuming Infrastructure Provider
- [ ] 2.6.4 Document wrapper chart pattern for Platform Consumers
- [ ] 2.6.5 Add Crossplane, ExternalSecret, Keycloak client template documentation

### 2.7 Section 08 - Governance and Guardrails
- [ ] 2.7.1 Update ownership rules for binary categorization
- [ ] 2.7.2 Remove any layer-based governance language

### 2.8 Section 09 - Rationale
- [ ] 2.8.1 Add rationale for binary categorization (circular dependency avoidance)
- [ ] 2.8.2 Add rationale for DAG-based resolution (why not phases)
- [ ] 2.8.3 Add rationale for base chart scope (why Infrastructure Providers excluded)

### 2.9 Section 10 - Future Considerations
- [ ] 2.9.1 Document adding new Infrastructure Providers (base chart updated after)
- [ ] 2.9.2 Document potential sub-category labels (optional, not primary)
- [ ] 2.9.3 Add base chart evolution considerations

### 2.10 Appendices
- [ ] 2.10.1 Update Glossary with Infrastructure Provider, Platform Consumer definitions
- [ ] 2.10.2 Remove any phase-related definitions

## 3. Cross-RFC Alignment

### 4.1 Deference Statements
- [ ] 4.1.1 Add clear deference to RFC-DEPLOY-0001 for orchestration implementation
- [ ] 4.1.2 Verify deference to RFC-SECOPS-0001 for secrets
- [ ] 4.1.3 Verify deference to RFC-IAM-0001 for human authentication
- [ ] 4.1.4 Verify deference to other domain RFCs

### 4.2 Cross-Reference Validation
- [ ] 4.2.1 Verify all cross-RFC references are bidirectional
- [ ] 4.2.2 Confirm no contradictory requirements between RFCs
- [ ] 4.2.3 Ensure RFC scope boundaries are clear

## 4. Diagram Updates

### 5.1 Diagrams to Add/Update
- [ ] 5.1.1 Create binary categorization decision tree diagram
- [ ] 5.1.2 Create capability dependency DAG example with cycle detection
- [ ] 5.1.3 Create base chart boundary diagram (what's in vs out)
- [ ] 5.1.4 Create component classification table (all components with category)

### 5.2 Diagrams to Remove
- [ ] 5.2.1 Remove any phase sequence diagrams
- [ ] 5.2.2 Remove hierarchical layer diagrams

## 5. Validation

### 6.1 Categorization Consistency
- [ ] 6.1.1 Verify all platform components are classified
- [ ] 6.1.2 Verify no circular dependencies in classification
- [ ] 6.1.3 Verify binary test produces consistent results

### 6.2 Terminology Consistency
- [ ] 6.2.1 Search for remaining "Platform Application" references
- [ ] 6.2.2 Search for remaining "layer" or "phase" references
- [ ] 6.2.3 Verify consistent use of Infrastructure Provider / Platform Consumer

### 6.3 RFC Scope
- [ ] 6.3.1 Verify RFC remains informative/design focused
- [ ] 6.3.2 Verify no implementation details leaked into RFC
- [ ] 6.3.3 Verify deference to implementation RFCs is clear

## 6. Final Review

- [ ] 7.1 Run OpenSpec validation: `openspec validate refactor-platform-arch-rfc-v2 --strict`
- [ ] 7.2 Review RFC for consistency and completeness
- [ ] 7.3 Update RFC changelog with revision date
- [ ] 7.4 Request stakeholder review and approval
