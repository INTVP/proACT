df$bidder_name_edited[grepl("gedetec",
                            df$bidder_name_edited,
                            ignore.case = T,
                            perl = T)] <- "gedetec, (sl)"

df$bidder_name_edited[grepl(
  "nihon kohden ib[eé]rica",
  df$bidder_name_edited,
  ignore.case = T,
  perl = T
)] <- "nihon kohden iberica (sl)"
df$bidder_name_edited[grepl(
  "oca construcciones y proyectos \\(sa\\)$",
  df$bidder_name_edited,
  ignore.case = T,
  perl = T
)] <- "oca construcciones y proyectos, (sa)"
df$bidder_name_edited[grepl(
  "convatec[, ]\\(s[l]\\)$",
  df$bidder_name_edited,
  ignore.case = T,
  perl = T
)] <- "convatec (sl)"
