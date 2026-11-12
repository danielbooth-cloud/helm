{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cluster-api-operator") }}
---
{{- include "bootstrap.valuesSecret" (dict "root" . "release" "cluster-api-providers") }}
---
# Every non-virtual cluster can host vClusters; virtual clusters never nest them.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-api") | quote }}
spec:
  {{- include "bootstrap.commonSpec" (dict "root" . "excludeVirtual" true) | nindent 2 }}
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cert-manager") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "kyverno") | quote }}
  # Providers are a second release: the operator's CRDs must exist before Helm can map them.
  helmCharts:
    - chartName: capi-operator/cluster-api-operator
      chartVersion: '{{ .Values.versions.clusterApiOperator }}'
      helmChartAction: Install
      options:
        timeout: 10m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: cluster-api-operator
      releaseNamespace: '{{ .Values.clusterApi.operatorNamespace }}'
      repositoryName: capi-operator
      repositoryURL: https://kubernetes-sigs.github.io/cluster-api-operator
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cluster-api-operator") | nindent 8 }}
    - chartName: bedag/raw
      chartVersion: '{{ .Values.versions.raw }}'
      helmChartAction: Install
      options:
        timeout: 10m
        wait: true
        waitForJobs: true
      releaseName: cluster-api-providers
      releaseNamespace: '{{ .Values.clusterApi.operatorNamespace }}'
      repositoryName: bedag
      repositoryURL: https://bedag.github.io/helm-charts
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "cluster-api-providers") | nindent 8 }}
  validateHealths:
    {{- range $provider := list (dict "kind" "CoreProvider" "name" "cluster-api" "namespace" .Values.clusterApi.coreNamespace) (dict "kind" "InfrastructureProvider" "name" "vcluster" "namespace" .Values.clusterApi.vclusterNamespace) }}
    - featureID: Helm
      group: operator.cluster.x-k8s.io
      version: v1alpha2
      kind: {{ $provider.kind }}
      name: {{ $provider.name | quote }}
      namespace: {{ $provider.namespace | quote }}
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
    {{- end }}
