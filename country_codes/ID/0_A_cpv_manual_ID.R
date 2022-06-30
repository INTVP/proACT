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
  "haven", 
  "readxl", 
  "stringr", 
  "tm", 
  "tidyverse",
  "data.table",
  "tokenizers"
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
df <- data.table::fread(
  paste0(utility_data,"/country/ID/ID_ten_title.csv"),
  header = TRUE,
  keepLeadingZeros = TRUE,
  encoding = "UTF-8",
  stringsAsFactors = FALSE,
  showProgress = TRUE,
  na.strings = c("", "-", "NA"),
  fill = TRUE
)

df <- df %>% select(c('ten_id','ten_title'))
gc()

# df$check <- ifelse(grepl(paste(health$health_term, collapse = "|"), df$ten_title), 1,0)


# df$cpv1 <- ifelse(grepl("jasa", df$ten_title) | grepl("dinas", df$ten_title) | grepl("konsultan", df$ten_title)  | grepl("pelayanan", df$ten_title) | grepl("pengawasan", df$ten_title) | grepl("supervisi", df$ten_title) , "S",NA)
# df$cpv1 <- ifelse(grepl("peralatan", df$ten_title) | grepl("mesin", df$ten_title) | grepl("barang", df$ten_title)  | grepl("kendaraan", df$ten_title), "G",df$cpv1)
# df$cpv1 <- ifelse(grepl("kerja", df$ten_title) | grepl("pembuatan", df$ten_title) | grepl("pemeliharaan", df$ten_title), "W",df$cpv1)


df$ten_title_orig <- df$ten_title

df$ten_title <- as.character(df$ten_title)
df$ten_title <- str_squish(df$ten_title)
# df <- df[!duplicated(df$ten_title), ]

#remove irrelevant words
df$ten_title <- gsub("\\d+", " ", df$ten_title) 
df$ten_title <- gsub("[[:punct:]]", " ", df$ten_title) 
df$ten_title <- sapply(df$ten_title, tolower)
df$ten_title <- str_squish(df$ten_title)

# descr <- VCorpus(VectorSource(df$ten_title))
# 
# descr <- tm_map(descr, removePunctuation)
# #descr <- tm_map(descr, removeWords, stopwords("indonesia"))
# descr <- tm_map(descr, stripWhitespace)
# descr <- tm_map(descr, stemDocument)
# descr <- tm_map(descr, PlainTextDocument)
# 
# #single words
# dtm <- DocumentTermMatrix(descr)
# dtm2 <- as.matrix(dtm)
# wordfreq <- colSums(dtm2)
# wordfreq <- sort(wordfreq, decreasing=TRUE)
# head(wordfreq, n=400)
# 
# bigr <- tokenize_ngrams(df$ten_title, n = 2)
# tri <- tokenize_ngrams(df$ten_title, n = 3)
# 
# descr2 <- data.frame(unlist(tri), stringsAsFactors = F)
# setDT(descr2, keep.rownames = T)
# setnames(descr2, 1, "rownr")
# setnames(descr2, 2, "term")
# 
# descr2$nr_occ <- 1
# 
# freq_ug <- descr2 %>% 
#   group_by(term) %>%
#   summarise(frequg = sum(nr_occ))
# 
# descr3 <- arrange(freq_ug, desc(frequg))

df$ten_title <- as.character(df$ten_title)
df$cpv_code <- NA

