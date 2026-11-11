{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cluster-issuer") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-issuer") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" true) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-issuer-secrets") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-issuer-cloudflare-secret") | quote }}
  helmCharts:
    - chartName: adfinis/cert-manager-issuers
      chartVersion: '{{ .Values.versions.certManagerIssuers }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: cluster-issuer
      releaseNamespace: '{{ .Values.namespaces.certManager }}'
      repositoryName: adfinis
      repositoryURL: https://charts.adfinis.com
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cluster-issuer") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: cert-manager.io
      kind: ClusterIssuer
      name: issuer-ready
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
