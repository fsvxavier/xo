{{ define "enum" }}
{{- $e := .Data -}}
// {{ $e.GoName }} is the '{{ $e.SQLName }}' enum type from schema '{{ schema }}'.
type {{ $e.GoName }} uint16

// {{ $e.GoName }} values.
const (
{{ range $e.Values -}}
	// {{ $e.GoName }}{{ .GoName }} is the '{{ .SQLName }}' {{ $e.SQLName }}.
	{{ $e.GoName }}{{ .GoName }} {{ $e.GoName }} = {{ .ConstValue }}
{{ end -}}
)

// String satisfies the fmt.Stringer interface.
func ({{ short $e.GoName }} {{ $e.GoName }}) String() string {
	switch {{ short $e.GoName }} {
{{ range $e.Values -}}
	case {{ $e.GoName }}{{ .GoName }}:
		return "{{ .SQLName }}"
{{ end -}}
	}
	return fmt.Sprintf("{{ $e.GoName }}(%d)", {{ short $e.GoName }})
}

// MarshalText marshals {{ $e.GoName }} into text.
func ({{ short $e.GoName }} {{ $e.GoName }}) MarshalText() ([]byte, error) {
	return []byte({{ short $e.GoName }}.String()), nil
}

// UnmarshalText unmarshals {{ $e.GoName }} from text.
func ({{ short $e.GoName }} *{{ $e.GoName }}) UnmarshalText(buf []byte) error {
	switch str := string(buf); str {
{{ range $e.Values -}}
	case "{{ .SQLName }}":
		*{{ short $e.GoName }} = {{ $e.GoName }}{{ .GoName }}
{{ end -}}
	default:
		return ErrInvalid{{ $e.GoName }}(str)
	}
	return nil
}

// Value satisfies the driver.Valuer interface.
func ({{ short $e.GoName }} {{ $e.GoName }}) Value() (driver.Value, error) {
	return {{ short $e.GoName }}.String(), nil
}

// Scan satisfies the sql.Scanner interface.
func ({{ short $e.GoName }} *{{ $e.GoName }}) Scan(v interface{}) error {
	if buf, ok := v.([]byte); ok {
		return {{ short $e.GoName }}.UnmarshalText(buf)
	}
	return ErrInvalid{{ $e.GoName }}(fmt.Sprintf("%T", v))
}

{{ $nullName := (printf "%s%s" "Null" $e.GoName) -}}
{{- $nullShort := (short $nullName) -}}
// {{ $nullName }} represents a null '{{ $e.SQLName }}' enum for schema '{{ schema }}'.
type {{ $nullName }} struct {
	{{ $e.GoName }} {{ $e.GoName }}
	// Valid is true if {{ $e.GoName }} is not null.
	Valid bool
}

// Value satisfies the driver.Valuer interface.
func ({{ $nullShort }} {{ $nullName }}) Value() (driver.Value, error) {
	if !{{ $nullShort }}.Valid {
		return nil, nil
	}
	return {{ $nullShort }}.{{ $e.GoName }}.Value()
}

// Scan satisfies the sql.Scanner interface.
func ({{ $nullShort }} *{{ $nullName }}) Scan(v interface{}) error {
	if v == nil {
		{{ $nullShort }}.{{ $e.GoName }}, {{ $nullShort }}.Valid = 0, false
		return nil
	}
	err := {{ $nullShort }}.{{ $e.GoName }}.Scan(v)
	{{ $nullShort }}.Valid = err == nil
	return err
}

// ErrInvalid{{ $e.GoName }} is the invalid {{ $e.GoName }} error.
type ErrInvalid{{ $e.GoName }} string

// Error satisfies the error interface.
func (err ErrInvalid{{ $e.GoName }}) Error() string {
	return fmt.Sprintf("invalid {{ $e.GoName }}(%s)", string(err))
}
{{ end }}

{{ define "foreignkey" }}
{{- $k := .Data -}}
{{- if context_both }}
{{- end }}
{{ end }}

