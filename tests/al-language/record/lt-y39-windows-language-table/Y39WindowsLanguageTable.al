// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: none (self-contained test codeunit 92700)
// Probe: observe probe (writer Y39, 2026-10-31, al-runner issue 6558, corpus issue 955). Every row of the system table Windows Language
//   (2000000045), read through a RecordRef: 16 fields (1 Language ID, 2 Primary Language ID, 10 Name, 11 Abbreviated Name, 20 Enabled,
//   21 Globally Enabled, 22 Form Enabled, 23 Report Enabled, 24 Dataport Enabled, 25 XMLport Enabled, 30 Primary CodePage,
//   31 STX File Exist, 32 ETX File Exist, 33 Help File Exist, 34 Localization Exist, 35 Language Tag), primary key Language ID.
//   Each expected row below is "<field values in that order>" joined by '|'.
// Facts: Windows BC 27.5 and 28.5 containers and a BC 29 SaaS sandbox give the same 248 rows. The one difference: Primary CodePage of
//   44 rows (Armenian, Georgian, Hindi and other languages with no OEM code page) is '65001' on Windows 27.5/28.5 and '1' on SaaS 29
//   (Utf8CodePage(); no Windows BC 29 container answered, so the split is by major).
// Linux suspect: the Linux CI containers build the table from ICU culture data, not Windows NLS data, and differ from Windows and SaaS
//   (aldevtools/MsDyn365Bc.On.Linux issue 198 covers the Chinese ids): other culture names (1027 'Catalan (Spain)' for 'Catalan (Catalan)',
//   2107 'Northern Sami (Sweden)' for 'Sami, Northern (Sweden)'), rows that do not exist there (9225 en-029, 1028 zh-TW, 3076, 4100, 5124 and
//   more), an extra row 31748 zh-Hant, and Primary CodePage '1' on BC 27/28. The [Test] procedures check the rows on which Linux agrees;
//   the Suspect_ procedures (no [Test]) hold the Windows/SaaS values of the other rows, the row count and the full walk.

// Linux CI (rows, rows equal to Windows/SaaS, extra rows): 27.5 (208, 150, 1), 28.5 (208, 150, 1), 29.0 (208, 180, 1).
// BC versions: 27, 28, 29

codeunit 92700 "LT Y39 WinLang Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Expected: Dictionary of [Integer, Text];
        AllIds: List of [Integer];

    local procedure Utf8CodePage(): Text
    begin
#if BC29PLUS
        exit('1');
#else
        exit('65001');
