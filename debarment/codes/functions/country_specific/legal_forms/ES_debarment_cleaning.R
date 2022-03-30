df$bidder_name_edited[grepl("gedetec", df$bidder_name_edited, ignore.case = T, perl = T)] <- "gedetec, (sl)"
df$bidder_name_edited[grepl("oca construcciones y proyectos",df$bidder_name_edited, ignore.case = T, perl = T)] <- "oca construcciones y proyectos, (sa)"
