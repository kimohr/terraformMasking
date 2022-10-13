terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"
      version = "0.47.0"
    }
  }
}

provider "snowflake" {
  // required
  username = "kkmohr"
  account  = "yv11672"
  region   = "west-europe.azure"

  // optional, at exactly one must be set
  password               = "o2ZP^e%szdWkx!"

  // optional
  role = "ACCOUNTADMIN"
}

resource "snowflake_database" "simple" {
  name                        = "testDB"
  comment                     = "test comment"
  data_retention_time_in_days = 1
}

resource snowflake_role role {
  name    = "mask_adm"
  comment = "Role for masking adming"
}

resource snowflake_role role1 {
  name    = "user_role"
  comment = "Role for testing masking"
}

resource snowflake_warehouse w {
  name           = "testWH"
  comment        = "foo"
  warehouse_size = "small"
}


resource snowflake_user user {
  name         = "user1"
  login_name   = "user1"
  comment      = "A user of snowflake."
  password     = "slkj%45"
  disabled     = false
  display_name = "Snowflake User1"
  email        = "kristine.mohr@capgemini.com"
  first_name   = "User"
  last_name    = "One"

  default_warehouse = "testWH"
  default_secondary_roles = ["ALL"]
  default_role      = "user_role"

  must_change_password = false
}

resource "snowflake_schema" "test" {
  database            = snowflake_database.simple.name
  name                = "testSCH"
  data_retention_days = snowflake_database.simple.data_retention_time_in_days
}

resource "snowflake_tag" "this" {
  name     = upper("test_tag")
  database = snowflake_database.simple.name
  schema   = snowflake_schema.test.name
}

resource "snowflake_masking_policy" "example_masking_policy" {
  name               = "EXAMPLE_MASKING_POLICY"
  database           = snowflake_database.simple.name
  schema             = snowflake_schema.test.name
  value_data_type    = "string"
  masking_expression = "case when current_role() in ('ACCOUNTADMIN') then val else sha2(val, 512) end"
  return_data_type   = "string"
}

resource "snowflake_tag_masking_policy_association" "name" {
  tag_id                  = snowflake_tag.this.id
  masking_policy_id       = snowflake_masking_policy.example_masking_policy.id
}

resource snowflake_user_grant grant {
  user_name = "user1"
  privilege = "SELECT"

  roles = [
    "mask_adm",
  ]

  with_grant_option = true
}
