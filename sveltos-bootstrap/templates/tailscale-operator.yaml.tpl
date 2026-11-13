{{- include "bootstrap.valuesSecret" (dict "root" . "release" "tailscale-operator") }}
---
{{- include "bootstrap.valuesSecret" (dict "root" . "release" "tailscale-proxy-class") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "tailscale-operator") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
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
    # A second release: the ProxyClass CRD comes with the operator chart, and the operator's
    # defaultProxyClass names this one.
    - chartName: bedag/raw
      chartVersion: '{{ .Values.versions.raw }}'
      helmChartAction: Install
      options:
        timeout: 300s
        wait: true
        waitForJobs: true
      releaseName: tailscale-proxy-class
      releaseNamespace: '{{ .Values.namespaces.tailscale }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "tailscale-proxy-class") | nindent 8 }}
