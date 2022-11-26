PGDMP     6                
    z            FitWithFriends    11.16    15.0     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    21526    FitWithFriends    DATABASE     �   CREATE DATABASE "FitWithFriends" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
     DROP DATABASE "FitWithFriends";
                danocon    false                        2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                azure_superuser    false            �           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   azure_superuser    false    8            �            1259    296527    activity_summaries    TABLE     K  CREATE TABLE public.activity_summaries (
    date date NOT NULL,
    calories_burned real NOT NULL,
    calories_goal real NOT NULL,
    exercise_time real NOT NULL,
    exercise_time_goal real NOT NULL,
    stand_time real NOT NULL,
    stand_time_goal real NOT NULL,
    daily_points real NOT NULL,
    user_id bytea NOT NULL
);
 &   DROP TABLE public.activity_summaries;
       public            danocon    false    8            �            1259    296533    competitions    TABLE       CREATE TABLE public.competitions (
    start_date date NOT NULL,
    end_date date NOT NULL,
    display_name text NOT NULL,
    access_token text NOT NULL,
    iana_timezone text NOT NULL,
    competition_id uuid NOT NULL,
    admin_user_id bytea NOT NULL
);
     DROP TABLE public.competitions;
       public            danocon    false    8            �            1259    296539    oauth_clients    TABLE     �   CREATE TABLE public.oauth_clients (
    redirect_uri text NOT NULL,
    client_id uuid NOT NULL,
    client_secret uuid NOT NULL
);
 !   DROP TABLE public.oauth_clients;
       public            danocon    false    8            �            1259    296545    oauth_tokens    TABLE     �   CREATE TABLE public.oauth_tokens (
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    user_id bytea NOT NULL,
    client_id uuid NOT NULL
);
     DROP TABLE public.oauth_tokens;
       public            danocon    false    8            �            1259    296551    users    TABLE     �   CREATE TABLE public.users (
    user_id bytea NOT NULL,
    first_name text NOT NULL,
    last_name text,
    max_active_competitions smallint DEFAULT 1 NOT NULL,
    is_pro boolean DEFAULT false NOT NULL,
    created_date date
);
    DROP TABLE public.users;
       public            danocon    false    8            �            1259    296557    users_competitions    TABLE     i   CREATE TABLE public.users_competitions (
    user_id bytea NOT NULL,
    competition_id uuid NOT NULL
);
 &   DROP TABLE public.users_competitions;
       public            danocon    false    8            #           2606    296564     oauth_clients oauth_clients_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id);
 J   ALTER TABLE ONLY public.oauth_clients DROP CONSTRAINT oauth_clients_pkey;
       public            danocon    false    202            !           2606    296566    competitions primary_key 
   CONSTRAINT     b   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT primary_key PRIMARY KEY (competition_id);
 B   ALTER TABLE ONLY public.competitions DROP CONSTRAINT primary_key;
       public            danocon    false    201                       2606    296568    activity_summaries primary_key2 
   CONSTRAINT     h   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT primary_key2 PRIMARY KEY (date, user_id);
 I   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT primary_key2;
       public            danocon    false    200    200            '           2606    296570    oauth_tokens token_primary_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT token_primary_key PRIMARY KEY (refresh_token);
 H   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT token_primary_key;
       public            danocon    false    203            -           2606    296572 *   users_competitions users_competitions_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_pkey PRIMARY KEY (user_id, competition_id);
 T   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT users_competitions_pkey;
       public            danocon    false    205    205            )           2606    296574    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            danocon    false    204                       1259    296639    fki_admin_user_id_foreignkey    INDEX     ^   CREATE INDEX fki_admin_user_id_foreignkey ON public.competitions USING btree (admin_user_id);
 0   DROP INDEX public.fki_admin_user_id_foreignkey;
       public            danocon    false    201            *           1259    296610    fki_competition_id_foreignkey    INDEX     f   CREATE INDEX fki_competition_id_foreignkey ON public.users_competitions USING btree (competition_id);
 1   DROP INDEX public.fki_competition_id_foreignkey;
       public            danocon    false    205            $           1259    296627    fki_oauth_tokens_client_id_fkey    INDEX     ]   CREATE INDEX fki_oauth_tokens_client_id_fkey ON public.oauth_tokens USING btree (client_id);
 3   DROP INDEX public.fki_oauth_tokens_client_id_fkey;
       public            danocon    false    203            %           1259    296633    fki_oauth_tokens_user_id_fkey    INDEX     Y   CREATE INDEX fki_oauth_tokens_user_id_fkey ON public.oauth_tokens USING btree (user_id);
 1   DROP INDEX public.fki_oauth_tokens_user_id_fkey;
       public            danocon    false    203            +           1259    296621    fki_user_id_foreignkey    INDEX     X   CREATE INDEX fki_user_id_foreignkey ON public.users_competitions USING btree (user_id);
 *   DROP INDEX public.fki_user_id_foreignkey;
       public            danocon    false    205            /           2606    296634 %   competitions admin_user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT admin_user_id_foreignkey FOREIGN KEY (admin_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.competitions DROP CONSTRAINT admin_user_id_foreignkey;
       public          danocon    false    201    204    4137            2           2606    296611 ,   users_competitions competition_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT competition_id_foreignkey FOREIGN KEY (competition_id) REFERENCES public.competitions(competition_id) ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT competition_id_foreignkey;
       public          danocon    false    205    4129    201            0           2606    296622 (   oauth_tokens oauth_tokens_client_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.oauth_clients(client_id) ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_client_id_fkey;
       public          danocon    false    4131    202    203            1           2606    296628 &   oauth_tokens oauth_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 P   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_user_id_fkey;
       public          danocon    false    204    203    4137            3           2606    296616 %   users_competitions user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT user_id_foreignkey;
       public          danocon    false    4137    204    205            .           2606    296640 %   activity_summaries user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT user_id_foreignkey;
       public          danocon    false    200    4137    204           