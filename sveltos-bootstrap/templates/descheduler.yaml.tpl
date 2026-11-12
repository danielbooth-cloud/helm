{{- include "bootstrap.valuesSecret" (dict "root" . "release" "descheduler") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "descheduler") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: descheduler/descheduler
      chartVersion: '{{ .Values.versions.descheduler }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: descheduler
      releaseNamespace: '{{ .Values.namespaces.kubeSystem }}'
      repositoryName: descheduler
      repositoryURL: https://kubernetes-sigs.github.io/descheduler
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "descheduler") | nindent 8 }}
