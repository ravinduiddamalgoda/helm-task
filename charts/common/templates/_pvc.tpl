{{- define "common.pvc" -}}
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include (printf "%s.fullname" .Chart.Name) . }}-data
  namespace: {{ .Values.global.namespace | default .Release.Namespace }}
  labels:
    {{- include (printf "%s.labels" .Chart.Name) . | nindent 4 }}
  {{- if and (eq .Values.global.deploymentMode "cluster") .Values.global.oci.enabled }}
  annotations:
    # OCI Block Volume annotations
    volume.beta.kubernetes.io/oci-volume-source: {{ .Values.oci.volumeSource | default "" | quote }}
    {{- if .Values.oci.volumeBackupId }}
    volume.beta.kubernetes.io/oci-volume-backup-id: {{ .Values.oci.volumeBackupId | quote }}
    {{- end }}
    {{- if .Values.oci.volumePerformance }}
    volume.beta.kubernetes.io/oci-volume-performance: {{ .Values.oci.volumePerformance | quote }}
    {{- end }}
  {{- end }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode | default "ReadWriteOnce" }}
  {{- if .Values.persistence.storageClass }}
  {{- if (eq "-" .Values.persistence.storageClass) }}
  storageClassName: ""
  {{- else }}
  storageClassName: {{ .Values.persistence.storageClass | default .Values.global.storageClass }}
  {{- end }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}
{{- end -}} 