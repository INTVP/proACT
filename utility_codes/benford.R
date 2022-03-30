# Code to implement benford's law
## Packages 
# Load and Install libraries ----
# The following lines checks if the libraries are install.
# If installed, then load. If not, then install then then load them.
# FIRST: list all the packages we have:
list.of.packages <- c("pacman", # for loading libraries
                      "tidyverse", # general data wrangling
                      "dplyr", # data wrangling 1: using pipe commands such as "%>%"
                      "benford.analysis", # Benford's analysis
                      "readxl", # read EXCEL files
                      "foreign", # read EXCEL files
                      "readr" # read CSV and TXT files
)  # Add libraries as needed here: Please also add the reason why this library is added
print(paste("Using", R.version[13], sep = " "))

# SECOND: installing and loading the packages
options(warn=-1) # suppress warnings ON
for (package in list.of.packages) {
  if(package %in% rownames(installed.packages()) == FALSE) {
    #print(paste(package, match(package,list.of.packages), "out of", length(list.of.packages),"is not installed","installing now"))
    install.packages(package, dependencies = T)
  }
  library(package, character.only=TRUE)
  #print(paste(package, match(package,list.of.packages), "out of", length(list.of.packages),"is installed"))

}
options(warn=0) # suppress warnings OFF
# load the data for the analysis
buyers_proc <- read.csv('buyers_for_R.csv',header = TRUE, sep = ",",  encoding = "UTF-16LE")
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
#readr::write_excel_csv(buyers_proc_summary,"buyers_benford.csv",  na = ".")
foreign::write.dta(dataframe = buyers_proc_summary,
                   file = "buyers_benford.dta")# END
