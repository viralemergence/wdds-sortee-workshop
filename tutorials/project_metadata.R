
source("packages.R")

### Project metadata

"Project metadata largely follow the Datacite Metadata Schema.
Again, the data standard allows you to include additional properties.

Note that if you are comfortable with JSON, it may be easier to write project 
metadata directly as JSON."

## lets look at why the project metadata is a little more complex

wddsWizard::project_metadata_schema$properties$creators

## nested references

datacite_schema <- wddsWizard::wdds_json(version = "latest",file = "schemas/datacite/datacite-v4.5.json") |>
  jsonlite::fromJSON()


## an array of objects
datacite_schema$properties$creators

datacite_schema$definitions$creator

## complex objects which contain references to other objects

datacite_schema$definitions$person

"This makes it possible to provide rich metadata for the creator of a work, but also
raises the technical bar for writing properly formatted project metadata"

## With the wddsWizard package, we are hopefully lowering the bar for project metadata

## use the metadata csv templates included in the package to create and format
## metadata
?generate_metadata_csv
generated_metadata <- wddsWizard::generate_metadata_csv(file_path = "test.csv",
                      event_based = TRUE,
                      archival = FALSE,
                      num_creators = 10,
                      num_titles = 1,
                      identifier = "https://doi.org/10.1080/example.doi",
                      identifier_type = "doi",
                      num_subjects = 5,
                      publication_year = "2025",
                      rights = "cc-by",
                      language = "en",
                      num_descriptions = 1,
                      num_fundingReferences = 4,
                      num_related_identifiers= 5,
                      write_output = FALSE) # set to true to write the csv


generated_metadata |> dplyr::tibble()

"This lets us create an empty shell ready to be populated"

## extract metadata from a work that is already published

doi <-"doi.org/10.1038/s41597-025-05332-x" 
extracted_metadata <- wddsWizard::extract_metadata_from_doi(doi = doi,write_output=FALSE)

## Lets review the metadata
extracted_metadata |> View()

## we see that there are some affiliation items that are wrong, we can 
## edit in place or write a csv, then edit that csv.

# there are also some placeholder values eg identifier, descriptions, and related items
# we want to be sure to add WDDS as a related item, update the description of the data,
# and add a DOI if we have one for the data.
extracted_metadata |> readr::write_csv(file = "./tutorials/wdds_metadata.csv",)

update_metadata <- read.csv(file = "./tutorials/wdds_metadata_updated.csv",row.names = NULL)


## lets use the extracted metadata

my_project_metadata_prepped <- wddsWizard::prep_from_metadata_template(update_metadata)

## double check that we have all required fields
required_fields <- wddsWizard::project_metadata_required_fields %in% names(my_project_metadata_prepped) 

all(required_fields)

## convert to json

my_project_metadata_json <- my_project_metadata_prepped |>
  jsonlite::toJSON(pretty = TRUE)

# validate against project metadata schema

schema <- wdds_json(version = "latest", file = "schemas/project_metadata.json")

pm_validator <- jsonvalidate::json_validator(schema, engine = "ajv")

pm_validation <- pm_validator(my_project_metadata_json, verbose = TRUE)

## check for errors!

errors <- attributes(pm_validation)

if (!pm_validation) {
  errors$errors
} else {
  print("Valid project metadata!😁")
}

## lets handle these errors - they all seem to come from enumerate values

# where did the errors occur?
errors$errors[c("instancePath","message")]

# what are the allowed values?
errors$errors$params$allowedValues

# what did we submit?
errors$errors$data

# enum is really strict, so you need to make sure that cases match.
# update the metadata file and re-run the validation

## now lets setup a data collection instrument

