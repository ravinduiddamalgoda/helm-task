{{/* 
Basic helpers file with minimal conditionals
*/}}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.names.fullname" -}}
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
{{- define "common.names.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the name
*/}}
{{- define "common.names.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.names.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common service template
*/}}
{{- define "common.service" -}}
{{- $fullName := include "common.names.fullname" . -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  {{- with .Values.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- with .Values.service.sessionAffinity }}
  sessionAffinity: {{ . }}
  {{- end }}
  ports:
    {{- with .Values.service.ports }}
    {{- toYaml . | nindent 4 }}
    {{- else }}
    - port: {{ .Values.service.port | default 80 }}
      targetPort: {{ .Values.service.targetPort | default "http" }}
      protocol: {{ .Values.service.protocol | default "TCP" }}
      name: {{ .Values.service.portName | default "http" }}
      {{- if and (eq (.Values.service.type | default "ClusterIP") "NodePort") .Values.service.nodePort }}
      nodePort: {{ .Values.service.nodePort }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
{{- end -}}

{{/*
Common deployment template
*/}}
{{- define "common.deployment" -}}
{{- $fullName := include "common.names.fullname" . -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.names.serviceAccountName" . }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          {{- with .Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          {{- with .Values.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.ports }}
          ports:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}

{{/*
Define the common Doppler secret helper templates
*/}}
{{- define "common.dopplerSecret" -}}
{{- if .Values.doppler.enabled }}
{{- $fullName := include "common.names.fullname" . -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common.doppler.secretName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  annotations:
    doppler.com/inject: "true"
    doppler.com/token-secret: {{ .Values.doppler.tokenSecretName }}
    doppler.com/project: {{ .Values.doppler.project }}
    doppler.com/config: {{ .Values.doppler.config }}
type: Opaque
{{- end }}
{{- end -}}

{{- define "common.doppler.secretName" -}}
{{- if .Values.doppler.managedSecretName -}}
    {{- .Values.doppler.managedSecretName -}}
{{- else -}}
    {{- printf "%s-doppler" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.doppler.annotations" -}}
{{- if .Values.doppler.enabled }}
doppler.com/watch: "true"
{{- end }}
{{- end -}}

{{/*
Service names for internal services
*/}}
{{- define "common.internalMysqlServiceName" -}}
{{- printf "%s-mysql" .Release.Name }}
{{- end -}}

{{- define "common.internalMongodbServiceName" -}}
{{- printf "%s-mongodb" .Release.Name }}
{{- end -}}

{{- define "common.internalRedisServiceName" -}}
{{- printf "%s-redis" .Release.Name }}
{{- end -}}

{{- define "common.internalRabbitmqServiceName" -}}
{{- printf "%s-rabbitmq" .Release.Name }}
{{- end -}}

{{/*
Secret names for database services
*/}}
{{- define "common.mongodb.secretName" -}}
{{- if .Values.mongodb.existingSecret -}}
    {{- .Values.mongodb.existingSecret -}}
{{- else if .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-mongodb" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.mysql.secretName" -}}
{{- if .Values.mysql.existingSecret -}}
    {{- .Values.mysql.existingSecret -}}
{{- else if .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-mysql" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.redis.secretName" -}}
{{- if .Values.redis.existingSecret -}}
    {{- .Values.redis.existingSecret -}}
{{- else if .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-redis" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.rabbitmq.secretName" -}}
{{- if .Values.rabbitmq.existingSecret -}}
    {{- .Values.rabbitmq.existingSecret -}}
{{- else if .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-rabbitmq" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Database environment variables
*/}}
{{- define "common.mysqlEnvVars" -}}
{{- include "common.mysql.envVars" . }}
{{- end -}}

{{- define "common.mongodbEnvVars" -}}
{{- include "common.mongodb.envVars" . }}
{{- end -}}

{{- define "common.redisEnvVars" -}}
{{- include "common.redis.envVars" . }}
{{- end -}}

{{- define "common.rabbitmqEnvVars" -}}
{{- include "common.rabbitmq.envVars" . }}
{{- end -}}

{{/*
MySQL environment variables implementations
*/}}
{{- define "common.mysql.envVars" -}}
- name: MYSQL_HOST
  {{- if .Values.mysql.internal.enabled }}
  value: {{ include "common.internalMysqlServiceName" . }}
  {{- else if .Values.mysql.external.enabled }}
  value: {{ .Values.mysql.external.host | quote }}
  {{- end }}
- name: MYSQL_PORT
  {{- if .Values.mysql.internal.enabled }}
  value: "3306"
  {{- else if .Values.mysql.external.enabled }}
  value: {{ .Values.mysql.external.port | quote }}
  {{- end }}
{{- if not .Values.doppler.enabled }}
- name: MYSQL_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mysql.secretName" . }}
      key: mysql-username
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mysql.secretName" . }}
      key: mysql-password
{{- end }}
- name: MYSQL_DATABASE
  value: {{ .Values.mysql.database | default "koci" | quote }}
{{- if .Values.mysql.ssl.enabled }}
- name: MYSQL_SSL_MODE
  value: {{ .Values.mysql.ssl.mode | default "VERIFY_CA" | quote }}
{{- if not .Values.doppler.enabled }}
- name: MYSQL_SSL_CA
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mysql.secretName" . }}
      key: {{ .Values.mysql.ssl.caKey | default "OCI_MYSQL_CA_CERT" }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
MongoDB environment variables implementations
*/}}
{{- define "common.mongodb.envVars" -}}
- name: MONGODB_HOST
  {{- if .Values.mongodb.internal.enabled }}
  value: {{ include "common.internalMongodbServiceName" . }}
  {{- else if .Values.mongodb.external.enabled }}
  value: {{ .Values.mongodb.external.host | quote }}
  {{- end }}
- name: MONGODB_PORT
  {{- if .Values.mongodb.internal.enabled }}
  value: "27017"
  {{- else if .Values.mongodb.external.enabled }}
  value: {{ .Values.mongodb.external.port | quote }}
  {{- end }}
{{- if not .Values.doppler.enabled }}
- name: MONGODB_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mongodb.secretName" . }}
      key: mongodb-username
- name: MONGODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mongodb.secretName" . }}
      key: mongodb-password
{{- end }}
- name: MONGODB_DATABASE
  value: {{ .Values.mongodb.database | default "koci" | quote }}
{{- end -}}

{{/*
Redis environment variables implementations
*/}}
{{- define "common.redis.envVars" -}}
- name: REDIS_HOST
  {{- if .Values.redis.internal.enabled }}
  value: {{ include "common.internalRedisServiceName" . }}
  {{- else if .Values.redis.external.enabled }}
  value: {{ .Values.redis.external.host | quote }}
  {{- end }}
- name: REDIS_PORT
  {{- if .Values.redis.internal.enabled }}
  value: "6379"
  {{- else if .Values.redis.external.enabled }}
  value: {{ .Values.redis.external.port | quote }}
  {{- end }}
{{- if not .Values.doppler.enabled }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.redis.secretName" . }}
      key: redis-password
{{- end }}
{{- end -}}

{{/*
RabbitMQ environment variables implementations
*/}}
{{- define "common.rabbitmq.envVars" -}}
- name: RABBITMQ_HOST
  {{- if .Values.rabbitmq.connection.internal.enabled }}
  value: {{ include "common.internalRabbitmqServiceName" . }}
  {{- else if .Values.rabbitmq.connection.external.enabled }}
  value: {{ .Values.rabbitmq.connection.external.host | quote }}
  {{- end }}
- name: RABBITMQ_PORT
  {{- if .Values.rabbitmq.connection.internal.enabled }}
  value: {{ .Values.rabbitmq.cluster.service.port | default "5672" | quote }}
  {{- else if .Values.rabbitmq.connection.external.enabled }}
  value: {{ .Values.rabbitmq.connection.external.port | quote }}
  {{- end }}
{{- if not .Values.doppler.enabled }}
- name: RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "common.rabbitmq.secretName" . }}
      key: {{ .Values.rabbitmq.cluster.auth.usernameSecretKey | default "RABBITMQ_USERNAME" }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.rabbitmq.secretName" . }}
      key: {{ .Values.rabbitmq.cluster.auth.passwordSecretKey | default "RABBITMQ_PASSWORD" }}
{{- end }}
- name: RABBITMQ_VHOST
  value: {{ .Values.rabbitmq.vhost | default "/" | quote }}
{{- end -}}

{{/* Original database helpers from your file */}}
{{- define "common.ociBlockVolumeAnnotations" -}}
{{- if and (eq .Values.global.deploymentMode "cluster") .Values.global.oci.enabled }}
annotations:
  
  volume.beta.kubernetes.io/oci-volume-source: {{ .Values.oci.volumeSource | default "" | quote }}
  {{- if .Values.oci.volumeBackupId }}
  volume.beta.kubernetes.io/oci-volume-backup-id: {{ .Values.oci.volumeBackupId | quote }}
  {{- end }}

  {{- if .Values.oci.volumePerformance }}
  volume.beta.kubernetes.io/oci-volume-performance: {{ .Values.oci.volumePerformance | quote }}
  {{- end }}
{{- end }}
{{- end -}}