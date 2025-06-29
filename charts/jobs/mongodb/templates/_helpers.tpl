{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb-backup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mongodb-backup.fullname" -}}
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
{{- define "mongodb-backup.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mongodb-backup.labels" -}}
helm.sh/chart: {{ include "mongodb-backup.chart" . }}
{{ include "mongodb-backup.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mongodb-backup.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mongodb-backup.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mongodb-backup.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mongodb-backup.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the MongoDB service name
*/}}
{{- define "mongodb.fullname" -}}
{{- printf "%s-mongodb" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get the MongoDB labels
*/}}
{{- define "mongodb.labels" -}}
app.kubernetes.io/name: mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }} 

{{/* Original database helpers from your file */}}
{{- define "common.ociBlockVolumeAnnotations" -}}
{{- if and (eq .Values.global.deploymentMode "cluster") (and .Values.global .Values.global.oci .Values.global.oci.enabled) }}
annotations:
  {{- if and .Values.oci .Values.oci.volumeSource }}
  volume.beta.kubernetes.io/oci-volume-source: {{ .Values.oci.volumeSource | quote }}
  {{- end }}
  {{- if and .Values.oci .Values.oci.volumeBackupId }}
  volume.beta.kubernetes.io/oci-volume-backup-id: {{ .Values.oci.volumeBackupId | quote }}
  {{- end }}
  {{- if and .Values.oci .Values.oci.volumePerformance }}
  volume.beta.kubernetes.io/oci-volume-performance: {{ .Values.oci.volumePerformance | quote }}
  {{- end }}
{{- end }}
{{- end -}}