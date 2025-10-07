source("packages.R")

"You received funding for a study of vertical transmission of a virus in mosquitos. 
In your data management and sharing plan you said that you would be using WDDS 
as a data standard for your project. 
How are you going to do that?"

"wdds is built on the idea that one observation == 1 row. 
If this works for your study design then you can directly use the built in 
data templates as collection instruments. Lucky you."

wddsWizard::use_wdds_template(template_file = "disease_data_template.xlsx")

"More likely, you will be collecting site data, host data, 
and parasite data in separate locations."

"To use WDDS in this instance you need to ensure that the minimal data requirements
are captured across those three data streams."

## disease data - required fields

wddsWizard::disease_data_required_fields

"use the schema documentation to get more information about the field definitions"
"https://viralemergence.github.io/wddsWizard/articles/schema_overview.html"

### need to modify the json schema

"Lets say you've modeled your data, and you realize two things
1) you would like to be much more specific when describing host life stage and
2) you need to provide context on how the hosts were captured."

"Any time we want to add fields or use more specific terms, we should make sure
the term doesnt already exist in the schema then look to
existing ontologies and controlled vocabularies so that our json schema remains
machine and human readable."


# copy the schemas folder into a new place and
# take a peak at the hostLifeStage item.


wdds_json(version = "latest","wdds_schema.json") |>
  fs::path_dir()|>
  fs::dir_copy(new_path = "modified_schemas")

file.edit("modified_schemas/schemas/disease_data.json")

# "hostLifeStage":{
#   "description":"The life stage of the animal from which the sample was collected (as appropriate for the organism) (e.g., juvenile, adult). See http://rs.tdwg.org/dwc/terms/lifeStage",
#   "examples":["juvenile","adult","larva"],
#   "type":"array",
#   "items":{
#     "type": ["string","null"],
#     "minItems":1
#   }
# }


"In our study, we use specific terms to describe host life stages and want to
make sure we are using only those terms. We can modify this part of the standard
to be more specific, but still compliant with the original WDDS standard. We can
use the enum keyword to list specific values."

"We classify the larva into first, second, and third instar so we will enumerate
those values in the JSON schema."

# "hostLifeStage":{
#   "description":"The life stage of the animal from which the sample was collected (as appropriate for the organism) (e.g., juvenile, adult). See http://rs.tdwg.org/dwc/terms/lifeStage",
#   "examples":["juvenile","adult","larva"],
#   "type":"array",
#   "items":{
    # "type": ["string","null"],
    # "enum": ["first instar","second instar","third instar","null"],
    # "minItems":1
#   }
# }

"Since we are collecting wild mosquito larvae, we may want to include 
information about trapping protocols and validate that field using the JSON 
schema. After reviewing the terms, we confirm there is no specific term for host
organism collection method. We can look for an equivalent term in one of our
trusted resources. In this case, we might use the darwincore term
samplingProtocol: http://rs.tdwg.org/dwc/terms/samplingProtocol."


# "samplingProtocol":{
#   "description":"The names of the methods used during a larval collection event. See http://rs.tdwg.org/dwc/terms/samplingProtocol. Protocol names from European Centre for Disease Prevention and Control; European Food Safety Authority. Field sampling methods for mosquitoes, sandflies, biting midges and ticks – VectorNet project 2014–2018. Stockholm and Parma: ECDC and EFSA; 2018.",
#   "type":"array",
#   "items":{
#     "type": ["string","null"],
#     "enum": ["complete submersion","flow-in","simple ladle","null"]"],
#               "minItems":1
#             }
#           }

## We can start by validating one of the disease data examples. 

my_disease_data <- wddsWizard::wdds_example_data(version = "latest",file = "my_interesting_disease_data.csv") |>
  read.csv()

my_disease_data_cn <- wddsWizard::clean_field_names(my_disease_data)

my_disease_data$samplingProtocol <- "complete submersion"

my_disease_data_prepped <- wddsWizard::prep_data(my_disease_data_cn)

## lets look at host life stage - these should fail
my_disease_data_prepped$hostLifeStage

disease_data_json<- jsonlite::toJSON(my_disease_data_prepped,pretty = TRUE)

dd_validator <- jsonvalidate::json_validator(schema = "modified_schemas/schemas/disease_data.json", engine = "ajv")

dd_validation <- dd_validator(disease_data_json, verbose = TRUE)

## check for errors!

errors <- attributes(dd_validation)

if (!dd_validation) {
  errors$errors
} else {
  print("Valid disease data metadata!😁")
}

### Anything else we can do to communicate these changes?

"Modify the wdds_schema.json file. 

1. Add a dev id to the semantic version in the title. Since we are very interested in the larval lifestages, we are going to call this v1.0.4-instar. 

2. Update the description to reflect the changes you made. Be sure to note if the data would still be valid under the unmodified version of WDDS."


# {
#   "$schema": "https://json-schema.org/draft/2020-12/schema",
#   "title": "Wildlife Disease Data Standard v1.0.4-instar",
#   "description":"Flexible data standard for wildlife disease data. This version of the schema has been modified in the following ways: added the property samplingProtocol from the DarwinCore schema and enumerated values for hostLifeStage. These changes increase the specificity of the standard without violating rules for required or suggested fields, there any data that meets this version of the standard should also be valid under v1.0.4.",
#   "type": "object",
#   "properties": {
#     "disease_data":{
#       "description":"Wildlife disease data. Stored in tidy form.",
#       "$ref":"schemas/disease_data.json"
#     },
#     "project_metadata":{
#       "description":"Metadata for a project that largely follows the Datacite data standard.",
#       "$ref":"schemas/project_metadata.json"
#     }
#   },
#   "required":["disease_data","project_metadata"]
# }


