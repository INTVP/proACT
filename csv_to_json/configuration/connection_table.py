from utils import get_field_index


class ConnectionTable:
    conversion_table = {}
    mapping_table = {}
    reverse_mapping_table = {}

    reverse_flatten_table = [['tender_id'], [['tender_id'],
                                            ['lot_number'],
                                            ['bid_number'],
                                            ['bid_iswinning', ['lot_number', 'bid_number']],
                                            ['tender_country'],
                                            ['tender_awarddecisiondate', ['lot_number']],
                                            ['tender_contractsignaturedate', ['lot_number']],
                                            ['tender_biddeadline'],
                                            ['tender_proceduretype'],
                                            ['tender_supplytype'],
                                            ['tender_publications_notice_type'],
                                            ['tender_publications_firstcallfortenderdate', ['tender_publications_notice_type']],
                                            ['notice_url', ['tender_publications_notice_type']],
                                            ['source', ['tender_publications_notice_type']],
                                            ['tender_publications_award_type'],
                                            ['tender_publications_firstdcontractawarddate', ['tender_publications_award_type']],
                                            ['tender_publications_lastcontractawardurl', ['tender_publications_award_type']],
                                            ['source', ['tender_publications_award_type']],
                                            ['buyer_masterid'],
                                            ['buyer_id', ['buyer_masterid']],
                                            ['buyer_city', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_postcode', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_country', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_nuts', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_name', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_buyertype', ['buyer_id', ['buyer_masterid']]],
                                            ['buyer_mainactivities', ['buyer_id', ['buyer_masterid']]],
                                            ['tender_addressofimplementation_country', ['lot_number']],
                                            ['tender_addressofimplementation_nuts', ['lot_number']],
                                            ['bidder_masterid', ['lot_number', 'bid_number']],
                                            ['bidder_id', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bidder_country', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bidder_nuts', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bidder_name', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bid_priceUsd', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bid_price', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bid_priceCurrency', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bidder_previousSanction', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['bidder_hasSanction', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['sanct_startdate', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['sanct_enddate', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['sanct_name', ['lot_number', 'bid_number', 'bidder_masterid']],
                                            ['lot_productCode', ['lot_number']],
                                            ['lot_localProductCode_type', ['lot_number']],
                                            ['lot_localProductCode', ['lot_number', 'lot_localProductCode_type']],
                                            ['lot_title', ['lot_number']],
                                            ['lot_bidscount', ['lot_number']],
                                            ['lot_estimatedpriceUsd', ['lot_number']],
                                            ['lot_estimatedprice', ['lot_number']],
                                            ['lot_estimatedpriceCurrency', ['lot_number']]]
                             ]

    # Example for modification
    # use example_modification.csv as modification csv file in settings
    modification_table = []

    # Example for deleting list item
    # use Kenya_Modification_Test_del_list_item.csv as modification csv file in settings
    # modification_table = ['tender_id', 'bidder_name', 'DELETE_LIST_ITEM']

    # Example for deleting single json property
    # use Kenya_Modification_Test_del_property.csv as modification csv file in settings
    # modification_table = ['tender_id', 'currency', 'DELETE_PROPERTY']

    connection_table = [['id', 'tender_id'],
                        ['country', 'tender_country'],
                        ['awardDecisionDate', 'tender_awarddecisiondate'],
                        ['contractSignatureDate', 'tender_contractsignaturedate'],
                        ['bidDeadline', 'tender_biddeadline'],
                        ['procedureType', 'tender_proceduretype'],
                        ['supplyType', 'tender_supplytype'],
                        ['publications[].formType', 'tender_publications_award_type'],
                        ['publications[].publicationDate', 'tender_publications_firstdcontractawarddate'],
                        ['publications[].humanReadableURL', 'tender_publications_lastcontractawardurl'],
                        ['publications[].formType', 'tender_publications_notice_type'],
                        ['publications[].publicationDate', 'tender_publications_firstcallfortenderdate'],
                        ['publications[].humanReadableURL', 'notice_url'],
                        ['publications[].source', 'source'],
                        ['buyers[].id', 'buyer_masterid'],
                        ['buyers[].address.city', 'buyer_city'],
                        ['buyers[].address.postcode', 'buyer_postcode'],
                        ['buyers[].address.country', 'buyer_country'],
                        ['buyers[].address.geoCodes', 'buyer_nuts'],
                        ['buyers[].name', 'buyer_name'],
                        ['buyers[].bodyIds[].id', 'buyer_id'],
                        ['buyers[].buyerType', 'buyer_buyertype'],
                        ['buyers[].mainActivities', 'buyer_mainactivities'],
                        ['lots[].lotNumber', 'lot_number', ['str_to_int_or_float']],
                        ['lots[].addressOfImplementation.country', 'tender_addressofimplementation_country'],
                        ['lots[].addressOfImplementation.geoCodes', 'tender_addressofimplementation_nuts'],
                        ['lots[].bids[].bidNumber', 'bid_number', ['str_to_int_or_float']],
                        ['lots[].bids[].bidders[].id', 'bidder_masterid'],
                        ['lots[].bids[].bidders[].address.country', 'bidder_country'],
                        ['lots[].bids[].bidders[].address.geoCodes', 'bidder_nuts'],
                        ['lots[].bids[].bidders[].name', 'bidder_name'],
                        ['lots[].bids[].bidders[].bodyIds[].id', 'bidder_id'],
                        ['lots[].bids[].bidders[].previousSanction', 'bidder_previousSanction', ['str_to_bool']],
                        ['lots[].bids[].bidders[].hasSanction', 'bidder_hasSanction', ['str_to_bool']],
                        ['lots[].bids[].bidders[].sanctions[].startDate', 'sanct_startdate'],
                        ['lots[].bids[].bidders[].sanctions[].endDate', 'sanct_enddate'],
                        ['lots[].bids[].bidders[].sanctions[].sanctioningAuthority.name', 'sanct_name'],
                        ['lots[].bids[].price.netAmountUsd', 'bid_priceUsd', ['str_to_int_or_float']],
                        ['lots[].bids[].price.netAmountNational', 'bid_price', ['str_to_int_or_float']],
                        ['lots[].bids[].price.currencyNational', 'bid_priceCurrency'],
                        ['lots[].bids[].isWinning', 'bid_iswinning', ['str_to_bool']],
                        ['lots[].productCodes[].code', 'lot_productCode'],
                        ['lots[].localProductCodes[].code', 'lot_localProductCode'],
                        ['lots[].localProductCodes[].type', 'lot_localProductCode_type'],
                        ['lots[].indicators', 'indicators'],
                        ['lots[].title', 'lot_title'],
                        ['lots[].bidsCount', 'lot_bidscount', ['str_to_int_or_float']],
                        ['lots[].estimatedPrice.netAmountUsd', 'lot_estimatedpriceUsd', ['str_to_int_or_float']],
                        ['lots[].estimatedPrice.netAmountNational', 'lot_estimatedprice', ['str_to_int_or_float']],
                        ['lots[].estimatedPrice.currencyNational', 'lot_estimatedpriceCurrency'],
                        ['lots[].awardDecisionDate', 'lot_awarddecisiondate'],
                        ['lots[].contractSignatureDate', 'lot_contractsignaturedate']
                        ]
    id_fields = ['tender_id', 'lot_number']
    id_field_indices = []

    def __init__(self, settings):
        self.settings = settings

    def get_connection_table(self):
        return self.connection_table

    def init_connection_table(self, header):
        self.id_field_indices = []
        for id_field in self.id_fields:
            field_index = get_field_index(header, id_field)
            self.id_field_indices.append(field_index)

        for row in self.connection_table:
            self.mapping_table[row[1]] = row[0]
            if row[0] not in self.reverse_mapping_table:
                self.reverse_mapping_table[row[0]] = []
            self.reverse_mapping_table[row[0]].append(row[1])

        self.make_conversion_table()

    def make_conversion_table(self):
        for conn_table_row in self.connection_table:
            temp_list = []

            if len(conn_table_row) >= 3:
                temp_list = conn_table_row[2]

            self.conversion_table[conn_table_row[1]] = temp_list

    def get_row_id(self, row):  # returns the concatenated row id values
        result = ""
        if len(row) > 0:
            for id_field_index in self.id_field_indices:
                result += str(row[id_field_index])
            return result
        else:
            return -1
