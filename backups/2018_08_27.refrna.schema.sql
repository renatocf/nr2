--
-- PostgreSQL database dump
--

-- Dumped from database version 10.4 (Debian 10.4-2.pgdg90+1)
-- Dumped by pg_dump version 10.4 (Debian 10.4-2.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: refrna; Type: SCHEMA; Schema: -; Owner: refrna
--

CREATE SCHEMA refrna;


ALTER SCHEMA refrna OWNER TO refrna;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.taxa (
    id_taxon bigint NOT NULL,
    taxon text NOT NULL
);


ALTER TABLE refrna.taxa OWNER TO refrna;

--
-- Name: child(refrna.taxa); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.child(refrna.taxa) RETURNS SETOF refrna.taxa
    LANGUAGE sql
    AS $_$ SELECT id_taxon, taxon FROM taxa_have_taxa INNER JOIN taxa ON (taxa_have_taxa.id_child = taxa.id_taxon) WHERE id_parent = $1.id_taxon ORDER BY taxon; $_$;


ALTER FUNCTION refrna.child(refrna.taxa) OWNER TO refrna;

--
-- Name: download_fasta(bigint, bigint[]); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.download_fasta(id_parent bigint, id_classes bigint[]) RETURNS TABLE(sequence json, organisms json, databases json, classes json)
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    SELECT ROW_TO_JSON(sequences.*),
           ARRAY_TO_JSON(ARRAY_AGG(organisms.*)),
           ARRAY_TO_JSON(ARRAY_AGG(databases.*)),
           ARRAY_TO_JSON(ARRAY_AGG(classes.*))
      FROM organisms_have_taxa
      JOIN sequences_have_organisms USING (id_organism)
      JOIN sequences_have_databases USING (id_sequence)
      JOIN sequences_have_classes USING (id_sequence)
      JOIN sequences USING (id_sequence)
      JOIN organisms USING (id_organism)
      JOIN databases USING (id_database)
      JOIN classes USING (id_class)
     WHERE organisms_have_taxa.id_taxon = $1
       AND sequences_have_classes.id_class = ANY($2)
  GROUP BY sequences.*;
$_$;


ALTER FUNCTION refrna.download_fasta(id_parent bigint, id_classes bigint[]) OWNER TO refrna;

--
-- Name: get_children(bigint, bigint[]); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.get_children(id_parent bigint, id_classes bigint[]) RETURNS TABLE(id_taxon bigint, taxon text, num_sequences bigint)
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
      SELECT q2.*, count(q1.id_sequence)
        FROM (SELECT id_sequence
              FROM sequences_have_classes
              WHERE sequences_have_classes.id_class = ANY($2)) AS q1
        JOIN sequences_have_organisms USING (id_sequence)
        JOIN (SELECT id_organism
              FROM taxa_have_taxa
              JOIN taxa ON (taxa.id_taxon = taxa_have_taxa.id_child)
              JOIN organisms_have_taxa USING (id_taxon)
             WHERE taxa_have_taxa.id_parent = $1) AS q2 USING (id_organism)
  GROUP BY q2.id_taxon, q2.taxon
  ORDER BY q2.taxon;
$_$;


ALTER FUNCTION refrna.get_children(id_parent bigint, id_classes bigint[]) OWNER TO refrna;

--
-- Name: get_root(bigint[]); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.get_root(id_classes bigint[]) RETURNS TABLE(id_taxon bigint, taxon text, num_sequences bigint)
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    SELECT taxa.*, count(DISTINCT sequences_have_organisms.id_sequence)
      FROM taxa
      JOIN organisms_have_taxa USING (id_taxon)
      JOIN sequences_have_organisms USING (id_organism)
      JOIN sequences_have_classes USING (id_sequence)
     WHERE taxa.id_taxon = 0
       AND sequences_have_classes.id_class = ANY($1)
  GROUP BY taxa.id_taxon
  ORDER BY taxa.taxon;
$_$;


ALTER FUNCTION refrna.get_root(id_classes bigint[]) OWNER TO refrna;

--
-- Name: search_taxon(text, bigint[], integer); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.search_taxon(input text, id_classes bigint[], maximum integer) RETURNS TABLE(id_taxon bigint, taxon text, num_sequences bigint)
    LANGUAGE sql
    AS $_$
    SELECT taxa.*, count(DISTINCT sequences_have_organisms.id_sequence)
      FROM taxa
      JOIN organisms_have_taxa USING (id_taxon)
      JOIN sequences_have_organisms USING (id_organism)
      JOIN sequences_have_classes USING (id_sequence),
           to_tsvector(taxa.taxon) AS target,
           phraseto_tsquery($1) AS query,
           ts_rank_cd(target, query) AS rank
     WHERE target @@ query
       AND sequences_have_classes.id_class = ANY($2)
  GROUP BY taxa.id_taxon, rank
  ORDER BY rank DESC
     LIMIT maximum;
$_$;


ALTER FUNCTION refrna.search_taxon(input text, id_classes bigint[], maximum integer) OWNER TO refrna;

--
-- Name: sequences; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.sequences (
    id_sequence bigint NOT NULL,
    length bigint NOT NULL,
    num_copies bigint,
    num_unclassified_copies bigint,
    sequence text NOT NULL,
    CONSTRAINT verify_num_copies CHECK ((num_unclassified_copies <= num_copies))
);


ALTER TABLE refrna.sequences OWNER TO refrna;

--
-- Name: sequences(refrna.taxa); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION refrna.sequences(refrna.taxa) RETURNS SETOF refrna.sequences
    LANGUAGE sql
    AS $_$ select sequences.* from organisms_have_taxa, sequences_have_organisms, sequences where $1.id_taxon = organisms_have_taxa.id_taxon AND organisms_have_taxa.id_organism = sequences_have_organisms.id_organism and sequences_have_organisms.id_sequence = sequences.id_sequence; $_$;


ALTER FUNCTION refrna.sequences(refrna.taxa) OWNER TO refrna;

--
-- Name: classes; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.classes (
    id_class bigint NOT NULL,
    class character varying(45) NOT NULL,
    full_name character varying(100),
    description text
);


ALTER TABLE refrna.classes OWNER TO refrna;

--
-- Name: database_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.database_versions (
    id_version bigint NOT NULL,
    version character varying(100) NOT NULL
);


ALTER TABLE refrna.database_versions OWNER TO refrna;

--
-- Name: databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.databases (
    id_database bigint NOT NULL,
    database character varying(45) NOT NULL
);


ALTER TABLE refrna.databases OWNER TO refrna;

--
-- Name: databases_have_database_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.databases_have_database_versions (
    id_database bigint NOT NULL,
    id_version bigint NOT NULL
);


ALTER TABLE refrna.databases_have_database_versions OWNER TO refrna;

--
-- Name: families; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.families (
    id_family bigint NOT NULL,
    family character varying(45),
    full_name character varying(200),
    url character varying(100)
);


ALTER TABLE refrna.families OWNER TO refrna;

--
-- Name: nrdr_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.nrdr_versions (
    id_version bigint NOT NULL,
    version character varying(100) NOT NULL
);


ALTER TABLE refrna.nrdr_versions OWNER TO refrna;

--
-- Name: nrdr_versions_have_databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.nrdr_versions_have_databases (
    id_database bigint NOT NULL,
    id_version bigint NOT NULL
);


ALTER TABLE refrna.nrdr_versions_have_databases OWNER TO refrna;

--
-- Name: organisms; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.organisms (
    id_organism bigint NOT NULL,
    organism character varying(100) NOT NULL
);


ALTER TABLE refrna.organisms OWNER TO refrna;

--
-- Name: organisms_have_taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.organisms_have_taxa (
    id_organism bigint NOT NULL,
    id_taxon bigint NOT NULL
);


ALTER TABLE refrna.organisms_have_taxa OWNER TO refrna;

--
-- Name: sequences_have_classes; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.sequences_have_classes (
    id_sequence bigint NOT NULL,
    id_class bigint NOT NULL
);


ALTER TABLE refrna.sequences_have_classes OWNER TO refrna;

--
-- Name: sequences_have_databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.sequences_have_databases (
    id_sequence bigint NOT NULL,
    id_database bigint NOT NULL
);


ALTER TABLE refrna.sequences_have_databases OWNER TO refrna;

--
-- Name: sequences_have_families; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.sequences_have_families (
    id_sequence bigint NOT NULL,
    id_family bigint NOT NULL
);


ALTER TABLE refrna.sequences_have_families OWNER TO refrna;

--
-- Name: sequences_have_organisms; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.sequences_have_organisms (
    id_sequence bigint NOT NULL,
    id_organism bigint NOT NULL
);


ALTER TABLE refrna.sequences_have_organisms OWNER TO refrna;

--
-- Name: taxa_have_taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE refrna.taxa_have_taxa (
    id_parent bigint NOT NULL,
    id_child bigint NOT NULL
);


ALTER TABLE refrna.taxa_have_taxa OWNER TO refrna;

--
-- Name: taxas_classes; Type: MATERIALIZED VIEW; Schema: refrna; Owner: refrna
--

CREATE MATERIALIZED VIEW refrna.taxas_classes AS
 SELECT organisms_have_taxa.id_taxon,
    array_agg(DISTINCT sequences_have_classes.id_class ORDER BY sequences_have_classes.id_class) AS id_classes
   FROM ((refrna.organisms_have_taxa
     JOIN refrna.sequences_have_organisms USING (id_organism))
     JOIN refrna.sequences_have_classes USING (id_sequence))
  GROUP BY organisms_have_taxa.id_taxon
  ORDER BY organisms_have_taxa.id_taxon
  WITH NO DATA;


ALTER TABLE refrna.taxas_classes OWNER TO refrna;

--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id_class);


