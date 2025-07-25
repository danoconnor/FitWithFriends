PGDMP  /                    }           testdb    16.9 (Debian 16.9-1.pgdg120+1)    16.0 !    O           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            P           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            Q           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            R           1262    16384    testdb    DATABASE     q   CREATE DATABASE testdb WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';
    DROP DATABASE testdb;
                postgres    false            �            1259    16385    activity_summaries    TABLE     C  CREATE TABLE public.activity_summaries (
    date date NOT NULL,
    calories_burned smallint NOT NULL,
    calories_goal smallint NOT NULL,
    exercise_time smallint NOT NULL,
    exercise_time_goal smallint NOT NULL,
    stand_time smallint NOT NULL,
    stand_time_goal smallint NOT NULL,
    user_id bytea NOT NULL
);
 &   DROP TABLE public.activity_summaries;
       public         heap    postgres    false            �            1259    16390    competitions    TABLE     +  CREATE TABLE public.competitions (
    start_date date NOT NULL,
    end_date date NOT NULL,
    display_name text NOT NULL,
    access_token text NOT NULL,
    iana_timezone text NOT NULL,
    competition_id uuid NOT NULL,
    admin_user_id bytea NOT NULL,
    state smallint DEFAULT 1 NOT NULL
);
     DROP TABLE public.competitions;
       public         heap    postgres    false            �            1259    16396    oauth_clients    TABLE     �   CREATE TABLE public.oauth_clients (
    redirect_uri text NOT NULL,
    client_id uuid NOT NULL,
    client_secret uuid NOT NULL
);
 !   DROP TABLE public.oauth_clients;
       public         heap    postgres    false            �            1259    16401    oauth_tokens    TABLE     �   CREATE TABLE public.oauth_tokens (
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    user_id bytea NOT NULL,
    client_id uuid NOT NULL
);
     DROP TABLE public.oauth_tokens;
       public         heap    postgres    false            �            1259    16406    push_tokens    TABLE     �   CREATE TABLE public.push_tokens (
    user_id bytea NOT NULL,
    push_token text NOT NULL,
    platform smallint NOT NULL,
    app_install_id uuid NOT NULL
);
    DROP TABLE public.push_tokens;
       public         heap    postgres    false            �            1259    16411    users    TABLE     �   CREATE TABLE public.users (
    user_id bytea NOT NULL,
    first_name text NOT NULL,
    last_name text,
    max_active_competitions smallint DEFAULT 1 NOT NULL,
    is_pro boolean DEFAULT false NOT NULL,
    created_date date NOT NULL
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    16418    users_competitions    TABLE     �   CREATE TABLE public.users_competitions (
    user_id bytea NOT NULL,
    competition_id uuid NOT NULL,
    final_points real
);
 &   DROP TABLE public.users_competitions;
       public         heap    postgres    false            �            1259    16423    workouts    TABLE     �   CREATE TABLE public.workouts (
    user_id bytea NOT NULL,
    start_date date NOT NULL,
    workout_type smallint NOT NULL,
    duration integer NOT NULL,
    distance integer,
    unit smallint,
    calories_burned integer NOT NULL
);
    DROP TABLE public.workouts;
       public         heap    postgres    false            �           2606    16429    push_tokens Primary Key 
   CONSTRAINT     v   ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT "Primary Key" PRIMARY KEY (user_id, platform, app_install_id);
 C   ALTER TABLE ONLY public.push_tokens DROP CONSTRAINT "Primary Key";
       public            postgres    false    219    219    219            �           2606    16431     oauth_clients oauth_clients_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id);
 J   ALTER TABLE ONLY public.oauth_clients DROP CONSTRAINT oauth_clients_pkey;
       public            postgres    false    217            �           2606    16433    competitions primary_key 
   CONSTRAINT     b   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT primary_key PRIMARY KEY (competition_id);
 B   ALTER TABLE ONLY public.competitions DROP CONSTRAINT primary_key;
       public            postgres    false    216            �           2606    16435    activity_summaries primary_key2 
   CONSTRAINT     h   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT primary_key2 PRIMARY KEY (date, user_id);
 I   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT primary_key2;
       public            postgres    false    215    215            �           2606    16437    oauth_tokens token_primary_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT token_primary_key PRIMARY KEY (refresh_token);
 H   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT token_primary_key;
       public            postgres    false    218            �           2606    16439 *   users_competitions users_competitions_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_pkey PRIMARY KEY (user_id, competition_id);
 T   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT users_competitions_pkey;
       public            postgres    false    221    221            �           2606    16441    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    220            �           2606    16443    workouts workouts_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.workouts
    ADD CONSTRAINT workouts_pkey PRIMARY KEY (user_id, start_date, workout_type);
 @   ALTER TABLE ONLY public.workouts DROP CONSTRAINT workouts_pkey;
       public            postgres    false    222    222    222            �           1259    16444    fki_admin_user_id_foreignkey    INDEX     ^   CREATE INDEX fki_admin_user_id_foreignkey ON public.competitions USING btree (admin_user_id);
 0   DROP INDEX public.fki_admin_user_id_foreignkey;
       public            postgres    false    216            �           1259    16445    fki_competition_id_foreignkey    INDEX     f   CREATE INDEX fki_competition_id_foreignkey ON public.users_competitions USING btree (competition_id);
 1   DROP INDEX public.fki_competition_id_foreignkey;
       public            postgres    false    221            �           1259    16446    fki_oauth_tokens_client_id_fkey    INDEX     ]   CREATE INDEX fki_oauth_tokens_client_id_fkey ON public.oauth_tokens USING btree (client_id);
 3   DROP INDEX public.fki_oauth_tokens_client_id_fkey;
       public            postgres    false    218            �           1259    16447    fki_oauth_tokens_user_id_fkey    INDEX     Y   CREATE INDEX fki_oauth_tokens_user_id_fkey ON public.oauth_tokens USING btree (user_id);
 1   DROP INDEX public.fki_oauth_tokens_user_id_fkey;
       public            postgres    false    218            �           1259    16448    fki_user_id_foreignkey    INDEX     X   CREATE INDEX fki_user_id_foreignkey ON public.users_competitions USING btree (user_id);
 *   DROP INDEX public.fki_user_id_foreignkey;
       public            postgres    false    221            �           2606    16449 %   competitions admin_user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT admin_user_id_foreignkey FOREIGN KEY (admin_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.competitions DROP CONSTRAINT admin_user_id_foreignkey;
       public          postgres    false    216    3247    220            �           2606    16454 ,   users_competitions competition_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT competition_id_foreignkey FOREIGN KEY (competition_id) REFERENCES public.competitions(competition_id) ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT competition_id_foreignkey;
       public          postgres    false    216    221    3237            �           2606    16459 (   oauth_tokens oauth_tokens_client_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.oauth_clients(client_id) ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_client_id_fkey;
       public          postgres    false    217    218    3239            �           2606    16464 &   oauth_tokens oauth_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 P   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_user_id_fkey;
       public          postgres    false    218    220    3247            �           2606    16469    push_tokens userIdFKey    FK CONSTRAINT     �   ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT "userIdFKey" FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.push_tokens DROP CONSTRAINT "userIdFKey";
       public          postgres    false    3247    219    220            �           2606    16474    workouts userId_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.workouts
    ADD CONSTRAINT "userId_fkey" FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 @   ALTER TABLE ONLY public.workouts DROP CONSTRAINT "userId_fkey";
       public          postgres    false    220    222    3247            �           2606    16479 %   users_competitions user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT user_id_foreignkey;
       public          postgres    false    221    3247    220            �           2606    16484 %   activity_summaries user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT user_id_foreignkey;
       public          postgres    false    215    220    3247           