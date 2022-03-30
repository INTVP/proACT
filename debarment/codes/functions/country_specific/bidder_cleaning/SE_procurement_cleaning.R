df$bidder_name_edited <-
  gsub("\\(germany\\)", "", df$bidder_name_edited, perl = TRUE)
df$bidder_name_edited[grepl('dipling ruppmann verbrennungsanlagen', df$bidder_name_edited)] <-
  "dipl-ing ruppmann verbrennungsanlagen"
df$bidder_name_edited[grepl('nihon koden', df$bidder_name_edited)] <-
  "nihon koden europe gmbh"
df$bidder_name_edited[grepl('nihon kohden deutschland', df$bidder_name_edited)] <-
  "nihon kohden deutschland gmbh"
df$bidder_name_edited[grepl('j mitra and company ltd', df$bidder_name_edited)] <-
  "j mitra & co private limited"
df$bidder_name_edited[grepl('indian progressive construction', df$bidder_name_edited)] <-
  "progressive constructions limited"