--
-- Name: database_versions database_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.database_versions
    ADD CONSTRAINT database_versions_pkey PRIMARY KEY (id_version);


--
-- Name: database_versions database_versions_version_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.database_versions
    ADD CONSTRAINT database_versions_version_key UNIQUE (version);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_database_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_database_key UNIQUE (id_database);


--
-- Name: databases_have_database_versions databases_have_database_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_pkey PRIMARY KEY (id_database, id_version);


--
-- Name: databases databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.databases
    ADD CONSTRAINT databases_pkey PRIMARY KEY (id_database);


--
-- Name: families families_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.families
    ADD CONSTRAINT families_pkey PRIMARY KEY (id_family);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_pkey PRIMARY KEY (id_database, id_version);


--
-- Name: nrdr_versions nrdr_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.nrdr_versions
    ADD CONSTRAINT nrdr_versions_pkey PRIMARY KEY (id_version);


--
-- Name: nrdr_versions nrdr_versions_version_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.nrdr_versions
    ADD CONSTRAINT nrdr_versions_version_key UNIQUE (version);


--
-- Name: organisms_have_taxa organisms_have_taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_pkey PRIMARY KEY (id_organism, id_taxon);


--
-- Name: organisms organisms_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.organisms
    ADD CONSTRAINT organisms_pkey PRIMARY KEY (id_organism);


