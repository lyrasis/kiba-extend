# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module Cspace
        # @since 2.8.0
        #
        # Converts existing value of :addresscountry to required optionslist
        #   value for country, based on ISO 3166 code.
        #
        # Prints warnings:
        #
        # - Cannot map addresscountry: No mapping for country value: Shangri-La
        # - Cannot map addresscountry: Field `country` does not exist in source
        #   data (triggered by last row)
        #
        # @note It is expected that this will need to be updated per client data
        #   set. Just add required values to the LOOKUP and make a pull request.
        #
        # @example Default: source/target field is `:addresscountry`
        #   # Used in pipeline as:
        #   # transform Cspace::AddressCountry
        #   xform = Cspace::AddressCountry.new
        #   input = [
        #     {addresscountry: 'Viet Nam'},
        #     {addresscountry: 'Shangri-La'},
        #     {addresscountry: ''},
        #     {addresscountry: nil},
        #     {addresscountry: 'LU'},
        #     {foo: 'bar'}
        #   ]
        #   nomap = "KIBA WARNING: Cannot map addresscountry: No mapping for "\
        #     "addresscountry value: Shangri-La"
        #   expect(xform).to receive(:warn).with(nomap)
        #   nofield = "KIBA WARNING: Cannot map addresscountry: Field "\
        #     "`addresscountry` does not exist in source data"
        #   expect(xform).to receive(:warn).with(nofield)
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #    {addresscountry: 'VN'},
        #    {addresscountry: nil},
        #    {addresscountry: ''},
        #    {addresscountry: nil},
        #    {addresscountry: 'LU'},
        #    {foo: 'bar', addresscountry: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Custom source field name without `keep_orig`
        #   # Used in pipeline as:
        #   # transform Cspace::AddressCountry,
        #   #   source: :country,
        #   #   keep_orig: false
        #   xform = Cspace::AddressCountry.new(source: :country, keep_orig: false)
        #   input = [
        #     {country: 'Viet Nam'},
        #     {country: 'Shangri-La'},
        #     {country: ''},
        #     {country: nil},
        #     {foo: 'bar'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #    {addresscountry: 'VN'},
        #    {addresscountry: nil},
        #    {addresscountry: ''},
        #    {addresscountry: nil},
        #    {foo: 'bar', addresscountry: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example `keep_orig`
        #   # Used in pipeline as:
        #   # transform Cspace::AddressCountry,
        #   #   source: :country,
        #   #   keep_orig: true
        #   xform = Cspace::AddressCountry.new(
        #     source: :country,
        #     keep_orig: true)
        #   input = [
        #     {country: 'Viet Nam'},
        #     {country: 'Shangri-La'},
        #     {country: ''},
        #     {country: nil},
        #     {foo: 'bar'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #    {country: 'Viet Nam', addresscountry: 'VN'},
        #    {country: 'Shangri-La', addresscountry: nil},
        #    {country: '', addresscountry: ''},
        #    {country: nil, addresscountry: nil},
        #    {foo: 'bar', addresscountry: nil}
        #   ]
        #   expect(result).to eq(expected)
        class AddressCountry
          include SingleWarnable

          LOOKUP = {
            "Afghanistan" => "AF",
            "Åland Islands" => "AX",
            "Albania" => "AL",
            "Algeria" => "DZ",
            "American Samoa" => "AS",
            "Andorra" => "AD",
            "Angola" => "AO",
            "Anguilla" => "AI",
            "Antarctica" => "AQ",
            "Antigua and Barbuda" => "AG",
            "Argentina" => "AR",
            "Armenia" => "AM",
            "Aruba" => "AW",
            "Australia" => "AU",
            "Austria" => "AT",
            "Azerbaijan" => "AZ",
            "Bahamas (the)" => "BS",
            "Bahrain" => "BH",
            "Bangladesh" => "BD",
            "Barbados" => "BB",
            "Belarus" => "BY",
            "Belgium" => "BE",
            "Belize" => "BZ",
            "Benin" => "BJ",
            "Bermuda" => "BM",
            "Bhutan" => "BT",
            "Bolivia (Plurinational State of)" => "BO",
            "Bonaire, Sint Eustatius and Saba" => "BQ",
            "Bosnia and Herzegovina" => "BA",
            "Botswana" => "BW",
            "Bouvet Island" => "BV",
            "Brazil" => "BR",
            "British Indian Ocean Territory (the)" => "IO",
            "Brunei Darussalam" => "BN",
            "Bulgaria" => "BG",
            "Burkina Faso" => "BF",
            "Burundi" => "BI",
            "Cambodia" => "KH",
            "Cameroon" => "CM",
            "Canada" => "CA",
            "Cape Verde" => "CV",
            "Cayman Islands (the)" => "KY",
            "Central African Republic (the)" => "CF",
            "Chad" => "TD",
            "Chile" => "CL",
            "China" => "CN",
            "Christmas Island" => "CX",
            "Cocos (Keeling) Islands (the)" => "CC",
            "Colombia" => "CO",
            "Comoros (the)" => "KM",
            "Congo (the)" => "CG",
            "Congo (the Democratic Republic of the)" => "CD",
            "Cook Islands (the)" => "CK",
            "Costa Rica" => "CR",
            "Côte d'Ivoire" => "CI",
            "Croatia" => "HR",
            "Cuba" => "CU",
            "Curaçao" => "CW",
            "Cyprus" => "CY",
            "Czechia" => "CZ",
            "Denmark" => "DK",
            "Djibouti" => "DJ",
            "Dominica" => "DM",
            "Dominican Republic (the)" => "DO",
            "Ecuador" => "EC",
            "Egypt" => "EG",
            "El Salvador" => "SV",
            "England" => "GB",
            "Equatorial Guinea" => "GQ",
            "Eritrea" => "ER",
            "Estonia" => "EE",
            "Ethiopia" => "ET",
            "Falkland Islands (the) [Malvinas]" => "FK",
            "Faroe Islands (the)" => "FO",
            "Fiji" => "FJ",
            "Finland" => "FI",
            "France" => "FR",
            "French Guiana" => "GF",
            "French Polynesia" => "PF",
            "French Southern Territories (the)" => "TF",
            "Gabon" => "GA",
            "Gambia (the)" => "GM",
            "Georgia" => "GE",
            "Germany" => "DE",
            "Ghana" => "GH",
            "Gibraltar" => "GI",
            "Greece" => "GR",
            "Greenland" => "GL",
            "Grenada" => "GD",
            "Guadeloupe" => "GP",
            "Guam" => "GU",
            "Guatemala" => "GT",
            "Guernsey" => "GG",
            "Guinea" => "GN",
            "Guinea-Bissau" => "GW",
            "Guyana" => "GY",
            "Haiti" => "HT",
            "Heard Island and McDonald Islands" => "HM",
            "Holy See (the)" => "VA",
            "Honduras" => "HN",
            "Hong Kong" => "HK",
            "Hungary" => "HU",
            "Iceland" => "IS",
            "India" => "IN",
            "Indonesia" => "ID",
            "Iran (Islamic Republic of)" => "IR",
            "Iraq" => "IQ",
            "Ireland" => "IE",
            "Isle of Man" => "IM",
            "Israel" => "IL",
            "Italy" => "IT",
            "Jamaica" => "JM",
            "Japan" => "JP",
            "Jersey" => "JE",
            "Jordan" => "JO",
            "Kazakhstan" => "KZ",
            "Kenya" => "KE",
            "Kiribati" => "KI",
            "Korea (the Democratic People's Republic of)" => "KP",
            "Korea (the Republic of)" => "KR",
            "Kuwait" => "KW",
            "Kyrgyzstan" => "KG",
            "Lao People's Democratic Republic (the)" => "LA",
            "Latvia" => "LV",
            "Lebanon" => "LB",
            "Lesotho" => "LS",
            "Liberia" => "LR",
            "Libya" => "LY",
            "Liechtenstein" => "LI",
            "Lithuania" => "LT",
            "Luxembourg" => "LU",
            "Macao" => "MO",
            "Macedonia (the former Yugoslav Republic of)" => "MK",
            "Madagascar" => "MG",
            "Malawi" => "MW",
            "Malaysia" => "MY",
            "Maldives" => "MV",
            "Mali" => "ML",
            "Malta" => "MT",
            "Marshall Islands (the)" => "MH",
            "Martinique" => "MQ",
            "Mauritania" => "MR",
            "Mauritius" => "MU",
            "Mayotte" => "YT",
            "Mexico" => "MX",
            "Mexico, D.F." => "MX",
            "Mexico D.V." => "MX",
            "Micronesia (Federated States of)" => "FM",
            "Moldova (the Republic of)" => "MD",
            "Monaco" => "MC",
            "Mongolia" => "MN",
            "Montenegro" => "ME",
            "Montserrat" => "MS",
            "Morocco" => "MA",
            "Mozambique" => "MZ",
            "Myanmar" => "MM",
            "Namibia" => "NA",
            "Nauru" => "NR",
            "Nepal" => "NP",
            "Netherlands" => "NL",
            "Netherlands (the)" => "NL",
            "New Caledonia" => "NC",
            "New Zealand" => "NZ",
            "Nicaragua" => "NI",
            "Niger (the)" => "NE",
            "Nigeria" => "NG",
            "Niue" => "NU",
            "Norfolk Island" => "NF",
            "Northern Mariana Islands (the)" => "MP",
            "Norway" => "NO",
            "Oman" => "OM",
            "Pakistan" => "PK",
            "Palau" => "PW",
            "Palestine, State of" => "PS",
            "Panama" => "PA",
            "Papua New Guinea" => "PG",
            "Paraguay" => "PY",
            "Peru" => "PE",
            "Philippines (the)" => "PH",
            "Pitcairn" => "PN",
            "Poland" => "PL",
            "Portugal" => "PT",
            "Puerto Rico" => "PR",
            "Qatar" => "QA",
            "Réunion" => "RE",
            "Romania" => "RO",
            "Russia" => "RU",
            "Russian Federation (the)" => "RU",
            "Rwanda" => "RW",
            "Saint Barthélemy" => "BL",
            "Saint Helena, Ascension and Tristan da Cunha" => "SH",
            "Saint Kitts and Nevis" => "KN",
            "Saint Lucia" => "LC",
            "Saint Martin (French part)" => "MF",
            "Saint Pierre and Miquelon" => "PM",
            "Saint Vincent and the Grenadines" => "VC",
            "Samoa" => "WS",
            "San Marino" => "SM",
            "Sao Tome and Principe" => "ST",
            "Saudi Arabia" => "SA",
            "Scotland" => "GB",
            "Senegal" => "SN",
            "Serbia" => "RS",
            "Seychelles" => "SC",
            "Sierra Leone" => "SL",
            "Singapore" => "SG",
            "Sint Maarten (Dutch part)" => "SX",
            "Slovakia" => "SK",
            "Slovenia" => "SI",
            "Solomon Islands" => "SB",
            "Somalia" => "SO",
            "South Africa" => "ZA",
            "South Georgia and the South Sandwich Islands" => "GS",
            "South Sudan" => "SS",
            "Spain" => "ES",
            "Sri Lanka" => "LK",
            "Sudan" => "SD",
            "Sudan (the)" => "SD",
            "Suriname" => "SR",
            "Svalbard and Jan Mayen" => "SJ",
            "Swaziland" => "SZ",
            "Sweden" => "SE",
            "Switzerland" => "CH",
            "Syria" => "SY",
            "Syrian Arab Republic" => "SY",
            "Taiwan" => "TW",
            "Taiwan (Province of China)" => "TW",
            "Tajikistan" => "TJ",
            "Tanzania, United Republic of" => "TZ",
            "Thailand" => "TH",
            "Timor-Leste" => "TL",
            "Togo" => "TG",
            "Tokelau" => "TK",
            "Tonga" => "TO",
            "Trinidad and Tobago" => "TT",
            "Tunisia" => "TN",
            "Turkey" => "TR",
            "Turkmenistan" => "TM",
            "Turks and Caicos Islands (the)" => "TC",
            "Tuvalu" => "TV",
            "Uganda" => "UG",
            "Ukraine" => "UA",
            "United Arab Emirates" => "AE",
            "United Arab Emirates (the)" => "AE",
            "United Kingdom" => "GB",
            "United Kingdom (UK)" => "GB",
            "United Kingdom of Great Britain and Northern Ireland (the)" => "GB",
            "United States" => "US",
            "United States of America" => "US",
            "United States of America (the)" => "US",
            "United States Minor Outlying Islands (the)" => "UM",
            "Uruguay" => "UY",
            "U.S." => "US",
            "U.S. Virgin Islands" => "VI",
            "U.S.A." => "US",
            "USA" => "US",
            "Uzbekistan" => "UZ",
            "Vanuatu" => "VU",
            "Venezuela (Bolivarian Republic of)" => "VE",
            "Viet Nam" => "VN",
            "Virgin Islands (British)" => "VG",
            "Virgin Islands (U.S.)" => "VI",
            "Wallis and Futuna" => "WF",
            "Western Sahara" => "EH",
            "Yemen" => "YE",
            "Zambia" => "ZM",
            "Zimbabwe" => "ZW"
          }

          # @param source [Symbol] field containing value to look up and map
          # @param target [Symbol] field in which to write ISO 3166 code
          # @param keep_orig [Boolean] whether to delete source field after
          #   mapping
          # @note If `keep_orig = false` and the source value couldn't be
          #   mapped, the output will not contain the original value at all. You
          #   should receive warnings to STDOUT indicating which values were
          #    unmappable
          # @note `keep_orig` has no effect if you are doing an in-place
          #   transform (i.e. your `source` and `target` values are the same
          def initialize(source: :addresscountry, target: :addresscountry,
            keep_orig: true)
            @source = source
            @target = target
            @keep_orig = keep_orig
            setup_single_warning
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row[target] = nil unless in_place?
            row.key?(source) ? handle_source(row) : handle_missing_source(row)
          end

          private

          attr_reader :source, :target, :keep_orig

          def delete_source(row)
            row.delete(source) unless in_place? || keep_orig
            row
          end

          def do_mapping(val, row)
            row[target] = lookup(val)
            delete_source(row)
          end

          def lookup(val)
            return val if LOOKUP.value?(val)

            LOOKUP[val]
          end

          def handle_source(row)
            sourceval = row[source]
            return handle_blank_source(sourceval, row) if sourceval.blank?

            handle_source_value(sourceval, row)
          end

          def handle_blank_source(val, row)
            row[target] = val
            delete_source(row)
          end

          def handle_missing_source(row)
            add_single_warning("Cannot map addresscountry: Field `#{source}` "\
                               "does not exist in source data")
            row[target] = nil
            row
          end

          def handle_source_value(val, row)
            return do_mapping(val, row) if LOOKUP.key?(val) ||
              LOOKUP.value?(val)

            handle_unmapped(val, row)
          end

          def handle_unmapped(val, row)
            add_single_warning("Cannot map addresscountry: No mapping for "\
                               "#{source} value: #{val}")
            row[target] = nil
            delete_source(row)
          end

          def in_place?
            source == target
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
