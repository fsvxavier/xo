package ischema

// Code generated by xo. DO NOT EDIT.

import (
	"database/sql"

	"github.com/xo/xo/_examples/pgcatalog/pgtypes"
)

// PgForeignTableColumn represents a row from 'information_schema._pg_foreign_table_columns'.
type PgForeignTableColumn struct {
	Nspname       pgtypes.Name     `json:"nspname"`       // nspname
	Relname       pgtypes.Name     `json:"relname"`       // relname
	Attname       pgtypes.Name     `json:"attname"`       // attname
	Attfdwoptions []sql.NullString `json:"attfdwoptions"` // attfdwoptions

}