{{ define "index" }}
{{- $i := .Data -}}
// {{ func_name_context $i }} retrieves a row from '{{ schema $i.Table.SQLName }}' as a {{ $i.Table.GoName }}.
//
// Generated from index '{{ $i.SQLName }}'.
{{ func_context $i }} {
	// query
	{{ sqlstr "index" $i }}
{{- if $i.IsUnique }}
	{{ short $i.Table }} := {{ $i.Table.GoName }}{
	}
	if err := {{ db "QueryRow"  $i }}.Scan({{ names (print "&" (short $i.Table) ".") $i.Table }}); err != nil {
		return nil, checkSQLError(err)
	}
	return &{{ short $i.Table }}, nil
{{- else }}
	rows, err := {{ db "Query" $i }}
	if err != nil {
		return nil, checkSQLError(err)
	}
	defer rows.Close()
	// process
	var res []*{{ $i.Table.GoName }}
	for rows.Next() {
		{{ short $i.Table }} := {{ $i.Table.GoName }}{
		}
		// scan
		if err := rows.Scan({{ names_ignore (print "&" (short $i.Table) ".")  $i.Table }}); err != nil {
			return nil, checkSQLError(err)
		}
		res = append(res, &{{ short $i.Table }})
	}
	if err := rows.Err(); err != nil {
		return nil, checkSQLError(err)
	}
	return res, nil
{{- end }}
}

{{ if context_both -}}
// {{ func_name $i }} retrieves a row from '{{ schema $i.Table.SQLName }}' as a {{ $i.Table.GoName }}.
//
// Generated from index '{{ $i.SQLName }}'.
{{ func $i }} {
	return {{ func_name_context $i }}({{ names "" "context.Background()" "db" $i }})
}
{{- end }}

{{end}}

