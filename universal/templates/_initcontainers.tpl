{{/*
Init containers shared by the deployment, statefulset and cronjob templates.

Each entry in .Values.initContainers accepts name, image{repository,tag,pullPolicy},
command, args, envs, envFrom, volumeMounts, securityContext and resources. The
persistence volumes are mounted automatically so a prep step can reach the data dir;
extra mounts come from the entry's own volumeMounts plus the pod-level extraVolumes.
*/}}
{{- define "universal.initContainers" -}}
{{- $top := . -}}
{{- range .Values.initContainers }}
- name: {{ required "initContainers[].name is required" .name | quote }}
  {{- $repository := required "initContainers[].image.repository is required" .image.repository }}
  {{- $tag := .image.tag | default $top.Values.image.tag | default $top.Chart.AppVersion }}
  image: {{ printf "%s:%s" $repository $tag | quote }}
  imagePullPolicy: {{ .image.pullPolicy | default $top.Values.image.pullPolicy }}
  {{- with .command }}
  command:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .args }}
  args:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .envs }}
  env:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .envFrom }}
  envFrom:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .securityContext }}
  securityContext:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:{{ toYaml . | nindent 4 }}
  {{- end }}
  {{- if or $top.Values.persistence.data.enabled $top.Values.persistence.logs.enabled .volumeMounts }}
  volumeMounts:
    {{- if $top.Values.persistence.data.enabled }}
    - name: {{ include "universal.name" $top }}-data
      mountPath: {{ $top.Values.persistence.data.mountPath }}
    {{- end }}
    {{- if $top.Values.persistence.logs.enabled }}
    - name: {{ include "universal.name" $top }}-logs
      mountPath: {{ $top.Values.persistence.logs.mountPath }}
    {{- end }}
    {{- with .volumeMounts }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