--
-- Name: sequences_have_classes sequences_have_classes_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_pkey PRIMARY KEY (id_sequence, id_class);


--
-- Name: sequences_have_databases sequences_have_databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_pkey PRIMARY KEY (id_sequence, id_database);


--
-- Name: sequences_have_families sequences_have_families_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_families
    ADD CONSTRAINT sequences_have_families_pkey PRIMARY KEY (id_sequence, id_family);


--
-- Name: sequences_have_organisms sequences_have_organisms_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_pkey PRIMARY KEY (id_sequence, id_organism);


--
-- Name: sequences sequences_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id_sequence);


--
-- Name: taxa_have_taxa taxa_have_taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.taxa_have_taxa
    ADD CONSTRAINT taxa_have_taxa_pkey PRIMARY KEY (id_parent, id_child);


--
-- Name: taxa taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.taxa
    ADD CONSTRAINT taxa_pkey PRIMARY KEY (id_taxon);


--
-- Name: nrdr_versions_have_databases_id_database_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX nrdr_versions_have_databases_id_database_fkey ON refrna.nrdr_versions_have_databases USING btree (id_database);


--
-- Name: nrdr_versions_have_databases_id_version_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX nrdr_versions_have_databases_id_version_fkey ON refrna.nrdr_versions_have_databases USING btree (id_version);


--
-- Name: organisms_have_taxa_id_organism_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX organisms_have_taxa_id_organism_fkey ON refrna.organisms_have_taxa USING btree (id_organism);


--
-- Name: organisms_have_taxa_id_taxon_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX organisms_have_taxa_id_taxon_fkey ON refrna.organisms_have_taxa USING btree (id_taxon);


--
-- Name: sequences_have_classes_id_class_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_classes_id_class_fkey ON refrna.sequences_have_classes USING btree (id_class);


--
-- Name: sequences_have_classes_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_classes_id_sequence_fkey ON refrna.sequences_have_classes USING btree (id_sequence);


--
-- Name: sequences_have_databases_id_database_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_databases_id_database_fkey ON refrna.sequences_have_databases USING btree (id_database);


--
-- Name: sequences_have_databases_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_databases_id_sequence_fkey ON refrna.sequences_have_databases USING btree (id_sequence);


--
-- Name: sequences_have_families_id_family_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_families_id_family_fkey ON refrna.sequences_have_families USING btree (id_family);


--
-- Name: sequences_have_families_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_families_id_sequence_fkey ON refrna.sequences_have_families USING btree (id_sequence);


--
-- Name: sequences_have_organisms_id_organism_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_organisms_id_organism_fkey ON refrna.sequences_have_organisms USING btree (id_organism);


--
-- Name: sequences_have_organisms_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_organisms_id_sequence_fkey ON refrna.sequences_have_organisms USING btree (id_sequence);


--
-- Name: taxa_have_taxa_id_child_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX taxa_have_taxa_id_child_fkey ON refrna.taxa_have_taxa USING btree (id_child);


