
## This code was written for the Pre-Workshop of the IUSSP Research workshop on Digital Demography in the Era 
## of Big Data by Sofia Gil-Clavel. 05.06.2019. 
## You can check the Markdown format of this code and more information in 
## https://github.com/SofiaG1l/Using_Facebook_API

#### 1. Basic URL ####
# 
# First lets try using a browser, replace your data in the next URL:

# https://graph.facebook.com/<<vX.X>>/act_<<ACT>>/delivery_estimate?access_token=<<TOKEN>>&include_headers=false&method=get&pretty=0&suppress_http_code=1&method=get&optimization_goal=REACH&pretty=0&suppress_http_code=1&targeting_spec={"geo_locations":{"countries":["MX"]},"genders":[1] ,"age_min":16, "age_max":24}


#### 2. Retrieving in a Programmatic Way ####
# 
# In order to retrieve and transform the data to a data frame we will use the packages **tidyverse** and **jsonlite**.

# Cleaning the enviroment
rm(list = ls())
gc()

# Opening packages
library(tidyverse)
library(jsonlite)

# The way we will pass our credentials to Facebook is through the string that we will save in **Credentials**, so save 
# your token into the variable *token* and your creation act into *act*:

token="Token"

act="Creation Act"

version="vX.X" # replace the X with your values

Credentials=paste0('https://graph.facebook.com/',version,'/act_',act,'/delivery_estimate?access_token=',token,'&include_headers=false&method=get&optimization_goal=REACH&pretty=0&suppress_http_code=1')

#### 3. Total Population broken down by age, gender and country ####
# 
# Let's set up our initial variables, they will be save in R and then we will concatenate them in a string.

Age1=25
Age2=55

g=1 # 1:men and 2:women

C='"DE"' # Country code

# The parameters we will use are in a JSON(https://www.w3schools.com/js/js_json_intro.asp) format, but we will handle 
# them in R through a string:
#   
# * age_min: is a value
# * age_max: is a value
# * genders: is an array
# * geo_locations: is a JSON object where *country* is an array

query <- paste0(Credentials,'&
                targeting_spec={
                "age_min":',Age1,',
                "age_max":',Age2,',
                "genders":[',g,'],
                "geo_locations":{"countries":[',C,'],"location_types":["home"]},
                "facebook_positions":["feed","instant_article","instream_video","marketplace"],
                "device_platforms":["mobile","desktop"],
                "publisher_platforms":["facebook","messenger"],
                "messenger_positions":["messenger_home"]}')


(query_val<-url(query)%>%fromJSON)


# Since **age_min** and **age_max** are *JSON values* their input is always a single value, 
# in this case an integer value between 16 and 65, where 65 means *65 and over*.
# 
# In the case of **genders**, it is an array, that means that it can receive more than one value, 
# but the values must be the same type (integer, float, character, etc). So, if we want to query the 
# number of either women or men that use Facebook, we would have to set **genders** to $[1,2]$.
# 
# Finally, **geo_locations** is a JSON object, therefore, it can contain all the JSON objects already 
# described. In this case, we are specifying **countries** and **location_types** and both are arrays.
# 
# You can find more information about these and other parameters in 
# https://developers.facebook.com/docs/marketing-api/targeting-specs.


#### 3.1 Exercise 1 ####

# Change the parameters in the code in order to retrieve the next data:
# *The number of women and men between 20 and 55 years old that live in Spain and Germany and are Facebook users.*

#### Your code
# 
# 
# 
# 
# 
# 
# 

#### 4. Total Population that match certain characteristics broken down by age, gender and country ####

# The first step is to know the name of all the possible variables that we can query. There are three 
# different classes:
# * demographics
# * interests
# * behaviors

# Let's retrieve all the *demographics* variables: 

library(httr)

DF_CHARTICS<-GET(
  
  "https://graph.facebook.com/v3.2/search",
  
  query=list(
    
    type='adTargetingCategory',
    
    class='demographics',
    
    access_token=token,
    
    limit=2000
    
  )) %>%content(as="text")%>%fromJSON%>%.[[1]]

View(DF_CHARTICS)

# Now we will prepare a basic query, for this you just need to choose one variable and save the next information:

ROW=1

(TYPE=DF_CHARTICS$type[ROW])
(ID=DF_CHARTICS$id[ROW])
(NAME=DF_CHARTICS$name[ROW])

# For targeting populations that match specific characteristics we will use the parameter *flexible_spec* from 
# the Facebook Marketing API, this parameter is a JSON object. In order to incorporate it to our initial string, 
# we will save the string in the variable **CHARTICS**.

CHARTICS<-paste0(',"flexible_spec":[{"',TYPE,'":[{"id":"',ID,'","name":"',NAME,'"}]}]')

# A basic query including this parameter is:

query <- paste0(Credentials,'&
                targeting_spec={"age_min":',Age1,',
                "age_max":',Age2,',
                "genders":[',g,']',
                CHARTICS,',
                "geo_locations":{"countries":[',C,'],"location_types":["home"]},
                "facebook_positions":["feed","instant_article","instream_video","marketplace"],
                "device_platforms":["mobile","desktop"],
                "publisher_platforms":["facebook","messenger"],
                "messenger_positions":["messenger_home"]}')


(query_val<-url(query)%>%fromJSON)


# In the case of the specific characteristics, you can make the next type of queries: 

### * *one characteristics **and** other*:

  '"flexible_spec":[{
      "TYPE_1":[{"id":"ID_1","name":"NAME_1"}]
    },
    {
      "TYPE_2":[{"id":"ID_2","name":"NAME_2"}]
  }]'

