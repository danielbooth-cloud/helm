{{- include "bootstrap.valuesSecret" (dict "root" . "release" "kyverno") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "kyverno") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: kyverno/kyverno
      chartVersion: '{{ .Values.versions.kyverno }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: kyverno
      releaseNamespace: '{{ .Values.namespaces.kyverno }}'
      repositoryName: kyverno
      repositoryURL: https://kyverno.github.io/kyverno
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "kyverno") | nindent 8 }}
