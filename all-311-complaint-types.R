library(tidyverse)

query_311_types <- utils::URLencode(stringr::str_glue(
  "https://data.cityofnewyork.us/resource/fhrw-4uyv.csv?$query=
      SELECT distinct complaint_type
      LIMIT 500000"
))

all_complaint_types <- readr::read_csv(query_311_types, col_types = "c", na = c("", "NA", "N/A"))

write_csv(all_complaint_types, "all-311-complaint-types.csv", na = "")