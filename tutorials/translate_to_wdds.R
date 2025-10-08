"Lets say we already collected our data and want to apply the standard to it."
"In this case, we will look at the data behind Museum collections and machine learning guide discovery of novel coronaviruses and paramyxoviruses"
"In this paper, the authors took a model that predicts bat-virus interactions and used it to guide sampling of museum specimens from the Chicago Field Museum."
"The project started in 2020 so their data collection schema is completely independent of WDDS - which was released in 2025."
"https://doi.org/10.1101/2025.09.11.675601"

## Look at the data

xlsx_file <- "./tutorials/fmnh_data/Supplementary_Data_S1.xlsx"

### look at the sheets
readxl::excel_sheets(xlsx_file)

## do the sheets have the same fields?

cov_data <- readxl::read_excel(xlsx_file,sheet = "Coronavirus screening",col_types = "text")
pmv_data <- readxl::read_excel(xlsx_file,sheet = "Paramyxovirus screening",col_types = "text")

## does the data follow the 1 row = 1 observation rule

View(head(cov_data))
View(head(pmv_data))

## are the columns the same? 
all(tolower(names(cov_data)) %in% tolower(names(pmv_data)))

"We are going to have to map the data standard to each sheet"

## map fields onto the standard

"Mapping requires a deep understanding of the data and a familiarity with the data standard.
In this case, I sat down with the lead author of the paper to map the fields."

# Animal ID == FMNH Number - official catalog number for a specimen - unique across the entire museum and all departments - at the animal level
# NOT NEEDED Collector* Number == unique id for each person who did the collecting -- person + series e.g. mmj7 is the 7th bat collected by Maya - not unique without initials before it.
# hostIdentification Taxon = host taxonomy to the finest degree known
# ?Keep? Country = country of collection * no direct mapping
# ?Keep? Locality = admin below country? to whatever degree of detail written by the collector - could be descriptive
# Lat = dec degree
# lon = dec degree
# Year = year of collection --- additional date information collected  ## expand dates later
# sampleMaterial = Tissue = organ sampled
# sampleCollectionMethod = everything is "necropsy"
# **KEEP** Buffer = storageMedium = what the sampleMaterial is stored in? ---> potentially add to wdds
# initial preservation techniques may also be important to capture
# Model Prediction ---> specific to this project ----> justification for screening = known, suspected, unlikely -- Drop when putting into PHAROS
# detectionOutcome = CoV screening result = positivie or negative for COV
# detectionMethod = Will be the same for everything --> RT-PCR
# geneTarget = RdRp for cov, L for pmv
# primerCitation =
#         PMV = Tong, S., Chern, S. W. W., Li, Y., et al. Sensitive and broadly reactive reverse transcription-PCR assays to detect novel paramyxoviruses. Journal of Clinical Microbiology 46, 2652–58 (2008).
#         COV = Waruhiu, C., Ommeh, S., Obanda, V., et al. Molecular detection of viruses in Kenyan bats and discovery of novel astroviruses, caliciviruses and rotaviruses. Virologica Sinica 32, 101–114 (2017).
# primersFoward
# primersReverse
# parasiteIdentification = Protocol allows for detection for pan-PMV, and pan-COV # not currently in the data but is in a table in the paper
# detectionTarget = pan-PMV and pan-COV
# genbankAccession = waiting on this, not currently in the data

## Coronavirus data

# Lets use the clean_names function in janitor to get more consistent naming conve
disease_data_cov_lc <-  janitor::clean_names(dat = cov_data, case = "lower_camel")


names(disease_data_cov_lc)

disease_data_cov_wdds <- disease_data_cov_lc |>
  dplyr::rename("animalID" = "fmnhNumber",
                "hostIdentification" = "taxon",
                "collectionYear" = "year",
                "sampleMaterial" = "tissue",
                "detectionOutcome" = "coVScreeningResult",
                "parasiteIdentification" = "viralGenus",
                "storageMedium" = "buffer"
  ) %>%
  dplyr::mutate(
    sampleCollectionMethod = "necropsy",
    detectionMethod = "RT-PCR",
    geneTarget = "RdRp",
    primerCitation = "Waruhiu, C., Ommeh, S., Obanda, V., et al. Molecular detection of viruses in Kenyan bats and discovery of novel astroviruses, caliciviruses and rotaviruses. Virologica Sinica 32, 101–114 (2017)",
    detectionTarget = "Coronaviridae",
    detectionOutcome = tolower(detectionOutcome)
  ) %>%
  # need to make a unique sample id
  dplyr::mutate(sampleID = sprintf("%s_%s_%s",animalID,detectionTarget,row_number()))

## Paromyxovirus data

disease_data_pmv_lc <-  janitor::clean_names(dat = pmv_data, case = "lower_camel")

names(disease_data_pmv_lc)


disease_data_pmv_wdds <- disease_data_pmv_lc |>
  dplyr::rename("animalID" = "fmnhNumber",
                "hostIdentification" = "taxon",
                "collectionYear" = "year",
                "sampleMaterial" = "tissue",
                "detectionOutcome" = "pmvScreeningResult",
                "storageMedium" = "buffer",
                "genbankAccessionNumber" = "sequence"
  ) %>%
  dplyr::mutate(
    sampleCollectionMethod = "necropsy",
    detectionMethod = "RT-PCR",
    geneTarget = "L",
    primerCitation = "Tong, S., Chern, S. W. W., Li, Y., et al. Sensitive and broadly reactive reverse transcription-PCR assays to detect novel paramyxoviruses. Journal of Clinical Microbiology 46, 2652–58 (2008).",
    detectionTarget = "Paramyxoviridae",
    detectionOutcome = tolower(detectionOutcome),
    parasiteIdentification = case_when(
      detectionOutcome == "positive" ~ "Paramyxoviridae",
      TRUE ~ ""
    )
  ) %>%
  dplyr::mutate(sampleID = sprintf("%s_%s_%s",animalID,detectionTarget,row_number()))

## correct data types
disease_data_wdds <- rbind(disease_data_cov_wdds,disease_data_pmv_wdds) |>
  
  dplyr::mutate(latitude = as.numeric(latitude),
                longitude = as.numeric(longitude),
                collectionYear = as.integer(collectionYear))

### KNOWLEDGE CHECK!

### check that all required fields are there

### bonus points for extending the disease data schema to include fields not in WDDS
## e.g. modelPrediction

### prep for json

### convert to json

## validate against standard

## extract metadata from openalex -- where did I see that doi?

## update metadata - 
# pay attention to the methodology field
# include related identifiers - e.g. the preprint and WDDS data standard

## validate project metadata 

#### Create a WDDS data package by combining the metadata and disease data

## use append so that you do not add levels to your list

data_package <- list(
  disease_data = my_disease_data_prepped,
  project_metadata = my_project_metadata_prepped
)

# check that all required fields are in the data
 wddsWizard::schema_required_fields %in% names(data_package)

# make json
 
data_package_json <- jsonlite::toJSON(data_package, pretty = TRUE)

# validate the package

schema <- wdds_json(version = "latest", file = "wdds_schema.json")

wdds_validator <- jsonvalidate::json_validator(schema, engine = "ajv")

project_validation <- wdds_validator(data_package_json, verbose = TRUE)

if (project_validation) {
  print("Your data package is valid! 🎊 ")
} else {
  errors <- attributes(project_validation)
  errors$errors
}

#### CONGRATULATIONS you're now a WDDS wizard!
"Check out the vignettes on depositing into Zenodo and PHAROS"



