{{- define "redis.fullname" -}}
{{ printf "%s-%s" .Release.Name "redis" }}
{{- end }}

{{- define "redis.name" -}}
redis
{{- end }}

{{- define "redis.labels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
