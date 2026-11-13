# Virtual clusters get kro's GatewayRoute API without the RGD: ListenerSets cannot sync to the
# host. Each GatewayRoute is mirrored to the host, whose kro builds the listener, certificate and DNS.
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "gateway-route-crd") | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
data:
  crd.yaml: |
    {{- .Files.Get "files/gateway-route-mirror/crd.yaml" | nindent 4 }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "gateway-route-crd") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "virtualOnly" true) | nindent 2 }}
  templateResourceRefs:
    - identifier: GatewayRouteCRD
      resource:
        apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: gatewayroutes.kro.run
  policyRefs:
    - kind: ConfigMap
      name: {{ include "bootstrap.profileName" (dict "root" . "name" "gateway-route-crd") | quote }}
      namespace: {{ .Release.Namespace | quote }}
      deploymentType: Remote
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ printf "%s-gateway-routes" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  collectResources: true
  resourceSelectors:
    - group: kro.run
      version: v1alpha1
      kind: GatewayRoute
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ printf "%s-gateway-route-mirror" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  sourceClusterSelector:
    {{- include "bootstrap.clusterSelector" (dict "root" . "virtualOnly" true) | nindent 4 }}
  # The host's SveltosCluster, recorded on the virtual one at registration.
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    namespace: {{ "{{ index .Cluster.metadata.annotations \"bootstrap.projectsveltos.io/host-cluster-namespace\" }}" | quote }}
    name: {{ "{{ index .Cluster.metadata.annotations \"bootstrap.projectsveltos.io/host-cluster-name\" }}" | quote }}
  eventSourceName: {{ printf "%s-gateway-routes" .Release.Name | quote }}
  # One ClusterProfile per route; deleting the route withdraws its mirror.
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-gateway-route-mirror" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-gateway-route-mirror" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/instantiate: ok
data:
  gatewayroute.yaml: |
    {{- .Files.Get "files/gateway-route-mirror/gatewayroute.yaml" | nindent 4 }}
