-- Generated by xo for the booktest schema.

-- table authors
CREATE TABLE authors (
  author_id INT IDENTITY(1, 1),
  name VARCHAR(255) DEFAULT ('') NOT NULL,
  CONSTRAINT authors_pkey PRIMARY KEY (author_id)
);

-- index authors_name_idx
CREATE INDEX authors_name_idx ON authors (name);

-- table books
CREATE TABLE books (
  book_id INT IDENTITY(1, 1),
  author_id INT NOT NULL CONSTRAINT books_author_id_fkey REFERENCES authors (author_id),
  isbn NVARCHAR(255) DEFAULT ('') NOT NULL,
  title NVARCHAR(255) DEFAULT ('') NOT NULL,
  year INT DEFAULT ((2000)) NOT NULL,
  available DATETIME2 DEFAULT (getdate()) NOT NULL,
  description NTEXT DEFAULT ('') NOT NULL,
  tags TEXT DEFAULT ('') NOT NULL,
  CONSTRAINT books_isbn_key UNIQUE (isbn),
  CONSTRAINT books_pkey PRIMARY KEY (book_id)
);

-- index books_title_idx
CREATE INDEX books_title_idx ON books (title, year);

-- procedure say_hello
CREATE PROCEDURE say_hello @name NVARCHAR(255), @result NVARCHAR(255) OUTPUT AS
BEGIN
  SELECT @result = CONCAT('hello ', @name)\;
END;