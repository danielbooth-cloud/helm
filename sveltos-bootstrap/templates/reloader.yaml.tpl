{{- include "bootstrap.valuesSecret" (dict "root" . "release" "reloader") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "reloader") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: stakater/reloader
      chartVersion: '{{ .Values.versions.reloader }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: reloader
      releaseNamespace: '{{ .Values.namespaces.reloader }}'
      repositoryName: stakater
      repositoryURL: https://stakater.github.io/stakater-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "reloader") | nindent 8 }}
