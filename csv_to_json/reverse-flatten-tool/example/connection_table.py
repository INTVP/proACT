from utils import get_field_index


class ConnectionTable:
    conversion_table = {}
    mapping_table = {}
    reverse_mapping_table = {}

    reverse_flatten_table = []

    # Example for modification
    # use example_modification.csv as modification csv file in settings
    modification_table = [['persistent_id'], [['lot_indicator_type', ['lot_number']],
                                        ['lot_indicator_value', ['lot_number', 'lot_indicator_type']],
                                        ['lot_indicator_status', ['lot_number', 'lot_indicator_type']],
                                        ['tender_indicators'],
                                        ['lot_updatedprice', ['lot_number']],
                                        ['lot_updateddurationdays', ['lot_number']],
                                        ['net_amount', ['lot_number', 'currency']]
                                        ]
                          ]

    # Example for deleting list item
    # use Kenya_Modification_Test_del_list_item.csv as modification csv file in settings
    # modification_table = ['tender_id', 'bidder_name', 'DELETE_LIST_ITEM']

    # Example for deleting single json property
    # use Kenya_Modification_Test_del_property.csv as modification csv file in settings
    # modification_table = ['tender_id', 'currency', 'DELETE_PROPERTY']

    connection_table = [['persistentId', 'persistent_id'],
                        ['id', 'tender_id'],
                        ['title', 'tender_title'],
                        ['procedureType', 'tender_proceduretype'],
                        ['nationalProcedureType', 'tender_nationalproceduretype'],
                        ['isAwarded', 'tender_isawarded', ['str_to_bool']],
                        ['supplyType', 'tender_supplytype'],
                        ['bidDeadline', 'tender_biddeadline'],
                        ['isCentralProcurement', 'tender_iscentralprocurement', ['str_to_bool']],
                        ['isJointProcurement', 'tender_isjointprocurement', ['str_to_bool']],
                        ['onbehalfof_count', 'tender_onbehalfof_count'],
                        ['isOnBehalfOf', 'tender_isonbehalfof', ['str_to_bool']],
                        ['lotsCount', 'tender_lotscount', ['str_to_int_or_float']],
                        ['documents_count', 'tender_documents_count'],
                        ['lots[].bidsCount', 'tender_recordedbidscount', ['str_to_int_or_float']],
                        ['npwpReason[]', 'tender_npwp_reasons'],
                        ['isFrameworkAgreement', 'tender_isframeworkagreement', ['str_to_bool']],
                        ['isDps', 'tender_isdps', ['str_to_bool']],
                        ['estimatedDurationInDays', 'tender_estimateddurationindays', ['str_to_int_or_float']],
                        ['contractSignatureDate', 'tender_contractsignaturedate'],
                        ['Cpvs[].code', 'tender_cpvs'],
                        ['mainCpv', 'tender_maincpv', ['str_to_bool']],
                        ['isEUFunded', 'tender_iseufunded', ['str_to_bool']],
                        ['selectionMethod', 'tender_selectionmethod'],
                        ['isElectronicAuction', 'tender_iselectronicauction', ['str_to_bool']],
                        ['cancellationDate', 'tender_cancellationdate'],
                        ['cancellationReason', 'cancellation_reason'],
                        ['awardDecisionDate', 'tender_awarddecisiondate'],
                        ['isCoveredByGpa', 'tender_iscoveredbygpa', ['str_to_bool']],
                        ['eligibleBidLanguages[]', 'tender_eligiblebidlanguages'],
                        ['estimatedPrice', 'tender_estimatedprice', ['str_to_int_or_float']],
                        ['finalPrice', 'tender_finalprice', ['str_to_int_or_float']],
                        ['lots[].estimatedPrice', 'lot_estimatedprice', ['str_to_int_or_float']],
                        ['lots[].bids[].price.netAmount', 'bid_price', ['str_to_int_or_float']],
                        ['corrections_count', 'tender_corrections_count'],
                        ['lot_row_nr', 'lot_row_nr'],
                        ['lots[].lotNumber', 'lot_number', ['str_to_int_or_float']],
                        ['lots[].indicators[].type', 'lot_indicator_type'],
                        ['lots[].indicators[].value', 'lot_indicator_value', ['str_to_int_or_float']],
                        ['lots[].indicators[].status', 'lot_indicator_status'],
                        ['lots[].indicators', 'lot_indicators'],
                        ['lots[].title', 'lot_title'],
                        ['lots[].bidsCount', 'lot_bidscount', ['str_to_int_or_float']],
                        ['lots[].validBidsCount', 'lot_validbidscount', ['str_to_int_or_float']],
                        ['lots[].electronicBidsCount', 'lot_electronicbidscount', ['str_to_int_or_float']],
                        ['lots[].SMEBidsCount', 'lot_smebidscount', ['str_to_int_or_float']],
                        ['lots[].otherEUMemberStatesCompaniesBidsCount', 'lot_othereumemberstatescompaniesbidscount',
                         ['str_to_int_or_float']],
                        ['lots[].nonEUMemberStatesCompaniesBidsCount', 'lot_noneumemberstatescompaniesbidscount',
                         ['str_to_int_or_float']],
                        ['lots[].foreignCompaniesBidsCount', 'lot_foreigncompaniesbidscount', ['str_to_int_or_float']],
                        ['lot_amendmentscount', 'lot_amendmentscount'],
                        ['lots[].updatedPrice', 'lot_updatedprice', ['str_to_int_or_float']],
                        ['lots[].updatedCompletionDate', 'lot_updatedcompletiondate'],
                        ['lots[].updatedDuration.days', 'lot_updateddurationdays', ['str_to_int_or_float']],
                        ['buyers[].bodyIds[].id', 'buyer_id'],
                        ['buyers[].id', 'buyer_masterid'],
                        ['buyers[].name', 'buyer_name'],
                        ['buyers[].address.nuts[]', 'buyer_nuts'],
                        ['buyers[].email', 'buyer_email'],
                        ['buyers[].contactName', 'buyer_contactname'],
                        ['buyers[].contactPoint', 'buyer_contactpoint'],
                        ['buyers[].address.city', 'buyer_city'],
                        ['buyers[].address.country', 'buyer_country'],
                        ['buyers[].mainActivities[]', 'buyer_mainactivities'],
                        ['buyers[].buyerType', 'buyer_buyertype'],
                        ['buyers[].indicators[].type', 'buyer_indicator_type'],
                        ['buyers[].indicators[].value', 'buyer_indicator_value', ['str_to_int_or_float']],
                        ['buyers[].indicators[].status', 'buyer_indicator_status'],
                        ['lots[].bids[].bidders[].bodyIds[].id', 'bidder_id'],
                        ['lots[].bids[].bidders[].id', 'bidder_masterid'],
                        ['lots[].bids[].bidders[].name', 'bidder_name'],
                        ['lots[].bids[].bidders[].address.nuts[]', 'bidder_nuts'],
                        ['lots[].bids[].bidders[].address.postcode', 'bidder_postcode'],
                        ['lots[].bids[].bidders[].address.city', 'bidder_city'],
                        ['lots[].bids[].bidders[].address.country', 'bidder_country'],
                        ['lots[].bids[].isWinning', 'bid_iswinning', ['str_to_bool']],
                        ['lots[].bids[].isSubcontracted', 'bid_issubcontracted', ['str_to_bool']],
                        ['lots[].bids[].subcontractedProportion', 'bid_subcontractedproportion'],
                        ['lots[].bids[].isConsortium', 'bid_isconsortium', ['str_to_bool']],
                        ['lots[].bids[].price.currency', 'currency'],
                        ['lots[].bids[].price.netAmount', 'net_amount', ['str_to_int_or_float']],
                        ['lots[].bids[].digiwhistPrice.netAmount', 'bid_digiwhist_price', ['str_to_int_or_float']],
                        ['award_count', 'award_count', ['str_to_int_or_float']],
                        ['notice_count', 'notice_count', ['str_to_int_or_float']],
                        ['publications[].source', 'source'],
                        ['publications[].lastContractAwardURL', 'tender_publications_lastcontractawardurl'],
                        ['publications[].firstDContractAwardDate', 'tender_publications_firstdcontractawarddate'],
                        ['publications[].humanReadableURL', 'notice_url'],
                        ['publications_lastcallfortenderdate', 'tender_publications_lastcallfortenderdate'],
                        ['publications_firstcallfortenderdate', 'tender_publications_firstcallfortenderdate'],
                        ['year', 'tender_year', ['str_to_int_or_float']],
                        ['savings', 'savings'],
                        ['award_period_length', 'award_period_length'],
                        ['addressOfImplementation.nuts[]', 'tender_addressofimplementation_nuts'],
                        ['description_length', 'tender_description_length'],
                        ['lot_description_length', 'lot_description_length'],
                        ['personalrequirements_length', 'tender_personalrequirements_length'],
                        ['technicalrequirements_length', 'tender_technicalrequirements_length'],
                        ['economicrequirements_length', 'tender_economicrequirements_length'],
                        ['indicators[].type', 'tender_indicator_type'],
                        ['indicators[].value', 'tender_indicator_value', ['str_to_int_or_float']],
                        ['indicators[].status', 'tender_indicator_status'],
                        ['indicators', 'tender_indicators'],
                        ['opentender', 'opentender'],
                        ['digiwhist_price', 'tender_digiwhist_price'],
                        ['recordedbidscount', 'tender_recordedbidscount'],
                        ['awardcriteria_count', 'tender_awardcriteria_count'],
                        ['payments_sum', 'payments_sum'],
                        ['last_payment_year', 'last_payment_year']]

    id_fields = ['persistent_id']
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
