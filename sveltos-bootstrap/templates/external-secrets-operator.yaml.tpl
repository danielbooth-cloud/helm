{{- include "bootstrap.valuesSecret" (dict "root" . "release" "external-secrets-operator") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "external-secrets-operator") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "selector" "bootstrap") | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    # ESO's ClusterSecretStore authenticates against 1Password Connect.
    - {{ include "bootstrap.profileName" (dict "root" . "name" "onepassword-connect") | quote }}
  helmCharts:
    - chartName: external-secrets/external-secrets
      chartVersion: '{{ .Values.versions.externalSecrets }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: external-secrets-operator
      releaseNamespace: '{{ .Values.namespaces.externalSecrets }}'
      repositoryName: external-secrets
      repositoryURL: https://charts.external-secrets.io
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "external-secrets-operator") | nindent 8 }}
