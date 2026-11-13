{{- define "bootstrap.profileName" -}}
{{ printf "%s-%s" .root.Values.profilePrefix .name }}
{{- end -}}

{{- define "bootstrap.clusterSelector" -}}
matchLabels:
  bootstrap.projectsveltos.io/enabled: "true"
  {{- if .clustermesh }}
  bootstrap.projectsveltos.io/clustermesh: "true"
  {{- end }}
  {{- if .cloudflareTunnel }}
  {{- /* Opt-in: the cluster has a Cloudflare Tunnel (ClusterConfig cloudflareTunnelId/Item). */}}
  bootstrap.projectsveltos.io/cloudflare-tunnel: "true"
  {{- end }}
  {{- if .gatewayRouteApi }}
  {{- /* Set by the gatewayroute-api Classifier once the GatewayRoute CRD is Established. */}}
  bootstrap.projectsveltos.io/gatewayroute-api: "true"
  {{- end }}
  {{- if .virtualOnly }}
  bootstrap.projectsveltos.io/virtual: "true"
  {{- end }}
matchExpressions:
  - key: bootstrap.projectsveltos.io/cluster
    operator: Exists
  {{- if .excludeManagement }}
  - key: bootstrap.projectsveltos.io/role
    operator: NotIn
    values:
      - {{ .root.Values.managementCluster.role | default "mgmt" | quote }}
  {{- end }}
  {{- /* Only vCluster registrations carry virtual "true"; unlabelled clusters are real. */}}
  {{- if .excludeVirtual }}
  - key: bootstrap.projectsveltos.io/virtual
    operator: NotIn
    values:
      - "true"
  {{- end }}
{{- end -}}

{{- define "bootstrap.mgmtSelector" -}}
matchLabels:
  bootstrap.projectsveltos.io/role: {{ .Values.managementCluster.role | default "mgmt" | quote }}
{{- end -}}

{{- define "bootstrap.commonSpec" -}}
clusterSelector:
  {{- include "bootstrap.clusterSelector" . | nindent 2 }}
syncMode: ContinuousWithDriftDetection
stopMatchingBehavior: {{ if .withdraw }}WithdrawPolicies{{ else }}LeavePolicies{{ end }}
continueOnConflict: false
continueOnError: false
{{- end -}}

{{- define "bootstrap.clusterReference" -}}
- identifier: ClusterConfig
  resource:
    apiVersion: v1
    kind: ConfigMap
    namespace: {{ .Values.registrationNamespace | quote }}
    name: {{ "{{ .Cluster.metadata.namespace }}-{{ .Cluster.metadata.name }}-bootstrap-config" | quote }}
{{- end -}}

{{- define "bootstrap.chartReferences" -}}
{{ include "bootstrap.clusterReference" .root }}
- identifier: BootstrapSettings
  resource:
    apiVersion: v1
    kind: ConfigMap
    namespace: {{ .root.Release.Namespace | quote }}
    name: {{ printf "%s-settings" .root.Release.Name | quote }}
{{- if .credentials }}
- identifier: BootstrapCredentials
  resource:
    apiVersion: v1
    kind: Secret
    namespace: {{ .root.Release.Namespace | quote }}
    name: {{ printf "%s-credentials" .root.Release.Name | quote }}
{{- end }}
{{- end -}}

{{- define "bootstrap.valuesSecret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-%s-values" .root.Values.profilePrefix .release | quote }}
  namespace: {{ .root.Release.Namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
type: addons.projectsveltos.io/cluster-profile
data:
  values.yaml: {{ index .root.Values.applicationValues .release | b64enc | quote }}
{{- end -}}

{{- define "bootstrap.valuesFrom" -}}
- kind: Secret
  name: {{ printf "%s-%s-values" .root.Values.profilePrefix .release | quote }}
  namespace: {{ .root.Release.Namespace | quote }}
- kind: Secret
  name: {{ printf "{{ .Cluster.metadata.name }}-bootstrap-%s" .release | quote }}
  optional: true
{{- end -}}
