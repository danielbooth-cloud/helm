{{- if .Values.sveltosRegistration.enabled }}
# Registers each cluster with Sveltos by writing its kubeconfig on the management cluster. Terraform
# writes a labelled Secret holding the cluster's Omni account key; Sveltos reacts to it and
# runs this Job, so the key never leaves the management plane. A key rotation rewrites the
# Secret and the event configures the kubeconfig again.
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventSource
metadata:
  name: {{ .Release.Name }}-sveltos-registrations
  namespace: {{ .Release.Namespace }}
spec:
  collectResources: true
  resourceSelectors:
    - group: ""
      version: v1
      kind: Secret
      labelFilters:
        - key: bootstrap.projectsveltos.io/registration
          operation: Equal
          value: "true"
---
apiVersion: lib.projectsveltos.io/v1beta1
kind: EventTrigger
metadata:
  name: {{ .Release.Name }}-sveltos-registration
  namespace: {{ .Release.Namespace }}
spec:
  # Events are detected on the management cluster itself. It is identified by the cluster
  # label the publisher sets on its own registration, which is unique per cluster.
  sourceClusterSelector:
    matchLabels:
      bootstrap.projectsveltos.io/cluster: {{ .Values.managementCluster.cluster | default .Values.managementCluster.name | quote }}
  # The Job runs on the management cluster, where Omni and the keys are.
  destinationCluster:
    kind: SveltosCluster
    apiVersion: lib.projectsveltos.io/v1beta1
    name: {{ .Values.managementCluster.name | quote }}
    namespace: {{ .Values.managementCluster.namespace | quote }}
  eventSourceName: {{ printf "%s-sveltos-registrations" .Release.Name | quote }}
  # One ClusterProfile per registration, so one cluster cannot block another's.
  oneForEvent: true
  policyRefs:
    - name: {{ printf "%s-sveltos-registration-job" .Release.Name | quote }}
      namespace: {{ .Release.Namespace | quote }}
      kind: ConfigMap
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-sveltos-registration-job" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
  annotations:
    # Rendered per event by the event-manager, where .Resource is the key Secret.
    projectsveltos.io/instantiate: ok
