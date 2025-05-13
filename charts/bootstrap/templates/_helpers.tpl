{{/* Helper template functions for the ArgoCD bootstrap */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "argocd-bootstrap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "argocd-bootstrap.fullname" -}}
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
{{- define "argocd-bootstrap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argocd-bootstrap.labels" -}}
helm.sh/chart: {{ include "argocd-bootstrap.chart" . }}
{{ include "argocd-bootstrap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argocd-bootstrap.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd-bootstrap.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Extract repository name from URL for use in secret name
*/}}
{{- define "argocd-bootstrap.repoName" -}}
{{- $repoURL := .Values.repository.url -}}
{{- $parsedURL := urlParse $repoURL -}}
{{- if $parsedURL.host -}}
  {{- $hostParts := splitList "." $parsedURL.host -}}
  {{- $path := trim $parsedURL.path "/" -}}
  {{- $pathParts := splitList "/" $path -}}
  {{- if eq (len $pathParts) 2 -}}
    {{- printf "%s-%s-%s" $hostParts._0 (index $pathParts 0) (index $pathParts 1) | trimSuffix ".git" | lower | replace "." "-" | replace "_" "-" -}}
  {{- else -}}
    {{- printf "%s-%s" $hostParts._0 (join "-" $pathParts) | trimSuffix ".git" | lower | replace "." "-" | replace "_" "-" -}}
  {{- end -}}
{{- else -}}
  {{- printf "repo-%s" (randAlphaNum 5) | lower -}}
{{- end -}}
{{- end }}
