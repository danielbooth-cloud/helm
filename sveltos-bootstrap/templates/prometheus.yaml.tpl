{{- include "bootstrap.valuesSecret" (dict "root" . "release" "prometheus") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "prometheus") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    # Its PVC uses the Ceph RBD default StorageClass.
    - {{ include "bootstrap.profileName" (dict "root" . "name" "ceph-csi-rbd") | quote }}
  helmCharts:
    - chartName: prometheus-community/prometheus
      chartVersion: '{{ .Values.versions.prometheus }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: prometheus
      releaseNamespace: '{{ .Values.namespaces.monitoring }}'
      repositoryName: prometheus-community
      repositoryURL: https://prometheus-community.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "prometheus") | nindent 8 }}
