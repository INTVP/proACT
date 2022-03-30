df$bidder_name_edited[grepl('capital engineering', df$bidder_name_edited)] <- 'capital engineering LLC'
df$bidder_name_edited[grepl('global technology solutions', df$bidder_name_edited)] <- 'global technology solutions, inc'