--
-- Name: taxa_have_taxa_id_parent_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX taxa_have_taxa_id_parent_fkey ON refrna.taxa_have_taxa USING btree (id_parent);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_database_fkey FOREIGN KEY (id_database) REFERENCES refrna.databases(id_database);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_version_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_version_fkey FOREIGN KEY (id_version) REFERENCES refrna.database_versions(id_version);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_id_database_fkey FOREIGN KEY (id_database) REFERENCES refrna.databases(id_database);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_id_version_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_id_version_fkey FOREIGN KEY (id_version) REFERENCES refrna.nrdr_versions(id_version);


--
-- Name: organisms_have_taxa organisms_have_taxa_id_organism_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_id_organism_fkey FOREIGN KEY (id_organism) REFERENCES refrna.organisms(id_organism);


--
-- Name: organisms_have_taxa organisms_have_taxa_id_taxon_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_id_taxon_fkey FOREIGN KEY (id_taxon) REFERENCES refrna.taxa(id_taxon);


--
-- Name: sequences_have_classes sequences_have_classes_id_class_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_id_class_fkey FOREIGN KEY (id_class) REFERENCES refrna.classes(id_class);


--
-- Name: sequences_have_classes sequences_have_classes_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES refrna.sequences(id_sequence);


--
-- Name: sequences_have_databases sequences_have_databases_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_id_database_fkey FOREIGN KEY (id_database) REFERENCES refrna.databases(id_database);


--
-- Name: sequences_have_databases sequences_have_databases_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES refrna.sequences(id_sequence);


--
-- Name: sequences_have_families sequences_have_families_id_family_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_families
    ADD CONSTRAINT sequences_have_families_id_family_fkey FOREIGN KEY (id_family) REFERENCES refrna.families(id_family);


--
-- Name: sequences_have_families sequences_have_families_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_families
    ADD CONSTRAINT sequences_have_families_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES refrna.sequences(id_sequence);


--
-- Name: taxa_have_taxa sequences_have_organisms_id_child_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.taxa_have_taxa
    ADD CONSTRAINT sequences_have_organisms_id_child_fkey FOREIGN KEY (id_child) REFERENCES refrna.taxa(id_taxon);


--
-- Name: sequences_have_organisms sequences_have_organisms_id_organism_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_id_organism_fkey FOREIGN KEY (id_organism) REFERENCES refrna.organisms(id_organism);


--
-- Name: taxa_have_taxa sequences_have_organisms_id_parent_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.taxa_have_taxa
    ADD CONSTRAINT sequences_have_organisms_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES refrna.taxa(id_taxon);


--
-- Name: sequences_have_organisms sequences_have_organisms_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY refrna.sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES refrna.sequences(id_sequence);


--
-- Name: SCHEMA refrna; Type: ACL; Schema: -; Owner: refrna
--

GRANT ALL ON SCHEMA refrna TO anon;


--
-- Name: TABLE taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.taxa TO anon;


--
-- Name: TABLE sequences; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.sequences TO anon;


--
-- Name: FUNCTION sequences(refrna.taxa); Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON FUNCTION refrna.sequences(refrna.taxa) TO anon;


--
-- Name: TABLE classes; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.classes TO anon;


--
-- Name: TABLE database_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.database_versions TO anon;


--
-- Name: TABLE databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.databases TO anon;


--
-- Name: TABLE databases_have_database_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.databases_have_database_versions TO anon;


--
-- Name: TABLE families; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.families TO anon;


--
-- Name: TABLE nrdr_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.nrdr_versions TO anon;


--
-- Name: TABLE nrdr_versions_have_databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.nrdr_versions_have_databases TO anon;


--
-- Name: TABLE organisms; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.organisms TO anon;


--
-- Name: TABLE organisms_have_taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.organisms_have_taxa TO anon;


--
-- Name: TABLE sequences_have_classes; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.sequences_have_classes TO anon;


--
-- Name: TABLE sequences_have_databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.sequences_have_databases TO anon;


--
-- Name: TABLE sequences_have_families; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.sequences_have_families TO anon;


--
-- Name: TABLE sequences_have_organisms; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.sequences_have_organisms TO anon;


--
-- Name: TABLE taxa_have_taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE refrna.taxa_have_taxa TO anon;


--
-- Name: TABLE taxas_classes; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT SELECT ON TABLE refrna.taxas_classes TO anon;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: refrna; Owner: refrna
--

ALTER DEFAULT PRIVILEGES FOR ROLE refrna IN SCHEMA refrna REVOKE ALL ON TABLES  FROM refrna;
ALTER DEFAULT PRIVILEGES FOR ROLE refrna IN SCHEMA refrna GRANT SELECT ON TABLES  TO anon;


--
-- PostgreSQL database dump complete
--

