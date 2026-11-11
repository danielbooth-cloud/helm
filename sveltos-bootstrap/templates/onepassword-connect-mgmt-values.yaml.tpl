# Per-cluster Helm values for the management cluster's Connect release, picked up by
# the profile's optional `<cluster>-bootstrap-onepassword-connect` source. Only the
# management cluster runs the CI and Terraform tooling whose secrets come from here,
# so it prefers its own replica instead of round-robining over the mesh.
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-bootstrap-onepassword-connect" .Values.managementCluster.name | quote }}
  namespace: {{ .Values.managementCluster.namespace | quote }}
  annotations:
    projectsveltos.io/template: ok
type: addons.projectsveltos.io/cluster-profile
stringData:
  values.yaml: |
    connect:
      serviceAnnotations:
        service.cilium.io/affinity: local
