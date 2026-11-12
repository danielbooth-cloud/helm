{{- include "bootstrap.valuesSecret" (dict "root" . "release" "gateway") }}
---
# Cilium serves it: Cilium and the Gateway API CRDs come with the cluster (Talos).
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "gateway") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
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
      releaseName: gateway
      releaseNamespace: '{{ .Values.namespaces.gateway }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "gateway") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: gateway.networking.k8s.io
      kind: Gateway
      name: gateway-programmed
      namespace: {{ default .Values.namespaces.gateway .Values.settings.gatewayNamespace | quote }}
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "{{ .Values.settings.gatewayName }}" then return {healthy=true, message=""} end
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Programmed" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for north-south gateway"}
        end
      version: v1
