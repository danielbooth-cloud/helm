{{- $prefix := printf "%s-%s" .Values.managementCluster.namespace .Values.managementCluster.name -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-bootstrap-config" $prefix | quote }}
  namespace: {{ .Values.registrationNamespace | quote }}
data:
  {{- range $key, $value := merge (dict) (deepCopy .Values.clusterConfig) (deepCopy .Values.sharedClusterConfig) }}
  {{ $key }}: {{ $value | toString | quote }}
  {{- end }}
