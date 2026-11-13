{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cloudflare-tunnel") }}
---
# Public north-south Gateway behind a Cloudflare Tunnel: GatewayRoutes with
# `gateway: cloudflare` attach here. Opt-in per cluster with the
# bootstrap.projectsveltos.io/cloudflare-tunnel=true label; the cluster's ClusterConfig
# supplies cloudflareTunnelId and cloudflareTunnelItem (the 1Password item holding the
# tunnel token).
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cloudflare-tunnel") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true "cloudflareTunnel" true "withdraw" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "reloader") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
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
      releaseName: cloudflare-tunnel
      releaseNamespace: '{{ .Values.namespaces.gateway }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cloudflare-tunnel") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: gateway.networking.k8s.io
      kind: Gateway
      name: cloudflare-gateway-programmed
      namespace: {{ default .Values.namespaces.gateway .Values.settings.gatewayNamespace | quote }}
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "{{ .Values.settings.cloudflareGatewayName }}" then return {healthy=true, message=""} end
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Programmed" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for the Cloudflare gateway"}
        end
      version: v1
    - featureID: Helm
      group: apps
      kind: Deployment
      name: cloudflared-available
      namespace: {{ default .Values.namespaces.gateway .Values.settings.gatewayNamespace | quote }}
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "cloudflared" then return {healthy=true, message=""} end
          if obj.status and obj.status.availableReplicas and obj.status.availableReplicas > 0 then
            return {healthy=true, message=""}
          end
          return {healthy=false, message="waiting for cloudflared to connect"}
        end
      version: v1
