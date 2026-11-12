{{/*
Expand the name of the chart.
*/}}
{{- define "universal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "universal.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "universal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "universal.labels" -}}
helm.sh/chart: {{ include "universal.chart" . }}
{{ include "universal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "universal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "universal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "universal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (printf "%s-sa" (include "universal.fullname" .)) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Main-container mounts for the rendered config ConfigMap.
Nothing is mounted when configMountPath is empty, so a ConfigMap can be consumed
only by init containers or sidecars. With configSubPath every key (config and
certificates) is mounted as its own file under configMountPath, which leaves the
rest of that directory writable and untouched.
*/}}
{{- define "universal.configVolumeMounts" -}}
{{- if and .Values.config .Values.configMountPath }}
{{- if .Values.configSubPath }}
{{- $keys := keys .Values.config }}
{{- if kindIs "map" .Values.certificates }}
{{- $keys = concat $keys (keys .Values.certificates) }}
{{- end }}
{{- range ($keys | sortAlpha | uniq) }}
- name: {{ include "universal.name" $ }}-config
  mountPath: {{ printf "%s/%s" (trimSuffix "/" $.Values.configMountPath) . }}
  subPath: {{ . }}
{{- end }}
{{- else }}
- name: {{ include "universal.name" . }}-config
  mountPath: {{ .Values.configMountPath }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Sidecar containers: full container specs appended after the main container of a
deployment or statefulset. Rendered through tpl so they can reference the release,
for example {{ include "universal.fullname" . }}. Sidecars mount pod volumes by
name (persistence, extraVolumes, secretVolumes or the config volume).
*/}}
{{- define "universal.sidecars" -}}
{{- with .Values.sidecars }}
{{- tpl (toYaml .) $ }}
{{- end }}
{{- end }}
