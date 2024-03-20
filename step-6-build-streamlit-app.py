# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session

# Get the current credentials
session = get_active_session()

# my_table = session.table()

# Write directly to the app - purely cosmetic headers
st.title("Very Basic Bedrock Agent")
st.caption("The quickest of examples. :snowflake:")

default_prompt = 'Review the customers most frequent retail purchases from last year. Write a personalized email explaining their shopper profile based on these habits. Add a tailored message suggesting products and brands for them to consider, from their purchase history.'

with st.expander("Adjust system prompt"):
    system = st.text_area("System instructions", value=default_prompt).replace("'","")

st.markdown('------') 
bedrock_model = st.selectbox(
     'Select Bedrock model',
     ('amazon.titan-text-express-v1', 'ai21.j2-ultra-v1', 'anthropic.claude-3-sonnet-20240229-v1:0'))

# A field to enter an example prompt
user_context = st.text_area('Product categories and other user context'
                    , height=100
                    , value='Product categories: Home Decor, Furniture, Lighting\nCustomer name: Obinze Agarwal\nStore name: Nilezone Bedshop').replace("'","")

#Use the job description to write the job to a table and run the function against it:
if(st.button('Ask Bedrock')):
    result = session.sql(f"""SELECT ask_bedrock('{system}','{user_context}', '{bedrock_model}')""").collect()
    st.header('Answer')
    st.write(result[0][0].replace('"','')) 