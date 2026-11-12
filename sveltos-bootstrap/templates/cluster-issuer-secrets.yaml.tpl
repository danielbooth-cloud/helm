{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cluster-issuer-secrets") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-issuer-secrets") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" true) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
  helmCharts:
    - chartName: yotron-helm-charts/k8s-secrets
      chartVersion: '{{ .Values.versions.k8sSecrets }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: cluster-issuer-secrets
      releaseNamespace: '{{ .Values.namespaces.certManager }}'
      repositoryName: yotron-helm-charts
      repositoryURL: http://helm.yotron.de
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cluster-issuer-secrets") | nindent 8 }}
