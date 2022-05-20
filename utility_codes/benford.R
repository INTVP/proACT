args = commandArgs(trailingOnly=TRUE)
setwd(args[1])

print("Running code")

# Code to implement Benford's law

# Packages 
# Load and Install libraries ----

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
  "foreign" # export dta file
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

options(warn=0) # suppress warnings OFF

# Load the data for the analysis
buyers_proc <-
  read_csv(
    'buyers_for_R.csv',
    col_names = TRUE  
    )

sprintf("reading in %s", "buyers_for_R.csv")

# Function for Benford values
benford_f <- function(vector_in, output_name) {
  temp <- benford(
    data = c(vector_in),
    number.of.digits = 1,
    sign = "positive",
    discrete = TRUE,
    round = 3
  )[[output_name]]
  return(temp)
}

buyers_proc_summary <- buyers_proc %>%
  rename(buyer_id = 1) %>%
  rename(ca_value = 2) %>%
  select(1, 2)

#Creating MAD_conformity and MAD values using the benford_f function
buyers_proc_summary <- buyers_proc_summary %>%
  group_by(buyer_id) %>%
  summarise(
    MAD_conformitiy = benford_f(vector_in = ca_value, "MAD.conformity"),
    MAD = benford_f(vector_in = ca_value, "MAD")
  )

sprintf("exporting %s", "buyers_benford.csv")

#Writing data frame to dta
write.dta(
  dataframe = buyers_proc_summary,
  file = "buyers_benford.dta"
)# END
