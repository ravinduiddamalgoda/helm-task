{{/* 
Global value helpers for safe access to nested values 
*/}}

{{- define "common.safe.global" -}}
{{- if .Values }}
{{- if .Values.global }}
{{- .Values.global }}
{{- else }}
{{- dict }}
{{- end }}
{{- else }}
{{- dict }}
{{- end }}
{{- end -}}

{{/* Helper to safely check if global RabbitMQ internal connection is enabled */}}
{{- define "common.global.rabbitmq.internal.enabled" -}}
{{- if .Values.global }}
  {{- if .Values.global.rabbitmq }}
    {{- if .Values.global.rabbitmq.connection }}
      {{- if .Values.global.rabbitmq.connection.internal }}
        {{- if .Values.global.rabbitmq.connection.internal.enabled }}
          {{- .Values.global.rabbitmq.connection.internal.enabled }}
        {{- else }}
          {{- false }}
        {{- end }}
      {{- else }}
        {{- false }}
      {{- end }}
    {{- else }}
      {{- false }}
    {{- end }}
  {{- else }}
    {{- false }}
  {{- end }}
{{- else }}
  {{- false }}
{{- end }}
{{- end -}}

{{/* Helper to safely check if global RabbitMQ external connection is enabled */}}
{{- define "common.global.rabbitmq.external.enabled" -}}
{{- if .Values.global }}
  {{- if .Values.global.rabbitmq }}
    {{- if .Values.global.rabbitmq.connection }}
      {{- if .Values.global.rabbitmq.connection.external }}
        {{- if .Values.global.rabbitmq.connection.external.enabled }}
          {{- .Values.global.rabbitmq.connection.external.enabled }}
        {{- else }}
          {{- false }}
        {{- end }}
      {{- else }}
        {{- false }}
      {{- end }}
    {{- else }}
      {{- false }}
    {{- end }}
  {{- else }}
    {{- false }}
  {{- end }}
{{- else }}
  {{- false }}
{{- end }}
{{- end -}}

{{/* Helper for safely getting global RabbitMQ service port */}}
{{- define "common.global.rabbitmq.service.port" -}}
{{- if .Values.global }}
  {{- if .Values.global.rabbitmq }}
    {{- if .Values.global.rabbitmq.cluster }}
      {{- if .Values.global.rabbitmq.cluster.service }}
        {{- if .Values.global.rabbitmq.cluster.service.port }}
          {{- .Values.global.rabbitmq.cluster.service.port }}
        {{- else }}
          {{- 5672 }}
        {{- end }}
      {{- else }}
        {{- 5672 }}
      {{- end }}
    {{- else }}
      {{- 5672 }}
    {{- end }}
  {{- else }}
    {{- 5672 }}
  {{- end }}
{{- else }}
  {{- 5672 }}
{{- end }}
{{- end -}}

{{/* Helper for safe access to secrets */}}
{{- define "common.safe.secret" -}}
{{- $path := . -}}
{{- if $path.default }}{{ $path.default }}{{ else }}""{{ end }}
{{- end -}}