--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.4
-- Dumped by pg_dump version 9.6.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
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


SET search_path = refrna, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE taxa (
    id_taxon bigint NOT NULL,
    taxon text NOT NULL
);


ALTER TABLE taxa OWNER TO refrna;

--
-- Name: child(taxa); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION child(taxa) RETURNS SETOF taxa
    LANGUAGE sql
    AS $_$ SELECT id_taxon, taxon FROM taxa_have_taxa INNER JOIN taxa ON (taxa_have_taxa.id_child = taxa.id_taxon) WHERE id_parent = $1.id_taxon ORDER BY taxon; $_$;


ALTER FUNCTION refrna.child(taxa) OWNER TO refrna;

--
-- Name: sequences; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE sequences (
    id_sequence bigint NOT NULL,
    length bigint NOT NULL,
    num_copies bigint,
    num_unclassified_copies bigint,
    sequence text NOT NULL,
    CONSTRAINT verify_num_copies CHECK ((num_unclassified_copies <= num_copies))
);


ALTER TABLE sequences OWNER TO refrna;

--
-- Name: sequences(taxa); Type: FUNCTION; Schema: refrna; Owner: refrna
--

CREATE FUNCTION sequences(taxa) RETURNS SETOF sequences
    LANGUAGE sql
    AS $_$ select sequences.* from organisms_have_taxa, sequences_have_organisms, sequences where $1.id_taxon = organisms_have_taxa.id_taxon AND organisms_have_taxa.id_organism = sequences_have_organisms.id_organism and sequences_have_organisms.id_sequence = sequences.id_sequence; $_$;


ALTER FUNCTION refrna.sequences(taxa) OWNER TO refrna;

--
-- Name: classes; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE classes (
    id_class bigint NOT NULL,
    class character varying(45) NOT NULL,
    full_name character varying(100),
    description text
);


ALTER TABLE classes OWNER TO refrna;

--
-- Name: database_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE database_versions (
    id_version bigint NOT NULL,
    version character varying(100) NOT NULL
);


ALTER TABLE database_versions OWNER TO refrna;

--
-- Name: databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE databases (
    id_database bigint NOT NULL,
    database character varying(45) NOT NULL
);


ALTER TABLE databases OWNER TO refrna;

--
-- Name: databases_have_database_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE databases_have_database_versions (
    id_database bigint NOT NULL,
    id_version bigint NOT NULL
);


ALTER TABLE databases_have_database_versions OWNER TO refrna;

--
-- Name: families; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE families (
    id_family bigint NOT NULL,
    family character varying(45),
    full_name character varying(200),
    url character varying(100)
);


ALTER TABLE families OWNER TO refrna;

--
-- Name: nrdr_versions; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE nrdr_versions (
    id_version bigint NOT NULL,
    version character varying(100) NOT NULL
);


ALTER TABLE nrdr_versions OWNER TO refrna;

--
-- Name: nrdr_versions_have_databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE nrdr_versions_have_databases (
    id_database bigint NOT NULL,
    id_version bigint NOT NULL
);


ALTER TABLE nrdr_versions_have_databases OWNER TO refrna;

--
-- Name: organisms; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE organisms (
    id_organism bigint NOT NULL,
    organism character varying(100) NOT NULL
);


ALTER TABLE organisms OWNER TO refrna;

--
-- Name: organisms_have_taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE organisms_have_taxa (
    id_organism bigint NOT NULL,
    id_taxon bigint NOT NULL
);


ALTER TABLE organisms_have_taxa OWNER TO refrna;

--
-- Name: taxa_have_taxa; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE taxa_have_taxa (
    id_parent bigint NOT NULL,
    id_child bigint NOT NULL
);


ALTER TABLE taxa_have_taxa OWNER TO refrna;

--
-- Name: root_taxa; Type: MATERIALIZED VIEW; Schema: refrna; Owner: refrna
--

CREATE MATERIALIZED VIEW root_taxa AS
 SELECT taxa.id_taxon,
    taxa.taxon
   FROM (taxa
     LEFT JOIN taxa_have_taxa ON ((taxa.id_taxon = taxa_have_taxa.id_child)))
  WHERE (taxa_have_taxa.id_parent IS NULL)
  ORDER BY taxa.taxon
  WITH NO DATA;


ALTER TABLE root_taxa OWNER TO refrna;

--
-- Name: sequences_have_classes; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE sequences_have_classes (
    id_sequence bigint NOT NULL,
    id_class bigint NOT NULL
);


ALTER TABLE sequences_have_classes OWNER TO refrna;

--
-- Name: sequences_have_databases; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE sequences_have_databases (
    id_sequence bigint NOT NULL,
    id_database bigint NOT NULL
);


ALTER TABLE sequences_have_databases OWNER TO refrna;

--
-- Name: sequences_have_families; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE sequences_have_families (
    id_sequence bigint NOT NULL,
    id_family bigint NOT NULL
);


ALTER TABLE sequences_have_families OWNER TO refrna;

