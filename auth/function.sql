-- select * from auth.user_check_validate('test', 1)
-- select * from auth.user_check_authorization('test4', 'password');
-- select * from auth.user_check_id(11)
-- select  * from auth.register('test', 'test1', 'test2', 'test4', 'password')
-- select * from auth.token_delete_user_id(1)
-- select * from auth.banned_user(1);
-- select * from auth.unblock_user(1);
-- select * from auth.token_create(2::int4, 'acc-tok-41'::varchar, 'ref-tok-31'::varchar,  (now() + interval '20 minutes')::timestamp)
-- select * from auth.exit('acc-tok-41')
-- select * from auth.exit_all('access-token132'::varchar)

DROP FUNCTION IF EXISTS auth.user_check_validate;
CREATE OR REPLACE FUNCTION auth.user_check_validate(in _email varchar, in _id_user int4 = null, out check_email_ bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	BEGIN
		select case 
			when count(u.id) = 1 then false 
			else true end
		from auth."user" u 
        where u.email = _email and (u.id != _id_user or _id_user IS null) into check_email_; 
	END;
$function$

DROP FUNCTION IF EXISTS auth.register;
CREATE OR REPLACE FUNCTION auth.register(in _name varchar, in _surname varchar, in _middlename varchar, in _email varchar, in _password varchar, out status_ int, out id_ int)
	RETURNS record
	LANGUAGE plpgsql
	AS $function$
	declare 
		check_email bool;
	begin
		select * into check_email from auth.user_check_validate(_email);
		if check_email = true then
			insert into auth."user" ("name", surname, middlename, email, "password") 
            values (_name, _surname, _middlename, _email, _password) RETURNING id into id_;
			status_ = 1;
		else
			status_ = 0;
		end if;
		END;
$function$

DROP FUNCTION IF EXISTS auth.user_check_id;
CREATE OR REPLACE FUNCTION auth.user_check_id(in _id int4, out check_user_ bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	BEGIN
		select 
			case when count(u.id) = 1 then true 
			else false end
		from auth."user" u 
		where u.id = _id into check_user_;
	END;
$function$

DROP FUNCTION IF EXISTS auth.user_check_authorization;
CREATE OR REPLACE FUNCTION auth.user_check_authorization(in _email varchar, in _password varchar, out check_user_ bool, out id_ int4)
	RETURNS record
	LANGUAGE plpgsql
	AS $function$
	BEGIN
		select case
			when count(u.id) = 1 then true 
			else false end, u.id
		into check_user_, id_ 
		from auth."user" u
		where u.email = _email and u."password" = _password
		group by u.id
		limit 1;
	if id_ is null then
		check_user_ = false;
	end if;
	END;
$function$

DROP FUNCTION IF EXISTS auth.token_delete_user_id;
CREATE OR REPLACE FUNCTION auth.token_delete_user_id(in _id_user int4, out check_user_ bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	begin
		select * into check_user_ from auth.user_check_id(_id_user);
		if check_user_ = true then
			delete from auth."token" t where t.id_user = _id_user;
		end if;
		END;
$function$

DROP FUNCTION IF EXISTS auth.banned_user;
CREATE OR REPLACE FUNCTION auth.banned_user(in _id_user int4, out check_user_ bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	begin
		select * into check_user_ from auth.token_delete_user_id(_id_user);
		if check_user_ = true then
			update auth."user" set is_active = false where id = _id_user;
		end if;
	END;
$function$

DROP FUNCTION IF EXISTS auth.unblock_user;
CREATE OR REPLACE FUNCTION auth.unblock_user(in _id_user int4, out check_user_ bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	begin
		select * into check_user_ from auth.user_check_id(_id_user);
		if check_user_ = true then
			update auth."user" set is_active = true where id = _id_user;
		end if;
	END;
$function$

DROP FUNCTION IF EXISTS auth.token_create;
CREATE OR REPLACE FUNCTION auth.token_create(in _id_user int4, in _access_token varchar, in _refresh_token varchar, in _time_life timestamp, out check_user_ bool, out id_token_ int4)
	RETURNS record
	LANGUAGE plpgsql
	AS $function$
	begin
		select * into check_user_ from auth.user_check_id(_id_user);
		if check_user_ = true then
			insert into auth."token" (access_token, refresh_token, time_life, id_user)
			values (_access_token, _refresh_token, _time_life, _id_user) 
			returning id into id_token_;
		end if;
		if check_user_ is null then
			check_user_ = false;
		end if;
	END;
$function$

DROP FUNCTION IF EXISTS auth.exit;
CREATE OR REPLACE FUNCTION auth.exit(_access_token varchar)
	RETURNS void
	LANGUAGE plpgsql
	AS $function$
	begin
		delete from auth."token" t where t.access_token = _access_token;
	END;
$function$

DROP FUNCTION IF EXISTS auth.exit_all;
CREATE OR REPLACE FUNCTION auth.exit_all(in _access_token varchar, out _status bool)
	RETURNS bool
	LANGUAGE plpgsql
	AS $function$
	begin
		delete from auth."token" t 
	where t.access_token <> _access_token 
	and t.id_user = (
		select t.id_user 
		from auth."token" t 
		where t.access_token = _access_token
	);
	_status = true;
	END;
$function$