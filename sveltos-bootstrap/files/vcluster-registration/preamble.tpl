{{- /* Rendered by the event-manager: .Cluster is the host cluster, .Resource the vCluster's CAPI kubeconfig Secret. */ -}}
{{- $host := index .Cluster.metadata.labels "bootstrap.projectsveltos.io/cluster" }}
{{- $capiCluster := trimSuffix "-kubeconfig" .Resource.metadata.name }}
{{- $namespace := .Resource.metadata.namespace }}
{{- /* Registered under the CAPI Cluster name, which must be unique fleet-wide: it names the
SveltosCluster, the Argo CD cluster and the mesh global Service. */ -}}
{{- $name := $capiCluster }}
{{- $onManagement := eq (index .Cluster.metadata.labels "bootstrap.projectsveltos.io/role" | default "") $config.managementRole }}
{{- if not (or $onManagement (eq (index .Cluster.metadata.labels "bootstrap.projectsveltos.io/clustermesh" | default "") "true")) }}
{{- fail (printf "vCluster %s/%s: host %s is not in the Cluster Mesh, so its API is unreachable" $namespace $capiCluster $host) }}
{{- end }}
{{- $server := printf "https://%s.%s.svc:%v" $capiCluster $namespace $config.apiPort }}
