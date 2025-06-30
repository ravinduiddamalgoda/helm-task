{{/*
Define the common Doppler secret helper templates for specific context
*/}}
{{- define "common.dopplerSecret" -}}
{{- $root := .root -}}
{{- if $root.Values.doppler.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common.doppler.secretName" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  annotations:
    doppler.com/inject: "true"
    doppler.com/token-secret: {{ $root.Values.doppler.tokenSecretName }}
    doppler.com/project: {{ $root.Values.doppler.project }}
    doppler.com/config: {{ $root.Values.doppler.config }}
type: Opaque
{{- end }}
{{- end -}}