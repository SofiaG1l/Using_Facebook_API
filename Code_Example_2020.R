# Downloading Facebook aggregate data, version November, 2020
# loading packages
library(tidyverse)
library(jsonlite)
library(httr)




#### Credentials
### After following "Requirements" of the ReadMe file, input token, act and version here.
## Replace each x with your value. As of 11/2020, the version is ""v8.0", but will change
token="x"
act="x"
version="x"
Credentials=paste0('https://graph.facebook.com/',version,'/act_',act,'/delivery_estimate?access_token=',token,'&include_headers=false&method=get&optimization_goal=REACH&pretty=0&suppress_http_code=1')




#### Example 1: 18-24 year olds, Male, in Germany
# setting up initial variables, save in r then in string
Age1 = 18 # The youngest age to be included
Age2 = 24 # The oldest age to be included
g=1 # The gender to be included. Men (1), women (2)
C = '"DE"' # Country code - list of country codes available here: https://medium.com/@felixlehmann_74058/facebook-ad-country-code-list-14bb131bd01d

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

(query_val<-url(query)%>%fromJSON) # this file contains all the information we need

# Tidying the query into a tibble
query_val <- query_val %>%  
  map_df(bind_rows) # To bind the rows, form simple sable
query_val <- query_val %>%
  select(-daily_outcomes_curve, -estimate_ready)  # remove unnecessary rows
query_val <- query_val %>%
  rename(Monthly=estimate_dau, Daily=estimate_mau) # rename rows




#### Gathering different types of variables: demographics, interests, behaviours
DF_CHARTICS<-GET(
  "https://graph.facebook.com/v8.0/search",
  query=list(
    type='adTargetingCategory',
    class='demographics', 
    access_token=token,
    limit=2000
  )) %>% content(as="text")%>%fromJSON%>%.[[1]]

INT_CHARTICS<-GET(
  "https://graph.facebook.com/v8.0/search",
  query=list(
    type='adTargetingCategory',
    class='interests',
    access_token=token,
    limit=2000
  )) %>%content(as="text")%>%fromJSON%>%.[[1]]

BE_CHARTICS<-GET(
  "https://graph.facebook.com/v8.0/search",
  query=list(
    type='adTargetingCategory',
    class='behaviors',
    access_token=token,
    limit=2000
  )) %>%content(as="text")%>%fromJSON%>%.[[1]]

# To view the variables available
View(DF_CHARTICS) 
View(INT_CHARTICS)
View(BE_CHARTICS)




#### Example 2: 13+ years old, 28 European countries, living abroad, women
### Select the characteristic of interest
ROW=60 # in this case, row 60 is "Lives abroad"
(TYPE=BE_CHARTICS$type[ROW])
(ID=BE_CHARTICS$id[ROW])
(NAME=BE_CHARTICS$name[ROW])
CHARTICS<-paste0(',"flexible_spec":[{"',TYPE,'":[{"id":"',ID,'","name":"',NAME,'"}]}]')


## The same process as Example 1
Age1 = 13 # The first age you want
Age2 = 65 # The last age you want. Here, 65 is open ended, meaining 65+
g = 2 # 1:men and 2: women


## Country codes chosen for data download
my_countries <- c('"AT"', '"BE"', '"BG"', '"HR"', '"CZ"',
                  '"DK"', '"EE"','"FI"','"FR"','"DE"','"GR"','"HU"','"IE"','"IT"','"LV"','"LT"','"LU"',
                  '"MT"','"NL"','"PL"', '"PT"', '"RO"', '"SK"', '"SI"', '"ES"', '"SE"', '"GB"')


## Lappy function with ",x," allowing for multiple countries to be collected. Also possible with ages, gender, characteristics
query_val_EU_Original <- sapply(X=my_countries, FUN=function(x){
  
  x <<- x
  ifelse(x=='AT', stop("THIS IS AT"), NA)
  
  query_EU <- paste0(Credentials,'&
                targeting_spec={
                "age_min":',Age1,',
                "age_max":',Age2,',
                "genders":[',g,']',
                  CHARTICS,',
                "geo_locations":{"countries":[',x,'],"location_types":["home"]},
                "facebook_positions":["feed","instant_article","instream_video","marketplace"],
                "device_platforms":["mobile","desktop"],
                "publisher_platforms":["facebook","messenger"],
                "messenger_positions":["messenger_home"]}')
  
  return(url(query_EU)%>%fromJSON)

}, simplify = F, USE.NAMES = T)


query_val_EU <- query_val_EU_Original %>%
  map("data") %>% # converts the data into a data frame
  map_df(bind_rows, .id = "Country") %>% # binds the rows by country
  select(-daily_outcomes_curve, -estimate_ready) %>% # removes unnecessary columns
  rename(Daily_LivesAbroad=estimate_dau, Monthly_LivesAbroad=estimate_mau) %>%
  arrange(Country)

# Removing quotation marks from the downloaded Facebook data to enable a merge with later mapping data
query_val_EU$Country <- gsub("\"", "", query_val_EU$Country)




#### Mapping & tidying the EU28 data
library(sf) # to crop the map file
library(rnaturalearth) # for map download
library(rnaturalearthdata) # for map download
library(readr)  # for read_csv



### Downloading mapping boundaries and tidying data
worldmap <- ne_countries(scale = 'medium', type = 'countries',
                         returnclass = 'sf')

worldmap <- worldmap %>% 
  select(-scalerank:-labelrank, -sov_a3:-homepart) # removing unnecessary columns

worldmap$sovereignt[worldmap$sovereignt  == "Czech Republic"]  <-  "Czechia" # renaming Czechia


## Downloading and merging country lookup
Country_Lookup <- read_csv("https://raw.githubusercontent.com/SofiaG1l/Using_Facebook_API/master/Country_Codes.csv") %>%   # found in the GitHub directory
  rename(Country='alpha-2') %>% # renaming for clarity
  select(-'alpha-3':-'sub-region') # removing unnecessary columns
Country_Lookup$NAME[Country_Lookup$NAME  == "United Kingdom of Great Britain and Northern Ireland"] <- "United Kingdom"

## Merging all three files together to create spatial data frame
EU_Poly_Data_World <- merge(worldmap, Country_Lookup, by.x = "sovereignt", by.y = "NAME", all.x=TRUE)
EU_Poly_Data_World <- merge(EU_Poly_Data_World, query_val_EU, by.x = "Country", by.y = "Country", all.x=TRUE)


### Cropping the data, as we only want to map Europe right now
EU_Poly_Data_Europe <- st_crop(EU_Poly_Data_World, xmin = -20, xmax = 45,
                          ymin = 30, ymax = 73)



#### Mapping example
library(scales) # to have comma in the legend
library(viridis) # for the colour scheme

Example_2_Map <- ggplot(EU_Poly_Data_Europe) +
  geom_sf(size = 0.1, aes(fill=Monthly_LivesAbroad), colour = "lightgrey") +
  scale_color_viridis("",
                      na.value = "NA",
                      guide = "colourbar",
                      aesthetics = "fill",
                      label=comma) +
  theme(text = element_text(size = 8),
        plot.title = element_text(size = 11, face = "bold"),
        legend.position = c(0.88, 0.5),
        legend.key = element_rect(fill = "white"),
        panel.background = element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank())+
  labs(title=paste("Population of men aged 13+ who are migrants",sep=""),
       subtitle='Collected 02/11/2020 \nData: Facebook API') 
Example_2_Map