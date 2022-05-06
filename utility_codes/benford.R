# Code to implement benford's law
## Packages 
# Load and Install libraries ----
# The following lines checks if the libraries are install.
# If installed, then load. If not, then install then then load them.
print(paste("Using", R.version[13], sep = " "))


# FIRST: check if pacman is installed. 
# This package installs and loads other packages
if (!require(pacman)) {
  install.packages("pacman", dependencies = TRUE)
}

# SECOND: list all other packages that will be used
# Add libraries as needed here.
# Please also add the reason why this library is added
packages <- c(
  "tidyverse", # general data wrangling
  "benford.analysis", # Benford's analysis
  "foreign", # export dta file
  "here" # use relative file paths starting on the root folder for the repository
)  

# THIRD: installing and loading the packages
# The following lines checks if the libraries are installed.
# If installed, they will be loaded.
# If not, they will be installed then loaded.
p_load(
  packages, 
  character.only = TRUE, 
  depencies = TRUE
)

# Data -------------------------------------------------------------------------
# Load the data for analysis
buyers_proc <- 
  read_csv(
  # Need to complement this with the path to the output folder starting at the repository root directory
    here(
      'buyers_for_R.csv'  
    ),
    header = TRUE, 
    sep = ",",  
    encoding = "UTF-16LE"
  )

sprintf("reading in %s", "buyers_for_R.csv")
# function for calculation
benford_f <- function(vector_in, output_name) {
  temp <- benford(data = c(vector_in),
          number.of.digits = 1, sign = "positive", discrete=TRUE, round=3)[[output_name]]
  return(temp)
}

buyers_proc_summary <- buyers_proc %>%
  rename(buyer_id = 1) %>%
  rename(ca_value = 2) %>%
  select(1,2)
buyers_proc_summary <- buyers_proc_summary %>%
  group_by(buyer_id) %>%
  summarise(MAD_conformitiy = benford_f(vector_in=ca_value,"MAD.conformity"),
            MAD = benford_f(vector_in=ca_value,"MAD"))

sprintf("exporting %s", "buyers_benford.csv")

write.dta(
  dataframe = buyers_proc_summary,
  file = here(
    # Need to complement this with the path to the output folder starting at the repository root directory
    "buyers_benford.dta"
  )
)# END
