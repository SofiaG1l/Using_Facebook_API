Using the Facebook Marketing API
================
Sofia Gil
May 20, 2019

-   [Requirements](#requirements)
-   [Retrieving Data](#retrieving-data)
    -   [1. Basic URL](#basic-url)
    -   [2. Retrieving in a Programmatic Way](#retrieving-in-a-programmatic-way)
    -   [3. Total Population broken down by age, gender and country](#total-population-broken-down-by-age-gender-and-country)
    -   [4. Total Population that match certain characteristics broken down by age, gender and country](#total-population-that-match-certain-characteristics-broken-down-by-age-gender-and-country)
-   [So Far, So Good?](#so-far-so-good)
    -   [Basic Demographic Information](#basic-demographic-information)
    -   [Specific Characteristics](#specific-characteristics)
    -   [The Solutions](#the-solutions)

**The aim of this course** is to give a quick overview on what it is and how to use the Facebook Marketing API. In this course you will learn how to query and retrieve aggregated data regarding different users' demographic characteristics.

Requirements
============

1.  Have a Facebook account
2.  Set up a Facebook Marketing App
3.  Obtain the Token and Creation Act of your Facebook Marketing App
4.  Install the next R packages:
    -   tidyverse
    -   jsonlite
    -   httr
5.  Knowledge of R

For the steps 1 to 3 you can check [**First\_Step.pdf**](https://github.com/SofiaG1l/Using_Facebook_API/blob/master/First_Step.pdf "First Step").

Retrieving Data
===============

Would you like to check more information about the Facebook Marketing API or about the JSON syntax? Then take a look on [**HandsOn.pdf**](https://github.com/SofiaG1l/Using_Facebook_API/blob/master/HandsOn.pdf "Hands On").

1. Basic URL
------------

First lets try using a browser:

``` r
https://graph.facebook.com/v3.2/act_<<creation_act>>/delivery_estimate?access_token=<<TOKEN>>&include_headers=false&method=get&pretty=0&suppress_http_code=1&method=get&optimization_goal=REACH&pretty=0&suppress_http_code=1&targeting_spec={"geo_locations":{"countries":["MX"]},"genders":[1] ,"age_min":16, "age_max":24}
```

2. Retrieving in a Programmatic Way
-----------------------------------

In order to retrieve and transform the data to a data frame we will use the packages **tidyverse** and **jsonlite**.

``` r
library(tidyverse)
library(jsonlite)
```

The way we will pass our credentials to Facebook is through the string that we will save in **Credentials**, so save your token into the variable *token* and your creation act into *act*:

``` r
token="Your Token"

act="Your Creation Act"
    
Credentials=paste0('https://graph.facebook.com/v3.2/act_',act,'/delivery_estimate?access_token=',token,'&include_headers=false&method=get&optimization_goal=REACH&pretty=0&suppress_http_code=1')
```

3. Total Population broken down by age, gender and country
----------------------------------------------------------

Let's set up our initial variables, they will be save in R and then we will concatenate them in a string.

``` r
Age1=25
Age2=55

g=1 # 1:men and 2:women

C='DE' # Country code
```

The parameters we will use are in a [JSON](https://www.w3schools.com/js/js_json_intro.asp "JSON") format, but we will handle them in R through a string:

-   age\_min: is a value
-   age\_max: is a value
-   genders: is an array
-   geo\_locations: is a JSON object where *country* is an array

``` r
query <- paste0(Credentials,'&targeting_spec={"age_min":',Age1,',"age_max":',Age2,',"genders":[',g,'],"geo_locations":{"countries":["',C,'"],"location_types":["home"]},"facebook_positions":["feed","instant_article","instream_video","marketplace"],"device_platforms":["mobile","desktop"],"publisher_platforms":["facebook","messenger"],"messenger_positions":["messenger_home"]}')


query_val<-url(query)%>%fromJSON

query_val$data['estimate_dau'][[1]]
query_val$data['estimate_mau'][[1]]
```

Since **age\_min** and **age\_max** are *JSON values* their input is always a single value, in this case a integer value between 16 and 65, where 65 means *65 and above*.

In the case of **genders**, it is an array, that means that it can receive more than one value, but the values must be the same type (integer, float, character, etc). So, if we want to query the number of women and men that use Facebook, we would have to set **genders** to \[1, 2\].

Finally, **geo\_locations** is a JSON object, therefore, it can contain all the JSON objects already described. In this case, we are specifying **countries** and **location\_types** and both are arrays.

You can find more information about these and other parameters [here](https://developers.facebook.com/docs/marketing-api/targeting-specs "Advanced Targeting and Placement").

### 3.1 Exercise

Change the parameters in the code in order to retrieve the next data:

*The number of women and men between 20 and 55 years old that live in Spain and Germany and are Facebook users.*


4. Total Population that match certain characteristics broken down by age, gender and country
---------------------------------------------------------------------------------------------

The first step is to know the name of all the possible variables that we can query. There are three different classes:

-   demographics
-   interests
-   behaviors

Let's retrieve all the *demographics* variables:

``` r
library(httr)

DF_CHARTICS<-GET(
  
            "https://graph.facebook.com/v3.2/search",
            
            query=list(
              
              type='adTargetingCategory',
              
              class='demographics',
              
              access_token=token,
              
              limit=2000
              
            )) %>%content(as="text")%>%fromJSON%>%.[[1]]
```

Now we will prepare a basic query, for this you just need to choose one variable and save the next information:

``` r
ROW=1

TYPE=DF_CHARTICS$type[ROW]
ID=DF_CHARTICS$id[ROW]
NAME=DF_CHARTICS$name[ROW]
```

For targeting populations that match specific characteristics we will use the parameter *flexible\_spec* from the Facebook Marketing API, this parameter is a JSON object. In order to incorporate it to our initial string, we will save the string in the variable **CHARTICS**.

``` r
CHARTICS<-paste0(',"flexible_spec":[{"',TYPE,'":[{"id":"',ID,'","name":"',NAME,'"}]}]')
```

A basic query including this parameter is:

``` r
query <- paste0(Credentials,'&targeting_spec={"age_min":',Age1,',"age_max":',Age2,',"genders":[',g,']',CHARTICS,',"geo_locations":{"countries":["',C,'"],"location_types":["home"]},"facebook_positions":["feed","instant_article","instream_video","marketplace"],"device_platforms":["mobile","desktop"],"publisher_platforms":["facebook","messenger"],"messenger_positions":["messenger_home"]}')


query_val<-url(query)%>%fromJSON

query_val$data['estimate_dau'][[1]]
query_val$data['estimate_mau'][[1]]
```

In the case of the specific characteristics, you can make the next type of queries:

-   *one characteristics **and** other*:

``` r
'"flexible_spec":[{"TYPE_1":[{"id":"ID_1","name":"NAME_1"}]},{"TYPE_2":[{"id":"ID_2","name":"NAME_2"}]}]'
```

-   *one characteristics **or** other*:

``` r
'"flexible_spec":[{"TYPE_1":[{"id":"ID_1","name":"NAME_1"}]}],"flexible_spec":[{"TYPE_2":[{"id":"ID_2","name":"NAME_2"}]}]'
```

### 4.1 Exercise 2

Code the next query: *The number of women between 50 and 60 years old that live in Mexico that are expats and parents and are Facebook users.*

### 4.1 Exercise 3

Code the next query: *The number of men between 50 and 60 years old that live in Mexico that are either expats or parents and are Facebook users.*

So Far, So Good?
================

Let's challenge your understanding on retrieving data. In the next steps you will recreate part of the code that was used for the paper [*Demographic Diferentials in Facebook Usage Around the World*](https://github.com/SofiaG1l/Demographic-Differentials-in-Facebook-Usage-Around-the-World "Demographic Diferentials in Facebook Usage Around the World"), but just for some of the countries in *Country\_Codes.csv*.

Basic Demographic Information
-----------------------------

1.  Upload *Country\_Codes.csv* into the R environment.
2.  Create a data frame where you will save all the information.
3.  Create a nest loop where you can change the next variables in your queries:
    -   Country: each country in *Country\_Codes.csv*.
    -   Age: 16-24, 25-54, 55-64
    -   Gender: female and male

If you already have the steps 1 to 3, then you will notice a problem. What problem are you encountering?

Specific Characteristics
------------------------

Now we are going to restrict the population to those that match specific characteristics:

-   Away from hometown
-   Close friend of users with birthdays in a month

The Solutions
-------------

You can find the complete code for replicating the [*Demographic Diferentials in Facebook Usage Around the World*](https://github.com/SofiaG1l/Demographic-Differentials-in-Facebook-Usage-Around-the-World "Demographic Diferentials in Facebook Usage Around the World") work from June 6th, 2019 onwards. (Yes, one day after the workshop!)
