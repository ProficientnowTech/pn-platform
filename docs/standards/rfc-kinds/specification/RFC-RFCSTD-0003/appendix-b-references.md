```
RFC-RFCSTD-0003                                                  Appendix B
Category: Standards Track                                       References
```

# Appendix B: References

[← Glossary](./appendix-a-glossary.md) | [Index](./00-index.md)

---

## Normative References

These standards MUST be followed when authoring Specification RFCs.

**[RFC2119]** Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.
<https://datatracker.ietf.org/doc/html/rfc2119>

**[RFC8174]** Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words", BCP 14, RFC 8174, May 2017.
<https://datatracker.ietf.org/doc/html/rfc8174>

---

## Informative References

These references provide background and context for the Specification kind design.

### Implementation Guide Patterns

**[FHIR-IG]** HL7 International, "FHIR Implementation Guide".
<https://hl7.org/fhir/implementationguide.html>

The FHIR Implementation Guide structure demonstrates how to specify implementations without embedding code. Key concepts adopted:

- Prerequisite documentation
- Phased implementation approach
- Validation requirements
- Test specifications

**[FHIR-CONFORMANCE]** HL7 International, "FHIR Conformance".
<https://hl7.org/fhir/conformance-rules.html>

Defines how conformance is specified and validated in FHIR implementations. Influenced our approach to deterministic validation criteria.

### Architecture Standards

**[ISO42010]** ISO/IEC/IEEE, "Systems and software engineering — Architecture description", ISO/IEC/IEEE 42010:2022.
<https://www.iso.org/standard/74393.html>

Defines the distinction between architecture description and implementation specification. Specification RFCs implement architectures described in Architecture RFCs.

### Testing Standards

**[IEEE829]** IEEE, "IEEE Standard for Software and System Test Documentation", IEEE 829-2008.

Defines standard format for test documentation. Influenced our test category structure.

### Risk Management

**[ISO31000]** ISO, "Risk management — Guidelines", ISO 31000:2018.
<https://www.iso.org/standard/65694.html>

Provides risk management framework. Influenced our risk documentation requirements (likelihood, impact, mitigation).

### IETF Standards Process

**[RFC2026]** Bradner, S., "The Internet Standards Process -- Revision 3", BCP 9, RFC 2026, October 1996.
<https://www.rfc-editor.org/rfc/rfc2026.html>

Defines the IETF standards track. Informed our kind classification (Standards Track specifications vs informational documents).

---

## Internal References

**[RFC-RFCSTD-0001]** Platform Engineering, "RFC Kind: Standards", RFC-RFCSTD-0001 v1.1.0.
`docs/standards/rfc-kinds/standards/RFC-RFCSTD-0001/`

**[RFC-RFCSTD-0002]** Platform Engineering, "RFC Kind: Architecture", RFC-RFCSTD-0002 v1.1.0.
`docs/standards/rfc-kinds/architecture/RFC-RFCSTD-0002/`

**[RFC-STANDARDS]** Platform Engineering, "RFC Authoring Standards".
`docs/standards/rfcs.md`

**[RFC-KIND-REGISTRY]** Platform Engineering, "RFC Kind Registry".
`docs/standards/rfc-kind-registry.md`

**[RFC-RFCSTD-0004]** Platform Engineering, "RFC Kind: Best Current Practice".
`docs/standards/rfc-kinds/bcp/RFC-RFCSTD-0004/`

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-10 | Platform Engineering | Initial release - single file format |
| 1.1.0 | 2026-02-10 | Platform Engineering | Converted to multi-file format; added research references |

---

*End of Appendix B — RFC-RFCSTD-0003*
