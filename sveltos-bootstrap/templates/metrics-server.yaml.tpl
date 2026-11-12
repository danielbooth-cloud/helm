{{- include "bootstrap.valuesSecret" (dict "root" . "release" "metrics-server") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "metrics-server") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "kubelet-csr-approver") | quote }}
  helmCharts:
    - chartName: metrics-server/metrics-server
      chartVersion: '{{ .Values.versions.metricsServer }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: metrics-server
      releaseNamespace: '{{ .Values.namespaces.kubeSystem }}'
      repositoryName: metrics-server
      repositoryURL: https://kubernetes-sigs.github.io/metrics-server/
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "metrics-server") | nindent 8 }}
