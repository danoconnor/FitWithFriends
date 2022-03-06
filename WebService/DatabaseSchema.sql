PGDMP     !    $                z            FitWithFriends    11.12    14.2     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    21526    FitWithFriends    DATABASE     t   CREATE DATABASE "FitWithFriends" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
     DROP DATABASE "FitWithFriends";
                danocon    false            �            1259    51104    activity_summaries    TABLE     M  CREATE TABLE public.activity_summaries (
    user_id integer NOT NULL,
    date date NOT NULL,
    calories_burned real NOT NULL,
    calories_goal real NOT NULL,
    exercise_time real NOT NULL,
    exercise_time_goal real NOT NULL,
    stand_time real NOT NULL,
    stand_time_goal real NOT NULL,
    daily_points real NOT NULL
);
 &   DROP TABLE public.activity_summaries;
       public            danocon    false            �            1259    21527    competitions    TABLE     	  CREATE TABLE public.competitions (
    start_date date NOT NULL,
    end_date date NOT NULL,
    display_name text NOT NULL,
    admin_user_id integer NOT NULL,
    access_token text NOT NULL,
    competition_id integer NOT NULL,
    iana_timezone text NOT NULL
);
     DROP TABLE public.competitions;
       public            danocon    false            �            1259    21533    competitions_competition_id_seq    SEQUENCE     �   CREATE SEQUENCE public.competitions_competition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 6   DROP SEQUENCE public.competitions_competition_id_seq;
       public          danocon    false    200            �           0    0    competitions_competition_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.competitions_competition_id_seq OWNED BY public.competitions.competition_id;
          public          danocon    false    201            �            1259    21535    oauth_clients    TABLE     �   CREATE TABLE public.oauth_clients (
    client_id text NOT NULL,
    client_secret text NOT NULL,
    redirect_uri text NOT NULL
);
 !   DROP TABLE public.oauth_clients;
       public            danocon    false            �            1259    21541    oauth_tokens    TABLE     D  CREATE TABLE public.oauth_tokens (
    access_token text NOT NULL,
    access_token_expires_on timestamp without time zone NOT NULL,
    client_id text NOT NULL,
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    tokenid integer NOT NULL,
    user_id integer NOT NULL
);
     DROP TABLE public.oauth_tokens;
       public            danocon    false            �            1259    21547    oauth_tokens_tokenid_seq    SEQUENCE     �   CREATE SEQUENCE public.oauth_tokens_tokenid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 /   DROP SEQUENCE public.oauth_tokens_tokenid_seq;
       public          danocon    false    203            �           0    0    oauth_tokens_tokenid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.oauth_tokens_tokenid_seq OWNED BY public.oauth_tokens.tokenid;
          public          danocon    false    204            �            1259    21549    users    TABLE     �   CREATE TABLE public.users (
    username text NOT NULL,
    password_hash text NOT NULL,
    password_salt text NOT NULL,
    userid integer NOT NULL,
    display_name text NOT NULL
);
    DROP TABLE public.users;
       public            danocon    false            �            1259    21555    users_competitions    TABLE     l   CREATE TABLE public.users_competitions (
    userid integer NOT NULL,
    competitionid integer NOT NULL
);
 &   DROP TABLE public.users_competitions;
       public            danocon    false            �            1259    21558    users_userid_seq    SEQUENCE     �   CREATE SEQUENCE public.users_userid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 '   DROP SEQUENCE public.users_userid_seq;
       public          danocon    false    205            �           0    0    users_userid_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.users_userid_seq OWNED BY public.users.userid;
          public          danocon    false    207                       2604    51125    competitions competition_id    DEFAULT     �   ALTER TABLE ONLY public.competitions ALTER COLUMN competition_id SET DEFAULT nextval('public.competitions_competition_id_seq'::regclass);
 J   ALTER TABLE public.competitions ALTER COLUMN competition_id DROP DEFAULT;
       public          danocon    false    201    200                        2604    51135    oauth_tokens tokenid    DEFAULT     |   ALTER TABLE ONLY public.oauth_tokens ALTER COLUMN tokenid SET DEFAULT nextval('public.oauth_tokens_tokenid_seq'::regclass);
 C   ALTER TABLE public.oauth_tokens ALTER COLUMN tokenid DROP DEFAULT;
       public          danocon    false    204    203            !           2604    51153    users userid    DEFAULT     l   ALTER TABLE ONLY public.users ALTER COLUMN userid SET DEFAULT nextval('public.users_userid_seq'::regclass);
 ;   ALTER TABLE public.users ALTER COLUMN userid DROP DEFAULT;
       public          danocon    false    207    205            +           2606    51170    users_competitions PrimaryKey 
   CONSTRAINT     p   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT "PrimaryKey" PRIMARY KEY (userid, competitionid);
 I   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT "PrimaryKey";
       public            danocon    false    206    206            -           2606    51215 *   activity_summaries activity_summaries_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT activity_summaries_pkey PRIMARY KEY (user_id, date);
 T   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT activity_summaries_pkey;
       public            danocon    false    208    208            #           2606    51127    competitions competitions_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (competition_id);
 H   ALTER TABLE ONLY public.competitions DROP CONSTRAINT competitions_pkey;
       public            danocon    false    200            %           2606    21566     oauth_clients oauth_clients_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id, client_secret);
 J   ALTER TABLE ONLY public.oauth_clients DROP CONSTRAINT oauth_clients_pkey;
       public            danocon    false    202    202            '           2606    51137    oauth_tokens oauth_tokens_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (tokenid);
 H   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_pkey;
       public            danocon    false    203            )           2606    51155    users users_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            danocon    false    205            3           2606    51220 2   activity_summaries activity_summaries_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.activity_summaries
    ADD CONSTRAINT activity_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) NOT VALID;
 \   ALTER TABLE ONLY public.activity_summaries DROP CONSTRAINT activity_summaries_user_id_fkey;
       public          danocon    false    205    208    4137            .           2606    51190 ,   competitions competitions_admin_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.users(userid) NOT VALID;
 V   ALTER TABLE ONLY public.competitions DROP CONSTRAINT competitions_admin_user_id_fkey;
       public          danocon    false    4137    205    200            /           2606    51195 -   competitions competitions_competition_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(competition_id) NOT VALID;
 W   ALTER TABLE ONLY public.competitions DROP CONSTRAINT competitions_competition_id_fkey;
       public          danocon    false    200    200    4131            0           2606    51185 &   oauth_tokens oauth_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) NOT VALID;
 P   ALTER TABLE ONLY public.oauth_tokens DROP CONSTRAINT oauth_tokens_user_id_fkey;
       public          danocon    false    4137    205    203            2           2606    51180 8   users_competitions users_competitions_competitionid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_competitionid_fkey FOREIGN KEY (competitionid) REFERENCES public.competitions(competition_id) NOT VALID;
 b   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT users_competitions_competitionid_fkey;
       public          danocon    false    206    4131    200            1           2606    51175 1   users_competitions users_competitions_userid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_competitions
    ADD CONSTRAINT users_competitions_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(userid) NOT VALID;
 [   ALTER TABLE ONLY public.users_competitions DROP CONSTRAINT users_competitions_userid_fkey;
       public          danocon    false    4137    206    205           