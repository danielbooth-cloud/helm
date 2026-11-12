{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cert-manager") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "reloader") | quote }}
  helmCharts:
    - chartName: jetstack/cert-manager
      chartVersion: '{{ .Values.versions.certManager }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: cert-manager
      releaseNamespace: '{{ .Values.namespaces.certManager }}'
      repositoryName: jetstack
      repositoryURL: https://charts.jetstack.io
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cert-manager") | nindent 8 }}
