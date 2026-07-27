{{- define "app-factory.appproject" -}}
{{- $d := .domain -}}
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: {{ $d }}
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: {{ $d | quote }}
spec:
  sourceRepos:
    {{- .sourceRepos | default (list "*") | toYaml | nindent 4 }}
  destinations:
    {{- .destinations | toYaml | nindent 4 }}
  roles:
    - name: admin
      groups: ["pn-{{ $d }}-admin"]
      policies: ["p, proj:{{ $d }}:admin, applications, *, {{ $d }}/*, allow"]
    - name: developer
      groups: ["pn-{{ $d }}-developer"]
      policies: ["p, proj:{{ $d }}:developer, applications, sync, {{ $d }}/*, allow"]
    - name: viewer
      groups: ["pn-{{ $d }}-viewer"]
      policies: ["p, proj:{{ $d }}:viewer, applications, get, {{ $d }}/*, allow"]
{{- end -}}
