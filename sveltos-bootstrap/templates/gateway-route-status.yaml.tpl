{{- /* GatewayRoute status back-fill: kro only reconciles on the host, so a vCluster's own
GatewayRoute stays status-less forever and Argo CD's built-in Kro health check (no status =
Progressing) wedges every app carrying a route. The forward mirror (gateway-route-mirror)
stamps the source vCluster's identity onto the host copy; this watches those mirrors and
copies kro's status into the vCluster's GatewayRoute via the status subresource
(projectsveltos.io/subresources). Argo CD ignores status in diffs by default (v3:
ignoreResourceStatusField: all), so selfHeal never fights the back-fill. */ -}}
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ printf "%s-mirrored-gateway-routes" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  collectResources: true
  resourceSelectors:
    - group: kro.run
      version: v1alpha1
      kind: GatewayRoute
      labelFilters:
        - key: bootstrap.projectsveltos.io/gateway-route-mirror
          operation: Equal
          value: "true"
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ printf "%s-gateway-route-status" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  # Hosts of vClusters: every non-virtual cluster. Only hosts carry labelled mirrors.
  sourceClusterSelector:
    {{- include "bootstrap.clusterSelector" (dict "root" . "excludeVirtual" true) | nindent 4 }}
  # The source vCluster's SveltosCluster, stamped on the mirror by the forward trigger.
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    namespace: {{ "{{ index .Resource.metadata.annotations \"bootstrap.projectsveltos.io/mirror-source-namespace\" }}" | quote }}
    name: {{ "{{ index .Resource.metadata.annotations \"bootstrap.projectsveltos.io/mirror-source-name\" }}" | quote }}
  eventSourceName: {{ printf "%s-mirrored-gateway-routes" .Release.Name | quote }}
  # One ClusterProfile per route, so one route cannot block another's back-fill.
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-gateway-route-status" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-gateway-route-status" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    # Rendered per event by the event-manager: .Resource is the host's mirrored GatewayRoute.
    projectsveltos.io/instantiate: ok
    # The manifest carries the host's kro status; this tells Sveltos to write the status
    # subresource on the vCluster's GatewayRoute instead of only its spec.
    projectsveltos.io/subresources: status
data:
  gatewayroute.yaml: |
    {{- .Files.Get "files/gateway-route-status/gatewayroute.yaml" | nindent 4 }}
