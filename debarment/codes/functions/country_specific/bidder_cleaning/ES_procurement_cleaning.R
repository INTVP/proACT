df$bidder_name_edited <-
  gsub(
    "\\(?\\w?\\s?-?\\s?\\d{4,}\\)?",
    "",
    df$bidder_name_edited,
    perl = T,
    ignore.case = T
  )
df$bidder_name_edited <-
  gsub(
    "^\\d{1,2}\\.?\\)\\s?",
    "",
    df$bidder_name_edited,
    perl = T,
    ignore.case = T
  )
df$bidder_name_edited <-
  gsub("\\)", "", df$bidder_name_edited, perl = TRUE)
df$bidder_name_edited <-
  gsub("\\(", "", df$bidder_name_edited, perl = TRUE)
