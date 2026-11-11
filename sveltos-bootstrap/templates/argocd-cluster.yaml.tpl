{{- if .Values.argocd.enabled }}
---
# Argo CD's identity inside every non-management cluster. Nothing here talks to Argo CD: the
# hub watches this token Secret and renders Argo CD's cluster Secret itself.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "argocd-cluster") | quote }}
spec:
  clusterSelector:
    matchLabels:
      bootstrap.projectsveltos.io/enabled: "true"
    matchExpressions:
      - key: bootstrap.projectsveltos.io/cluster
        operator: Exists
      - key: bootstrap.projectsveltos.io/argocd-role
        operator: NotIn
        values: [mgmt]
  syncMode: ContinuousWithDriftDetection
  stopMatchingBehavior: LeavePolicies
  continueOnConflict: false
  continueOnError: false
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  policyRefs:
    - name: {{ printf "%s-argocd-cluster" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-argocd-cluster" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
data:
  serviceaccount.yaml: |
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: argocd-manager
      namespace: {{ .Values.namespaces.kubeSystem }}
  clusterrolebinding.yaml: |
    # Argo CD deploys arbitrary applications, CRDs and cluster-scoped objects; its own default
    # for a managed cluster is the same cluster-admin authority.
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: argocd-manager
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: argocd-manager
        namespace: {{ .Values.namespaces.kubeSystem }}
  token.yaml: |
    # Long-lived token for the identity above; the label is what the hub's EventSource selects.
    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-manager-token
      namespace: {{ .Values.namespaces.kubeSystem }}
      labels:
        bootstrap.projectsveltos.io/argocd-registration: "true"
      annotations:
        kubernetes.io/service-account.name: argocd-manager
    type: kubernetes.io/service-account-token
{{- end }}
