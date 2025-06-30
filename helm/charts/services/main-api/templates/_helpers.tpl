{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "main-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "main-api.fullname" -}}
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
{{- define "main-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "main-api.labels" -}}
helm.sh/chart: {{ include "main-api.chart" . }}
{{ include "main-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }} # Use the umbrella release name
{{- end }}

{{/*
Selector labels
*/}}
{{- define "main-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "main-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }} # Use the umbrella release name
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "main-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "main-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Helper to get the internal MySQL service name.
Assumes the MySQL sub-chart is named 'mysql'.
*/}}
{{- define "main-api.internalMysqlServiceName" -}}
{{- printf "%s-%s" .Release.Name "mysql" -}}
{{- end -}}

{{/*
Helper to get the internal MongoDB service name.
Assumes the MongoDB sub-chart is named 'mongodb'.
*/}}
{{- define "main-api.internalMongodbServiceName" -}}
{{- printf "%s-%s" .Release.Name "mongodb" -}}
{{- end -}}

{{/* --- Add other helpers as needed --- */}} 