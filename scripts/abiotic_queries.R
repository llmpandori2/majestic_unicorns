#################################################
# title: noaa abiotic and tidal data queries
# purpose: get abiotic data, tidy for use in data analysis
# author: lp
# created: 12/15/21
# last edited: 5/15/21
##################################################

##### packages #####

library(janitor) # clean up data
library(rnoaa) # buoy data/weather data
library(lubridate) # dates/times
library(tidyverse) # always

##### sio pier water temp data #####
# station website
# https://www.ndbc.noaa.gov/station_page.php?station=ljac1

# pull data 1990 - 2021
years <- c(2005:2022)

for(i in 1:length(years)) {
lj <- buoy(buoyid = 'LJAC1', dataset = 'stdmet', year = years[i])$data
write_csv(lj, paste('./data/abiotic/sio_pier/pier', years[i], '.csv', sep = ''))
}

remove(years, lj)

# assemble data
pier_data <- list.files(path = './data/abiotic/sio_pier/',
                        pattern = '*.csv') %>%
  map(~ read_csv(file.path('./data/abiotic/sio_pier/', .))) %>%
  reduce(rbind)

# tidy
pier_data <- pier_data %>%
  # remove columnns with all NAs
  remove_empty(which = c('cols')) %>%
  # make all col names snake case
  clean_names() %>%
  # rename time column
  rename(dtime = time,
         sio_air_temp = air_temperature,
         sio_sst = sea_surface_temperature) %>%
  select(dtime, sio_sst, sio_air_temp)
  

# write csv
write_csv(pier_data, './data/abiotic/sio_pier_assembled.csv')

##### sd bay tide data (obs + predictions) #####
# station website
# https://www.ndbc.noaa.gov/station_history.php?station=sdbc1

# data pulled from site below - not available on rnoaa b/c data not qa/qc'ed
# https://tidesandcurrents.noaa.gov/waterlevels.html?id=9410170&units=standard&bdate=20190101&edate=20191231&timezone=GMT&datum=MLLW&interval=h&action=data

tide_data <- list.files(path = './data/abiotic/sd_tide/',
                        pattern = '*.csv') %>%
  map(~ read_csv(file.path('./data/abiotic/sd_tide/', .))) %>%
  reduce(rbind)

tide_data <- tide_data %>%
  clean_names() %>%
  select(-preliminary_ft) %>%
  # change time zone from gmt to pst to match temp data
  mutate(dtime = with_tz(force_tz(as_datetime(paste(date, time_gmt)), 
                             tzone = 'UTC'), tzone = 'US/Pacific')) %>%
  select(dtime, predicted_ft, verified_ft) %>%
  # convert from ft to m in tide height
  mutate(tide_predict_m = predicted_ft/3.2808399,
         tide_verified_m = verified_ft/3.2808399) %>%
  select(-predicted_ft, -verified_ft) 

write_csv(tide_data, './data/abiotic/sd_bay_tides_assembled.csv')

##### CABR Zone 1 Temp Logger (air + water temp) #####
# TidbiT deployed in Zone 1 at CABR since July
# Data are in PST (GMT -8)

tidbit <- read_csv('data/abiotic/cabr_tidbit/CABR_Zone1_TidbiT_June20_Dec21.csv', 
         skip = 2)

tidbit <- tidbit %>%
  clean_names() %>%
  remove_empty(which = c('cols')) %>%
  rename(dtime = date_time_gmt_08_00,
         tidbit_temp_c = temp_c)

write_csv(tidbit, './data/abiotic/cabr_z1_tidbit.csv')

# I put the csv's that are written in this script in the google drive folder
  
