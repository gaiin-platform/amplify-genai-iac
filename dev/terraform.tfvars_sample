# terraform.tfvars

# Load Balancer Vars
public_subnet_cidrs     = ["172.1.0.0/23", "172.1.2.0/23"]
private_subnet_cidrs    = ["172.1.4.0/23", "172.1.8.0/23"]
vpc_cidr                = "172.1.0.0/16"
vpc_name                = "main-vpc"
alb_name                = "amplifygenai-alb" #Name for Application Load Balancer amplifygenai-alb 
domain_name             = "" #Root of domain for application. Will be pre-pended with Environment by locals.tf
app_route53_zone_id     = "" #Route53 Hosted Zone ID of delegated Subdomain for Application
target_group_port       = 3000
target_group_name       = "amplifygenai-tg"
alb_security_group_name = "amplifygenai-sg"
root_redirect           = false #set to true if redirecting to "www"
alb_logging_bucket_name = "amplifygenai-alb-access-logs"

#cognito vars
cognito_domain          = "" #Example auth.yourdomain.com will be pre-pended with Environment by locals.tf (i.e. dev-auth.yourdomain.com)
cognito_route53_zone_id = "" ##Route53 Hosted Zone ID of delegated Subdomain for Authentication (Can be the same as Route53 app_route53_zone_id above)
userpool_name          = "AmplifyGenAI-UserPool"
provider_name          = "AmplifyGenAI"
sp_metadata_url        = "" #service provider metadata url for your SAML SSO
callback_urls          = [""] #DO NOT CHANGE CALLBACK URLS
logout_urls            = [""] #DO NOT CHANGE LOGOUT URLS
create_pre_auth_lambda = false #set to true if using pre-auth lambda
use_saml_idp           = false #set to true if using federated SAML
disable_public_signup  = true #set to false for demo/testing using Cognito-based authentication


# Variables with defaults don't need to be specified unless you want to override the default


#ECR Vars
ecr_repo_name        = "amplifygenai-repo"
image_tag_mutability = "IMMUTABLE"
scan_on_push         = false

#ECS Vars
desired_count                    = 1
cluster_name                     = "amplifygenai-cluster"
service_name                     = "amplifygenai-service"
container_port                   = 3000
max_capacity                     = 5
min_capacity                     = 1
scale_target_value               = 75
scale_in_cooldown                = 300
scale_out_cooldown               = 300
cloudwatch_log_group_name        = "amplifygenai-loggroup"
cloudwatch_policy_name           = "amplifygenai-cloudwatch-policy"
cloudwatch_log_stream_prefix     = "ecs"
secret_access_policy_name        = "amplifygenai-secret-access-policy"
ecs_alarm_email                  = "" #email addresss for SNS Topic on Scaling
ecs_scale_down_alarm_description = "scaling up due to high CPU utilization"
ecs_scale_up_alarm_description   = "scaling down due to low CPU utilization"

#Task Definition Vars
container_cpu            = 1024
container_memory         = 4096
task_name                = "gen-ai-app-task"
task_execution_role_name = "gen-ai-app-task-execution-role"
task_role_name           = "gen-ai-app-task-role"
region                   = "us-east-1"
container_name           = "amplifyApp" #dont change this container name

# Secrets Manager 
openai_api_key_name = "openai-api-key" #Do not Change
openai_endpoints_name = "openai-endpoints" #Do not Change
secret_name = "amplify-app-secrets" #Do not Change
secrets = {
  COGNITO_CLIENT_SECRET = ""
  OPENAI_API_KEY        = ""
  NEXTAUTH_SECRET       = ""
}


envs_name = "amplify-app-vars" #Do not Change

envs = {
  API_BASE_URL                = "https://<REPLACE_WITH_VALUE_FROM_BACKEND>"
  ASSISTANTS_API_BASE         = "https://<REPLACE_WITH_VALUE_FROM_BACKEND>"
  AVAILABLE_MODELS            = "anthropic.claude-3-sonnet-20240229-v1:0,anthropic.claude-3-haiku-20240307-v1:0,gpt-35-turbo,gpt-4-1106-Preview"
  AZURE_API_NAME              = "openai"
  AZURE_DEPLOYMENT_ID         = "gpt-4"
  CHAT_ENDPOINT               = "https://<REPLACE_WITH_VALUE_FROM_BACKEND>"
  COGNITO_CLIENT_ID           = ""
  COGNITO_DOMAIN              = "https://<REPLACE_WITH_VALUE_FROM_BACKEND>"
  COGNITO_ISSUER              = "https://<REPLACE_WITH_VALUE_FROM_BACKEND>"
  DEFAULT_MODEL               = "anthropic.claude-3-haiku-20240307-v1:0"
  DEFAULT_FUNCTION_CALL_MODEL = "gpt-4-1106-Preview" # Deprecated
  MIXPANEL_TOKEN              = ""
  NEXTAUTH_SECRET             = ""
  NEXTAUTH_URL                = "https://<REPLACE_WITH_APP_DOMAIN_NAME>"
  OPENAI_API_HOST             = "https://api.openai.com"
  OPENAI_API_TYPE             = "azure"
  OPENAI_API_VERSION          = "2024-02-15-preview"
}
