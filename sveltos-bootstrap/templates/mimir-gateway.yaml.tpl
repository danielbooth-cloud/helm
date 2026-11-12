{{- include "bootstrap.valuesSecret" (dict "root" . "release" "mimir-gateway") }}
---
# Workload clusters' Prometheus agents write to this name. The management cluster runs
# the real gateway and is excluded by its role label, so this cluster contributes no
# endpoints of its own.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "mimir-gateway") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeManagement" true "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: bedag/raw
      chartVersion: '{{ .Values.versions.raw }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: mimir-gateway
      releaseNamespace: '{{ .Values.namespaces.monitoring }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "mimir-gateway") | nindent 8 }}
