apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.registrationNamespace | quote }}
  annotations:
    # Workload clusters' Terraform registers SveltosClusters here; uninstalling the
    # publisher must not delete them or their ClusterSummaries mid-withdrawal.
    helm.sh/resource-policy: keep
