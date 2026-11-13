{{- if .Values.argocd.enabled }}
{{- include "bootstrap.valuesSecret" (dict "root" . "release" "argocd") }}
---
# Argo CD lives on the management cluster only: it is the hub every other cluster is
# registered into. The role label keeps the workload-side profiles off this cluster.
apiVersion: config.projectsveltos.io/v1beta1
kind: ClusterProfile
metadata:
  name: {{ include "bootstrap.profileName" (dict "root" . "name" "argocd-mgr") | quote }}
spec:
  clusterSelector:
    {{- include "bootstrap.mgmtSelector" . | nindent 4 }}
  syncMode: ContinuousWithDriftDetection
  stopMatchingBehavior: LeavePolicies
  continueOnConflict: false
  continueOnError: false
  templateResourceRefs:
    {{- include "bootstrap.chartReferences" (dict "root" . "credentials" false) | nindent 4 }}
  dependsOn:
    - {{ include "bootstrap.profileName" (dict "root" . "name" "namespaces") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "cluster-secret-store") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "gateway") | quote }}
    - {{ include "bootstrap.profileName" (dict "root" . "name" "kro") | quote }}
  helmCharts:
    - chartName: argo/argo-cd
      chartVersion: '{{ .Values.versions.argoCd }}'
      helmChartAction: Install
      options:
        timeout: 15m
        upgradeOptions:
          upgradeCRDs: true
        wait: true
        waitForJobs: true
      releaseName: argocd
      releaseNamespace: '{{ .Values.namespaces.argocd }}'
      repositoryName: argo
      repositoryURL: https://argoproj.github.io/argo-helm
      valuesFrom:
        {{- include "bootstrap.valuesFrom" (dict "root" . "release" "argocd") | nindent 8 }}
  policyRefs:
    - name: {{ printf "%s-argocd-resources" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
# Repository credentials, the OIDC client and the app-of-apps seed are plain objects, so they
# are policyRefs rather than another Helm release. Every value comes from ClusterConfig.
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-argocd-resources" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
data:
  repository.yaml: |
    apiVersion: external-secrets.io/v1
    kind: ExternalSecret
    metadata:
      name: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoSecretName }}" }}
      namespace: {{ .Values.namespaces.argocd }}
    spec:
      refreshInterval: 1h
      secretStoreRef:
        kind: ClusterSecretStore
        name: {{ "{{ (getResource \"BootstrapSettings\").data.secretStoreName }}" }}
      target:
        name: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoSecretName }}" }}
        template:
          # Merge keeps the fetched sshPrivateKey, so no ESO expressions clash with Sveltos templating.
          mergePolicy: Merge
          metadata:
            labels:
              # Argo CD discovers repository credentials by this label, not the Secret name.
              argocd.argoproj.io/secret-type: repository
          # Argo CD matches credentials to an Application by url; without it git falls back to an SSH agent.
          data:
            type: git
            name: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoName }}" }}
            url: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoUrl }}" }}
      data:
        - secretKey: sshPrivateKey
          remoteRef:
            key: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoSecretItem }}" }}
            property: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoPrivateKeyField }}" }}
  oidc.yaml: |
    apiVersion: external-secrets.io/v1
    kind: ExternalSecret
    metadata:
      name: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcSecretName }}" }}
      namespace: {{ .Values.namespaces.argocd }}
    spec:
      secretStoreRef:
        kind: ClusterSecretStore
        name: {{ "{{ (getResource \"BootstrapSettings\").data.secretStoreName }}" }}
      target:
        name: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcSecretName }}" }}
        template:
          metadata:
            labels:
              # argocd-cm resolves $<secret>:<key> only from secrets carrying this label.
              app.kubernetes.io/part-of: argocd
      data:
        - secretKey: clientID
          remoteRef:
            key: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcSecretItem }}" }}
            property: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcClientIdField }}" }}
        - secretKey: clientSecret
          remoteRef:
            key: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcSecretItem }}" }}
            property: {{ "{{ (getResource \"ClusterConfig\").data.argocdOidcClientSecretField }}" }}
  application.yaml: |
    # No syncPolicy: the app-of-apps stays manual until synced by hand, and it does not cascade,
    # so removing or upgrading the release never deletes what the repository owns.
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: {{ "{{ (getResource \"ClusterConfig\").data.argocdAppName }}" }}
      namespace: {{ .Values.namespaces.argocd }}
    spec:
      project: default
      destination:
        name: in-cluster
        namespace: default
      source:
        repoURL: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoUrl }}" }}
        targetRevision: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoBranch }}" }}
        path: {{ "{{ (getResource \"ClusterConfig\").data.argocdRepoPath }}" }}
  route.yaml: |
    # Tailnet only: kro publishes the route's DNS record to the gateway's Tailscale IP.
    apiVersion: kro.run/v1alpha1
    kind: GatewayRoute
    metadata:
      name: argocd
      namespace: {{ .Values.namespaces.argocd }}
    spec:
      gateway: tailscale
      hostname: {{ "{{ (getResource \"ClusterConfig\").data.argocdDomain }}" }}
      serviceName: argocd-server
      servicePort: 8080
      # The UI's application watch is a long-lived SSE stream; Envoy's default 15s
      # route timeout would cut it off and force constant reconnects.
      timeouts:
        request: "0s"
{{- end }}
