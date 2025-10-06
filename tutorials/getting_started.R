### package from R universe

install.packages('wddsWizard', repos = c('https://viralemergence.r-universe.dev',
                                         'https://cloud.r-project.org'))
# or
# remotes::install_github("viralemergence/wddsWizard")

# renv::restore()

library(dplyr)
library(jsonvalidate)
library(fs)

## The Whole game ----

# Flat data files (csv/xlsx) are imported into R, lightly restructured, and 
# then converted to JSON and validated against the Wildlife Disease Data 
# Standard. Data sets either pass (🎉) or fail with informative errors.


## To get you familiar with the workflow, we will validate an example dataset
## in the wddsWizard package.

## to see all the example datasets in the package, supply a package version 
## to the wdds_example_data function. 

wddsWizard::wdds_example_data(version = "latest") |>
  fs::path_file()

## We can start by validating one of the disease data examples. 

my_disease_data <- wddsWizard::wdds_example_data(version = "latest",file = "my_interesting_disease_data.csv") |>
  read.csv()

## take a quick look at the data
names(my_disease_data)

## Now lets look at the terms in the disease data component of data standard

wddsWizard::disease_data_schema$properties |> names()


# What differences do you see between the property names, and the names in the example data?

## use the wddsWizard::clean_field_names function to align case conventions
 
my_disease_data_cn <- wddsWizard::clean_field_names(my_disease_data)

names(my_disease_data_cn)

## if we are curious about types or definitions for a specific property, we can 
## drill down to that property in the list
wddsWizard::disease_data_schema$properties$animalID$description

## or look a summarized table of properties
wddsWizard::schema_properties[1:3,]


## The disease data component has required fields - lets see what those are
## and make sure they are part of the example data

wddsWizard::disease_data_required_fields

all(wddsWizard::disease_data_required_fields %in% names(my_disease_data_cn))

## WDDS is written as a JSON schema, so we have to get our data ready for
# translation to json.

my_disease_data_prepped <- wddsWizard::prep_data(my_disease_data_cn)

### we have a lot of empty fields, we probably should remove those before
### proceeding. 

list_filter <- my_disease_data_prepped |>
  purrr::map_lgl(\(x){
    all(is.na(x))
  })

my_disease_data_prepped_cleaned <- my_disease_data_prepped[!list_filter]

## why is this filtering approach potentially problematic? are there any steps
## we should repeat?

## convert to JSON
my_disease_data_json <- my_disease_data_prepped_cleaned |>
  jsonlite::toJSON(pretty = TRUE)

## look at your beautiful object of arrays 
my_disease_data_json

## validate the data -----

# get the schema file
schema <- wddsWizard::wdds_json(version = "latest", file = "schemas/disease_data.json")

# this creates a function that we can use to validate our data
dd_validator <- jsonvalidate::json_validator(schema, engine = "ajv")

# use the validator to check if the disease data conforms to the disease_data component of the standard
dd_validation <- dd_validator(my_disease_data_json, verbose = TRUE)

errors <- attributes(dd_validation)

if (!dd_validation) {
  errors$errors
} else {
  print("Valid disease data!😁")
}




