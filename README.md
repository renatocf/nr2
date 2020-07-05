# RefRNA

RefRNA is the database for RNA databases.

## Getting started

RefRNA is a [PostgreSQL](https://www.postgresql.org/) open source database
that groups RNA sequences and related info available in other RNA databases.

RefRNA is powered by [PostgreREST](https://postgrest.com/), a simple web server
that allows easy access to the data through a RESTful API using HTTPS. To see
how to query the database, check: https://postgrest.com/en/v0.4/api.html.

Here are some simple examples of queries you can do in RefRNA. Open your browser
and try them directly!

| Query                                                                | Meaning                            |
| -------------------------------------------------------------------- | ---------------------------------- |
| http://localhost:3000/sequences?id\_sequence=eq.1                    | Get a sequence with ID 1           |
| http://localhost:3000/organisms?id\_organism=eq.1&select=taxa{taxon} | Get taxa of the organism with ID 1 |
| http://localhost:3000/taxa?taxon=eq.Homo&select=organisms{organism}  | Get organisms from genre "Homo"    |

By default, results are in JSON, but they can also be returned in
[CSV](https://postgrest.com/en/v0.4/api.html?highlight=csv#response-format).

## Backups

- To create a backup of the database, run:
  ```bash
  pg_dump --format=c --no-acl --no-owner -U refrna refrna > YYYY_MM_DD.refrna.dump
  ```
  The flag `--format` asks the file to be compressed in a special binary
  compressed format that can be used by `pg_restore` to recreate the database.
  The flag `--no-acl` avoids restoring permissions and `--no-owner` avoids
  restoring ownership. This configuration is recommended by Heroku's
  [documentation](https://devcenter.heroku.com/articles/heroku-postgres-import-export#create-dump-file).

- To restore the database, run:
  ```bash
  pg_restore --verbose --clean --no-acl --no-owner -U refrna refrna > YYYY_MM_DD.refrna.dump
  ```
  The flag `--clean` asks to drop the database before recreating it.
  The flag `--no-acl` avoids restoring permissions and `--no-owner` avoids
  restoring ownership. This configuration is recommended by Heroku's
  [documentation](https://devcenter.heroku.com/articles/heroku-postgres-import-export#restore-to-local-database).