{{ define "procs" }}
{{- $ps := .Data -}}
{{- range $p := $ps -}}
// {{ func_name_context $p }} calls the stored {{ $p.Type }} '{{ $p.Signature }}' on db.
{{ func_context $p }} {
{{- if and (driver "mysql") (eq $p.Type "procedure") (not $p.Void) }}
	// At the moment, the Go MySQL driver does not support stored procedures
	// with out parameters
	return {{ zero $p.Returns }}, fmt.Errorf("unsupported")
{{- else }}
	// call {{ schema $p.SQLName }}
	{{ sqlstr "proc" $p }}
	// run
{{- if not $p.Void }}
{{- range $p.Returns }}
	var {{ check_name .GoName }} {{ type .Type }}
{{- end }}
{{- if and (driver "sqlserver" "oracle") (eq $p.Type "procedure")}}
	if _, err := {{ db_named "Exec" $p }}; err != nil {
{{- else }}
	if err := {{ db "QueryRow" $p }}.Scan({{ names "&" $p.Returns }}); err != nil {
{{- end }}
		return {{ zero $p.Returns }}, checkSQLError(err)
	}
	return {{ range $p.Returns }}{{ check_name .GoName }}, {{ end }}nil
{{- else }}
{{- if driver "sqlserver" "oracle" }}
	if _, err := {{ db_named "Exec" $p }}; err != nil {
{{- else }}
	if _, err := {{ db "Exec" $p }}; err != nil {
{{- end }}
		return checkSQLError(err)
	}
	return nil
{{- end }}
{{- end }}
}

{{ if context_both -}}
// {{ func_name $p }} calls the {{ $p.Type }} '{{ $p.Signature }}' on db.
{{ func $p }} {
	return {{ func_name_context $p }}({{ names_all "" "context.Background()" "db" $p.Params }})
}
{{- end -}}
{{- end }}
{{ end }}

{{ define "typedef" }}
{{- $t := .Data -}}
{{- if $t.Comment -}}
// {{ $t.Comment | eval $t.GoName }}
{{- else -}}
// {{ $t.GoName }} represents a row from '{{ schema $t.SQLName }}'.
{{- end }}
type {{ $t.GoName }} struct {
{{ range $t.Fields -}}
	{{ field . }}
{{ end }}
}

// {{ func_name_context "Insert" }} inserts the {{ $t.GoName }} to the database.
{{ recv_context $t "Insert" }} {
{{ if $t.Manual -}}
	// insert (manual)
	{{ sqlstr "insert_manual" $t }}
	if _, err := {{ db_prefix "Exec" false $t }}; err != nil {
		return checkSQLError(err)
	}
{{- else -}}
	// insert (primary key generated and returned by database)
	{{ sqlstr "insert" $t }}
{{ if (driver "postgres") -}}
	if err := {{ db_prefix "QueryRow" true $t }}.Scan(&{{ short $t }}.{{ (index $t.PrimaryKeys 0).GoName }}); err != nil {
		return checkSQLError(err)
	}
{{- else if (driver "sqlserver") -}}
	rows, err := {{ db_prefix "Query" true $t }}
	if err != nil {
		return checkSQLError(err)
	}
	defer rows.Close()
	// retrieve id
	var id int64
	for rows.Next() {
		if err := rows.Scan(&id); err != nil {
			return checkSQLError(err)
		}
	}
	if err := rows.Err(); err != nil {
		return checkSQLError(err)
	}
{{- else if (driver "oracle") -}}
	var id int64
	if _, err := {{ db_prefix "Exec" true $t (named "pk" "&id" true) }}; err != nil {
		return checkSQLError(err)
	}
{{- else -}}
	res, err := {{ db_prefix "Exec" true $t }}
	if err != nil {
		return checkSQLError(err)
	}
	// retrieve id
	id, err := res.LastInsertId()
	if err != nil {
		return checkSQLError(err)
	}
{{- end -}}
{{ if not (driver "postgres") -}}
	// set primary key
	{{ short $t }}.{{ (index $t.PrimaryKeys 0).GoName }} = {{ (index $t.PrimaryKeys 0).Type }}(id)
{{- end }}
{{- end }}
	return nil
}

{{ if context_both -}}
// Insert inserts the {{ $t.GoName }} to the database.
{{ recv $t "Insert" }} {
	return {{ short $t }}.InsertContext(context.Background(), db)
}
{{- end }}


{{ if eq (len $t.Fields) (len $t.PrimaryKeys) -}}
// ------ NOTE: Update statements omitted due to lack of fields other than primary key ------
{{- else -}}
// {{ func_name_context "Update" }} updates a {{ $t.GoName }} in the database.
{{ recv_context $t "Update" }} {
	// update with {{ if driver "postgres" }}composite {{ end }}primary key
	{{ sqlstr "update" $t }}
	if _, err := {{ db_update "Exec" $t }}; err != nil {
		return checkSQLError(err)
	}
	return nil
}

{{ if context_both -}}
// Update updates a {{ $t.GoName }} in the database.
{{ recv $t "Update" }} {
	return {{ short $t }}.UpdateContext(context.Background(), db)
}
{{- end }}

// {{ func_name_context "Save" }} saves the {{ $t.GoName }} to the database.
{{ recv_context $t "Save" }} {
	return {{ short $t }}.{{ func_name_context "Insert" }}({{ if context }}ctx, {{ end }}db)
}

{{ if context_both -}}
// Save saves the {{ $t.GoName }} to the database.
{{ recv $t "Save" }} {
	return {{ short $t }}.InsertContext(context.Background(), db)
}
{{- end }}

// {{ func_name_context "Upsert" }} performs an upsert for {{ $t.GoName }}.
{{ recv_context $t "Upsert" }} {
	// upsert
	{{ sqlstr "upsert" $t }}
	if _, err := {{ db_prefix "Exec" false $t }}; err != nil {
		return checkSQLError(err)
	}
	return nil
}

{{ if context_both -}}
// Upsert performs an upsert for {{ $t.GoName }}.
{{ recv $t "Upsert" }} {
	return {{ short $t }}.UpsertContext(context.Background(), db)
}
{{- end -}}
{{- end }}

// {{ func_name_context "Delete" }} deletes the {{ $t.GoName }} from the database.
{{ recv_context $t "Delete" }} {
{{ if eq (len $t.PrimaryKeys) 1 -}}
	// delete with single primary key
	{{ sqlstr "delete" $t }}
	if _, err := {{ db "Exec" (print (short $t) "." (index $t.PrimaryKeys 0).GoName) }}; err != nil {
		return checkSQLError(err)
	}
{{- else -}}
	// delete with composite primary key
	{{ sqlstr "delete" $t }}
	if _, err := {{ db "Exec" (names (print (short $t) ".") $t.PrimaryKeys) }}; err != nil {
		return checkSQLError(err)
	}
{{- end }}
	return nil
}

{{ if context_both -}}
// Delete deletes the {{ $t.GoName }} from the database.
{{ recv $t "Delete" }} {
	return {{ short $t }}.DeleteContext(context.Background(), db)
}
{{- end -}}
{{- end }}