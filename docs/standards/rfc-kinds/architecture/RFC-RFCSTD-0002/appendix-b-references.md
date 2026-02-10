```
RFC-RFCSTD-0002                                                  Appendix B
Category: Standards Track                                       References
```

# Appendix B: References

[← Glossary](./appendix-a-glossary.md) | [Index](./00-index.md)

---

## Normative References

These standards MUST be followed when authoring Architecture RFCs.

**[RFC2119]** Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.
<https://datatracker.ietf.org/doc/html/rfc2119>

**[RFC8174]** Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words", BCP 14, RFC 8174, May 2017.
<https://datatracker.ietf.org/doc/html/rfc8174>

---

## Informative References

These references provide background and context for the Architecture kind design.

### Architecture Standards

**[ISO42010]** ISO/IEC/IEEE, "Systems and software engineering — Architecture description", ISO/IEC/IEEE 42010:2022.
<https://www.iso.org/standard/74393.html>

The international standard for architecture description. Defines the distinction between architecture (conceptual) and implementation. Key concepts adopted:

- Architecture as the fundamental organization of a system
- Separation of concerns between architecture and implementation
- Stakeholder-driven views and viewpoints

**[arc42]** Starke, G., Hruschka, P., "arc42 Template".
<https://arc42.org/overview>

A practical 12-section architecture documentation template. Influenced our approach to:

- Modular, optional sections
- Clear separation of concerns
- Quality requirements and constraints
- Decision logging (rationale)

### IETF Standards Process

**[RFC2026]** Bradner, S., "The Internet Standards Process -- Revision 3", BCP 9, RFC 2026, October 1996.
<https://www.rfc-editor.org/rfc/rfc2026.html>

Defines the IETF standards track and document categories. Informed our kind classification approach.

### Industry Practices

**[PRAGMATIC-RFC]** Orosz, G., "Software Engineering RFC and Design Docs", The Pragmatic Engineer Newsletter.
<https://newsletter.pragmaticengineer.com/p/software-engineering-rfc-and-design>

Analysis of RFC practices at technology companies including Uber, Hashicorp, and others. Provides context for:

- How architecture RFCs are used in practice
- Common sections and their purposes
- Review and approval processes

---

## Internal References

**[RFC-RFCSTD-0001]** Platform Engineering, "RFC Kind: Standards", RFC-RFCSTD-0001 v1.1.0.
`docs/standards/rfc-kinds/standards/RFC-RFCSTD-0001/`

**[RFC-STANDARDS]** Platform Engineering, "RFC Authoring Standards".
`docs/standards/rfcs.md`

**[RFC-KIND-REGISTRY]** Platform Engineering, "RFC Kind Registry".
`docs/standards/rfc-kind-registry.md`

**[RFC-RFCSTD-0003]** Platform Engineering, "RFC Kind: Specification".
`docs/standards/rfc-kinds/specification/RFC-RFCSTD-0003/`

**[RFC-RFCSTD-0004]** Platform Engineering, "RFC Kind: Best Current Practice".
`docs/standards/rfc-kinds/bcp/RFC-RFCSTD-0004/`

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-10 | Platform Engineering | Initial release - single file format |
| 1.1.0 | 2026-02-10 | Platform Engineering | Converted to multi-file format; added research references |

---

*End of Appendix B — RFC-RFCSTD-0002*
