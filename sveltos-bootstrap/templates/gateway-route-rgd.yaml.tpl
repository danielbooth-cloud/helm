{{- include "bootstrap.valuesSecret" (dict "root" . "release" "gateway-route-rgd") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "gateway-route-rgd") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "kro") | quote }}
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
      releaseName: gateway-route-rgd
      releaseNamespace: '{{ .Values.namespaces.kro }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "gateway-route-rgd") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: kro.run
      kind: ResourceGraphDefinition
      name: gateway-route-active
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "gatewayroute.kro.run" then
            return {healthy=true, message=""}
          end
          return {healthy=obj.status ~= nil and obj.status.state == "Active", message="waiting for GatewayRoute RGD to become Active"}
        end
      version: v1alpha1
