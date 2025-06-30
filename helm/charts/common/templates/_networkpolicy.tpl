{{- define "common.networkPolicy" -}}
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include (printf "%s.fullname" .Chart.Name) . }}
  namespace: {{ .Values.global.namespace | default .Release.Namespace }}
  labels:
    {{- include (printf "%s.labels" .Chart.Name) . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include (printf "%s.selectorLabels" .Chart.Name) . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    {{- with .Values.networkPolicy.ingress }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  egress:
    # Allow DNS resolution
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    {{- if .Values.redis.internal.enabled }}
    # Allow outbound traffic to Redis
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: redis
      ports:
        - protocol: TCP
          port: {{ .Values.global.redis.service.port }}
    {{- end }}
    {{- if .Values.mysql.internal.enabled }}
    # Allow outbound traffic to MySQL
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: mysql
      ports:
        - protocol: TCP
          port: {{ .Values.global.mysql.primary.service.port }}
    {{- end }}
    {{- if .Values.mongodb.internal.enabled }}
    # Allow outbound traffic to MongoDB
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: mongodb
      ports:
        - protocol: TCP
          port: {{ .Values.global.mongodb.service.port }}
    {{- end }}
    {{- if .Values.global.rabbitmq.connection.internal.enabled }}
    # Allow outbound traffic to RabbitMQ
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: rabbitmq
      ports:
        - protocol: TCP
          port: {{ .Values.global.rabbitmq.cluster.service.port }}
    {{- end }}
    {{- with .Values.networkPolicy.additionalEgress }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end }}
{{- end -}} 