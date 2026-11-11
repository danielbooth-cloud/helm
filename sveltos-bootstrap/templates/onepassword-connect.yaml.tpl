{{- include "bootstrap.valuesSecret" (dict "root" . "release" "onepassword-connect") }}
---
# One replica per cluster behind one ClusterMesh global Service: ESO resolves
# connectHost locally and falls back to a peer's replica when this one is down.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "onepassword-connect") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" true) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: connect
      chartVersion: '{{ .Values.versions.onePasswordConnect }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: onepassword-connect
      releaseNamespace: '{{ .Values.namespaces.onepassword }}'
      repositoryName: 1password
      repositoryURL: https://1password.github.io/connect-helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "onepassword-connect") | nindent 8 }}
