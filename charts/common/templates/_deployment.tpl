{{/*
Common deployment template with safer dependency handling
*/}}
{{- define "common.deployment" -}}
{{- $root := .root -}}
{{- $dependencies := .dependencies | default dict -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.names.fullname" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $root.Values.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  replicas: {{ $root.Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      {{- with $root.Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "common.selectorLabels" $root | nindent 8 }}
    spec:
      #{{- with $root.Values.imagePullSecrets }}
      {{- with $root.Values.global.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.names.serviceAccountName" $root }}
      {{- with $root.Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ $root.Chart.Name }}
          {{- with $root.Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: "{{ $root.Values.image.repository }}:{{ $root.Values.image.tag | default $root.Chart.AppVersion }}"
          imagePullPolicy: {{ $root.Values.image.pullPolicy | default "IfNotPresent" }}
          {{- with $root.Values.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          env:
            {{- if $root.Values.env }}
            {{- toYaml $root.Values.env | nindent 12 }}
            {{- end }}
            {{- range $key, $val := $dependencies }}
            {{- if eq $val true }}
            {{- if eq $key "mysql" }}
            # Add MySQL environment variables
            {{- include "common.mysql.envVars" $root | nindent 12 }}
            {{- else if eq $key "mongodb" }}
            # Add MongoDB environment variables
            {{- include "common.mongodb.envVars" $root | nindent 12 }}
            {{- else if eq $key "redis" }}
            # Add Redis environment variables
            {{- include "common.redis.envVars" $root | nindent 12 }}
            {{- else if eq $key "rabbitmq" }}
            # Add RabbitMQ environment variables
            {{- include "common.rabbitmq.envVars" $root | nindent 12 }}
            {{- end }}
            {{- end }}
            {{- end }}
            {{- end }}
          {{- with $root.Values.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with $root.Values.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $root.Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $root.Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $root.Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}