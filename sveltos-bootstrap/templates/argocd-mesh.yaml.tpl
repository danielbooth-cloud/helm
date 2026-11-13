{{- include "bootstrap.valuesSecret" (dict "root" . "release" "argocd-mesh") }}
---
# Selectorless argocd-server shim on every mesh-connected workload cluster: no local
# endpoints, Cilium merges the management cluster's advertised argocd-server (its Service
# is Cluster Mesh global) as the only backend. vClusters are not in the mesh; their
# networking.replicateServices.fromHost entry maps the host's shim, whose ClusterIP the
# vCluster's DNS hands out, so the same in-cluster name resolves fleet-wide.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "argocd-mesh") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "clustermesh" true "excludeManagement" true "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
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
      releaseName: argocd-mesh
      releaseNamespace: '{{ .Values.namespaces.argocd }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "argocd-mesh") | nindent 8 }}
