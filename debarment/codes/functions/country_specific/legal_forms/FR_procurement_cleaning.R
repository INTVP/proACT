df$bidder_name_edited[grepl(
  'Eckert (&|et) Ziegler Bebig',
  df$bidder_name_edited,
  perl = T,
  ignore.case = T
)] <-
  'eckert & ziegler bebig gmbh'
