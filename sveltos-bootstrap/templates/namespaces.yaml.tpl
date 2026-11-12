apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
data:
  namespaces.yaml: |
    {{- .Values.namespacePolicyPreamble | nindent 4 }}
    {{ "{{- $virtual := eq (index .Cluster.metadata.labels \"bootstrap.projectsveltos.io/virtual\" | default \"\") \"true\" }}" }}
    {{- range $logicalName, $namespace := .Values.namespaces }}
    {{- if ne $logicalName "kubeSystem" }}
    {{- $shared := not (has $logicalName $.Values.virtualNamespaces) }}
    {{- if $shared }}
    {{ "{{- if not $virtual }}" }}
    {{- end }}
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: {{ $namespace | quote }}
      {{- with index $.Values.namespaceLabels $logicalName }}
      labels: {{ toYaml . | nindent 8 }}
      {{- end }}
    {{- if $shared }}
    {{ "{{- end }}" }}
    {{- end }}
    {{- end }}
    {{- end }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.clusterReference" . | nindent 4 }}
  policyRefs:
    - kind: ConfigMap
      name: {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
      namespace: {{ .Release.Namespace | quote }}
      deploymentType: Remote
