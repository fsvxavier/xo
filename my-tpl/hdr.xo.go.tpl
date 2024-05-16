{{ define "header" }}
{{- $tags := tags -}}
{{- $inject := inject -}}
{{- if $tags -}}
//go:build{{ range $tags }} {{ . }}{{ end }}

{{ end -}}
{{- if first -}}
// Package {{ pkg }} contains generated code for schema '{{ schema }}'.
{{ end -}}
package {{ pkg }}



import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"regexp"
	"strings"
	"time"
{{- if driver "postgres" }}
	"github.com/lib/pq"
	"github.com/lib/pq/hstore"
{{ end }}{{ range imports }}
	{{ with .Alias }}{{ . }} {{ end }}{{ .Pkg }}
{{ end }}
)

{{- if $inject }}
{{ $inject }}
{{- end }}
{{ end }}
