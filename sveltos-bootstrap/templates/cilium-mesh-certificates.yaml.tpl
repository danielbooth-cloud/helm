{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cilium-mesh-certificates") }}
---
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cilium-mesh-certificates") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "clustermesh" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
  helmCharts:
    - chartName: bedag/raw
      chartVersion: '{{ .Values.versions.raw }}'
      helmChartAction: Install
      options:
        timeout: 10m
        wait: true
        waitForJobs: true
      releaseName: cilium-mesh-certificates
      releaseNamespace: '{{ .Values.namespaces.kubeSystem }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cilium-mesh-certificates") | nindent 8 }}
  validateHealths:
    - featureID: Helm
      group: external-secrets.io
      version: v1
      kind: ExternalSecret
      namespace: '{{ .Values.namespaces.certManager }}'
      name: mesh-ca-ready
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "{{ .Values.clusterMesh.caSecretName }}" then return {healthy=true, message=""} end
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Ready" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for mesh CA secret"}
        end
    - featureID: Helm
      group: cert-manager.io
      version: v1
      kind: ClusterIssuer
      name: mesh-issuer-ready
      script: |
        function evaluate(obj)
          if obj.metadata.name ~= "{{ .Values.clusterMesh.issuerName }}" then return {healthy=true, message=""} end
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Ready" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for mesh issuer"}
        end
    - featureID: Helm
      group: cert-manager.io
      version: v1
      kind: Certificate
      namespace: '{{ .Values.namespaces.kubeSystem }}'
      name: mesh-certificates-ready
      script: |
        function evaluate(obj)
          local labels = obj.metadata.labels or {}
          if labels["bootstrap.projectsveltos.io/cilium-certificate"] ~= "true" then return {healthy=true, message=""} end
          local issuer = obj.spec and obj.spec.issuerRef or {}
          if issuer.group ~= "cert-manager.io" or issuer.kind ~= "ClusterIssuer"
            or issuer.name ~= "{{ .Values.clusterMesh.issuerName }}" then
            return {healthy=false, message="unexpected Cilium certificate issuer"}
          end
          if obj.status and obj.status.conditions then
            for _, condition in ipairs(obj.status.conditions) do
              if condition.type == "Ready" and condition.status == "True" then
                return {healthy=true, message=""}
              end
            end
          end
          return {healthy=false, message="waiting for Cilium certificate"}
        end
