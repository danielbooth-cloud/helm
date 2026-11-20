{{- /* Copies each mirrored route's cert-manager Secret from the host back into its source vCluster. */ -}}
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ printf "%s-mirrored-route-certificates" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  collectResources: true
  resourceSelectors:
    # Set through the RGD's secretTemplate only on Secrets of mirrored routes.
    - group: ""
      version: v1
      kind: Secret
      labelFilters:
        - key: bootstrap.projectsveltos.io/gateway-route-mirror
          operation: Equal
          value: "true"
        # Cilium's Gateway copies listener Secrets with their labels into cilium-secrets.
        - key: secretsync.cilium.io/owning-secret-name
          operation: DoesNotHave
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ printf "%s-gateway-route-tls" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  sourceClusterSelector:
    {{- include "bootstrap.clusterSelector" (dict "root" . "excludeVirtual" true "gatewayRouteApi" true) | nindent 4 }}
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    namespace: {{ "{{ index .Resource.metadata.annotations \"bootstrap.projectsveltos.io/mirror-source-namespace\" }}" | quote }}
    name: {{ "{{ index .Resource.metadata.annotations \"bootstrap.projectsveltos.io/mirror-source-name\" }}" | quote }}
  eventSourceName: {{ printf "%s-mirrored-route-certificates" .Release.Name | quote }}
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-gateway-route-tls" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: Secret
---
# A Secret, not a ConfigMap, so each instantiated copy holding the private key is a Secret too.
apiVersion: v1
kind: Secret
type: addons.projectsveltos.io/cluster-profile
metadata:
  name: {{ printf "%s-gateway-route-tls" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/instantiate: ok
data:
  secret.yaml: {{ .Files.Get "files/gateway-route-tls/secret.yaml" | b64enc | quote }}
