#!/bin/bash
set -e

echo "Configuring database"
psql -v ON_ERROR_STOP=1 -U ${POSTGRES_USER} <<-EOSQL
  -- Load extension that allows search. More info at:
  -- http://azakirov.blogspot.com.br/2015/12/fuzzy-substring-searching-with-pgtrgm.html
  CREATE EXTENSION IF NOT EXISTS pg_trgm;

  -- Create anonymous user
  CREATE USER ${PGRST_DB_ANON_ROLE};

  -- Set default search_path for the database:
  -- + '${PGRST_DB_SCHEMA}' is necessary for computed columns:
  --    https://postgrest.com/en/v4.3/api.html#computed-columns
  -- + 'public' is necessary for pg_trgm extension:
  --    http://azakirov.blogspot.com.br/2015/12/fuzzy-substring-searching-with-pgtrgm.html
  ALTER DATABASE ${POSTGRES_DB} SET search_path TO '${PGRST_DB_SCHEMA}', 'public';
EOSQL