--
-- Name: sequences_have_organisms; Type: TABLE; Schema: refrna; Owner: refrna
--

CREATE TABLE sequences_have_organisms (
    id_sequence bigint NOT NULL,
    id_organism bigint NOT NULL
);


ALTER TABLE sequences_have_organisms OWNER TO refrna;

--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id_class);


--
-- Name: database_versions database_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY database_versions
    ADD CONSTRAINT database_versions_pkey PRIMARY KEY (id_version);


--
-- Name: database_versions database_versions_version_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY database_versions
    ADD CONSTRAINT database_versions_version_key UNIQUE (version);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_database_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_database_key UNIQUE (id_database);


--
-- Name: databases_have_database_versions databases_have_database_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_pkey PRIMARY KEY (id_database, id_version);


--
-- Name: databases databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY databases
    ADD CONSTRAINT databases_pkey PRIMARY KEY (id_database);


--
-- Name: families families_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY families
    ADD CONSTRAINT families_pkey PRIMARY KEY (id_family);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_pkey PRIMARY KEY (id_database, id_version);


--
-- Name: nrdr_versions nrdr_versions_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY nrdr_versions
    ADD CONSTRAINT nrdr_versions_pkey PRIMARY KEY (id_version);


--
-- Name: nrdr_versions nrdr_versions_version_key; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY nrdr_versions
    ADD CONSTRAINT nrdr_versions_version_key UNIQUE (version);


--
-- Name: organisms_have_taxa organisms_have_taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_pkey PRIMARY KEY (id_organism, id_taxon);


--
-- Name: organisms organisms_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY organisms
    ADD CONSTRAINT organisms_pkey PRIMARY KEY (id_organism);


--
-- Name: sequences_have_classes sequences_have_classes_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_pkey PRIMARY KEY (id_sequence, id_class);


--
-- Name: sequences_have_databases sequences_have_databases_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_pkey PRIMARY KEY (id_sequence, id_database);


--
-- Name: sequences_have_families sequences_have_families_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_families
    ADD CONSTRAINT sequences_have_families_pkey PRIMARY KEY (id_sequence, id_family);


--
-- Name: sequences_have_organisms sequences_have_organisms_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_pkey PRIMARY KEY (id_sequence, id_organism);


--
-- Name: sequences sequences_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id_sequence);


--
-- Name: taxa_have_taxa taxa_have_taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY taxa_have_taxa
    ADD CONSTRAINT taxa_have_taxa_pkey PRIMARY KEY (id_parent, id_child);


--
-- Name: taxa taxa_pkey; Type: CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY taxa
    ADD CONSTRAINT taxa_pkey PRIMARY KEY (id_taxon);


--
-- Name: nrdr_versions_have_databases_id_database_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX nrdr_versions_have_databases_id_database_fkey ON nrdr_versions_have_databases USING btree (id_database);


--
-- Name: nrdr_versions_have_databases_id_version_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX nrdr_versions_have_databases_id_version_fkey ON nrdr_versions_have_databases USING btree (id_version);


--
-- Name: organisms_have_taxa_id_organism_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX organisms_have_taxa_id_organism_fkey ON organisms_have_taxa USING btree (id_organism);


--
-- Name: organisms_have_taxa_id_taxon_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX organisms_have_taxa_id_taxon_fkey ON organisms_have_taxa USING btree (id_taxon);


--
-- Name: sequences_have_classes_id_class_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_classes_id_class_fkey ON sequences_have_classes USING btree (id_class);


--
-- Name: sequences_have_classes_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_classes_id_sequence_fkey ON sequences_have_classes USING btree (id_sequence);


--
-- Name: sequences_have_databases_id_database_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_databases_id_database_fkey ON sequences_have_databases USING btree (id_database);


--
-- Name: sequences_have_databases_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_databases_id_sequence_fkey ON sequences_have_databases USING btree (id_sequence);


--
-- Name: sequences_have_families_id_family_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_families_id_family_fkey ON sequences_have_families USING btree (id_family);


--
-- Name: sequences_have_families_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_families_id_sequence_fkey ON sequences_have_families USING btree (id_sequence);


--
-- Name: sequences_have_organisms_id_organism_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_organisms_id_organism_fkey ON sequences_have_organisms USING btree (id_organism);


--
-- Name: sequences_have_organisms_id_sequence_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX sequences_have_organisms_id_sequence_fkey ON sequences_have_organisms USING btree (id_sequence);


--
-- Name: taxa_have_taxa_id_child_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX taxa_have_taxa_id_child_fkey ON taxa_have_taxa USING btree (id_child);


--
-- Name: taxa_have_taxa_id_parent_fkey; Type: INDEX; Schema: refrna; Owner: refrna
--

CREATE INDEX taxa_have_taxa_id_parent_fkey ON taxa_have_taxa USING btree (id_parent);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_database_fkey FOREIGN KEY (id_database) REFERENCES databases(id_database);


