{{- /*
kapp (Carvel) apply-ordering annotations, derived from the SAME `dependency-layer` that produces the
ArgoCD sync-wave. This is the design's claim in cluster-bootstrap-orchestration.md §3 made real:
ONE authored ordering fact, compiled into whatever engine applies the manifest — ArgoCD in Phase 2,
kapp in Phase 1 — so the two can never disagree.

Syntax per carvel.dev/kapp apply-ordering:
  kapp.k14s.io/change-group: <name>
  kapp.k14s.io/change-rule[.<suffix>]: "(upsert|delete) (after|before) (upserting|deleting) <name>"
Multiple rules require a unique `.suffix` on the key.

Delete ordering is the REVERSE of create ordering: a later layer must be torn down before the layer
it depends on, or you rip the foundation out from under things still running on it.

NOTE: nothing consumes these today. Phase-1 foundation bring-up is currently done by the Ansible
seed (playbooks/onprem-cluster-bootstrap.yml), not by kapp. They are emitted so that adopting the
kapp CLI later is a configuration change rather than a redesign — and so the "one authored fact"
property is true in the data even while only one consumer exists. kapp-CONTROLLER is explicitly out
of scope: §4 chose the CLI precisely because it vanishes, and a second in-cluster reconciler
alongside ArgoCD is the cost that decision exists to avoid.
*/ -}}
{{- define "app-factory.kappordering" -}}
{{- $layer := .layer -}}
{{- $prev := dict "core" "foundation" "platform" "core" "application" "platform" -}}
{{- $g := printf "pnats.cloud/layer-%s" $layer -}}
kapp.k14s.io/change-group: {{ $g | quote }}
{{- if hasKey $prev $layer }}
{{- $p := printf "pnats.cloud/layer-%s" (get $prev $layer) }}
kapp.k14s.io/change-rule.create-order: {{ printf "upsert after upserting %s" $p | quote }}
kapp.k14s.io/change-rule.delete-order: {{ printf "delete before deleting %s" $p | quote }}
{{- end }}
{{- end -}}
