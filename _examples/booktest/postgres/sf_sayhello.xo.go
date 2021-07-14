package postgres

// Code generated by xo. DO NOT EDIT.

import (
	"context"
)

// SayHello calls the stored function 'public.say_hello(character varying) character varying' on db.
func SayHello(ctx context.Context, db DB, name string) (string, error) {
	// call public.say_hello
	const sqlstr = `SELECT * FROM public.say_hello($1)`
	// run
	var r0 string
	logf(sqlstr, name)
	if err := db.QueryRowContext(ctx, sqlstr, name).Scan(&r0); err != nil {
		return "", logerror(err)
	}
	return r0, nil
}