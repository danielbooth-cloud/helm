{{- include "bootstrap.valuesSecret" (dict "root" . "release" "hubble-relay") }}
---
# Ops' central Hubble UI dials each cluster's relay through this tailnet Service.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "hubble-relay") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "tailscale-operator") | quote }}
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
      releaseName: hubble-relay
      releaseNamespace: '{{ .Values.namespaces.kubeSystem }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "hubble-relay") | nindent 8 }}
