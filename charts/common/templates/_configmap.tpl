{{/*
Create a configmap
*/}}
{{- define "common.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.names.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  {{- toYaml .Values.configMapData | nindent 2 }}
{{- end -}} 