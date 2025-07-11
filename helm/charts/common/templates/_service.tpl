{{/*
Common service template for specific context structure
*/}}
{{- define "common.service" -}}
{{- $root := .root -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.names.fullname" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $root.Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ $root.Values.service.type | default "ClusterIP" }}
  {{- with $root.Values.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- with $root.Values.service.sessionAffinity }}
  sessionAffinity: {{ . }}
  {{- end }}
  ports:
    {{- with $root.Values.service.ports }}
    {{- toYaml . | nindent 4 }}
    {{- else }}
    - port: {{ $root.Values.service.port | default 80 | int }}
      targetPort: {{ $root.Values.service.targetPort | default "http" }}
      protocol: {{ $root.Values.service.protocol | default "TCP" }}
      name: {{ $root.Values.service.portName | default "http" }}
      {{- if and (eq ($root.Values.service.type | default "ClusterIP") "NodePort") $root.Values.service.nodePort }}
      nodePort: {{ $root.Values.service.nodePort | int }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end -}}