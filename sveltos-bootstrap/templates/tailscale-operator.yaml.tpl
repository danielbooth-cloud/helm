{{- include "bootstrap.valuesSecret" (dict "root" . "release" "tailscale-operator") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "tailscale-operator") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" true) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "reloader") | quote }}
  helmCharts:
    - chartName: tailscale/tailscale-operator
      chartVersion: '{{ .Values.versions.tailscale }}'
      helmChartAction: Install
      options:
        timeout: 300s
        upgradeOptions:
          maxHistory: 10
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: tailscale-operator
      releaseNamespace: '{{ .Values.namespaces.tailscale }}'
      repositoryName: tailscale
      repositoryURL: https://pkgs.tailscale.com/helmcharts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "tailscale-operator") | nindent 8 }}