#endif
    end;

    local procedure RowText(var WindowsLanguage: Record "Windows Language"): Text
    begin
        exit(Format(WindowsLanguage."Language ID", 0, 9) + '|' + Format(WindowsLanguage."Primary Language ID", 0, 9) + '|' +
            WindowsLanguage.Name + '|' + WindowsLanguage."Abbreviated Name" + '|' +
            Format(WindowsLanguage.Enabled) + '|' + Format(WindowsLanguage."Globally Enabled") + '|' +
            Format(WindowsLanguage."Form Enabled") + '|' + Format(WindowsLanguage."Report Enabled") + '|' +
            Format(WindowsLanguage."Dataport Enabled") + '|' + Format(WindowsLanguage."XMLport Enabled") + '|' +
            WindowsLanguage."Primary CodePage" + '|' +
            Format(WindowsLanguage."STX File Exist") + '|' + Format(WindowsLanguage."ETX File Exist") + '|' +
            Format(WindowsLanguage."Help File Exist") + '|' + Format(WindowsLanguage."Localization Exist") + '|' +
            WindowsLanguage."Language Tag");
    end;

    local procedure Check(LanguageId: Integer)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        Load();
        if not WindowsLanguage.Get(LanguageId) then
            Error('Windows Language %1: no row, expected [%2]', LanguageId, Expected.Get(LanguageId));
        if RowText(WindowsLanguage) <> Expected.Get(LanguageId) then
            Error('Windows Language %1: expected [%2], got [%3]', LanguageId, Expected.Get(LanguageId), RowText(WindowsLanguage));
    end;

    local procedure AddRow(LanguageId: Integer; Row: Text)
    begin
        Expected.Add(LanguageId, Row);
        AllIds.Add(LanguageId);
    end;

    local procedure Load()
    begin
        if Expected.Count() > 0 then
            exit;
        AddRow(1025, '1025|1025|Arabic (Saudi Arabia)|ARA|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-SA');
        AddRow(1026, '1026|1026|Bulgarian (Bulgaria)|BGR|Yes|Yes|Yes|Yes|No|Yes|866|Yes|Yes|No|Yes|bg-BG');
        AddRow(1027, '1027|1027|Catalan (Catalan)|CAT|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ca-ES');
        AddRow(1028, '1028|1028|Chinese (Traditional, Taiwan)|CHT|Yes|Yes|Yes|Yes|No|Yes|950|Yes|Yes|No|Yes|zh-TW');
        AddRow(1029, '1029|1029|Czech (Czechia)|CSY|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|cs-CZ');
        AddRow(1030, '1030|1030|Danish (Denmark)|DAN|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|da-DK');
        AddRow(1031, '1031|1031|German (Germany)|DEU|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|de-DE');
        AddRow(1032, '1032|1032|Greek (Greece)|ELL|Yes|Yes|Yes|Yes|No|Yes|737|Yes|Yes|No|Yes|el-GR');
        AddRow(1033, '1033|1033|English (United States)|ENU|Yes|Yes|Yes|Yes|No|Yes|437|Yes|Yes|No|Yes|en-US');
        AddRow(1034, '1034|1034|Spanish (Spain, Traditional Sort)|ESP|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|es-ES');
        AddRow(1035, '1035|1035|Finnish (Finland)|FIN|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|fi-FI');
        AddRow(1036, '1036|1036|French (France)|FRA|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|fr-FR');
        AddRow(1037, '1037|1037|Hebrew (Israel)|HEB|Yes|Yes|Yes|Yes|No|Yes|862|No|No|No|No|he-IL');
        AddRow(1038, '1038|1038|Hungarian (Hungary)|HUN|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|hu-HU');
        AddRow(1039, '1039|1039|Icelandic (Iceland)|ISL|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|is-IS');
        AddRow(1040, '1040|1040|Italian (Italy)|ITA|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|it-IT');
        AddRow(1041, '1041|1041|Japanese (Japan)|JPN|Yes|Yes|Yes|Yes|No|Yes|932|Yes|Yes|No|Yes|ja-JP');
        AddRow(1042, '1042|1042|Korean (Korea)|KOR|Yes|Yes|Yes|Yes|No|Yes|949|Yes|Yes|No|Yes|ko-KR');
        AddRow(1043, '1043|1043|Dutch (Netherlands)|NLD|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|nl-NL');
        AddRow(1044, '1044|1044|Norwegian Bokmål (Norway)|NOR|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|nb-NO');
        AddRow(1045, '1045|1045|Polish (Poland)|PLK|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|pl-PL');
        AddRow(1046, '1046|1046|Portuguese (Brazil)|PTB|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|pt-BR');
        AddRow(1047, '1047|1047|Romansh (Switzerland)|RMC|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|rm-CH');
        AddRow(1048, '1048|1048|Romanian (Romania)|ROM|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|ro-RO');
        AddRow(1049, '1049|1049|Russian (Russia)|RUS|Yes|Yes|Yes|Yes|No|Yes|866|Yes|Yes|No|Yes|ru-RU');
        AddRow(1050, '1050|1050|Croatian (Croatia)|HRV|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|hr-HR');
        AddRow(1051, '1051|1051|Slovak (Slovakia)|SKY|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|sk-SK');
        AddRow(1052, '1052|1052|Albanian (Albania)|SQI|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|sq-AL');
        AddRow(1053, '1053|1053|Swedish (Sweden)|SVE|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|sv-SE');
        AddRow(1054, '1054|1054|Thai (Thailand)|THA|Yes|Yes|Yes|Yes|No|Yes|874|Yes|Yes|No|Yes|th-TH');
        AddRow(1055, '1055|1055|Turkish (Türkiye)|TRK|Yes|Yes|Yes|Yes|No|Yes|857|Yes|Yes|No|Yes|tr-TR');
        AddRow(1056, '1056|1056|Urdu (Pakistan)|URD|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ur-PK');
        AddRow(1057, '1057|1057|Indonesian (Indonesia)|IND|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|id-ID');
        AddRow(1058, '1058|1058|Ukrainian (Ukraine)|UKR|Yes|Yes|Yes|Yes|No|Yes|866|Yes|Yes|No|Yes|uk-UA');
        AddRow(1059, '1059|1059|Belarusian (Belarus)|BEL|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|be-BY');
        AddRow(1060, '1060|1060|Slovenian (Slovenia)|SLV|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|sl-SI');
        AddRow(1061, '1061|1061|Estonian (Estonia)|ETI|Yes|Yes|Yes|Yes|No|Yes|775|Yes|Yes|No|Yes|et-EE');
        AddRow(1062, '1062|1062|Latvian (Latvia)|LVI|Yes|Yes|Yes|Yes|No|Yes|775|Yes|Yes|No|Yes|lv-LV');
        AddRow(1063, '1063|1063|Lithuanian (Lithuania)|LTH|Yes|Yes|Yes|Yes|No|Yes|775|Yes|Yes|No|Yes|lt-LT');
        AddRow(1064, '1064|1064|Tajik (Cyrillic, Tajikistan)|TAJ|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|tg-Cyrl-TJ');
        AddRow(1065, '1065|1065|Persian (Iran)|FAR|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|fa-IR');
        AddRow(1066, '1066|1066|Vietnamese (Vietnam)|VIT|Yes|Yes|Yes|Yes|No|Yes|1258|Yes|Yes|No|Yes|vi-VN');
        AddRow(1067, '1067|1067|Armenian (Armenia)|HYE|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|hy-AM');
        AddRow(1068, '1068|1068|Azerbaijani (Latin, Azerbaijan)|AZE|Yes|Yes|Yes|Yes|No|Yes|857|No|No|No|No|az-Latn-AZ');
        AddRow(1069, '1069|1069|Basque (Basque)|EUQ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|eu-ES');
        AddRow(1070, '1070|1070|Upper Sorbian (Germany)|HSB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|hsb-DE');
        AddRow(1071, '1071|1071|Macedonian (North Macedonia)|MKI|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|mk-MK');
        AddRow(1072, '1072|1072|Sesotho (South Africa)|SOT|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|st-ZA');
        AddRow(1073, '1073|1073|Xitsonga (South Africa)|TSO|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ts-ZA');
        AddRow(1074, '1074|1074|Setswana (South Africa)|TSN|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|tn-ZA');
        AddRow(1076, '1076|1076|isiXhosa (South Africa)|XHO|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|xh-ZA');
        AddRow(1077, '1077|1077|isiZulu (South Africa)|ZUL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|zu-ZA');
        AddRow(1078, '1078|1078|Afrikaans (South Africa)|AFK|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|af-ZA');
        AddRow(1079, '1079|1079|Georgian (Georgia)|KAT|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ka-GE');
        AddRow(1080, '1080|1080|Faroese (Faroe Islands)|FOS|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fo-FO');
        AddRow(1081, '1081|1081|Hindi (India)|HIN|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|hi-IN');
        AddRow(1082, '1082|1082|Maltese (Malta)|MLT|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|mt-MT');
        AddRow(1083, '1083|1083|Sami, Northern (Norway)|SME|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|se-NO');
        AddRow(1086, '1086|1086|Malay (Malaysia)|MSL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ms-MY');
        AddRow(1087, '1087|1087|Kazakh (Kazakhstan)|KKZ|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|kk-KZ');
        AddRow(1088, '1088|1088|Kyrgyz (Kyrgyzstan)|KYR|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|ky-KG');
        AddRow(1089, '1089|1089|Kiswahili (Kenya)|SWK|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|sw-KE');
        AddRow(1090, '1090|1090|Turkmen (Turkmenistan)|TUK|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|tk-TM');
        AddRow(1091, '1091|1091|Uzbek (Latin, Uzbekistan)|UZB|Yes|Yes|Yes|Yes|No|Yes|857|No|No|No|No|uz-Latn-UZ');
        AddRow(1092, '1092|1092|Tatar (Russia)|TTT|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|tt-RU');
        AddRow(1093, '1093|1093|Bengali (India)|BNG|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|bn-IN');
        AddRow(1094, '1094|1094|Punjabi (India)|PAN|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|pa-IN');
        AddRow(1095, '1095|1095|Gujarati (India)|GUJ|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|gu-IN');
        AddRow(1096, '1096|1096|Odia (India)|ORI|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|or-IN');
        AddRow(1097, '1097|1097|Tamil (India)|TAI|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ta-IN');
        AddRow(1098, '1098|1098|Telugu (India)|TEL|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|te-IN');
        AddRow(1099, '1099|1099|Kannada (India)|KDI|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|kn-IN');
        AddRow(1100, '1100|1100|Malayalam (India)|MYM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ml-IN');
        AddRow(1101, '1101|1101|Assamese (India)|ASM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|as-IN');
        AddRow(1102, '1102|1102|Marathi (India)|MAR|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|mr-IN');
        AddRow(1103, '1103|1103|Sanskrit (India)|SAN|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|sa-IN');
        AddRow(1104, '1104|1104|Mongolian (Mongolia)|MNN|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|mn-MN');
        AddRow(1105, '1105|1105|Tibetan (China)|BOB|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|bo-CN');
        AddRow(1106, '1106|1106|Welsh (United Kingdom)|CYM|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|cy-GB');
        AddRow(1107, '1107|1107|Khmer (Cambodia)|KHM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|km-KH');
        AddRow(1108, '1108|1108|Lao (Laos)|LAO|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|lo-LA');
        AddRow(1109, '1109|1109|Burmese (Myanmar)|MYA|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|my-MM');
        AddRow(1110, '1110|1110|Galician (Galician)|GLC|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|gl-ES');
        AddRow(1111, '1111|1111|Konkani (India)|KNK|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|kok-IN');
        AddRow(1113, '1113|1113|Sindhi (Devanagari, India)|ZZZ|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|sd-Deva-IN');
        AddRow(1114, '1114|1114|Syriac (Syria)|SYR|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|syr-SY');
        AddRow(1115, '1115|1115|Sinhala (Sri Lanka)|SIN|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|si-LK');
        AddRow(1116, '1116|1116|Cherokee (Cherokee, United States)|CRE|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|chr-Cher-US');
        AddRow(1117, '1117|1117|Inuktitut (Syllabics, Canada)|IUS|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|iu-Cans-CA');
        AddRow(1118, '1118|1118|Amharic (Ethiopia)|AMH|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|am-ET');
        AddRow(1119, '1119|1119|Central Atlas Tamazight (Arabic, Morocco)|ZZZ|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|tzm-Arab-MA');
        AddRow(1121, '1121|1121|Nepali (Nepal)|NEP|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ne-NP');
        AddRow(1122, '1122|1122|Western Frisian (Netherlands)|FYN|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fy-NL');
        AddRow(1123, '1123|1123|Pashto (Afghanistan)|PAS|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ps-AF');
        AddRow(1124, '1124|1124|Filipino (Philippines)|FPO|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|fil-PH');
        AddRow(1125, '1125|1125|Divehi (Maldives)|DIV|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|dv-MV');
        AddRow(1127, '1127|1127|Fulah (Latin, Nigeria)|ZZZ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ff-Latn-NG');
        AddRow(1128, '1128|1128|Hausa (Latin, Nigeria)|HAU|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|ha-Latn-NG');
        AddRow(1130, '1130|1130|Yoruba (Nigeria)|YOR|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|yo-NG');
        AddRow(1131, '1131|1131|Quechua (Bolivia)|QUB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|quz-BO');
        AddRow(1132, '1132|1132|Sesotho sa Leboa (South Africa)|NSO|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|nso-ZA');
        AddRow(1133, '1133|1133|Bashkir (Russia)|BAS|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|ba-RU');
        AddRow(1134, '1134|1134|Luxembourgish (Luxembourg)|LBX|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|lb-LU');
        AddRow(1135, '1135|1135|Kalaallisut (Greenland)|KAL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|kl-GL');
        AddRow(1136, '1136|1136|Igbo (Nigeria)|IBO|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|ig-NG');
        AddRow(1138, '1138|1138|Oromo (Ethiopia)|ORM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|om-ET');
        AddRow(1139, '1139|1139|Tigrinya (Ethiopia)|TIE|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ti-ET');
        AddRow(1140, '1140|1140|Guarani (Paraguay)|GRN|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|gn-PY');
        AddRow(1141, '1141|1141|Hawaiian (United States)|HAW|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|haw-US');
        AddRow(1143, '1143|1143|Somali (Somalia)|SOM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|so-SO');
        AddRow(1144, '1144|1144|Yi (China)|III|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ii-CN');
        AddRow(1146, '1146|1146|Mapuche (Chile)|MPD|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|arn-CL');
        AddRow(1148, '1148|1148|Mohawk (Mohawk)|MWK|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|moh-CA');
        AddRow(1150, '1150|1150|Breton (France)|BRE|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|br-FR');
        AddRow(1152, '1152|1152|Uyghur (China)|UIG|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ug-CN');
        AddRow(1153, '1153|1153|Maori (New Zealand)|MRI|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|mi-NZ');
        AddRow(1154, '1154|1154|Occitan (France)|OCI|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|oc-FR');
        AddRow(1155, '1155|1155|Corsican (France)|COS|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|co-FR');
        AddRow(1156, '1156|1156|Alsatian (France)|GSW|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|gsw-FR');
        AddRow(1157, '1157|1157|Sakha (Russia)|SAH|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|sah-RU');
        AddRow(1158, '1158|1158|K''iche'' (Guatemala)|QUC|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|quc-Latn-GT');
        AddRow(1159, '1159|1159|Kinyarwanda (Rwanda)|KIN|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|rw-RW');
        AddRow(1160, '1160|1160|Wolof (Senegal)|WOL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|wo-SN');
        AddRow(1164, '1164|1164|Dari (Afghanistan)|PRS|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|prs-AF');
        AddRow(1169, '1169|1169|Scottish Gaelic (United Kingdom)|GLA|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|gd-GB');
        AddRow(1170, '1170|1170|Central Kurdish (Iraq)|KUR|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ku-Arab-IQ');
        AddRow(2049, '2049|1025|Arabic (Iraq)|ARI|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-IQ');
        AddRow(2051, '2051|1027|Valencian (Spain)|VAL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ca-ES-valencia');
        AddRow(2052, '2052|1028|Chinese (Simplified, China)|CHS|Yes|Yes|Yes|Yes|No|Yes|936|Yes|Yes|No|Yes|zh-CN');
        AddRow(2055, '2055|1031|German (Switzerland)|DES|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|de-CH');
        AddRow(2057, '2057|1033|English (United Kingdom)|ENG|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|en-GB');
        AddRow(2058, '2058|1034|Spanish (Mexico)|ESM|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|es-MX');
        AddRow(2060, '2060|1036|French (Belgium)|FRB|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|fr-BE');
        AddRow(2064, '2064|1040|Italian (Switzerland)|ITS|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|it-CH');
        AddRow(2067, '2067|1043|Dutch (Belgium)|NLB|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|nl-BE');
        AddRow(2068, '2068|1044|Norwegian Nynorsk (Norway)|NON|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|nn-NO');
        AddRow(2070, '2070|1046|Portuguese (Portugal)|PTG|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|pt-PT');
        AddRow(2072, '2072|1048|Romanian (Moldova)|ROD|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|ro-MD');
        AddRow(2073, '2073|1049|Russian (Moldova)|RUM|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|ru-MD');
        AddRow(2077, '2077|1053|Swedish (Finland)|SVF|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|sv-FI');
        AddRow(2080, '2080|1056|Urdu (India)|URI|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ur-IN');
        AddRow(2092, '2092|1068|Azerbaijani (Cyrillic, Azerbaijan)|AZC|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|az-Cyrl-AZ');
        AddRow(2094, '2094|1070|Lower Sorbian (Germany)|DSB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|dsb-DE');
        AddRow(2098, '2098|1074|Setswana (Botswana)|TSB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|tn-BW');
        AddRow(2107, '2107|1083|Sami, Northern (Sweden)|SMF|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|se-SE');
        AddRow(2108, '2108|1084|Irish (Ireland)|IRE|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ga-IE');
        AddRow(2110, '2110|1086|Malay (Brunei)|MSB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ms-BN');
        AddRow(2115, '2115|1091|Uzbek (Cyrillic, Uzbekistan)|UZC|Yes|Yes|Yes|Yes|No|Yes|866|No|No|No|No|uz-Cyrl-UZ');
        AddRow(2117, '2117|1093|Bangla (Bangladesh)|BNB|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|bn-BD');
        AddRow(2118, '2118|1094|Punjabi (Pakistan)|PAP|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|pa-Arab-PK');
        AddRow(2121, '2121|1097|Tamil (Sri Lanka)|TAM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ta-LK');
        AddRow(2128, '2128|1104|Mongolian (Traditional Mongolian, China)|MNG|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|mn-Mong-CN');
        AddRow(2137, '2137|1113|Sindhi (Pakistan)|SIP|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|sd-Arab-PK');
        AddRow(2141, '2141|1117|Inuktitut (Latin, Canada)|IUK|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|iu-Latn-CA');
        AddRow(2143, '2143|1119|Central Atlas Tamazight (Latin, Algeria)|TZA|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|tzm-Latn-DZ');
        AddRow(2145, '2145|1121|Nepali (India)|NEI|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ne-IN');
        AddRow(2151, '2151|1127|Fulah (Latin, Senegal)|FUL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|ff-Latn-SN');
        AddRow(2155, '2155|1131|Quechua (Ecuador)|QUE|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|quz-EC');
        AddRow(2163, '2163|1139|Tigrinya (Eritrea)|TIR|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|ti-ER');
        AddRow(3073, '3073|1025|Arabic (Egypt)|ARE|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-EG');
        AddRow(3076, '3076|1028|Chinese (Traditional, Hong Kong SAR)|ZHH|Yes|Yes|Yes|Yes|No|Yes|950|Yes|Yes|No|Yes|zh-HK');
        AddRow(3079, '3079|1031|German (Austria)|DEA|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|de-AT');
        AddRow(3081, '3081|1033|English (Australia)|ENA|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|en-AU');
        AddRow(3082, '3082|1034|Spanish (Spain, International Sort)|ESN|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|es-ES');
        AddRow(3084, '3084|1036|French (Canada)|FRC|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|fr-CA');
        AddRow(3131, '3131|1083|Sami, Northern (Finland)|SMG|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|se-FI');
        AddRow(3152, '3152|1104|Mongolian (Traditional Mongolian, Mongolia)|MNM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|mn-Mong-MN');
        AddRow(3179, '3179|1131|Quechua (Peru)|QUP|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|quz-PE');
        AddRow(4097, '4097|1025|Arabic (Libya)|ARL|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-LY');
        AddRow(4100, '4100|1028|Chinese (Simplified, Singapore)|ZHI|Yes|Yes|Yes|Yes|No|Yes|936|No|No|No|No|zh-SG');
        AddRow(4103, '4103|1031|German (Luxembourg)|DEL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|de-LU');
        AddRow(4105, '4105|1033|English (Canada)|ENC|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|en-CA');
        AddRow(4106, '4106|1034|Spanish (Guatemala)|ESG|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-GT');
        AddRow(4108, '4108|1036|French (Switzerland)|FRS|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|fr-CH');
        AddRow(4122, '4122|1050|Croatian (Bosnia & Herzegovina)|HRB|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|hr-BA');
        AddRow(4155, '4155|1083|Sami, Lule (Norway)|SMJ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|smj-NO');
        AddRow(4191, '4191|1119|Central Atlas Tamazight (Tifinagh, Morocco)|TZM|Yes|Yes|Yes|Yes|No|Yes|' + Utf8CodePage() + '|No|No|No|No|tzm-Tfng-MA');
        AddRow(5121, '5121|1025|Arabic (Algeria)|ARG|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-DZ');
        AddRow(5124, '5124|1028|Chinese (Traditional, Macao SAR)|ZHM|Yes|Yes|Yes|Yes|No|Yes|950|No|No|No|No|zh-MO');
        AddRow(5127, '5127|1031|German (Liechtenstein)|DEC|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|de-LI');
        AddRow(5129, '5129|1033|English (New Zealand)|ENZ|Yes|Yes|Yes|Yes|No|Yes|850|Yes|Yes|No|Yes|en-NZ');
        AddRow(5130, '5130|1034|Spanish (Costa Rica)|ESC|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-CR');
        AddRow(5132, '5132|1036|French (Luxembourg)|FRL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-LU');
        AddRow(5146, '5146|1050|Bosnian (Latin, Bosnia & Herzegovina)|BSB|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|bs-Latn-BA');
        AddRow(5179, '5179|1083|Sami, Lule (Sweden)|SMK|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|smj-SE');
        AddRow(6145, '6145|1025|Arabic (Morocco)|ARM|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-MA');
        AddRow(6153, '6153|1033|English (Ireland)|ENI|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-IE');
        AddRow(6154, '6154|1034|Spanish (Panama)|ESA|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-PA');
        AddRow(6156, '6156|1036|French (Monaco)|FRM|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-MC');
        AddRow(6170, '6170|1050|Serbian (Latin, Bosnia & Herzegovina)|SRS|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|sr-Latn-BA');
        AddRow(6203, '6203|1083|Sami, Southern (Norway)|SMA|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|sma-NO');
        AddRow(7169, '7169|1025|Arabic (Tunisia)|ART|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-TN');
        AddRow(7177, '7177|1033|English (South Africa)|ENS|Yes|Yes|Yes|Yes|No|Yes|437|Yes|Yes|No|Yes|en-ZA');
        AddRow(7178, '7178|1034|Spanish (Dominican Republic)|ESD|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-DO');
        AddRow(7194, '7194|1050|Serbian (Cyrillic, Bosnia and Herzegovina)|SRN|Yes|Yes|Yes|Yes|No|Yes|855|No|No|No|No|sr-Cyrl-BA');
        AddRow(7227, '7227|1083|Sami, Southern (Sweden)|SMB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|sma-SE');
        AddRow(8193, '8193|1025|Arabic (Oman)|ARO|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-OM');
        AddRow(8201, '8201|1033|English (Jamaica)|ENJ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-JM');
        AddRow(8202, '8202|1034|Spanish (Venezuela)|ESV|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-VE');
        AddRow(8204, '8204|1036|French (Réunion)|FRR|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-RE');
        AddRow(8218, '8218|1050|Bosnian (Cyrillic, Bosnia and Herzegovina)|BSC|Yes|Yes|Yes|Yes|No|Yes|855|No|No|No|No|bs-Cyrl-BA');
        AddRow(8251, '8251|1083|Sami, Skolt (Finland)|SMS|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|sms-FI');
        AddRow(9217, '9217|1025|Arabic (Yemen)|ARY|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-YE');
        AddRow(9225, '9225|1033|English (Caribbean)|ENB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-029');
        AddRow(9226, '9226|1034|Spanish (Colombia)|ESO|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-CO');
        AddRow(9228, '9228|1036|French Congo (DRC)|FRD|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-CD');
        AddRow(9242, '9242|1050|Serbian (Latin, Serbia)|SRM|Yes|Yes|Yes|Yes|No|Yes|852|Yes|Yes|No|Yes|sr-Latn-RS');
        AddRow(9275, '9275|1083|Sami, Inari (Finland)|SMN|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|smn-FI');
        AddRow(10241, '10241|1025|Arabic (Syria)|ARS|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-SY');
        AddRow(10249, '10249|1033|English (Belize)|ENL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-BZ');
        AddRow(10250, '10250|1034|Spanish (Peru)|ESR|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-PE');
        AddRow(10252, '10252|1036|French (Senegal)|FRN|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-SN');
        AddRow(10266, '10266|1050|Serbian (Cyrillic, Serbia)|SRO|Yes|Yes|Yes|Yes|No|Yes|855|No|No|No|No|sr-Cyrl-RS');
        AddRow(11265, '11265|1025|Arabic (Jordan)|ARJ|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-JO');
        AddRow(11273, '11273|1033|English (Trinidad & Tobago)|ENT|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-TT');
        AddRow(11274, '11274|1034|Spanish (Argentina)|ESS|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-AR');
        AddRow(11276, '11276|1036|French (Cameroon)|FRE|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-CM');
        AddRow(11290, '11290|1050|Serbian (Latin, Montenegro)|SRP|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|sr-Latn-ME');
        AddRow(12289, '12289|1025|Arabic (Lebanon)|ARB|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-LB');
        AddRow(12297, '12297|1033|English (Zimbabwe)|ENW|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|en-ZW');
        AddRow(12298, '12298|1034|Spanish (Ecuador)|ESF|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-EC');
        AddRow(12300, '12300|1036|French (Côte d’Ivoire)|FRI|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-CI');
        AddRow(12314, '12314|1050|Serbian (Cyrillic, Montenegro)|SRQ|Yes|Yes|Yes|Yes|No|Yes|855|No|No|No|No|sr-Cyrl-ME');
        AddRow(13313, '13313|1025|Arabic (Kuwait)|ARK|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-KW');
        AddRow(13321, '13321|1033|English (Philippines)|ENP|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|en-PH');
        AddRow(13322, '13322|1034|Spanish (Chile)|ESL|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-CL');
        AddRow(13324, '13324|1036|French (Mali)|FRF|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-ML');
        AddRow(14337, '14337|1025|Arabic (United Arab Emirates)|ARU|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-AE');
        AddRow(14345, '14345|1033|English (Indonesia)|ZZZ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-ID');
        AddRow(14346, '14346|1034|Spanish (Uruguay)|ESY|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-UY');
        AddRow(14348, '14348|1036|French (Morocco)|FRO|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-MA');
        AddRow(15361, '15361|1025|Arabic (Bahrain)|ARH|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-BH');
        AddRow(15369, '15369|1033|English (Hong Kong SAR)|ENH|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|en-HK');
        AddRow(15370, '15370|1034|Spanish (Paraguay)|ESZ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-PY');
        AddRow(15372, '15372|1036|French (Haiti)|FRH|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|fr-HT');
        AddRow(16385, '16385|1025|Arabic (Qatar)|ARQ|Yes|Yes|Yes|Yes|No|Yes|720|No|No|No|No|ar-QA');
        AddRow(16393, '16393|1033|English (India)|ENN|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|en-IN');
        AddRow(16394, '16394|1034|Spanish (Bolivia)|ESB|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-BO');
        AddRow(17417, '17417|1033|English (Malaysia)|ENM|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|en-MY');
        AddRow(17418, '17418|1034|Spanish (El Salvador)|ESE|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-SV');
        AddRow(18441, '18441|1033|English (Singapore)|ENE|Yes|Yes|Yes|Yes|No|Yes|437|No|No|No|No|en-SG');
        AddRow(18442, '18442|1034|Spanish (Honduras)|ESH|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-HN');
        AddRow(19466, '19466|1034|Spanish (Nicaragua)|ESI|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-NI');
        AddRow(20490, '20490|1034|Spanish (Puerto Rico)|ESU|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-PR');
        AddRow(21514, '21514|1034|Spanish (United States)|EST|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-US');
        AddRow(22538, '22538|1034|Spanish (Latin America)|ESJ|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-419');
        AddRow(23562, '23562|1034|Spanish (Cuba)|ESK|Yes|Yes|Yes|Yes|No|Yes|850|No|No|No|No|es-CU');
        AddRow(31770, '31770|1050|Serbian|SRB|Yes|Yes|Yes|Yes|No|Yes|852|No|No|No|No|sr');
    end;

    local procedure AddCheckedIds(var Ids: List of [Integer])
    begin
        Ids.Add(1025);
        Ids.Add(1026);
        Ids.Add(1029);
        Ids.Add(1030);
        Ids.Add(1031);
        Ids.Add(1032);
        Ids.Add(1033);
        Ids.Add(1035);
        Ids.Add(1036);
        Ids.Add(1037);
        Ids.Add(1038);
        Ids.Add(1039);
        Ids.Add(1040);
        Ids.Add(1041);
        Ids.Add(1043);
        Ids.Add(1044);
        Ids.Add(1045);
        Ids.Add(1046);
        Ids.Add(1047);
        Ids.Add(1048);
        Ids.Add(1049);
        Ids.Add(1050);
        Ids.Add(1051);
        Ids.Add(1052);
        Ids.Add(1053);
        Ids.Add(1054);
        Ids.Add(1055);
        Ids.Add(1056);
        Ids.Add(1057);
        Ids.Add(1058);
        Ids.Add(1059);
        Ids.Add(1060);
        Ids.Add(1061);
        Ids.Add(1062);
        Ids.Add(1063);
        Ids.Add(1065);
        Ids.Add(1066);
