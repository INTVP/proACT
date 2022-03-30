df$bidder_name_edited[grepl('dipling ruppmann verbrennungsanlagen',
                            df$bidder_name_edited)] <- "dipl-ing ruppmann verbrennungsanlagen"
df$bidder_name_edited[grepl('nihon koden', df$bidder_name_edited)] <-
  "nihon koden europe gmbh"
df$bidder_name_edited[grepl('nihon kohden deutschland', df$bidder_name_edited)] <-
  "nihon kohden deutschland gmbh"
