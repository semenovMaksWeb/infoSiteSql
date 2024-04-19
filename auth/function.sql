-- select * from auth.user_check_validate('test', 1)
-- select * from auth.user_check_authorization('test4', 'password');
-- select * from auth.user_check_id(11)
-- select  * from auth.register('test', 'test1', 'test2', 'test4', 'password')
-- select * from auth.token_delete_user_id(1)
-- select * from auth.banned_user(1);


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