data:
  job.yaml: |
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: {{ "{{ index .Resource.metadata.labels \"bootstrap.projectsveltos.io/registration-cluster\" }}-sveltos-registration-{{ .Resource.metadata.resourceVersion }}" }}
      namespace: {{ .Release.Namespace }}
      labels:
        app.kubernetes.io/managed-by: {{ .Release.Name }}
    spec:
      backoffLimit: 3
      activeDeadlineSeconds: 600
      ttlSecondsAfterFinished: 3600
      template:
        metadata:
          labels:
            app.kubernetes.io/managed-by: {{ .Release.Name }}
        spec:
          serviceAccountName: {{ printf "%s-sveltos-registration" .Release.Name }}
          restartPolicy: Never
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534
            runAsGroup: 65534
            seccompProfile:
              type: RuntimeDefault
          initContainers:
            - name: omnictl
              image: {{ .Values.sveltosRegistration.image | quote }}
              command: [sh, -ec]
              args:
                - |
                  curl -fsSL -o /tools/omnictl.download \
                    "https://github.com/siderolabs/omni/releases/download/v{{ .Values.sveltosRegistration.omnictl.version }}/omnictl-linux-amd64"
                  echo "{{ .Values.sveltosRegistration.omnictl.sha256 }}  /tools/omnictl.download" | sha256sum -c -
                  chmod 0755 /tools/omnictl.download
                  mv /tools/omnictl.download /tools/omnictl
              securityContext: &container-security
                allowPrivilegeEscalation: false
                readOnlyRootFilesystem: true
                capabilities:
                  drop: [ALL]
              volumeMounts:
                - name: tools
                  mountPath: /tools
          containers:
            - name: sveltos-registration
              image: {{ .Values.sveltosRegistration.image | quote }}
              command: [bash, /scripts/sveltos-registration.sh]
              securityContext: *container-security
              env:
                - name: HOME
                  value: /tmp
                - name: CLUSTER
                  value: {{ "{{ index .Resource.metadata.labels \"bootstrap.projectsveltos.io/registration-cluster\" }}" }}
                - name: NAMESPACE
                  value: {{ "{{ .Resource.metadata.namespace }}" }}
                - name: OMNI_KEY_SECRET
                  value: {{ "{{ .Resource.metadata.name }}" }}
                - name: KUBECONFIG_SECRET
                  value: {{ printf "{{ index .Resource.metadata.labels \"bootstrap.projectsveltos.io/registration-cluster\" }}%s" .Values.sveltosRegistration.kubeconfigSecretSuffix }}
                - name: OMNI_ENDPOINT
                  value: {{ required "sveltosRegistration.omniEndpoint is required" .Values.sveltosRegistration.omniEndpoint | quote }}
                - name: KUBECONFIG_USER
                  value: {{ .Values.sveltosRegistration.kubeconfig.user | quote }}
                - name: KUBECONFIG_GROUPS
                  value: {{ join "," .Values.sveltosRegistration.kubeconfig.groups | quote }}
                - name: KUBECONFIG_TTL
                  value: {{ .Values.sveltosRegistration.kubeconfig.ttl | quote }}
                - name: OWNER
                  value: {{ .Release.Name | quote }}
              volumeMounts:
                - name: tools
                  mountPath: /tools
                  readOnly: true
                - name: script
                  mountPath: /scripts
                  readOnly: true
                - name: tmp
                  mountPath: /tmp
          volumes:
            - name: tools
              emptyDir: {}
            - name: tmp
              emptyDir: {}
            - name: script
              configMap:
                name: {{ printf "%s-sveltos-registration-script" .Release.Name }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-sveltos-registration-script" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
data:
  sveltos-registration.sh: |
    #!/usr/bin/env bash
    # Write one cluster's kubeconfig from its Omni account key; re-runs are idempotent.
    set -euo pipefail
    export PATH="/tools:$PATH"
    export OMNI_ENDPOINT

    : "${CLUSTER:?}" "${NAMESPACE:?}" "${OMNI_KEY_SECRET:?}" "${KUBECONFIG_SECRET:?}"
    : "${KUBECONFIG_USER:?}" "${KUBECONFIG_GROUPS:?}" "${KUBECONFIG_TTL:?}" "${OWNER:?}"

    work=$(mktemp -d)
    trap 'rm -rf -- "$work"' EXIT

    key=$(kubectl --namespace "$NAMESPACE" get secret "$OMNI_KEY_SECRET" \
      --output jsonpath='{.data.key}' | base64 -d)
    if [[ -z $key ]]; then
      echo "Secret $OMNI_KEY_SECRET holds no Omni key" >&2
      exit 1
    fi

    OMNI_SERVICE_ACCOUNT_KEY="$key" omnictl kubeconfig --service-account \
      --cluster "$CLUSTER" --user "$KUBECONFIG_USER" --groups "$KUBECONFIG_GROUPS" \
      --ttl "$KUBECONFIG_TTL" --merge=false --force-context-name "$CLUSTER" \
      "$work/kubeconfig" > /dev/null

    kubectl --namespace "$NAMESPACE" create secret generic "$KUBECONFIG_SECRET" \
      --from-file=kubeconfig="$work/kubeconfig" --dry-run=client --output yaml \
      | kubectl apply --server-side --field-manager="$OWNER" -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ printf "%s-sveltos-registration" .Release.Name | quote }}
  namespace: {{ .Release.Namespace | quote }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ printf "%s-sveltos-registration" .Release.Name | quote }}
  namespace: {{ .Values.registrationNamespace | quote }}
rules:
  # The registration namespace holds nothing but Omni account keys and kubeconfigs.
  - apiGroups: [""]
    resources: [secrets]
    verbs: [get, create, patch]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ printf "%s-sveltos-registration" .Release.Name | quote }}
  namespace: {{ .Values.registrationNamespace | quote }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ printf "%s-sveltos-registration" .Release.Name | quote }}
subjects:
  - kind: ServiceAccount
    name: {{ printf "%s-sveltos-registration" .Release.Name | quote }}
    namespace: {{ .Release.Namespace | quote }}
{{- end }}
