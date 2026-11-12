{{- /* Rendered by the event-manager: .Cluster is the host cluster, .Resource the vCluster's CAPI kubeconfig Secret. */ -}}
{{- $host := index .Cluster.metadata.labels "bootstrap.projectsveltos.io/cluster" }}
{{- $capiCluster := index .Resource.metadata.labels "cluster.x-k8s.io/cluster-name" }}
{{- $namespace := .Resource.metadata.namespace }}
{{- /* Global Services join on namespace/name across the mesh, so the namespace must be unique fleet-wide. */ -}}
{{- if not (hasPrefix (printf "%s-" $host) $namespace) }}
{{- fail (printf "vCluster %s/%s: its namespace must start with %s-" $namespace $capiCluster $host) }}
{{- end }}
{{- $name := printf "%s-%s" $namespace $capiCluster }}
{{- $onManagement := eq (index .Cluster.metadata.labels "bootstrap.projectsveltos.io/role" | default "") $config.managementRole }}
{{- if not (or $onManagement (eq (index .Cluster.metadata.labels "bootstrap.projectsveltos.io/clustermesh" | default "") "true")) }}
{{- fail (printf "vCluster %s/%s: host %s is not in the Cluster Mesh, so its API is unreachable" $namespace $capiCluster $host) }}
{{- end }}
{{- $server := printf "https://%s.%s.svc:%v" $capiCluster $namespace $config.apiPort }}