df$cpv_code <- ifelse(grepl("jalan", df$ten_title) & is.na(df$cpv_code),452331000, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan jembatan", df$ten_title) & is.na(df$cpv_code),452210002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("drainase", df$ten_title) & is.na(df$cpv_code),452324501, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("gedung", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("kontruksi", df$ten_title) & grepl("gedung", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pengawasan pembangunan", df$ten_title) & is.na(df$cpv_code),715200009, df$cpv_code)
df$cpv_code <- ifelse(grepl("jaringan irigasi", df$ten_title) & is.na(df$cpv_code),452321003, df$cpv_code)
df$cpv_code <- ifelse(grepl("kontruksi", df$ten_title) & grepl("konsultansi", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("kontruksi", df$ten_title) & grepl("jasa", df$ten_title) & is.na(df$cpv_code),713100004, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("sarana", df$ten_title) & is.na(df$cpv_code),452000009, df$cpv_code)
df$cpv_code <- ifelse(grepl("supervisi pembangunan", df$ten_title) & is.na(df$cpv_code),715200009, df$cpv_code)
df$cpv_code <- ifelse(grepl("konstruksi", df$ten_title) & grepl("supervisi", df$ten_title) & is.na(df$cpv_code),715200009, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("fasilitas", df$ten_title) & grepl("pelabuhan", df$ten_title) & is.na(df$cpv_code),452000009, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("konsultansi", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("ruang", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("rumah dinas", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("perpipaan", df$ten_title) & grepl("air", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("sistem", df$ten_title) & grepl("air minum", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("jaringan", df$ten_title) & grepl("pengairan", df$ten_title) & is.na(df$cpv_code),452471111, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan", df$ten_title) & grepl("air bersih", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("jaringan", df$ten_title) & grepl("drainase", df$ten_title) & is.na(df$cpv_code),452324501, df$cpv_code)
df$cpv_code <- ifelse(grepl("konsultansi", df$ten_title) & grepl("drainase", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("lingkungan", df$ten_title) & grepl("drainase", df$ten_title) & is.na(df$cpv_code),452324501, df$cpv_code)
df$cpv_code <- ifelse(grepl("drainase", df$ten_title) & is.na(df$cpv_code),452324501, df$cpv_code)
df$cpv_code <- ifelse(grepl("konstruksi", df$ten_title) & grepl("manajemen", df$ten_title) & is.na(df$cpv_code),715400005, df$cpv_code)
df$cpv_code <- ifelse(grepl("peralatan kantor", df$ten_title) & is.na(df$cpv_code),301920001, df$cpv_code)
df$cpv_code <- ifelse(grepl("pengawasan teknis", df$ten_title) & is.na(df$cpv_code),716000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan rumah", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("jaringan", df$ten_title) & grepl("air bersih", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("sarana", df$ten_title) & grepl("air bersih", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("pengadaan bahan makanan", df$ten_title) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("makanan", df$ten_title) & is.na(df$cpv_code),150000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("kontruksi", df$ten_title) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("alat kedokteran", df$ten_title) & is.na(df$cpv_code),331000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("peraga pendidikan", df$ten_title) & is.na(df$cpv_code),391622007, df$cpv_code)
df$cpv_code <- ifelse(grepl("alat kesehatan", df$ten_title) & is.na(df$cpv_code),331000001, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi gedung kantor", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("cleaning service", df$ten_title) & is.na(df$cpv_code),909100009, df$cpv_code)
df$cpv_code <- ifelse(grepl("peralatan pendidikan", df$ten_title) & is.na(df$cpv_code),391620005, df$cpv_code)
df$cpv_code <- ifelse(grepl("pakaian dinas", df$ten_title) & is.na(df$cpv_code),181000000, df$cpv_code)
df$cpv_code <- ifelse(grepl("alat tulis kantor", df$ten_title) & is.na(df$cpv_code),301920001, df$cpv_code)
df$cpv_code <- ifelse(grepl("pemasangan pipa", df$ten_title) & is.na(df$cpv_code),452300008, df$cpv_code)
df$cpv_code <- ifelse(grepl("obat obatan", df$ten_title) & is.na(df$cpv_code),336000006, df$cpv_code)
df$cpv_code <- ifelse(grepl("engineering design", df$ten_title) & is.na(df$cpv_code),713200007, df$cpv_code)
df$cpv_code <- ifelse(grepl("bibit tanaman", df$ten_title) & is.na(df$cpv_code),31100005, df$cpv_code)
df$cpv_code <- ifelse(grepl("alat alat angkutan", df$ten_title) & is.na(df$cpv_code),340000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan rkb", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi perencanaan", df$ten_title) & is.na(df$cpv_code),713110001, df$cpv_code)
df$cpv_code <- ifelse(grepl("kontruksi", df$ten_title) & grepl("gedung kantor", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi gedung", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehab gedung", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan puskesmas", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("daerah irigasi", df$ten_title) & is.na(df$cpv_code),452321209, df$cpv_code)
df$cpv_code <- ifelse(grepl("air minum", df$ten_title) & is.na(df$cpv_code),452300008, df$cpv_code)
df$cpv_code <- ifelse(grepl("saluran irigasi", df$ten_title) & is.na(df$cpv_code),452321209, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan saluran", df$ten_title) & is.na(df$cpv_code),452400001, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi saluran", df$ten_title) & is.na(df$cpv_code),452400001, df$cpv_code)
df$cpv_code <- ifelse(grepl("perkuatan tebing", df$ten_title) & is.na(df$cpv_code),452400001, df$cpv_code)
df$cpv_code <- ifelse(grepl("technical support", df$ten_title) & is.na(df$cpv_code),713563001, df$cpv_code)
df$cpv_code <- ifelse(grepl("software", df$ten_title) & is.na(df$cpv_code),480000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan kantor", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan pagar", df$ten_title) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan poskesdes", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pemeliharaan gedung", df$ten_title) & is.na(df$cpv_code),507000002, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi puskesmas", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("culvert", df$ten_title) & is.na(df$cpv_code),452400001, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan balai", df$ten_title) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("irigasi air", df$ten_title) & is.na(df$cpv_code),452321209, df$cpv_code)
df$cpv_code <- ifelse(grepl("air tanah", df$ten_title) & is.na(df$cpv_code),452600007, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan dermaga", df$ten_title) & is.na(df$cpv_code),452414002, df$cpv_code)
df$cpv_code <- ifelse(grepl("konstruksi", df$ten_title) & grepl("konsultan", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("konstruksi", df$ten_title) & grepl("pengawasan", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("konstruksi", df$ten_title) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi penelitian", df$ten_title) & is.na(df$cpv_code),732100007, df$cpv_code)
df$cpv_code <- ifelse(grepl("pengolahan air limbah", df$ten_title) & is.na(df$cpv_code),452521274, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi jembatan", df$ten_title) & is.na(df$cpv_code),452210002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembuatan pagar", df$ten_title) & is.na(df$cpv_code),450000007, df$cpv_code)
df$cpv_code <- ifelse(grepl("penggantian jembatan", df$ten_title) & is.na(df$cpv_code),452210002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pengendalian banjir", df$ten_title) & is.na(df$cpv_code),452460003, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi rumah", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("bahan kimia", df$ten_title) & is.na(df$cpv_code),240000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("studi kelayakan", df$ten_title) & is.na(df$cpv_code),793140008, df$cpv_code)
df$cpv_code <- ifelse(grepl("rehabilitasi bangunan", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pembangunan asrama", df$ten_title) & is.na(df$cpv_code),452100002, df$cpv_code)
df$cpv_code <- ifelse(grepl("pupuk organik", df$ten_title) & is.na(df$cpv_code),143000004, df$cpv_code)
df$cpv_code <- ifelse(grepl("kendaraan bermotor", df$ten_title) & is.na(df$cpv_code),341000008, df$cpv_code)
df$cpv_code <- ifelse(grepl("jaringan perpipaan", df$ten_title) & is.na(df$cpv_code),452313008, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi", df$ten_title) & grepl("keuangan", df$ten_title) & is.na(df$cpv_code),661710009, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi", df$ten_title) & grepl("audit", df$ten_title) & is.na(df$cpv_code),661710009, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi", df$ten_title) & grepl("gedung", df$ten_title) & is.na(df$cpv_code),715300002, df$cpv_code)
df$cpv_code <- ifelse(grepl("jasa konsultansi", df$ten_title) & is.na(df$cpv_code),710000008, df$cpv_code)

df$check <- ifelse(grepl(paste(health$health_term, collapse = "|"), df$ten_title), 1,0)
df$cpv_code <- ifelse(df$check==1 & is.na(df$cpv_code),336000006, df$cpv_code)
df$cpv_code <- ifelse(df$cpv_code==983900003, NA, df$cpv_code)

df <- df %>% select(c('ten_id','ten_title_orig','cpv_code'))

data.table::fwrite(df,"ID_cpv_R.csv",
                   quote = TRUE, sep = "," )
