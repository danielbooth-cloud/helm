{{- include "bootstrap.valuesSecret" (dict "root" . "release" "kubelet-csr-approver") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "kubelet-csr-approver") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
  helmCharts:
    - chartName: kubelet-csr-approver/kubelet-csr-approver
      chartVersion: '{{ .Values.versions.kubeletCsrApprover }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: kubelet-csr-approver
      releaseNamespace: '{{ .Values.namespaces.kubeSystem }}'
      repositoryName: kubelet-csr-approver
      repositoryURL: https://postfinance.github.io/kubelet-csr-approver
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "kubelet-csr-approver") | nindent 8 }}
