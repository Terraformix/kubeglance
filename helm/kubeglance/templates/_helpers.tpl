# Define reusable templates (like labels, names, annotations).

{{- define "kubeglance.labels" -}}
app: kubeglance
{{- end }}

{{- define "kubeglance.frontend.selectorLabels" -}}
app: kubeglance
type: frontend
{{- end }}

{{- define "kubeglance.backend.selectorLabels" -}}
app: kubeglance
type: backend
{{- end }}
