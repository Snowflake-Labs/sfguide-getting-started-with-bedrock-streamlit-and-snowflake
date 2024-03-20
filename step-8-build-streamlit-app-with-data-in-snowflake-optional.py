# Import python packages
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.functions import array_agg

# Get the current credentials
session = get_active_session()

# access underlying snowflake tables
purchases_df = session.table("customer_purchases")
products_df = session.table("products")
categories_df = session.table("product_category")

# join all tables together
# join the purchases_df, products_df and the categories_df into one dataframe
purchases_products_categories_df = # ADD YOUR CODE HERE

# aggregate products by customer
# with the purchases_products_categories_df dataframe aggregate the products by customer to create a new dataframe
# hint you will likely use the array_agg() function from snowpark
purchases_products_df = # ADD YOUR CODE HERE

# aggregate product categories by customer
# with the purchases_products_categories_df dataframe aggregate the product categories by customer to create a new dataframe
# hint you will likely use the array_agg() function from snowpark
purchases_categories_df = # ADD YOUR CODE HERE

# Add some cosmetic headers
st.title("Bedrock Shopper")
st.caption("You could add some more context here if you wanted to share this with business users. :snowflake:")

default_prompt = 'Review the customers most frequent retail purchases from last year. Write a personalized email explaining their shopper profile based on these habits. Add a tailored message suggesting products and brands for them to consider, from their purchase history.'

st.markdown('------') 
with st.expander("Adjust system prompt"):
    system = st.text_area("System instructions", value=default_prompt).replace("'","")

st.markdown('------') 
bedrock_model = st.selectbox(
     'Select Bedrock model',
     ('amazon.titan-text-express-v1', 'ai21.j2-ultra-v1', 'anthropic.claude-3-sonnet-20240229-v1:0'))

# widget for customer filter
option = st.selectbox(
    'Select a Customer ID',
     purchases_products_df['CUSTOMER_ID'])

# filter down to relevant products and categories
# products
filtered_products_df = purchases_products_df.loc[purchases_products_df['CUSTOMER_ID'] == option]['PRODUCT_ARRAY'].iloc[0]
# categories
filtered_categories_df = # ADD YOUR CODE HERE

# display products and categories
st.subheader("Products Purchased")
filtered_products_df
st.subheader("Categories Purchased")
filtered_categories_df

user_context = f"Products purchased: {filtered_products_df}, Product Categories: {filtered_categories_df}"

# Use the job description to write the job to a table and run the function against it:
# Use the job description to write the job to a table and run the function against it:
# Use the job description to write the job to a table and run the function against it:
if(st.button('Ask Bedrock')):
    result = session.sql(f"""SELECT ask_bedrock('{system}','{user_context}','{bedrock_model}')""").collect()
    st.header('Answer')
    st.write(result[0][0].replace('"','')) 