{{/*
MySQL connection environment variables with null checks
*/}}

{{- define "common.rabbitmq.envVars" -}}
- name: RABBITMQ_HOST
  {{- if and .Values.rabbitmq .Values.rabbitmq.connection .Values.rabbitmq.connection.internal .Values.rabbitmq.connection.internal.enabled }}
  value: {{ include "common.internalRabbitmqServiceName" . }}
  {{- else if and .Values.rabbitmq .Values.rabbitmq.connection .Values.rabbitmq.connection.external .Values.rabbitmq.connection.external.enabled }}
  value: {{ .Values.rabbitmq.connection.external.host | quote }}
  {{- else }}
  value: "rabbitmq"
  {{- end }}
- name: RABBITMQ_PORT
  {{- if and .Values.rabbitmq .Values.rabbitmq.connection .Values.rabbitmq.connection.internal .Values.rabbitmq.connection.internal.enabled }}
  value: {{ if and .Values.rabbitmq .Values.rabbitmq.cluster .Values.rabbitmq.cluster.service .Values.rabbitmq.cluster.service.port }}{{ .Values.rabbitmq.cluster.service.port | quote }}{{ else }}"5672"{{ end }}
  {{- else if and .Values.rabbitmq .Values.rabbitmq.connection .Values.rabbitmq.connection.external .Values.rabbitmq.connection.external.enabled }}
  value: {{ .Values.rabbitmq.connection.external.port | quote }}
  {{- else }}
  value: "5672"
  {{- end }}
{{- if and .Values.doppler (not .Values.doppler.enabled) }}
- name: RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "common.rabbitmq.secretName" . }}
      key: {{ if and .Values.rabbitmq .Values.rabbitmq.cluster .Values.rabbitmq.cluster.auth .Values.rabbitmq.cluster.auth.usernameSecretKey }}{{ .Values.rabbitmq.cluster.auth.usernameSecretKey }}{{ else }}"RABBITMQ_USERNAME"{{ end }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.rabbitmq.secretName" . }}
      key: {{ if and .Values.rabbitmq .Values.rabbitmq.cluster .Values.rabbitmq.cluster.auth .Values.rabbitmq.cluster.auth.passwordSecretKey }}{{ .Values.rabbitmq.cluster.auth.passwordSecretKey }}{{ else }}"RABBITMQ_PASSWORD"{{ end }}
{{- end }}
- name: RABBITMQ_VHOST
  value: {{ if and .Values.rabbitmq .Values.rabbitmq.vhost }}{{ .Values.rabbitmq.vhost | quote }}{{ else }}"/"{{ end }}
{{- end -}}

{{- define "common.mysql.envVars" -}}
- name: MYSQL_HOST
  {{- if and .Values.mysql .Values.mysql.internal .Values.mysql.internal.enabled }}
  value: {{ include "common.internalMysqlServiceName" . }}
  {{- else if and .Values.mysql .Values.mysql.external .Values.mysql.external.enabled }}
  value: {{ .Values.mysql.external.host | quote }}
  {{- else }}
  value: "mysql"
  {{- end }}
- name: MYSQL_PORT
  {{- if and .Values.mysql .Values.mysql.internal .Values.mysql.internal.enabled }}
  value: "3306"
  {{- else if and .Values.mysql .Values.mysql.external .Values.mysql.external.enabled }}
  value: {{ .Values.mysql.external.port | quote }}
  {{- else }}
  value: "3306"
  {{- end }}
{{- if and .Values.doppler (not .Values.doppler.enabled) }}
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
  value: {{ if and .Values.mysql .Values.mysql.database }}{{ .Values.mysql.database | quote }}{{ else }}"koci"{{ end }}
{{- if and .Values.mysql .Values.mysql.ssl .Values.mysql.ssl.enabled }}
- name: MYSQL_SSL_MODE
  value: {{ .Values.mysql.ssl.mode | default "VERIFY_CA" | quote }}
{{- if and .Values.doppler (not .Values.doppler.enabled) }}
- name: MYSQL_SSL_CA
  valueFrom:
    secretKeyRef:
      name: {{ include "common.mysql.secretName" . }}
      key: {{ .Values.mysql.ssl.caKey | default "OCI_MYSQL_CA_CERT" }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "common.mongodb.envVars" -}}
- name: MONGODB_HOST
  {{- if and .Values.mongodb .Values.mongodb.internal .Values.mongodb.internal.enabled }}
  value: {{ include "common.internalMongodbServiceName" . }}
  {{- else if and .Values.mongodb .Values.mongodb.external .Values.mongodb.external.enabled }}
  value: {{ .Values.mongodb.external.host | quote }}
  {{- else }}
  value: "mongodb"
  {{- end }}
- name: MONGODB_PORT
  {{- if and .Values.mongodb .Values.mongodb.internal .Values.mongodb.internal.enabled }}
  value: "27017"
  {{- else if and .Values.mongodb .Values.mongodb.external .Values.mongodb.external.enabled }}
  value: {{ .Values.mongodb.external.port | quote }}
  {{- else }}
  value: "27017"
  {{- end }}
{{- if and .Values.doppler (not .Values.doppler.enabled) }}
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
  value: {{ if and .Values.mongodb .Values.mongodb.database }}{{ .Values.mongodb.database | quote }}{{ else }}"koci"{{ end }}
{{- end -}}

{{- define "common.redis.envVars" -}}
- name: REDIS_HOST
  {{- if and .Values.redis .Values.redis.internal .Values.redis.internal.enabled }}
  value: {{ include "common.internalRedisServiceName" . }}
  {{- else if and .Values.redis .Values.redis.external .Values.redis.external.enabled }}
  value: {{ .Values.redis.external.host | quote }}
  {{- else }}
  value: "redis"
  {{- end }}
- name: REDIS_PORT
  {{- if and .Values.redis .Values.redis.internal .Values.redis.internal.enabled }}
  value: "6379"
  {{- else if and .Values.redis .Values.redis.external .Values.redis.external.enabled }}
  value: {{ .Values.redis.external.port | quote }}
  {{- else }}
  value: "6379"
  {{- end }}
{{- if and .Values.doppler (not .Values.doppler.enabled) }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "common.redis.secretName" . }}
      key: redis-password
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
Secret names for database services with null checks
*/}}
{{- define "common.mongodb.secretName" -}}
{{- if and .Values.mongodb .Values.mongodb.existingSecret -}}
    {{- .Values.mongodb.existingSecret -}}
{{- else if and .Values.doppler .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-mongodb" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.mysql.secretName" -}}
{{- if and .Values.mysql .Values.mysql.existingSecret -}}
    {{- .Values.mysql.existingSecret -}}
{{- else if and .Values.doppler .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-mysql" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.redis.secretName" -}}
{{- if and .Values.redis .Values.redis.existingSecret -}}
    {{- .Values.redis.existingSecret -}}
{{- else if and .Values.doppler .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-redis" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "common.rabbitmq.secretName" -}}
{{- if and .Values.rabbitmq .Values.rabbitmq.existingSecret -}}
    {{- .Values.rabbitmq.existingSecret -}}
{{- else if and .Values.doppler .Values.doppler.enabled -}}
    {{- include "common.doppler.secretName" . -}}
{{- else -}}
    {{- printf "%s-rabbitmq" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}