{{/*
Define the common Doppler secret helper templates
*/}}
{{- define "common.dopplerSecret" -}}
{{- $context := . -}}
{{- if $context.doppler.enabled }}
{{- $fullName := default (printf "%s-%s" $context.Release.Name $context.Chart.Name) $context.name -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ default (printf "%s-doppler" $fullName) $context.doppler.managedSecretName }}
  labels:
    app.kubernetes.io/name: {{ default $context.Chart.Name $context.name }}
    app.kubernetes.io/instance: {{ $context.Release.Name }}
    helm.sh/chart: {{ printf "%s-%s" $context.Chart.Name $context.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/managed-by: {{ $context.Release.Service }}
  annotations:
    doppler.com/inject: "true"
    doppler.com/token-secret: {{ $context.doppler.tokenSecretName }}
    doppler.com/project: {{ $context.doppler.project }}
    doppler.com/config: {{ $context.doppler.config }}
type: Opaque
{{- end }}
{{- end -}}