### * *one characteristics **or** other*:
  
  '"flexible_spec":[{
    "TYPE_1":[{"id":"ID_1","name":"NAME_1"}],
    "TYPE_2":[{"id":"ID_2","name":"NAME_2"}]
  }]'

# In the case of OR we need to group by TYPE. Check the next example:
# *People that are travelers **OR** like soccer **OR** movies.*
  
  '"flexible_spec": [{ 
    "behaviors": [
      {"id":6002714895372,"name":"All travelers"}
    ], 
    "interests": [ 
      {"id":6003107902433,"name":"Association football (Soccer)"}, 
      {"id":6003139266461,"name":"Movies"} 
    ] 
  }]'

# More info here: https://developers.facebook.com/docs/marketing-api/targeting-specs#broadcategories

#### 4.1 Exercise 2 ####

# Code the next query:
#   *The number of women between 50 and 60 years old that live in Spain that 
#    are "Away from hometown" and "Close friends of people with birthdays in a month" and are Facebook users.*

#### Your code:
# 
# 
# 
# 
# 

#### 4.1 Exercise 3 ####

# Code the next query:
#   *The number of women between 50 and 60 years old that live in Spain that 
#    are either "Away from hometown" or "Close friends of people with birthdays in a month" and are Facebook users.*

#### Your code:
# 
# 
# 
# 
# 
  

#### So Far, So Good? ####
   
# Let's challenge your understanding on retrieving data. In the next steps you will recreate part of the code that was 
# used for the paper Demographic Diferentials in Facebook Usage Around the World, but just for some of the countries 
# in Country_Codes.csv.


#### **Exercise: Basic Demographic Information** ####
#
# 1. Upload Country_Codes.csv into the R environment.
# 2. Create a data frame where you will save all the information.
# 3. Create a nest loop where you can change the next variables in your queries:
#     Country: each country in Country_Codes.csv.
#     Age: 16-24, 25-54, 55-64
#     Gender: female and male
# 
#### Your code:
# 
# 
# 
# 
#  
# If you already have the steps 1 to 3, then you will notice a problem. What problem are you encountering?


#### **Exercise: Specific Characteristics** ####
# 
# Now we are going to restrict the population to those that match specific characteristics:
#   Away from hometown
#   Close friend of users with birthdays in a month
#
#### Your code:
# 
# 
# 
# 
# 

# **The Solutions**
# 
# You can find the complete code for replicating the Demographic Diferentials in Facebook Usage Around the 
# World work from June 6th, 2019 onwards. (Yes, one day after the workshop!)
# 














  