#if BC29PLUS
        Ids.Add(1067);
#endif
        Ids.Add(1068);
        Ids.Add(1070);
        Ids.Add(1071);
        Ids.Add(1078);
#if BC29PLUS
        Ids.Add(1079);
#endif
        Ids.Add(1080);
#if BC29PLUS
        Ids.Add(1081);
#endif
#if BC29PLUS
        Ids.Add(1082);
#endif
        Ids.Add(1086);
#if BC29PLUS
        Ids.Add(1087);
#endif
        Ids.Add(1088);
        Ids.Add(1090);
        Ids.Add(1091);
        Ids.Add(1092);
#if BC29PLUS
        Ids.Add(1095);
#endif
#if BC29PLUS
        Ids.Add(1096);
#endif
#if BC29PLUS
        Ids.Add(1097);
#endif
#if BC29PLUS
        Ids.Add(1098);
#endif
#if BC29PLUS
        Ids.Add(1099);
#endif
#if BC29PLUS
        Ids.Add(1100);
#endif
#if BC29PLUS
        Ids.Add(1101);
#endif
#if BC29PLUS
        Ids.Add(1102);
#endif
#if BC29PLUS
        Ids.Add(1103);
#endif
        Ids.Add(1104);
#if BC29PLUS
        Ids.Add(1105);
