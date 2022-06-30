args = commandArgs(trailingOnly=TRUE)
setwd(args[1])
utility_data = args[2]

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
  "stringr", 
  "data.table", 
  "tokenizers", 
  "dplyr", 
  "haven"
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



#Loading data 
health <-
  read.csv(
    paste0(utility_data, "/country/UG/health_termsRN.csv"),
    header = TRUE,
    sep = ","
  )

#Old data: dfid2_ug_cri_200515.csv
df <- data.table::fread(
  paste0(utility_data,"/country/UG/starting_data/UG_final_data.csv"),
  header = TRUE,
  keepLeadingZeros = TRUE,
  encoding = "UTF-8",
  stringsAsFactors = FALSE,
  showProgress = TRUE,
  na.strings = c("", "-", "NA"),
  fill = TRUE
)

# df$tender_title <- df$planpr_title
# df$tender_title <- ifelse(is.na(df$tender_title),
#                           df$aw_title,
#                           df$tender_title)

df$tender_title_orig <- df$tender_title
df$tender_title <- as.character(df$tender_title)
df$tender_title <- str_squish(df$tender_title)
#df <- df[!duplicated(df$tender_title), ]

#remove irrelevant words
df$tender_title <- gsub("[[:punct:]]", " ", df$tender_title) 
df$tender_title <- gsub("\\d+", " ", df$tender_title) 
df$tender_title <- sapply(df$tender_title, tolower)
df$tender_title <- gsub(" in ", " ", df$tender_title)
df$tender_title <- gsub(" at ", " ", df$tender_title)
df$tender_title <- gsub(" ug ", " ", df$tender_title)
df$tender_title <- gsub(" on ", " ", df$tender_title)
df$tender_title <- gsub(" from ", " ", df$tender_title)
df$tender_title <- gsub(" lot ", " ", df$tender_title)
df$tender_title <- gsub(" km ", " ", df$tender_title)
df$tender_title <- gsub(" ml", " ", df$tender_title)
df$tender_title <- gsub("\\W*\\b\\w\\b\\W*", " ", df$tender_title)
df$ca_descr_cpv <- gsub("acquisition", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub(" a ", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub(" an ", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("stware", "software", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("ment", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("june", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("november", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("december", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("april", "", df$ca_descr_cpv)
df$ca_descr_cpv <- gsub("january", "", df$ca_descr_cpv)
df$tender_title <- str_squish(df$tender_title)

# descr <- tm_map(descr, removePunctuation)
# descr <- tm_map(descr, removeWords, stopwords("english"))
# descr <- tm_map(descr, stripWhitespace)
# descr <- tm_map(descr, stemDocument)
# descr <- tm_map(descr, PlainTextDocument)

#most common single words
# dtm <- DocumentTermMatrix(descr)
# dtm2 <- as.matrix(dtm)
# wordfreq <- colSums(dtm2)
# wordfreq <- sort(wordfreq, decreasing=TRUE)
# head(wordfreq, n=400)


#identify most common two words expressions
# bigr <- tokenize_ngrams(df$ca_descr_cpv, n = 2)
# sigr <- tokenize_ngrams(df$ca_descr_cpv, n = 1)
# 
# descr2 <- data.frame(unlist(bigr), stringsAsFactors = F)
# setDT(descr2, keep.rownames = T)
# setnames(descr2, 1, "rownr")
# setnames(descr2, 2, "term")
# 
# descr2$nr_occ <- 1
# 
# #count most frequent expressions
# freq_ug <- descr2 %>%
#   group_by(term) %>%
#   summarise(frequg = sum(nr_occ))


health$health_term <- as.character(health$health_term)
health$nchar <- nchar(health$health_term)

#remove irrelevant keywords from health terms
health <-
  health[-c(
    health$row_nr == 143,
    health$row_nr == 152,
    health$row_nr == 237 ,
    health$row_nr == 238 ,
    health$row_nr == 370 ,
    health$row_nr == 393 ,
    health$row_nr == 422 ,
    health$row_nr == 484 ,
    health$row_nr == 514 ,
    health$row_nr == 921 ,
    health$row_nr == 922 ,
    health$row_nr == 923 ,
    health$row_nr == 930 ,
    health$row_nr == 1031 ,
    health$row_nr == 1063 ,
    health$row_nr == 1068
  ),]

health <- health[ -c(health$nchar <=3), ]

df$ca_descr_cpv <- df$tender_title
# df$cpv_code <- NA
# df$cpv_code <-
#   ifelse(is.na(df$cpv_code),
#          tkn$code[match(df$ca_descr_cpv,
#                         tkn$ca_descr_cpv)],
#          df$cpv_code)

df$cpv_code <- ifelse(grepl("motor vehicle", df$ca_descr_cpv) & is.na(df$cpv_code),341000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("hotel services", df$ca_descr_cpv) & is.na(df$cpv_code),551000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("repair motor", df$ca_descr_cpv) & is.na(df$cpv_code),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("air ticket", df$ca_descr_cpv) & is.na(df$cpv_code),349800000, df$cpv_code)
df$cpv_code <- ifelse(grepl("return air", df$ca_descr_cpv) & is.na(df$cpv_code),349800000, df$cpv_code)
df$cpv_code <- ifelse(grepl("servic", df$ca_descr_cpv) & grepl("vehicle", df$ca_descr_cpv) & is.na(df$cpv_code),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("repair", df$ca_descr_cpv) & grepl("vehicle", df$ca_descr_cpv) & is.na(df$cpv_code),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("catering", df$ca_descr_cpv) & grepl("services", df$ca_descr_cpv) & is.na(df$cpv_code),555200001, df$cpv_code)
df$cpv_code <- ifelse(grepl("spare parts", df$ca_descr_cpv) & is.na(df$cpv_code),343200006, df$cpv_code)
df$cpv_code <- ifelse(grepl("service repair", df$ca_descr_cpv) & is.na(df$cpv_code),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("office equipment", df$ca_descr_cpv) & is.na(df$cpv_code),301900007, df$cpv_code)
df$cpv_code <- ifelse(grepl("motor", df$ca_descr_cpv) & grepl("servic", df$ca_descr_cpv) & is.na(df$cpv_code),501150004, df$cpv_code)
df$cpv_code <- ifelse(grepl("office furniture", df$ca_descr_cpv) & is.na(df$cpv_code),391300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("vehicle maintenance", df$ca_descr_cpv),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("conference facilities", df$ca_descr_cpv),551200007, df$cpv_code)
df$cpv_code <- ifelse(grepl("stationery", df$ca_descr_cpv) & is.na(df$cpv_code),301927008, df$cpv_code)
df$cpv_code <- ifelse(grepl("civil works", df$ca_descr_cpv),452000009, df$cpv_code)
df$cpv_code <- ifelse(grepl("repair service", df$ca_descr_cpv),501000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("cleaning services", df$ca_descr_cpv) & is.na(df$cpv_code),909100009, df$cpv_code)
df$cpv_code <- ifelse(grepl("cabinet", df$ca_descr_cpv),391413005, df$cpv_code)
df$cpv_code <- ifelse(grepl("cabin", df$ca_descr_cpv),442111106	, df$cpv_code)
df$cpv_code <- ifelse(grepl("lubricants", df$ca_descr_cpv) & is.na(df$cpv_code),249511006, df$cpv_code)
df$cpv_code <- ifelse(grepl("office", df$tender_title) & grepl("supply", df$tender_title) & is.na(df$cpv_code),301920001, df$cpv_code)
df$cpv_code <- ifelse(grepl("office", df$tender_title) & grepl("clean", df$tender_title) & is.na(df$cpv_code),909192004, df$cpv_code)
df$cpv_code <- ifelse(grepl("fuel", df$ca_descr_cpv) & is.na(df$cpv_code),91000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("air condition", df$ca_descr_cpv) & is.na(df$cpv_code),425100004, df$cpv_code)
df$cpv_code <- ifelse(grepl("cleaning material", df$ca_descr_cpv) & is.na(df$cpv_code),398000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("reagent tests", df$ca_descr_cpv) & is.na(df$cpv_code),331000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("business cards", df$ca_descr_cpv) & is.na(df$cpv_code),301997306, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & grepl("supervision", df$ca_descr_cpv) & is.na(df$cpv_code),715200009, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & grepl("material", df$ca_descr_cpv) & is.na(df$cpv_code),441000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & grepl("staff", df$ca_descr_cpv) & is.na(df$cpv_code),715000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & grepl("road", df$ca_descr_cpv) & is.na(df$cpv_code),452331206, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & grepl("work", df$ca_descr_cpv) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("construction", df$ca_descr_cpv) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("printing", df$ca_descr_cpv) & is.na(df$cpv_code),798100005, df$cpv_code)
df$cpv_code <- ifelse(grepl("equipment", df$ca_descr_cpv) & grepl("machinery", df$ca_descr_cpv) & is.na(df$cpv_code),300000009, df$cpv_code)
df$cpv_code <- ifelse(grepl("equipment", df$ca_descr_cpv) & grepl("it ", df$ca_descr_cpv) & is.na(df$cpv_code),302000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("equipment", df$ca_descr_cpv) & grepl("office", df$ca_descr_cpv) & is.na(df$cpv_code),300000009, df$cpv_code)
df$cpv_code <- ifelse(grepl("computer", df$ca_descr_cpv) & is.na(df$cpv_code),302000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("medical", df$ca_descr_cpv) & is.na(df$cpv_code),330000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("training", df$ca_descr_cpv) & is.na(df$cpv_code),800000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("water", df$ca_descr_cpv) & grepl("drinking", df$ca_descr_cpv) & is.na(df$cpv_code),411100003, df$cpv_code)
df$cpv_code <- ifelse(grepl("hotel", df$ca_descr_cpv) & is.na(df$cpv_code),551000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("software", df$ca_descr_cpv) & is.na(df$cpv_code),480000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("tyres", df$ca_descr_cpv) & is.na(df$cpv_code),343500005, df$cpv_code)
df$cpv_code <- ifelse(grepl("furniture", df$ca_descr_cpv) & is.na(df$cpv_code),390000002, df$cpv_code)
df$cpv_code <- ifelse(grepl("books", df$ca_descr_cpv) & is.na(df$cpv_code),228000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("conference", df$ca_descr_cpv) & is.na(df$cpv_code),551200007, df$cpv_code)
df$cpv_code <- ifelse(grepl("chairs", df$ca_descr_cpv) & is.na(df$cpv_code),391100006, df$cpv_code)
df$cpv_code <- ifelse(grepl("workshop", df$ca_descr_cpv) & is.na(df$cpv_code),800000004, df$cpv_code)
df$cpv_code <- ifelse(grepl(" venue", df$ca_descr_cpv) & is.na(df$cpv_code),703000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("food", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("security services", df$ca_descr_cpv) & is.na(df$cpv_code),797100004, df$cpv_code)
df$cpv_code <- ifelse(grepl("security", df$ca_descr_cpv) & grepl("services", df$ca_descr_cpv) & is.na(df$cpv_code),797100004, df$cpv_code)
df$cpv_code <- ifelse(grepl("printer", df$ca_descr_cpv) & is.na(df$cpv_code),301000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("toner", df$ca_descr_cpv) & is.na(df$cpv_code),301000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("generator", df$ca_descr_cpv) & is.na(df$cpv_code),311000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("tests", df$ca_descr_cpv) & is.na(df$cpv_code),330000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("meals", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("insurance", df$ca_descr_cpv) & is.na(df$cpv_code),660000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("radio", df$ca_descr_cpv) & is.na(df$cpv_code),320000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("laboratory", df$ca_descr_cpv) & is.na(df$cpv_code),330000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("lunch", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("refreshments", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("photocop", df$ca_descr_cpv) & is.na(df$cpv_code),301200006, df$cpv_code)
df$cpv_code <- ifelse(grepl("advertising", df$ca_descr_cpv) & is.na(df$cpv_code),793400009, df$cpv_code)
df$cpv_code <- ifelse(grepl("travel", df$ca_descr_cpv) & is.na(df$cpv_code),799000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("coffee", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("media ", df$ca_descr_cpv) & is.na(df$cpv_code),302000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("electrical", df$ca_descr_cpv) & is.na(df$cpv_code),310000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("tea ", df$ca_descr_cpv) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("pump", df$ca_descr_cpv) & is.na(df$cpv_code),421200006, df$cpv_code)
df$cpv_code <- ifelse(grepl("internet", df$ca_descr_cpv) & is.na(df$cpv_code),482000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("laptop", df$ca_descr_cpv) & is.na(df$cpv_code),302000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("survey", df$ca_descr_cpv) & is.na(df$cpv_code),712500005, df$cpv_code)
df$cpv_code <- ifelse(grepl("tourism", df$ca_descr_cpv) & is.na(df$cpv_code),751250008, df$cpv_code)
df$cpv_code <- ifelse(grepl("solar", df$ca_descr_cpv) & is.na(df$cpv_code),93000002, df$cpv_code)
df$cpv_code <- ifelse(grepl("toilet", df$ca_descr_cpv) & is.na(df$cpv_code),337100000, df$cpv_code)
df$cpv_code <- ifelse(grepl("education", df$ca_descr_cpv) & is.na(df$cpv_code),800000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("server", df$ca_descr_cpv) & is.na(df$cpv_code),488000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("subscription", df$ca_descr_cpv) & is.na(df$cpv_code),799800007, df$cpv_code)
df$cpv_code <- ifelse(grepl("desks", df$ca_descr_cpv) & is.na(df$cpv_code),391000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("certificate", df$ca_descr_cpv) & is.na(df$cpv_code),224000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("safety", df$ca_descr_cpv) & is.na(df$cpv_code),349000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("digital", df$ca_descr_cpv) & is.na(df$cpv_code),302000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("legal", df$ca_descr_cpv) & is.na(df$cpv_code),791000005, df$cpv_code)
df$cpv_code <- ifelse(grepl("party", df$ca_descr_cpv) & is.na(df$cpv_code),799540006, df$cpv_code)
df$cpv_code <- ifelse(grepl("sanitation", df$ca_descr_cpv) & is.na(df$cpv_code),906000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("accommodation", df$ca_descr_cpv) & is.na(df$cpv_code),551100004, df$cpv_code)
df$cpv_code <- ifelse(grepl("drugs", df$ca_descr_cpv) & is.na(df$cpv_code),336000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("uniforms", df$ca_descr_cpv) & is.na(df$cpv_code),358000002, df$cpv_code)
df$cpv_code <- ifelse(grepl("fencing", df$ca_descr_cpv) & is.na(df$cpv_code),453400002, df$cpv_code)
df$cpv_code <- ifelse(grepl("plumbing", df$ca_descr_cpv) & is.na(df$cpv_code),441000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("adverts", df$ca_descr_cpv) & is.na(df$cpv_code),793410006, df$cpv_code)
df$cpv_code <- ifelse(grepl("newspaper", df$ca_descr_cpv) & is.na(df$cpv_code),222000002, df$cpv_code)
df$cpv_code <- ifelse(grepl("cleaning", df$ca_descr_cpv) & is.na(df$cpv_code),398000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("license", df$ca_descr_cpv) & is.na(df$cpv_code),722000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("study", df$ca_descr_cpv) & is.na(df$cpv_code),710000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("transportation", df$ca_descr_cpv) & is.na(df$cpv_code),600000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("water", df$ca_descr_cpv) & grepl("tank", df$ca_descr_cpv) & is.na(df$cpv_code),446000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("telecommunication", df$ca_descr_cpv) & is.na(df$cpv_code),320000003, df$cpv_code)
df$cpv_code <- ifelse(grepl("communication", df$ca_descr_cpv) & is.na(df$cpv_code),320000003, df$cpv_code)
df$cpv_code <- ifelse(grepl(" gas", df$ca_descr_cpv) & is.na(df$cpv_code),91200006, df$cpv_code)
df$cpv_code <- ifelse(grepl("shelves", df$ca_descr_cpv) & is.na(df$cpv_code),391411003, df$cpv_code)
df$cpv_code <- ifelse(grepl("tube", df$ca_descr_cpv) & is.na(df$cpv_code),330000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("consultancy services", df$ca_descr_cpv) & is.na(df$cpv_code),710000008, df$cpv_code)
df$cpv_code <- ifelse(is.na(df$cpv_code),983900003, df$cpv_code)


# tt <- subset(df, grepl("management system", df$ca_descr_cpv))
# tt <- subset(tt, is.na(tt$cpv_code))
# sum(!is.na(df$cpv_code))

#check if tender title includes listed health terms and assign the cpv code if yes
#check <- ifelse(sapply(health$health_term, grep, df$ca_descr_cpv), 1, 0)
df$check <- ifelse(grepl(paste(health$health_term, collapse = "|"), df$ca_descr_cpv), 1,0)
df$cpv_code <- ifelse(df$check==1 & is.na(df$cpv_code),336000006, df$cpv_code)
df$cpv_code <- ifelse(df$cpv_code==983900003, NA, df$cpv_code)

data.table::fwrite(df,"UG_wip.csv",
                   quote = TRUE, sep = "," )
