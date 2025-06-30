{{/*
Debug template to print context structure
*/}}
{{- define "common.debug.context" -}}
{{- /* This will capture the full context structure */ -}}
Context dump:
.Release: {{ .Release | toYaml }}
.Chart: {{ .Chart | toYaml }}
.Values: {{ .Values | toYaml }}
.Template: {{ .Template | toYaml }}
{{- end -}}