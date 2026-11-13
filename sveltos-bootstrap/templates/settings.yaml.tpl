apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-settings" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
data:
  externalSecretsNamespace: {{ .Values.namespaces.externalSecrets | quote }}
  cephNamespace: {{ .Values.namespaces.ceph | quote }}
  onepasswordNamespace: {{ .Values.namespaces.onepassword | quote }}
  certificateNamespace: {{ .Values.namespaces.certManager | quote }}
  kubeSystemNamespace: {{ .Values.namespaces.kubeSystem | quote }}
  # Identifies the GatewayRoute RGD revision; vCluster CRD copies wait for kro to serve it.
  gatewayRouteRgdHash: {{ index .Values.applicationValues "gateway-route-rgd" | sha256sum | trunc 16 | quote }}
  argocdNamespace: {{ .Values.namespaces.argocd | quote }}
  clusterMeshIssuerName: {{ .Values.clusterMesh.issuerName | quote }}
  clusterMeshApiserverIpAddresses: {{ .Values.clusterMesh.apiserverIpAddresses | toJson | quote }}
  clusterMeshCaSecretName: {{ .Values.clusterMesh.caSecretName | quote }}
  clusterMeshCaItem: {{ .Values.clusterMesh.caItem | quote }}
  clusterMeshCaCertificateField: {{ .Values.clusterMesh.caCertificateField | quote }}
  clusterMeshCaPrivateKeyField: {{ .Values.clusterMesh.caPrivateKeyField | quote }}
  clusterMeshCertificateDuration: {{ .Values.clusterMesh.certificateDuration | quote }}
  clusterMeshCertificateRenewBefore: {{ .Values.clusterMesh.certificateRenewBefore | quote }}
  hubbleTlsSecretPrefix: {{ .Values.clusterMesh.hubbleTlsSecretPrefix | quote }}
  secretStoreName: {{ .Values.settings.secretStoreName | quote }}
  connectTokenSecretName: {{ .Values.settings.connectTokenSecretName | quote }}
  connectCredentialsSecretName: {{ .Values.settings.connectCredentialsSecretName | quote }}
  s3ServiceName: {{ .Values.settings.s3ServiceName | quote }}
  issuerName: {{ .Values.settings.issuerName | quote }}
  eabSecretName: {{ .Values.settings.eabSecretName | quote }}
  acmeAccountSecretName: {{ .Values.settings.acmeAccountSecretName | quote }}
  certificateCloudflareSecretName: {{ .Values.settings.certificateCloudflareSecretName | quote }}
  dnsCloudflareSecretName: {{ .Values.settings.dnsCloudflareSecretName | quote }}
  cloudflareSecretKey: {{ .Values.settings.cloudflareSecretKey | quote }}
  cloudflareSecretItem: {{ .Values.settings.cloudflareSecretItem | quote }}
  cloudflareSecretField: {{ .Values.settings.cloudflareSecretField | quote }}
  gatewayName: {{ .Values.settings.gatewayName | quote }}
  gatewayNamespace: {{ default .Values.namespaces.gateway .Values.settings.gatewayNamespace | quote }}
  cloudflareGatewayName: {{ .Values.settings.cloudflareGatewayName | quote }}
  cloudflareGatewayLoadBalancerIp: {{ .Values.settings.cloudflareGatewayLoadBalancerIp | quote }}
  cloudflareTunnelSecretName: {{ .Values.settings.cloudflareTunnelSecretName | quote }}
  cloudflareTunnelTokenField: {{ .Values.settings.cloudflareTunnelTokenField | quote }}
  cloudflaredReplicas: {{ .Values.settings.cloudflaredReplicas | quote }}
  cloudflaredImage: {{ printf "cloudflare/cloudflared:%s" .Values.versions.cloudflared | quote }}
  tailscaleProxyClass: {{ .Values.settings.tailscaleProxyClass | quote }}
  tailscaleProxyMtu: {{ .Values.settings.tailscaleProxyMtu | quote }}
  clusterApiCoreNamespace: {{ .Values.clusterApi.coreNamespace | quote }}
  clusterApiVclusterNamespace: {{ .Values.clusterApi.vclusterNamespace | quote }}
  clusterApiVersion: {{ .Values.versions.clusterApi | quote }}
  clusterApiVclusterVersion: {{ .Values.versions.clusterApiVcluster | quote }}
  clusterApiVclusterRbacProxyImage: {{ .Values.versions.clusterApiVclusterRbacProxy | quote }}
  vclusterApiServiceLabels: {{ .Values.vclusterRegistration.apiServiceLabels | toJson | quote }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-credentials" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
type: Opaque
data:
  {{- range $key := list "op-connect-token" "op-connect-credentials" "tailscale-client-secret" "zerossl-key-id" "zerossl-hmac-key" }}
  {{ $key }}: {{ required (printf "credentials.%s must be supplied" $key) (index $.Values.credentials $key) | b64enc | quote }}
  {{- end }}
---
{{- range .Values.managementResources }}
{{ toYaml . }}
---
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
data:
  desiredRevision: {{ default (toJson .Values | sha256sum) .Values.deploymentRevision | quote }}