--
-- Name: databases_have_database_versions databases_have_database_versions_id_version_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY databases_have_database_versions
    ADD CONSTRAINT databases_have_database_versions_id_version_fkey FOREIGN KEY (id_version) REFERENCES database_versions(id_version);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_id_database_fkey FOREIGN KEY (id_database) REFERENCES databases(id_database);


--
-- Name: nrdr_versions_have_databases nrdr_versions_have_databases_id_version_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY nrdr_versions_have_databases
    ADD CONSTRAINT nrdr_versions_have_databases_id_version_fkey FOREIGN KEY (id_version) REFERENCES nrdr_versions(id_version);


--
-- Name: organisms_have_taxa organisms_have_taxa_id_organism_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_id_organism_fkey FOREIGN KEY (id_organism) REFERENCES organisms(id_organism);


--
-- Name: organisms_have_taxa organisms_have_taxa_id_taxon_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY organisms_have_taxa
    ADD CONSTRAINT organisms_have_taxa_id_taxon_fkey FOREIGN KEY (id_taxon) REFERENCES taxa(id_taxon);


--
-- Name: sequences_have_classes sequences_have_classes_id_class_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_id_class_fkey FOREIGN KEY (id_class) REFERENCES classes(id_class);


--
-- Name: sequences_have_classes sequences_have_classes_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_classes
    ADD CONSTRAINT sequences_have_classes_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES sequences(id_sequence);


--
-- Name: sequences_have_databases sequences_have_databases_id_database_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_id_database_fkey FOREIGN KEY (id_database) REFERENCES databases(id_database);


--
-- Name: sequences_have_databases sequences_have_databases_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_databases
    ADD CONSTRAINT sequences_have_databases_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES sequences(id_sequence);


--
-- Name: sequences_have_families sequences_have_families_id_family_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_families
    ADD CONSTRAINT sequences_have_families_id_family_fkey FOREIGN KEY (id_family) REFERENCES families(id_family);


--
-- Name: sequences_have_families sequences_have_families_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_families
    ADD CONSTRAINT sequences_have_families_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES sequences(id_sequence);


--
-- Name: taxa_have_taxa sequences_have_organisms_id_child_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY taxa_have_taxa
    ADD CONSTRAINT sequences_have_organisms_id_child_fkey FOREIGN KEY (id_child) REFERENCES taxa(id_taxon);


--
-- Name: sequences_have_organisms sequences_have_organisms_id_organism_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_id_organism_fkey FOREIGN KEY (id_organism) REFERENCES organisms(id_organism);


--
-- Name: taxa_have_taxa sequences_have_organisms_id_parent_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY taxa_have_taxa
    ADD CONSTRAINT sequences_have_organisms_id_parent_fkey FOREIGN KEY (id_parent) REFERENCES taxa(id_taxon);


--
-- Name: sequences_have_organisms sequences_have_organisms_id_sequence_fkey; Type: FK CONSTRAINT; Schema: refrna; Owner: refrna
--

ALTER TABLE ONLY sequences_have_organisms
    ADD CONSTRAINT sequences_have_organisms_id_sequence_fkey FOREIGN KEY (id_sequence) REFERENCES sequences(id_sequence);


--
-- Name: refrna; Type: ACL; Schema: -; Owner: refrna
--

GRANT ALL ON SCHEMA refrna TO anon;


--
-- Name: taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE taxa TO anon;


--
-- Name: sequences; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE sequences TO anon;


--
-- Name: sequences(taxa); Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON FUNCTION sequences(taxa) TO anon;


--
-- Name: classes; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE classes TO anon;


--
-- Name: database_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE database_versions TO anon;


--
-- Name: databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE databases TO anon;


--
-- Name: databases_have_database_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE databases_have_database_versions TO anon;


--
-- Name: families; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE families TO anon;


--
-- Name: nrdr_versions; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE nrdr_versions TO anon;


--
-- Name: nrdr_versions_have_databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE nrdr_versions_have_databases TO anon;


--
-- Name: organisms; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE organisms TO anon;


--
-- Name: organisms_have_taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE organisms_have_taxa TO anon;


--
-- Name: taxa_have_taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE taxa_have_taxa TO anon;


--
-- Name: root_taxa; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE root_taxa TO anon;


--
-- Name: sequences_have_classes; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE sequences_have_classes TO anon;


--
-- Name: sequences_have_databases; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE sequences_have_databases TO anon;


--
-- Name: sequences_have_families; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE sequences_have_families TO anon;


--
-- Name: sequences_have_organisms; Type: ACL; Schema: refrna; Owner: refrna
--

GRANT ALL ON TABLE sequences_have_organisms TO anon;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: refrna; Owner: refrna
--

ALTER DEFAULT PRIVILEGES FOR ROLE refrna IN SCHEMA refrna REVOKE ALL ON TABLES  FROM refrna;
ALTER DEFAULT PRIVILEGES FOR ROLE refrna IN SCHEMA refrna GRANT SELECT ON TABLES  TO anon;


--
-- PostgreSQL database dump complete
--

