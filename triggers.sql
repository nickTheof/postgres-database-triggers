create table audits(
    id serial primary key,
    username varchar(100) not null,
    event varchar(50) not null,
    command text not null,
    executed_at timestamp default current_timestamp
);



create table employees(
    id serial primary key,
    firstName varchar(100) not null,
    lastName varchar(100) not null,
    salary numeric(10,2) not null
);

create table archive_employees(
    employee_id int primary key,
    firstName varchar(100) not null,
    lastName varchar(100) not null,
    salary numeric(10,2) not null,
    deleted_at timestamp default current_timestamp
);

create table log_salary_changes(
    id serial primary key,
    employee_id int not null,
    firstName varchar(100) not null,
    lastName varchar(100) not null,
    oldSalary numeric(10,2) not null,
    changed_at timestamp default current_timestamp
);



create or replace function audit_command()
returns event_trigger
language plpgsql
as
$$
begin
    insert into audits(username, event, command)
    values (session_user, TG_EVENT, TG_TAG);
    end;
$$;


create event trigger audit_ddl_commands
on ddl_command_end
execute function audit_command();


create or replace function delete_employee_triger()
returns trigger
language plpgsql
as
$$
begin
    insert into archive_employees(employee_id, firstName, lastName, salary)
    values (OLD.id, OLD.firstName, OLD.lastName, OLD.salary);
    return OLD;
end;
$$;

create or replace trigger after_delete_employee
after delete on employees
for each row
execute function delete_employee_triger();


create or replace function log_sal_changes()
returns trigger
language plpgsql
as
$$
begin
    if NEW.salary > OLD.salary then 
        insert into log_salary_changes(employee_id, firstName, lastName, oldSalary)
        values (OLD.id, OLD.firstName, OLD.lastName, OLD.salary);
    else 
        raise exception 'New salary must be greater than the current salary';
    end if;
    return NEW;
end;
$$;

create or replace trigger log_sal_after_update
after update of salary on employees
for each row
execute function log_sal_changes();




-- Check the right implementation of the trigger

insert into employees(firstName, lastName, salary)
values ('Nickolas', 'Johnson', 2000);


insert into employees(firstName, lastName, salary)
values ('Nickolas', 'Theofanis', 2000);

select * from employees;

delete from employees
where id = 1;


SELECT * from archive_employees;
select * from employees;


drop table employees;
DROP TABLE log_salary_changes;
drop TABLE archive_employees;



update employees
set salary=2500
where id = 2;

update employees
set salary=2100
where id = 2;

SELECT * from log_salary_changes;

SELECT * FROM audits;




