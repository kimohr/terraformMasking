*italic* indicates values that need to be changed/modified depending on naming convention, roles and users the organization creates

# 1. CREATING A ROLE WITH THE FUNCTION MASKING ADMIN 
// Create a user
create or replace user *masking_user* password='*********' must_change_password=false; //Creating the user if this does not exsist, setting a password
// Create a role with masking rights
create role if not exists *masking_admin*; // Creating the masking_admin role
// Grant masking role to user
grant role *masking_admin* to user *masking_user*; // Granting the role of masking_admin to the user who will create the masking policies (masking_user)

// Grant priveleges to masking role
grant all privileges on database *testDB* to role *masking_admin*; // Granting access to database
grant all privileges on warehouse *testWH* to role *masking_admin*; // Granting access to warehouse
grant all on all schemas in database *testDB* to role *masking_admin*; // Granting access to schemas
grant all on all tables in database *testDB* to role *masking_admin*; // Granting access to tables in schemas

// Grant masking rights to masking role
grant apply masking policy on account to role *masking_admin*; // Granting the right to apply masking policies to the role masking_admin
grant create masking policy on schema *masking_schema* to role *masking_admin*; // Granting the right to create masking policies on the schema "masking_schema"


# 2. CREATING AND ASSIGNING ROLES 
## User #1 ANALYST 
create or replace user *ANALYST* Password='************' MUST_CHANGE_PASSWORD = false; //Creating the user if this does not exsist, setting a password
create or replace Role *role_anlst*; // Creating the role_anlst role
grant role *role_anlst* to User *ANALYS*T; // Granting the role of role_anlst to the user ANALYST
grant all privileges on DATABASE* testDB* to role *role_anlst*; // Granting access to database
grant all privileges on warehouse *testWH* to role *role_anlst*; // Granting access to warehouse
grant all on all schemas in database *testDB* to role *role_anlst*; // Granting access to schemas
grant all on all tables in database *testDB* to role *role_anlst*; // Granting access to tables in schemas

## User#2 REPORTER
create or replace user *REPORTER* Password='**********' MUST_CHANGE_PASSWORD = false; //Creating the user if this does not exsist, setting a password
create or replace Role *role_rptr*; // Creating the role_rptr role
grant role *role_rptr* to User *REPORTER*; // Granting the role of role_rptr to the user REPORTER
grant all privileges on DATABASE *testDB* to role *role_rptr*; // Granting access to database
grant all privileges on warehouse *testWH* to role *role_rptr*; // Granting access to warehouse
grant all on all schemas in database *testDB* to role *role_rptr*; // Granting access to schemas
grant all on all tables in database *testDB* to role *role_rptr*; // Granting access to tables in schemas



# 3. CREATING AND APPLYING MASKING POLICIES 
// Masking the Name column with the masking policy "name_plcy"
create or replace masking policy *masking_schema*.*name_plcy* as (name string) returns string ->
    case when current_role() in ('*MASKING_ADMIN*') then name
    else '**Name masked**'
end;
// If the user has the role "masking_admin" they can see names, if not they will see "**Name masked**"

// Masking the Business_ID column with the masking policy "businessID_plcy"
create or replace masking policy *masking_schema*.*businessID_plcy* as (business_id string) returns string ->
    case when current_role() in ('*MASKING_ADMIN*') then business_id
    when current_role() in ('*role_anlst*') then regexp_replace(business_id, substring(business_id, 1, 17), 'xxxx-')
    when current_role() in ('*role_rptr*') then regexp_replace(business_id, substring(business_id, 1, 19), 'xxxx-')
    else '**Business ID masked**'
end;
// If the user has the role "masking_admin" they will see all
// If the user has the role "role_anlst" they will not see the first 17 letters, only the last 5
// If the user has the role "role_rptr" they will not see the first 19 letters, only the last 3

// Alter table with masking policie for name
alter table *masking_schema*.*testFile* modify column name set masking policy *masking_schema*.*name_plcy*;
// Alter table with masking policie for businessID
alter table *masking_schema*.*testFile* modify column business_id set masking policy *masking_schema*.*businessID_plcy*;