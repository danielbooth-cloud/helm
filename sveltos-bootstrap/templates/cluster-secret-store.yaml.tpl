{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cluster-secret-store") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" true) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "external-secrets-operator") | quote }}
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
      releaseName: cluster-secret-store
      releaseNamespace: '{{ .Values.namespaces.externalSecrets }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cluster-secret-store") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: external-secrets.io
      kind: ClusterSecretStore
      name: {{ .Values.settings.secretStoreName | quote }}
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
