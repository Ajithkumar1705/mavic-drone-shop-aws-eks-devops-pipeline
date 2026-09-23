{{/*
Return the application name.
*/}}
{{- define "mavic-drone-service.name" -}}
{{- .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Return the fully qualified application name.
The service name is used directly so that the Kubernetes Deployment
matches the service name used by the CD workflow.
*/}}
{{- define "mavic-drone-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "mavic-drone-service.name" . | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "mavic-drone-service.labels" -}}
app.kubernetes.io/name: {{ include "mavic-drone-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
These labels ensure that each Helm release selects only its own pods.
*/}}
{{- define "mavic-drone-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mavic-drone-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}