{{- if .Values.argocd.enabled }}
---
# Watches the token Secret the workload-side profile creates and turns it into Argo CD's
# cluster Secret. Events are detected inside the managed clusters; the trigger deploys the
# result back here, so nothing in a workload cluster ever contacts Argo CD.
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ printf "%s-argocd-registrations" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  collectResources: true
  resourceSelectors:
    - group: ""
      version: v1
      kind: Secret
      labelFilters:
        - key: bootstrap.projectsveltos.io/argocd-registration
          operation: Equal
          value: "true"
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ printf "%s-argocd-register" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  sourceClusterSelector:
    matchLabels:
      bootstrap.projectsveltos.io/enabled: "true"
    matchExpressions:
      - key: bootstrap.projectsveltos.io/cluster
        operator: Exists
      - key: bootstrap.projectsveltos.io/argocd-role
        operator: NotIn
        values: [mgmt]
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    name: {{ .Values.managementCluster.name | quote }}
    namespace: {{ .Values.managementCluster.namespace | quote }}
  eventSourceName: {{ printf "%s-argocd-registrations" .Release.Name | quote }}
  # One ClusterProfile per registration, so one cluster cannot block another's.
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-argocd-registration" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-argocd-registration" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    # Rendered per event by the event-manager: .Cluster is the source cluster, .Resource its token.
    projectsveltos.io/instantiate: ok
data:
  cluster.yaml: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: {{ "{{ .Cluster.metadata.name }}" }}
      namespace: {{ .Values.namespaces.argocd }}
      labels:
        argocd.argoproj.io/secret-type: cluster
    type: Opaque
    stringData:
      name: {{ "{{ .Cluster.metadata.name }}" }}
      # A cluster ServiceAccount token is only valid at that cluster's own apiserver.
      server: {{ "{{ index .Cluster.metadata.annotations \"bootstrap.projectsveltos.io/argocd-server\" }}" }}
      config: |
        {"bearerToken":"{{ "{{ .Resource.data.token | b64dec }}" }}","tlsClientConfig":{"caData":"{{ "{{ index .Resource.data \"ca.crt\" }}" }}"}}
{{- end }}
