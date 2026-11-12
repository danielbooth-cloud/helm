# Aliases each remote cluster's Hubble relay (its hubble-relay-mesh NodePort, published by
# the hubble-relay profile) as an in-cluster Service on the management cluster, where the
# central Hubble UIs run. A selectorless Service plus an EndpointSlice, like s3-endpoint;
# plain policyRefs because Argo CD excludes EndpointSlices, so it cannot own them.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "hubble-relay-shims") | quote }}
spec:
  clusterSelector:
    {{- include "bootstrap.mgmtSelector" . | nindent 4 }}
  syncMode: ContinuousWithDriftDetection
  stopMatchingBehavior: LeavePolicies
  continueOnConflict: false
  continueOnError: false
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  policyRefs:
    - name: {{ printf "%s-hubble-relay-shims" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-hubble-relay-shims" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
data:
  shims.yaml: |
    {{- .Files.Get "files/hubble-relay-shims.yaml" | nindent 4 }}
