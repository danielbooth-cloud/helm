{{- include "bootstrap.valuesSecret" (dict "root" . "release" "kro") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "kro") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
  helmCharts:
    - chartName: kro
      chartVersion: '{{ .Values.versions.kro }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: kro
      releaseNamespace: '{{ .Values.namespaces.kro }}'
      repositoryName: kro
      repositoryURL: oci://registry.k8s.io/kro/charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "kro") | nindent 8 }}
