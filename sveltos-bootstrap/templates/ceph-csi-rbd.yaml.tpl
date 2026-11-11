{{- include "bootstrap.valuesSecret" (dict "root" . "release" "ceph-csi-rbd") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "ceph-csi-rbd") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
  helmCharts:
    - chartName: ceph-csi/ceph-csi-rbd
      chartVersion: '{{ .Values.versions.cephCsi }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: ceph-csi-rbd
      releaseNamespace: '{{ .Values.namespaces.ceph }}'
      repositoryName: ceph-csi
      repositoryURL: https://ceph.github.io/csi-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "ceph-csi-rbd") | nindent 8 }}
  # The StorageClass works only once ESO has synced the client key.
  validateHealths:
    - featureID: Helm
      group: external-secrets.io
      kind: ExternalSecret
      name: ceph-rbd-credential-ready
      namespace: '{{ .Values.namespaces.ceph }}'
      script: |
        function evaluate(obj)
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Ready" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for Ready condition"}
        end
      version: v1