#endif
        Ids.Add(1106);
#if BC29PLUS
        Ids.Add(1107);
#endif
#if BC29PLUS
        Ids.Add(1108);
#endif
#if BC29PLUS
        Ids.Add(1111);
#endif
#if BC29PLUS
        Ids.Add(1114);
#endif
#if BC29PLUS
        Ids.Add(1115);
#endif
#if BC29PLUS
        Ids.Add(1118);
#endif
#if BC29PLUS
        Ids.Add(1121);
#endif
        Ids.Add(1122);
#if BC29PLUS
        Ids.Add(1123);
#endif
        Ids.Add(1124);
        Ids.Add(1130);
        Ids.Add(1134);
        Ids.Add(1135);
        Ids.Add(1136);
#if BC29PLUS
        Ids.Add(1138);
#endif
#if BC29PLUS
        Ids.Add(1139);
#endif
        Ids.Add(1141);
#if BC29PLUS
        Ids.Add(1143);
#endif
        Ids.Add(1150);
        Ids.Add(1152);
        Ids.Add(1154);
        Ids.Add(1159);
        Ids.Add(1160);
        Ids.Add(1169);
        Ids.Add(2049);
        Ids.Add(2055);
        Ids.Add(2057);
        Ids.Add(2058);
        Ids.Add(2060);
        Ids.Add(2064);
        Ids.Add(2067);
        Ids.Add(2068);
        Ids.Add(2070);
        Ids.Add(2072);
        Ids.Add(2073);
        Ids.Add(2077);
        Ids.Add(2080);
        Ids.Add(2092);
        Ids.Add(2094);
        Ids.Add(2108);
        Ids.Add(2110);
        Ids.Add(2115);
