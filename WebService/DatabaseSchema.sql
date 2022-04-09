PGDMP     
            	        z           FitWithFriends    13.0    14.2     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    16394    FitWithFriends    DATABASE     t   CREATE DATABASE "FitWithFriends" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
     DROP DATABASE "FitWithFriends";
                postgres    false            �           0    0    DATABASE "FitWithFriends"    ACL     6   GRANT ALL ON DATABASE "FitWithFriends" TO "TestUser";
                   postgres    false    3027            �            1259    24734    activity_summaries    TABLE     K  CREATE TABLE public.activity_summaries (
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
       public         heap    postgres    false            �            1259    16483    competitions    TABLE       CREATE TABLE public.competitions (
    start_date date NOT NULL,
    end_date date NOT NULL,
    display_name text NOT NULL,
    access_token text NOT NULL,
    iana_timezone text NOT NULL,
    competition_id uuid NOT NULL,
    admin_user_id bytea NOT NULL
);
     DROP TABLE public.competitions;
       public         heap    postgres    false            �           0    0    TABLE competitions    ACL     6   GRANT ALL ON TABLE public.competitions TO "TestUser";
          public          postgres    false    202            �            1259    16402    oauth_clients    TABLE     �   CREATE TABLE public.oauth_clients (
    redirect_uri text NOT NULL,
    client_id uuid NOT NULL,
    client_secret uuid NOT NULL
);
 !   DROP TABLE public.oauth_clients;
       public         heap    postgres    false            �            1259    16396    oauth_tokens    TABLE     �   CREATE TABLE public.oauth_tokens (
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    user_id bytea NOT NULL,
    client_id uuid NOT NULL
);
     DROP TABLE public.oauth_tokens;
       public         heap    postgres    false            �            1259    24747    users    TABLE     l   CREATE TABLE public.users (
    user_id bytea NOT NULL,
    first_name text NOT NULL,
    last_name text
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    24755    users_competitions    TABLE     i   CREATE TABLE public.users_competitions (
    user_id bytea NOT NULL,
    competition_id uuid NOT NULL
);
 &   DROP TABLE public.users_competitions;
       public         heap    postgres    false            =           2606    24806     oauth_clients oauth_clients_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id);
 J   ALTER TABLE ONLY public.oauth_clients DROP CONSTRAINT oauth_clients_pkey;
       public            postgres    false    201            ?           2606    24769    competitions primary_key 
   CONSTRAINT     b   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT primary_key PRIMARY KEY (competition_id);
 B   ALTER TABLE ONLY public.competitions DROP CONSTRAINT primary_key;
       public            postgres    false    202            A           2606    24790    activity_summaries primary_key2 
   CONSTRAINT     h   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT primary_key2 PRIMARY KEY (date, user_id);
 I   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT primary_key2;
       public            postgres    false    203    203            ;           2606    24797    oauth_tokens token_primary_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT token_primary_key PRIMARY KEY (refresh_token);
 H   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT token_primary_key;
       public            postgres    false    200            E           2606    24762 *   users_competitions users_competitions_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_pkey PRIMARY KEY (user_id, competition_id);
 T   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT users_competitions_pkey;
       public            postgres    false    205    205            C           2606    24754    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    204            H           2606    24791 %   competitions admin_user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT admin_user_id_foreignkey FOREIGN KEY (admin_user_id) REFERENCES public.users(user_id) NOT VALID;
 O   ALTER TABLE ONLY public.competitions DROP CONSTRAINT admin_user_id_foreignkey;
       public          postgres    false    2883    204    202            K           2606    24812 ,   users_competitions competition_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT competition_id_foreignkey FOREIGN KEY (competition_id) REFERENCES public.competitions(competition_id) ON DELETE CASCADE NOT VALID;
 V   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT competition_id_foreignkey;
       public          postgres    false    2879    205    202            G           2606    24807 (   oauth_tokens oauth_tokens_client_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.oauth_clients(client_id) NOT VALID;
 R   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_client_id_fkey;
       public          postgres    false    200    201    2877            F           2606    24798 &   oauth_tokens oauth_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) NOT VALID;
 P   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_user_id_fkey;
       public          postgres    false    204    2883    200            J           2606    24763 %   users_competitions user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 O   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT user_id_foreignkey;
       public          postgres    false    2883    204    205            I           2606    24784 %   activity_summaries user_id_foreignkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT user_id_foreignkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) NOT VALID;
 O   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT user_id_foreignkey;
       public          postgres    false    2883    203    204           