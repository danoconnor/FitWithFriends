--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Homebrew)
-- Dumped by pg_dump version 16.0

-- Started on 2024-02-28 21:38:11 EST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

-- CREATE SCHEMA public;


-- ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3664 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

-- COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 16391)
-- Name: activity_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_summaries (
    date date NOT NULL,
    calories_burned smallint NOT NULL,
    calories_goal smallint NOT NULL,
    exercise_time smallint NOT NULL,
    exercise_time_goal smallint NOT NULL,
    stand_time smallint NOT NULL,
    stand_time_goal smallint NOT NULL,
    user_id bytea NOT NULL
);


ALTER TABLE public.activity_summaries OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16396)
-- Name: competitions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.competitions (
    start_date date NOT NULL,
    end_date date NOT NULL,
    display_name text NOT NULL,
    access_token text NOT NULL,
    iana_timezone text NOT NULL,
    competition_id uuid NOT NULL,
    admin_user_id bytea NOT NULL
);


ALTER TABLE public.competitions OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16401)
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_clients (
    redirect_uri text NOT NULL,
    client_id uuid NOT NULL,
    client_secret uuid NOT NULL
);


ALTER TABLE public.oauth_clients OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16406)
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_tokens (
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    user_id bytea NOT NULL,
    client_id uuid NOT NULL
);


ALTER TABLE public.oauth_tokens OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24616)
-- Name: push_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.push_tokens (
    user_id bytea NOT NULL,
    push_token text NOT NULL,
    platform smallint NOT NULL
);


ALTER TABLE public.push_tokens OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16411)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id bytea NOT NULL,
    first_name text NOT NULL,
    last_name text,
    max_active_competitions smallint DEFAULT 1 NOT NULL,
    is_pro boolean DEFAULT false NOT NULL,
    created_date date NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16418)
-- Name: users_competitions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users_competitions (
    user_id bytea NOT NULL,
    competition_id uuid NOT NULL
);


ALTER TABLE public.users_competitions OWNER TO postgres;

--
-- TOC entry 3496 (class 2606 OID 16424)
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id);


--
-- TOC entry 3494 (class 2606 OID 16426)
-- Name: competitions primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT primary_key PRIMARY KEY (competition_id);


--
-- TOC entry 3491 (class 2606 OID 16428)
-- Name: activity_summaries primary_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT primary_key2 PRIMARY KEY (date, user_id);


--
-- TOC entry 3508 (class 2606 OID 24622)
-- Name: push_tokens push_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT push_tokens_pkey PRIMARY KEY (user_id, push_token, platform);


--
-- TOC entry 3500 (class 2606 OID 16430)
-- Name: oauth_tokens token_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT token_primary_key PRIMARY KEY (refresh_token);


--
-- TOC entry 3506 (class 2606 OID 16432)
-- Name: users_competitions users_competitions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_pkey PRIMARY KEY (user_id, competition_id);


--
-- TOC entry 3502 (class 2606 OID 16434)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3492 (class 1259 OID 16435)
-- Name: fki_admin_user_id_foreignkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_admin_user_id_foreignkey ON public.competitions USING btree (admin_user_id);


--
-- TOC entry 3503 (class 1259 OID 16436)
-- Name: fki_competition_id_foreignkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_competition_id_foreignkey ON public.users_competitions USING btree (competition_id);


--
-- TOC entry 3497 (class 1259 OID 16437)
-- Name: fki_oauth_tokens_client_id_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_oauth_tokens_client_id_fkey ON public.oauth_tokens USING btree (client_id);


--
-- TOC entry 3498 (class 1259 OID 16438)
-- Name: fki_oauth_tokens_user_id_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_oauth_tokens_user_id_fkey ON public.oauth_tokens USING btree (user_id);


--
-- TOC entry 3504 (class 1259 OID 16439)
-- Name: fki_user_id_foreignkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_user_id_foreignkey ON public.users_competitions USING btree (user_id);


--
-- TOC entry 3510 (class 2606 OID 16440)
-- Name: competitions admin_user_id_foreignkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT admin_user_id_foreignkey FOREIGN KEY (admin_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3513 (class 2606 OID 16445)
-- Name: users_competitions competition_id_foreignkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT competition_id_foreignkey FOREIGN KEY (competition_id) REFERENCES public.competitions(competition_id) ON DELETE CASCADE;


--
-- TOC entry 3511 (class 2606 OID 16450)
-- Name: oauth_tokens oauth_tokens_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.oauth_clients(client_id) ON DELETE CASCADE;


--
-- TOC entry 3512 (class 2606 OID 16455)
-- Name: oauth_tokens oauth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3515 (class 2606 OID 24623)
-- Name: push_tokens userIdFKey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT "userIdFKey" FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3514 (class 2606 OID 16460)
-- Name: users_competitions user_id_foreignkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3509 (class 2606 OID 16465)
-- Name: activity_summaries user_id_foreignkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3665 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

-- REVOKE USAGE ON SCHEMA public FROM PUBLIC;
-- GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2024-02-28 21:38:11 EST

--
-- PostgreSQL database dump complete
--