#if BC29PLUS
        Ids.Add(2117);
#endif
#if BC29PLUS
        Ids.Add(2121);
#endif
#if BC29PLUS
        Ids.Add(2145);
#endif
#if BC29PLUS
        Ids.Add(2163);
#endif
        Ids.Add(3073);
        Ids.Add(3079);
        Ids.Add(3081);
        Ids.Add(3084);
        Ids.Add(4097);
        Ids.Add(4103);
        Ids.Add(4105);
        Ids.Add(4106);
        Ids.Add(4108);
        Ids.Add(4122);
        Ids.Add(5121);
        Ids.Add(5127);
        Ids.Add(5129);
        Ids.Add(5130);
        Ids.Add(5132);
        Ids.Add(5146);
        Ids.Add(6145);
        Ids.Add(6153);
        Ids.Add(6154);
        Ids.Add(6156);
        Ids.Add(6170);
        Ids.Add(7169);
        Ids.Add(7177);
        Ids.Add(7178);
        Ids.Add(8193);
        Ids.Add(8201);
        Ids.Add(8202);
        Ids.Add(8204);
        Ids.Add(9217);
        Ids.Add(9226);
        Ids.Add(9242);
        Ids.Add(10241);
        Ids.Add(10249);
        Ids.Add(10250);
        Ids.Add(10252);
        Ids.Add(10266);
        Ids.Add(11265);
        Ids.Add(11273);
        Ids.Add(11274);
        Ids.Add(11276);
        Ids.Add(11290);
        Ids.Add(12289);
        Ids.Add(12297);
        Ids.Add(12298);
        Ids.Add(12300);
        Ids.Add(12314);
        Ids.Add(13313);
        Ids.Add(13321);
        Ids.Add(13322);
        Ids.Add(13324);
        Ids.Add(14337);
        Ids.Add(14345);
        Ids.Add(14346);
        Ids.Add(14348);
        Ids.Add(15361);
        Ids.Add(15370);
        Ids.Add(15372);
        Ids.Add(16385);
        Ids.Add(16393);
        Ids.Add(16394);
        Ids.Add(17417);
        Ids.Add(17418);
        Ids.Add(18441);
        Ids.Add(18442);
        Ids.Add(19466);
        Ids.Add(20490);
        Ids.Add(21514);
        Ids.Add(22538);
        Ids.Add(23562);
        Ids.Add(31770);
    end;

    [Test]
    procedure WindowsLanguage_Rows_1025_1049()
    begin
        Check(1025);
        Check(1026);
        Check(1029);
        Check(1030);
        Check(1031);
        Check(1032);
        Check(1033);
        Check(1035);
        Check(1036);
        Check(1037);
        Check(1038);
        Check(1039);
        Check(1040);
        Check(1041);
        Check(1043);
        Check(1044);
        Check(1045);
        Check(1046);
        Check(1047);
        Check(1048);
        Check(1049);
    end;

    [Test]
    procedure WindowsLanguage_Rows_1050_1074()
    begin
        Check(1050);
        Check(1051);
        Check(1052);
        Check(1053);
        Check(1054);
        Check(1055);
        Check(1056);
        Check(1057);
        Check(1058);
        Check(1059);
        Check(1060);
        Check(1061);
        Check(1062);
        Check(1063);
        Check(1065);
        Check(1066);
