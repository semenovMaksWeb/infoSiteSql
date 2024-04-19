DROP SCHEMA IF EXISTS auth CASCADE;
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION postgres;

DROP TABLE IF EXISTS auth."user";
CREATE TABLE IF NOT EXISTS auth."user" (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	surname varchar NOT NULL,
	middlename varchar NOT NULL,
	email varchar NOT NULL,
	"password" varchar NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	is_email bool DEFAULT false NOT NULL,
	CONSTRAINT user_email_unique UNIQUE (email),
	CONSTRAINT user_pk PRIMARY KEY (id)
);

DROP TABLE IF EXISTS auth."token";
CREATE TABLE IF NOT EXISTS auth."token" (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	access_token varchar NOT NULL,
	refresh_token varchar NOT NULL,
	is_active bool DEFAULT true NOT NULL,
	date_create timestamp DEFAULT now() NOT NULL,
	time_life timestamp NOT NULL,
	id_user int4 NOT NULL,
	CONSTRAINT access_token_unique UNIQUE (access_token),
	CONSTRAINT refresh_token_unique UNIQUE (refresh_token),
	CONSTRAINT token_pk PRIMARY KEY (id),
	CONSTRAINT token_user_fk FOREIGN KEY (id_user) REFERENCES auth."user"(id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS auth.roles;
CREATE TABLE IF NOT EXISTS auth.roles (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	const_name varchar NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	is_active bool DEFAULT true NOT NULL,
	CONSTRAINT roles_const_name_unique UNIQUE (const_name),
	CONSTRAINT roles_name_unique UNIQUE (name),
	CONSTRAINT roles_pk PRIMARY KEY (id)
);

DROP TABLE IF EXISTS auth."right";
CREATE TABLE IF NOT EXISTS auth."right" (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	const_name varchar NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	is_active bool DEFAULT true NOT NULL,
	CONSTRAINT right_const_name_unique UNIQUE (const_name),
	CONSTRAINT right_name_unique UNIQUE (name),
	CONSTRAINT right_pk PRIMARY KEY (id)
);

DROP TABLE IF EXISTS auth.right_roles;
CREATE TABLE IF NOT EXISTS auth.right_roles (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	id_right int4 NOT NULL,
	id_roles int4 NOT NULL,
	CONSTRAINT right_roles_pk PRIMARY KEY (id),
	CONSTRAINT right_roles_right_fk FOREIGN KEY (id_roles) REFERENCES auth."right"(id) ON DELETE CASCADE,
	CONSTRAINT right_roles_roles_fk FOREIGN KEY (id_roles) REFERENCES auth.roles(id)
);
CREATE UNIQUE INDEX right_roles_id_right_idx ON auth.right_roles USING btree (id_right, id_roles);

DROP TABLE IF EXISTS auth.roles_user;
CREATE TABLE IF NOT EXISTS auth.roles_user (
	id int4 GENERATED ALWAYS AS IDENTITY NOT NULL,
	id_roles int4 NOT NULL,
	id_user int4 NOT NULL,
	CONSTRAINT roles_user_pk PRIMARY KEY (id),
	CONSTRAINT roles_user_roles_fk FOREIGN KEY (id_roles) REFERENCES auth.roles(id) ON DELETE CASCADE,
	CONSTRAINT roles_user_user_fk FOREIGN KEY (id_user) REFERENCES auth."user"(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX roles_user_id_roles_idx ON auth.roles_user USING btree (id_roles, id_user);