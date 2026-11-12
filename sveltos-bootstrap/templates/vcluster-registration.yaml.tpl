{{- $config := dict
  "registrationNamespace" .Values.registrationNamespace
  "managementRole" (.Values.managementCluster.role | default "mgmt")
  "kubeconfigSecretSuffix" .Values.sveltosRegistration.kubeconfigSecretSuffix
  "apiPortName" .Values.vclusterRegistration.apiPortName
  "apiPort" .Values.vclusterRegistration.apiPort
  "apiTargetPort" .Values.vclusterRegistration.apiTargetPort
  "sharedClusterConfig" .Values.sharedClusterConfig -}}
{{- $preamble := printf "{{- $config := fromJson %s }}\n%s" (toJson $config | quote) (.Files.Get "files/vcluster-registration/preamble.tpl") -}}
# Registers each CAPI-provisioned vCluster on a non-virtual host as a virtual SveltosCluster
# here. The host's sveltos-agent reports the kubeconfig Secret; Ops reaches the API over the mesh.
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ printf "%s-vcluster-registrations" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  collectResources: true
  resourceSelectors:
    - group: ""
      version: v1
      kind: Secret
      # CAPI's <cluster>-kubeconfig Secret with its single "value" key; the vCluster provider
      # writes it as an unlabelled Opaque Secret, so the name and shape are all there is.
      evaluate: |
        function evaluate()
          local hs = {matching = false}
          if obj.data == nil or obj.data.value == nil or string.sub(obj.metadata.name, -11) ~= "-kubeconfig" then
            return hs
          end
          for key, _ in pairs(obj.data) do
            if key ~= "value" then
              return hs
            end
          end
          hs.matching = true
          return hs
        end
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ printf "%s-vcluster-register" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
spec:
  sourceClusterSelector:
    {{- include "bootstrap.clusterSelector" (dict "root" . "excludeVirtual" true) | nindent 4 }}
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    name: {{ .Values.managementCluster.name | quote }}
    namespace: {{ .Values.managementCluster.namespace | quote }}
  eventSourceName: {{ printf "%s-vcluster-registrations" .Release.Name | quote }}
  # One ClusterProfile per vCluster; deleting the vCluster withdraws its registration.
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-vcluster-registration" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
    - name: {{ printf "%s-vcluster-kubeconfig" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: Secret
    - name: {{ printf "%s-vcluster-config" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-vcluster-registration" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/instantiate: ok
data:
  cluster.yaml: |
    {{- $preamble | nindent 4 }}
    {{- .Files.Get "files/vcluster-registration/cluster.yaml" | nindent 4 }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-vcluster-kubeconfig" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/instantiate: ok
type: addons.projectsveltos.io/cluster-profile
data:
  kubeconfig.yaml: {{ printf "%s%s" $preamble (.Files.Get "files/vcluster-registration/kubeconfig.yaml") | b64enc | quote }}
---
# The profiles virtual clusters get read only clusterName from ClusterConfig.
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-vcluster-config" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/instantiate: ok
data:
  config.yaml: |
    {{- $preamble | nindent 4 }}
    {{- .Files.Get "files/vcluster-registration/config.yaml" | nindent 4 }}