#if BC29PLUS
        Check(1067);
#endif
        Check(1068);
        Check(1070);
        Check(1071);
    end;

    [Test]
    procedure WindowsLanguage_Rows_1076_1102()
    begin
        Check(1078);
#if BC29PLUS
        Check(1079);
#endif
        Check(1080);
#if BC29PLUS
        Check(1081);
#endif
#if BC29PLUS
        Check(1082);
#endif
        Check(1086);
#if BC29PLUS
        Check(1087);
#endif
        Check(1088);
        Check(1090);
        Check(1091);
        Check(1092);
#if BC29PLUS
        Check(1095);
#endif
#if BC29PLUS
        Check(1096);
#endif
#if BC29PLUS
        Check(1097);
#endif
#if BC29PLUS
        Check(1098);
#endif
#if BC29PLUS
        Check(1099);
#endif
#if BC29PLUS
        Check(1100);
#endif
#if BC29PLUS
        Check(1101);
#endif
#if BC29PLUS
        Check(1102);
#endif
    end;

    [Test]
    procedure WindowsLanguage_Rows_1103_1131()
    begin
#if BC29PLUS
        Check(1103);
#endif
        Check(1104);
#if BC29PLUS
        Check(1105);
#endif
        Check(1106);
#if BC29PLUS
        Check(1107);
