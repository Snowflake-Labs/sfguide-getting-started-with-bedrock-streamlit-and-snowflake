use role ACCOUNTADMIN;
use database CUSTOMER_WRAPPED;

--create object with aws keys
CREATE OR REPLACE SECRET aws_keys
    TYPE = password
    USERNAME = '<AWS Access Key ID>'
    PASSWORD = '<AWS Secret Access Key>';

-- optional, if using a session_key - if so, remember that this credential will expire
CREATE OR REPLACE SECRET session_key
    TYPE = password
    USERNAME = 'session'
    PASSWORD = ''; -- if not using a session key, leave this blank and it won't be used later

--create network rule - select your AWS region here
create or replace network rule aws_network_rule
mode = EGRESS
type = HOST_PORT
value_list = ('bedrock-runtime.<AWS Region - e.g. us-west-2>.amazonaws.com');


--create external access integration
create or replace EXTERNAL ACCESS INTEGRATION aws_integration
allowed_network_rules = (aws_network_rule)
ALLOWED_AUTHENTICATION_SECRETS = (aws_keys, session_key)
enabled=true;

create or replace function ask_bedrock(llm_instructions string, user_context_prompt string, model string)
returns string
language python
runtime_version=3.8
handler = 'ask_bedrock'
external_access_integrations=(aws_integration)
SECRETS = ('aws_keys' = aws_keys, 'session_key' = session_key)
PACKAGES = ('boto3')
as
$$
import json
import boto3
import _snowflake

# Function to get AWS credentials
def get_aws_credentials():
    aws_key_object = _snowflake.get_username_password('aws_keys')
    session_key_object = _snowflake.get_username_password('session_key')
    region = 'us-west-2'

    boto3_session_args = {
        'aws_access_key_id': aws_key_object.username,
        'aws_secret_access_key': aws_key_object.password,
        'region_name': region
    }

    if session_key_object.password != '':
        boto3_session_args['aws_session_token'] = session_key_object.password

    return boto3_session_args, region

# Function to prepare the request body based on the model
def prepare_request_body(model_id, instructions, user_context):
    default_max_tokens = 512
    default_temperature = 0.7
    default_top_p = 1.0

    if model_id == 'amazon.titan-text-express-v1':
        body = {
            "inputText": f"<SYSTEM>Follow these:{instructions}<END_SYSTEM>\n<USER_CONTEXT>Use this user context in your response:{user_context}<END_USER_CONTEXT>",
            "textGenerationConfig": {
                "maxTokenCount": default_max_tokens,
                "stopSequences": [],
                "temperature": default_temperature,
                "topP": default_top_p
            }
        }
    elif model_id == 'ai21.j2-ultra-v1':
        body = {
            "prompt": f"<SYSTEM>Follow these:{instructions}<END_SYSTEM>\n<USER_CONTEXT>Use this user context in your response:{user_context}<END_USER_CONTEXT>",
            "temperature": default_temperature,
            "topP": default_top_p,
            "maxTokens": default_max_tokens
        }
    elif model_id == 'anthropic.claude-3-sonnet-20240229-v1:0':
        body = {
            "max_tokens": default_max_tokens,
            "messages": [{"role": "user", "content": f"<SYSTEM>Follow these:{instructions}<END_SYSTEM>\n<USER_CONTEXT>Use this user context in your response:{user_context}<END_USER_CONTEXT>"}],
            "anthropic_version": "bedrock-2023-05-31"
                }
    else:
        raise ValueError("Unsupported model ID")

    return json.dumps(body)

# parse API response format from different model families in Bedrock
def get_completion_from_response(response_body, model_id):
    if model_id == 'amazon.titan-text-express-v1':
        output_text = response_body.get('results')[0].get('outputText')
    elif model_id == 'ai21.j2-ultra-v1':
        output_text = response_body.get('completions')[0].get('data').get('text')
    elif model_id == 'anthropic.claude-3-sonnet-20240229-v1:0':
        output_text = response_body.get('content')[0].get('text')
    else:
        raise ValueError("Unsupported model ID")
    return output_text

# Main function to call bedrock
def ask_bedrock(instructions, user_context, model):
    boto3_session_args, region = get_aws_credentials()

    # Create a session using the provided credentials
    session = boto3.Session(**boto3_session_args)

    # Create a bedrock client from session
    client = session.client('bedrock-runtime', region_name=region)

    # Prepare the request body based on the model
    body = prepare_request_body(model, instructions, user_context)

    response = client.invoke_model(modelId=model, body=body)
    response_body = json.loads(response.get('body').read())

    output_text = get_completion_from_response(response_body, model)
    return output_text
$$;


SET DEFAULT_LLM_INSTRUCTIONS = 'Review the customer\'s most frequent retail purchases from last year. Write a personalized email explaining their shopper profile based on these habits. Add a tailored message suggesting products and brands for them to consider, from their purchase history.';
SET DEFAULT_MODEL = 'anthropic.claude-3-sonnet-20240229-v1:0';

select ask_bedrock($DEFAULT_LLM_INSTRUCTIONS, 'Home Decor, Furniture, Lighting', $DEFAULT_MODEL);
--select ask_bedrock($DEFAULT_LLM_INSTRUCTIONS, PRODUCTS_PURCHASED, $DEFAULT_MODEL) from CUSTOMER_WRAPPED.public.customer_wrapped;