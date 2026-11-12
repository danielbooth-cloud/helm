{{- include "bootstrap.valuesSecret" (dict "root" . "release" "external-dns") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "external-dns") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "reloader") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "external-dns-token-secret") | quote }}
  helmCharts:
    - chartName: external-dns/external-dns
      chartVersion: '{{ .Values.versions.externalDns }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: external-dns
      releaseNamespace: '{{ .Values.namespaces.externalDns }}'
      repositoryName: external-dns
      repositoryURL: https://kubernetes-sigs.github.io/external-dns/
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "external-dns") | nindent 8 }}