#endif
#if BC29PLUS
        Check(1108);
#endif
#if BC29PLUS
        Check(1111);
#endif
#if BC29PLUS
        Check(1114);
#endif
#if BC29PLUS
        Check(1115);
#endif
#if BC29PLUS
        Check(1118);
#endif
#if BC29PLUS
        Check(1121);
#endif
        Check(1122);
#if BC29PLUS
        Check(1123);
#endif
        Check(1124);
        Check(1130);
    end;

    [Test]
    procedure WindowsLanguage_Rows_1132_1169()
    begin
        Check(1134);
        Check(1135);
        Check(1136);
#if BC29PLUS
        Check(1138);
#endif
#if BC29PLUS
        Check(1139);
#endif
        Check(1141);
#if BC29PLUS
        Check(1143);
#endif
        Check(1150);
        Check(1152);
        Check(1154);
        Check(1159);
        Check(1160);
        Check(1169);
    end;

    [Test]
    procedure WindowsLanguage_Rows_1170_2118()
    begin
        Check(2049);
        Check(2055);
        Check(2057);
        Check(2058);
        Check(2060);
        Check(2064);
        Check(2067);
        Check(2068);
        Check(2070);
        Check(2072);
        Check(2073);
        Check(2077);
        Check(2080);
        Check(2092);
        Check(2094);
        Check(2108);
        Check(2110);
        Check(2115);
#if BC29PLUS
        Check(2117);
#endif
    end;

    [Test]
    procedure WindowsLanguage_Rows_2121_4122()
    begin
#if BC29PLUS
        Check(2121);
#endif
#if BC29PLUS
        Check(2145);
#endif
#if BC29PLUS
        Check(2163);
