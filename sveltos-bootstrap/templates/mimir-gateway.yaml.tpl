{{- include "bootstrap.valuesSecret" (dict "root" . "release" "mimir-gateway") }}
{{- /* The management cluster is identified in the selector by its cluster label, not its SveltosCluster name. */ -}}
{{- $managementCluster := .Values.managementCluster.cluster | default .Values.managementCluster.name }}
---
# Workload clusters' Prometheus agents write to this name. The management cluster runs
# the real gateway and is excluded, so this cluster contributes no endpoints of its own.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "mimir-gateway") | quote }}
spec:
  clusterSelector:
    matchLabels:
      bootstrap.projectsveltos.io/enabled: "true"
    matchExpressions:
      - key: bootstrap.projectsveltos.io/cluster
        operator: Exists
      - key: bootstrap.projectsveltos.io/cluster
        operator: NotIn
        values:
          - {{ $managementCluster | quote }}
  syncMode: ContinuousWithDriftDetection
  stopMatchingBehavior: LeavePolicies
  continueOnConflict: false
  continueOnError: false
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
