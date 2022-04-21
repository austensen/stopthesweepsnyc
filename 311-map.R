library(tidyverse)
library(lubridate)
library(sf) # install instructions: https://github.com/r-spatial/sf
library(leaflet)
library(leaflet.mapboxgl)
library(leafpop)
library(htmlwidgets)
library(htmltools)
library(dotenv)


# Setup -------------------------------------------------------------------

# Edit ".env_sample" to set variables and save as ".env"
load_dot_env(".env")

# Free to sign up for API key here: https://account.mapbox.com/auth/signup/
options(mapbox.accessToken = Sys.getenv("MAPBOX_TOKEN"))

start_date <- "2022-01-01"
end_date <- as.character(today())

complaint_types <- c('Encampment','Homeless Encampment','Homeless Person Assistance','Homeless Street Condition') %>% 
  glue::glue_collapse(sep = "', '") %>% 
  str_c("'", ., "'")


# Get 311 Data ------------------------------------------------------------

query_311 <- utils::URLencode(stringr::str_glue(
  "https://data.cityofnewyork.us/resource/fhrw-4uyv.csv?$query=
      SELECT bbl, closed_date, community_board, created_date, incident_zip, latitude, longitude, 
       resolution_action_updated_date, resolution_description, status, complaint_type, descriptor, location_type
      WHERE created_date between '{start_date}T00:00:00' and '{end_date}T23:59:59' 
       AND complaint_type IN ({complaint_types})
      LIMIT 500000"
))

cols_311 <- readr::cols(
  bbl = col_character(),
  closed_date = col_datetime(format = ""),
  community_board = col_character(),
  created_date = col_datetime(format = ""),
  incident_zip = col_character(),
  latitude = col_double(),
  longitude = col_double(),
  resolution_action_updated_date = col_datetime(format = ""),
  resolution_description = col_character(),
  status = col_character(),
  complaint_type = col_character(),
  descriptor = col_character(), 
  location_type = col_character()
)

complaints_raw <- readr::read_csv(query_311, col_types = cols_311, na = c("", "NA", "N/A"))

complaints_sf <- complaints_raw %>% 
  drop_na(latitude) %>% # we have to drop records with no lat/lon location
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% 
  select(
    created_date,status,complaint_type,location_type,descriptor,
    resolution_action_updated_date,resolution_description
  )


# Make Map ----------------------------------------------------------------

map_title <- tags$div(
  HTML(glue::glue("<h3>311 Calls</h3><span><b>From:</b> {start_date} to {end_date}</span><br><span><b>Complaint types:</b> {complaint_types}</span>"))
)  

popup <- popupTable(
  complaints_sf, 
  c("created_date","status","complaint_type","location_type","descriptor",
    "resolution_action_updated_date","resolution_description"), 
  row.numbers = FALSE, 
  feature.id = FALSE
)

complaint_map <- complaints_sf %>% 
  leaflet() %>% 
  addMapboxGL(style = "mapbox://styles/mapbox/light-v9") %>% 
  addControl(map_title, position = "topright") %>% 
  setView(-73.95826223225097, 40.704354100354415, zoom = 13) %>% 
  addCircleMarkers(
    fillOpacity = 0.6,
    color = "steelblue",
    weight = 0,
    radius = 2,
    opacity = 0.8,
    popup = popup
  )

saveWidget(complaint_map, file="docs/311-map.html")