#endif
        Check(3073);
        Check(3079);
        Check(3081);
        Check(3084);
        Check(4097);
        Check(4103);
        Check(4105);
        Check(4106);
        Check(4108);
        Check(4122);
    end;

    [Test]
    procedure WindowsLanguage_Rows_4155_8204()
    begin
        Check(5121);
        Check(5127);
        Check(5129);
        Check(5130);
        Check(5132);
        Check(5146);
        Check(6145);
        Check(6153);
        Check(6154);
        Check(6156);
        Check(6170);
        Check(7169);
        Check(7177);
        Check(7178);
        Check(8193);
        Check(8201);
        Check(8202);
        Check(8204);
    end;

    [Test]
    procedure WindowsLanguage_Rows_8218_13321()
    begin
        Check(9217);
        Check(9226);
        Check(9242);
        Check(10241);
        Check(10249);
        Check(10250);
        Check(10252);
        Check(10266);
        Check(11265);
        Check(11273);
        Check(11274);
        Check(11276);
        Check(11290);
        Check(12289);
        Check(12297);
        Check(12298);
        Check(12300);
        Check(12314);
        Check(13313);
        Check(13321);
    end;

    [Test]
    procedure WindowsLanguage_Rows_13322_31770()
    begin
        Check(13322);
        Check(13324);
        Check(14337);
        Check(14345);
        Check(14346);
        Check(14348);
        Check(15361);
        Check(15370);
        Check(15372);
        Check(16385);
        Check(16393);
        Check(16394);
        Check(17417);
        Check(17418);
        Check(18441);
        Check(18442);
        Check(19466);
        Check(20490);
        Check(21514);
        Check(22538);
        Check(23562);
        Check(31770);
    end;

    [Test]
    procedure WindowsLanguage_Walk_KeyOrder_CheckedRows()
    var
        WindowsLanguage: Record "Windows Language";
        Ids: List of [Integer];
        Seen: Integer;
        Previous: Integer;
    begin
        // Every row in Language ID order: ids ascend, and every row checked above appears once with the expected values.
        Load();
        AddCheckedIds(Ids);
        WindowsLanguage.SetCurrentKey("Language ID");
        if WindowsLanguage.FindSet() then
            repeat
                if WindowsLanguage."Language ID" <= Previous then
                    Error('Windows Language: %1 after %2', WindowsLanguage."Language ID", Previous);
                Previous := WindowsLanguage."Language ID";
                if Ids.Contains(WindowsLanguage."Language ID") then begin
                    Seen += 1;
                    if RowText(WindowsLanguage) <> Expected.Get(WindowsLanguage."Language ID") then
                        Error('Windows Language %1: expected [%2], got [%3]', WindowsLanguage."Language ID", Expected.Get(WindowsLanguage."Language ID"), RowText(WindowsLanguage));
                end;
            until WindowsLanguage.Next() = 0;
        if Seen <> Ids.Count() then
            Error('Windows Language: walked %1 of the %2 checked rows', Seen, Ids.Count());
    end;

    // ---- Held: Linux suspect (Windows 27.5/28.5 and SaaS 29 values; the Linux CI containers differ, see the header) ----

    [Test]
    procedure Suspect_WindowsLanguage_Walk_AllRows()
    var
        WindowsLanguage: Record "Windows Language";
        Index: Integer;
    begin
        Load();
        if WindowsLanguage.Count() <> 248 then
            Error('Windows Language: %1 rows, expected 248', WindowsLanguage.Count());
        WindowsLanguage.SetCurrentKey("Language ID");
        if WindowsLanguage.FindSet() then
            repeat
                Index += 1;
                if RowText(WindowsLanguage) <> Expected.Get(AllIds.Get(Index)) then
                    Error('Windows Language row %1: expected [%2], got [%3]', Index, Expected.Get(AllIds.Get(Index)), RowText(WindowsLanguage));
            until WindowsLanguage.Next() = 0;
        if Index <> 248 then
            Error('Windows Language: walked %1 rows, expected 248', Index);
        if WindowsLanguage.Get(31748) then
            Error('Windows Language 31748 (zh-Hant): a row, expected none');
    end;

    [Test]
    procedure Suspect_WindowsLanguage_Rows_LinuxDiffers()
    begin
        Check(1027);
        Check(1028);
        Check(1034);
        Check(1042);
        Check(1064);
#if not BC29PLUS
        Check(1067);
#endif
        Check(1069);
        Check(1072);
        Check(1073);
        Check(1074);
        Check(1076);
        Check(1077);
#if not BC29PLUS
        Check(1079);
#endif
#if not BC29PLUS
        Check(1081);
#endif
#if not BC29PLUS
        Check(1082);
#endif
        Check(1083);
#if not BC29PLUS
        Check(1087);
#endif
        Check(1089);
        Check(1093);
        Check(1094);
#if not BC29PLUS
        Check(1095);
#endif
#if not BC29PLUS
        Check(1096);
#endif
#if not BC29PLUS
        Check(1097);
#endif
#if not BC29PLUS
        Check(1098);
#endif
#if not BC29PLUS
        Check(1099);
#endif
#if not BC29PLUS
        Check(1100);
#endif
#if not BC29PLUS
        Check(1101);
#endif
#if not BC29PLUS
        Check(1102);
#endif
#if not BC29PLUS
        Check(1103);
#endif
#if not BC29PLUS
        Check(1105);
#endif
#if not BC29PLUS
        Check(1107);
#endif
#if not BC29PLUS
        Check(1108);
#endif
        Check(1109);
        Check(1110);
#if not BC29PLUS
        Check(1111);
#endif
        Check(1113);
#if not BC29PLUS
        Check(1114);
#endif
#if not BC29PLUS
        Check(1115);
#endif
        Check(1116);
        Check(1117);
#if not BC29PLUS
        Check(1118);
#endif
        Check(1119);
#if not BC29PLUS
        Check(1121);
#endif
#if not BC29PLUS
        Check(1123);
#endif
        Check(1125);
        Check(1127);
        Check(1128);
        Check(1131);
        Check(1132);
        Check(1133);
#if not BC29PLUS
        Check(1138);
#endif
#if not BC29PLUS
        Check(1139);
#endif
        Check(1140);
#if not BC29PLUS
        Check(1143);
#endif
        Check(1144);
        Check(1146);
        Check(1148);
        Check(1153);
        Check(1155);
        Check(1156);
        Check(1157);
        Check(1158);
        Check(1164);
        Check(1170);
        Check(2051);
        Check(2052);
        Check(2098);
        Check(2107);
#if not BC29PLUS
        Check(2117);
#endif
        Check(2118);
#if not BC29PLUS
        Check(2121);
#endif
        Check(2128);
        Check(2137);
        Check(2141);
        Check(2143);
#if not BC29PLUS
        Check(2145);
#endif
        Check(2151);
        Check(2155);
#if not BC29PLUS
        Check(2163);
#endif
        Check(3076);
        Check(3082);
        Check(3131);
        Check(3152);
        Check(3179);
        Check(4100);
        Check(4155);
        Check(4191);
        Check(5124);
        Check(5179);
        Check(6203);
        Check(7194);
        Check(7227);
        Check(8218);
        Check(8251);
        Check(9225);
        Check(9228);
        Check(9275);
        Check(15369);
    end;
}
