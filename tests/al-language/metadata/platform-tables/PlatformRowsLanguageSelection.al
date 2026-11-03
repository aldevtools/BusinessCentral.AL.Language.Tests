// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, with every column, of the platform table Language Selection on the fresh tenant of a test container (read through RecordRef by
// table name). The rows are named by Language Tag; where a row differs between BC 27, 28 and 29 (or is missing in one), the expected text is guarded with BC28PLUS and BC29PLUS.
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78100.

codeunit 78100 "LT AD Plat Rows Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef; MaxField: Integer): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class() = FieldClass::Normal) and ((MaxField = 0) or (FR.Number() <= MaxField)) then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure KeyText(var RR: RecordRef; KeyField: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = KeyField then
                exit(Format(FR.Value()));
        end;
    end;

    // Observes the rows whose KeyField value is in Keys (separated by ~), named by that value and not by position, because the rows of a platform
    // table differ between BC versions. A key without a row is observed as <absent>.
    local procedure DumpKeys(var Observer: Codeunit "Probe Observer"; TableName: Text; KeyField: Text; MaxField: Integer; Keys: Text)
    var
        RR: RecordRef;
        Rows: Dictionary of [Text, Text];
        RowKey: Text;
        Id: Integer;
    begin
        Id := TableIdByName(TableName);
        RR.Open(Id);
        if RR.FindSet() then
            repeat
                Rows.Set(KeyText(RR, KeyField), RowText(RR, MaxField));
            until RR.Next() = 0;
        foreach RowKey in Keys.Split('~') do
            if Rows.ContainsKey(RowKey) then
                Observer.Observe(TableName + ' row ' + RowKey, Rows.Get(RowKey))
            else
                Observer.Observe(TableName + ' row ' + RowKey, '<absent>');
    end;

    [Test]
    procedure Rows_LanguageSelection_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'af-ZA~am-ET~ar-AE~ar-BH~ar-DZ~ar-EG~ar-IQ~ar-JO');
        Observer.Expect('Language Selection row af-ZA', 'Name=Afrikaans (South Africa)|Language Tag=af-ZA|Language ID=1078|Primary Language ID=1078|Abbreviated Name=AFK|Enabled=No|');
        Observer.Expect('Language Selection row am-ET', 'Name=Amharic (Ethiopia)|Language Tag=am-ET|Language ID=1118|Primary Language ID=1118|Abbreviated Name=AMH|Enabled=No|');
        Observer.Expect('Language Selection row ar-AE', 'Name=Arabic (United Arab Emirates)|Language Tag=ar-AE|Language ID=14337|Primary Language ID=1025|Abbreviated Name=ARU|Enabled=No|');
        Observer.Expect('Language Selection row ar-BH', 'Name=Arabic (Bahrain)|Language Tag=ar-BH|Language ID=15361|Primary Language ID=1025|Abbreviated Name=ARH|Enabled=No|');
        Observer.Expect('Language Selection row ar-DZ', 'Name=Arabic (Algeria)|Language Tag=ar-DZ|Language ID=5121|Primary Language ID=1025|Abbreviated Name=ARG|Enabled=No|');
        Observer.Expect('Language Selection row ar-EG', 'Name=Arabic (Egypt)|Language Tag=ar-EG|Language ID=3073|Primary Language ID=1025|Abbreviated Name=ARE|Enabled=No|');
        Observer.Expect('Language Selection row ar-IQ', 'Name=Arabic (Iraq)|Language Tag=ar-IQ|Language ID=2049|Primary Language ID=1025|Abbreviated Name=ARI|Enabled=No|');
        Observer.Expect('Language Selection row ar-JO', 'Name=Arabic (Jordan)|Language Tag=ar-JO|Language ID=11265|Primary Language ID=1025|Abbreviated Name=ARJ|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'ar-KW~ar-LB~ar-LY~ar-MA~ar-OM~ar-QA~ar-SA~ar-SY');
        Observer.Expect('Language Selection row ar-KW', 'Name=Arabic (Kuwait)|Language Tag=ar-KW|Language ID=13313|Primary Language ID=1025|Abbreviated Name=ARK|Enabled=No|');
        Observer.Expect('Language Selection row ar-LB', 'Name=Arabic (Lebanon)|Language Tag=ar-LB|Language ID=12289|Primary Language ID=1025|Abbreviated Name=ARB|Enabled=No|');
        Observer.Expect('Language Selection row ar-LY', 'Name=Arabic (Libya)|Language Tag=ar-LY|Language ID=4097|Primary Language ID=1025|Abbreviated Name=ARL|Enabled=No|');
        Observer.Expect('Language Selection row ar-MA', 'Name=Arabic (Morocco)|Language Tag=ar-MA|Language ID=6145|Primary Language ID=1025|Abbreviated Name=ARM|Enabled=No|');
        Observer.Expect('Language Selection row ar-OM', 'Name=Arabic (Oman)|Language Tag=ar-OM|Language ID=8193|Primary Language ID=1025|Abbreviated Name=ARO|Enabled=No|');
        Observer.Expect('Language Selection row ar-QA', 'Name=Arabic (Qatar)|Language Tag=ar-QA|Language ID=16385|Primary Language ID=1025|Abbreviated Name=ARQ|Enabled=No|');
        Observer.Expect('Language Selection row ar-SA', 'Name=Arabic (Saudi Arabia)|Language Tag=ar-SA|Language ID=1025|Primary Language ID=1025|Abbreviated Name=ARA|Enabled=No|');
        Observer.Expect('Language Selection row ar-SY', 'Name=Arabic (Syria)|Language Tag=ar-SY|Language ID=10241|Primary Language ID=1025|Abbreviated Name=ARS|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'ar-TN~ar-YE~as-IN~az-Cyrl-AZ~az-Latn-AZ~be-BY~bg-BG~bn-IN');
        Observer.Expect('Language Selection row ar-TN', 'Name=Arabic (Tunisia)|Language Tag=ar-TN|Language ID=7169|Primary Language ID=1025|Abbreviated Name=ART|Enabled=No|');
        Observer.Expect('Language Selection row ar-YE', 'Name=Arabic (Yemen)|Language Tag=ar-YE|Language ID=9217|Primary Language ID=1025|Abbreviated Name=ARY|Enabled=No|');
        Observer.Expect('Language Selection row as-IN', 'Name=Assamese (India)|Language Tag=as-IN|Language ID=1101|Primary Language ID=1101|Abbreviated Name=ASM|Enabled=No|');
        Observer.Expect('Language Selection row az-Cyrl-AZ', 'Name=Azerbaijani (Cyrillic, Azerbaijan)|Language Tag=az-Cyrl-AZ|Language ID=2092|Primary Language ID=1068|Abbreviated Name=AZC|Enabled=No|');
        Observer.Expect('Language Selection row az-Latn-AZ', 'Name=Azerbaijani (Latin, Azerbaijan)|Language Tag=az-Latn-AZ|Language ID=1068|Primary Language ID=1068|Abbreviated Name=AZE|Enabled=No|');
        Observer.Expect('Language Selection row be-BY', 'Name=Belarusian (Belarus)|Language Tag=be-BY|Language ID=1059|Primary Language ID=1059|Abbreviated Name=BEL|Enabled=No|');
        Observer.Expect('Language Selection row bg-BG', 'Name=Bulgarian (Bulgaria)|Language Tag=bg-BG|Language ID=1026|Primary Language ID=1026|Abbreviated Name=BGR|Enabled=Yes|');
        Observer.Expect('Language Selection row bn-IN', 'Name=Bangla (India)|Language Tag=bn-IN|Language ID=1093|Primary Language ID=1093|Abbreviated Name=BNG|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'bo-CN~br-FR~bs-Cyrl-BA~bs-Latn-BA~ca-ES~cs-CZ~cy-GB~da-DK');
        Observer.Expect('Language Selection row bo-CN', 'Name=Tibetan (China)|Language Tag=bo-CN|Language ID=1105|Primary Language ID=1105|Abbreviated Name=BOB|Enabled=No|');
        Observer.Expect('Language Selection row br-FR', 'Name=Breton (France)|Language Tag=br-FR|Language ID=1150|Primary Language ID=1150|Abbreviated Name=BRE|Enabled=No|');
        Observer.Expect('Language Selection row bs-Cyrl-BA', 'Name=Bosnian (Cyrillic, Bosnia & Herzegovina)|Language Tag=bs-Cyrl-BA|Language ID=8218|Primary Language ID=1050|Abbreviated Name=BSC|Enabled=No|');
        Observer.Expect('Language Selection row bs-Latn-BA', 'Name=Bosnian (Latin, Bosnia & Herzegovina)|Language Tag=bs-Latn-BA|Language ID=5146|Primary Language ID=1050|Abbreviated Name=BSB|Enabled=No|');
        Observer.Expect('Language Selection row ca-ES', 'Name=Catalan (Spain)|Language Tag=ca-ES|Language ID=1027|Primary Language ID=1027|Abbreviated Name=CAT|Enabled=No|');
        Observer.Expect('Language Selection row cs-CZ', 'Name=Czech (Czechia)|Language Tag=cs-CZ|Language ID=1029|Primary Language ID=1029|Abbreviated Name=CSY|Enabled=Yes|');
        Observer.Expect('Language Selection row cy-GB', 'Name=Welsh (United Kingdom)|Language Tag=cy-GB|Language ID=1106|Primary Language ID=1106|Abbreviated Name=CYM|Enabled=No|');
        Observer.Expect('Language Selection row da-DK', 'Name=Danish (Denmark)|Language Tag=da-DK|Language ID=1030|Primary Language ID=1030|Abbreviated Name=DAN|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'de-AT~de-DE~de-LU~dsb-DE~el-GR~en-AU~en-BZ~en-CA');
        Observer.Expect('Language Selection row de-AT', 'Name=German (Austria)|Language Tag=de-AT|Language ID=3079|Primary Language ID=1031|Abbreviated Name=DEA|Enabled=Yes|');
        Observer.Expect('Language Selection row de-DE', 'Name=German (Germany)|Language Tag=de-DE|Language ID=1031|Primary Language ID=1031|Abbreviated Name=DEU|Enabled=Yes|');
        Observer.Expect('Language Selection row de-LU', 'Name=German (Luxembourg)|Language Tag=de-LU|Language ID=4103|Primary Language ID=1031|Abbreviated Name=DEL|Enabled=No|');
        Observer.Expect('Language Selection row dsb-DE', 'Name=Lower Sorbian (Germany)|Language Tag=dsb-DE|Language ID=2094|Primary Language ID=1070|Abbreviated Name=DSB|Enabled=No|');
        Observer.Expect('Language Selection row el-GR', 'Name=Greek (Greece)|Language Tag=el-GR|Language ID=1032|Primary Language ID=1032|Abbreviated Name=ELL|Enabled=Yes|');
        Observer.Expect('Language Selection row en-AU', 'Name=English (Australia)|Language Tag=en-AU|Language ID=3081|Primary Language ID=1033|Abbreviated Name=ENA|Enabled=Yes|');
        Observer.Expect('Language Selection row en-BZ', 'Name=English (Belize)|Language Tag=en-BZ|Language ID=10249|Primary Language ID=1033|Abbreviated Name=ENL|Enabled=No|');
        Observer.Expect('Language Selection row en-CA', 'Name=English (Canada)|Language Tag=en-CA|Language ID=4105|Primary Language ID=1033|Abbreviated Name=ENC|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_06()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'en-GB~en-HK~en-IN~en-JM~en-MY~en-NZ~en-PH~en-SG');
        Observer.Expect('Language Selection row en-GB', 'Name=English (United Kingdom)|Language Tag=en-GB|Language ID=2057|Primary Language ID=1033|Abbreviated Name=ENG|Enabled=Yes|');
        Observer.Expect('Language Selection row en-HK', 'Name=English (Hong Kong SAR China)|Language Tag=en-HK|Language ID=15369|Primary Language ID=1033|Abbreviated Name=ENH|Enabled=No|');
        Observer.Expect('Language Selection row en-IN', 'Name=English (India)|Language Tag=en-IN|Language ID=16393|Primary Language ID=1033|Abbreviated Name=ENN|Enabled=No|');
        Observer.Expect('Language Selection row en-JM', 'Name=English (Jamaica)|Language Tag=en-JM|Language ID=8201|Primary Language ID=1033|Abbreviated Name=ENJ|Enabled=No|');
        Observer.Expect('Language Selection row en-MY', 'Name=English (Malaysia)|Language Tag=en-MY|Language ID=17417|Primary Language ID=1033|Abbreviated Name=ENM|Enabled=No|');
        Observer.Expect('Language Selection row en-NZ', 'Name=English (New Zealand)|Language Tag=en-NZ|Language ID=5129|Primary Language ID=1033|Abbreviated Name=ENZ|Enabled=Yes|');
        Observer.Expect('Language Selection row en-PH', 'Name=English (Philippines)|Language Tag=en-PH|Language ID=13321|Primary Language ID=1033|Abbreviated Name=ENP|Enabled=No|');
        Observer.Expect('Language Selection row en-SG', 'Name=English (Singapore)|Language Tag=en-SG|Language ID=18441|Primary Language ID=1033|Abbreviated Name=ENE|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_07()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'en-TT~en-US~en-ZA~en-ZW~es-419~es-AR~es-BO~es-CL');
        Observer.Expect('Language Selection row en-TT', 'Name=English (Trinidad & Tobago)|Language Tag=en-TT|Language ID=11273|Primary Language ID=1033|Abbreviated Name=ENT|Enabled=No|');
        Observer.Expect('Language Selection row en-US', 'Name=English (United States)|Language Tag=en-US|Language ID=1033|Primary Language ID=1033|Abbreviated Name=ENU|Enabled=Yes|');
        Observer.Expect('Language Selection row en-ZA', 'Name=English (South Africa)|Language Tag=en-ZA|Language ID=7177|Primary Language ID=1033|Abbreviated Name=ENS|Enabled=Yes|');
        Observer.Expect('Language Selection row en-ZW', 'Name=English (Zimbabwe)|Language Tag=en-ZW|Language ID=12297|Primary Language ID=1033|Abbreviated Name=ENW|Enabled=No|');
        Observer.Expect('Language Selection row es-419', 'Name=Spanish (Latin America)|Language Tag=es-419|Language ID=22538|Primary Language ID=1034|Abbreviated Name=ESJ|Enabled=No|');
        Observer.Expect('Language Selection row es-AR', 'Name=Spanish (Argentina)|Language Tag=es-AR|Language ID=11274|Primary Language ID=1034|Abbreviated Name=ESS|Enabled=No|');
        Observer.Expect('Language Selection row es-BO', 'Name=Spanish (Bolivia)|Language Tag=es-BO|Language ID=16394|Primary Language ID=1034|Abbreviated Name=ESB|Enabled=No|');
        Observer.Expect('Language Selection row es-CL', 'Name=Spanish (Chile)|Language Tag=es-CL|Language ID=13322|Primary Language ID=1034|Abbreviated Name=ESL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_08()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'es-CO~es-CR~es-CU~es-DO~es-EC~es-ES~es-ES_tradnl~es-GT');
        Observer.Expect('Language Selection row es-CO', 'Name=Spanish (Colombia)|Language Tag=es-CO|Language ID=9226|Primary Language ID=1034|Abbreviated Name=ESO|Enabled=No|');
        Observer.Expect('Language Selection row es-CR', 'Name=Spanish (Costa Rica)|Language Tag=es-CR|Language ID=5130|Primary Language ID=1034|Abbreviated Name=ESC|Enabled=No|');
        Observer.Expect('Language Selection row es-CU', 'Name=Spanish (Cuba)|Language Tag=es-CU|Language ID=23562|Primary Language ID=1034|Abbreviated Name=ESK|Enabled=No|');
        Observer.Expect('Language Selection row es-DO', 'Name=Spanish (Dominican Republic)|Language Tag=es-DO|Language ID=7178|Primary Language ID=1034|Abbreviated Name=ESD|Enabled=No|');
        Observer.Expect('Language Selection row es-EC', 'Name=Spanish (Ecuador)|Language Tag=es-EC|Language ID=12298|Primary Language ID=1034|Abbreviated Name=ESF|Enabled=No|');
        Observer.Expect('Language Selection row es-ES', 'Name=Spanish (Spain)|Language Tag=es-ES|Language ID=3082|Primary Language ID=1034|Abbreviated Name=ESN|Enabled=Yes|');
        Observer.Expect('Language Selection row es-ES_tradnl', 'Name=Spanish (Spain, Sort Order=tradnl)|Language Tag=es-ES_tradnl|Language ID=1034|Primary Language ID=1034|Abbreviated Name=ESP|Enabled=Yes|');
        Observer.Expect('Language Selection row es-GT', 'Name=Spanish (Guatemala)|Language Tag=es-GT|Language ID=4106|Primary Language ID=1034|Abbreviated Name=ESG|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_09()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'es-HN~es-NI~es-PA~es-PE~es-PR~es-PY~es-US~es-UY');
        Observer.Expect('Language Selection row es-HN', 'Name=Spanish (Honduras)|Language Tag=es-HN|Language ID=18442|Primary Language ID=1034|Abbreviated Name=ESH|Enabled=No|');
        Observer.Expect('Language Selection row es-NI', 'Name=Spanish (Nicaragua)|Language Tag=es-NI|Language ID=19466|Primary Language ID=1034|Abbreviated Name=ESI|Enabled=No|');
        Observer.Expect('Language Selection row es-PA', 'Name=Spanish (Panama)|Language Tag=es-PA|Language ID=6154|Primary Language ID=1034|Abbreviated Name=ESA|Enabled=No|');
        Observer.Expect('Language Selection row es-PE', 'Name=Spanish (Peru)|Language Tag=es-PE|Language ID=10250|Primary Language ID=1034|Abbreviated Name=ESR|Enabled=No|');
        Observer.Expect('Language Selection row es-PR', 'Name=Spanish (Puerto Rico)|Language Tag=es-PR|Language ID=20490|Primary Language ID=1034|Abbreviated Name=ESU|Enabled=No|');
        Observer.Expect('Language Selection row es-PY', 'Name=Spanish (Paraguay)|Language Tag=es-PY|Language ID=15370|Primary Language ID=1034|Abbreviated Name=ESZ|Enabled=No|');
        Observer.Expect('Language Selection row es-US', 'Name=Spanish (United States)|Language Tag=es-US|Language ID=21514|Primary Language ID=1034|Abbreviated Name=EST|Enabled=No|');
        Observer.Expect('Language Selection row es-UY', 'Name=Spanish (Uruguay)|Language Tag=es-UY|Language ID=14346|Primary Language ID=1034|Abbreviated Name=ESY|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'es-VE~eu-ES~fa-IR~ff-Latn-SN~ff-NG~fi-FI~fil-PH~fr-BE');
        Observer.Expect('Language Selection row es-VE', 'Name=Spanish (Venezuela)|Language Tag=es-VE|Language ID=8202|Primary Language ID=1034|Abbreviated Name=ESV|Enabled=No|');
        Observer.Expect('Language Selection row eu-ES', 'Name=Basque (Spain)|Language Tag=eu-ES|Language ID=1069|Primary Language ID=1069|Abbreviated Name=EUQ|Enabled=No|');
        Observer.Expect('Language Selection row fa-IR', 'Name=Persian (Iran)|Language Tag=fa-IR|Language ID=1065|Primary Language ID=1065|Abbreviated Name=FAR|Enabled=No|');
        Observer.Expect('Language Selection row ff-Latn-SN', 'Name=Fula (Latin, Senegal)|Language Tag=ff-Latn-SN|Language ID=2151|Primary Language ID=1127|Abbreviated Name=FUL|Enabled=No|');
#if BC29PLUS
        Observer.Expect('Language Selection row ff-NG', 'Name=Fula (Nigeria)|Language Tag=ff-NG|Language ID=1127|Primary Language ID=1127|Abbreviated Name=ZZZ|Enabled=No|');
#else
        Observer.Expect('Language Selection row ff-NG', '<absent>');
#endif
        Observer.Expect('Language Selection row fi-FI', 'Name=Finnish (Finland)|Language Tag=fi-FI|Language ID=1035|Primary Language ID=1035|Abbreviated Name=FIN|Enabled=Yes|');
        Observer.Expect('Language Selection row fil-PH', 'Name=Filipino (Philippines)|Language Tag=fil-PH|Language ID=1124|Primary Language ID=1124|Abbreviated Name=FPO|Enabled=No|');
        Observer.Expect('Language Selection row fr-BE', 'Name=French (Belgium)|Language Tag=fr-BE|Language ID=2060|Primary Language ID=1036|Abbreviated Name=FRB|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'fr-CA~fr-CD~fr-CH~fr-CI~fr-CM~fr-FR~fr-HT~fr-LU');
        Observer.Expect('Language Selection row fr-CA', 'Name=French (Canada)|Language Tag=fr-CA|Language ID=3084|Primary Language ID=1036|Abbreviated Name=FRC|Enabled=Yes|');
        Observer.Expect('Language Selection row fr-CD', 'Name=French (Congo - Kinshasa)|Language Tag=fr-CD|Language ID=9228|Primary Language ID=1036|Abbreviated Name=FRD|Enabled=No|');
        Observer.Expect('Language Selection row fr-CH', 'Name=French (Switzerland)|Language Tag=fr-CH|Language ID=4108|Primary Language ID=1036|Abbreviated Name=FRS|Enabled=Yes|');
        Observer.Expect('Language Selection row fr-CI', 'Name=French (Côte d’Ivoire)|Language Tag=fr-CI|Language ID=12300|Primary Language ID=1036|Abbreviated Name=FRI|Enabled=No|');
        Observer.Expect('Language Selection row fr-CM', 'Name=French (Cameroon)|Language Tag=fr-CM|Language ID=11276|Primary Language ID=1036|Abbreviated Name=FRE|Enabled=No|');
        Observer.Expect('Language Selection row fr-FR', 'Name=French (France)|Language Tag=fr-FR|Language ID=1036|Primary Language ID=1036|Abbreviated Name=FRA|Enabled=Yes|');
        Observer.Expect('Language Selection row fr-HT', 'Name=French (Haiti)|Language Tag=fr-HT|Language ID=15372|Primary Language ID=1036|Abbreviated Name=FRH|Enabled=No|');
        Observer.Expect('Language Selection row fr-LU', 'Name=French (Luxembourg)|Language Tag=fr-LU|Language ID=5132|Primary Language ID=1036|Abbreviated Name=FRL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'fr-MA~fr-RE~fr-SN~fy-NL~ga-IE~gd-GB~gl-ES~gsw-FR');
        Observer.Expect('Language Selection row fr-MA', 'Name=French (Morocco)|Language Tag=fr-MA|Language ID=14348|Primary Language ID=1036|Abbreviated Name=FRO|Enabled=No|');
        Observer.Expect('Language Selection row fr-RE', 'Name=French (Réunion)|Language Tag=fr-RE|Language ID=8204|Primary Language ID=1036|Abbreviated Name=FRR|Enabled=No|');
        Observer.Expect('Language Selection row fr-SN', 'Name=French (Senegal)|Language Tag=fr-SN|Language ID=10252|Primary Language ID=1036|Abbreviated Name=FRN|Enabled=No|');
        Observer.Expect('Language Selection row fy-NL', 'Name=Western Frisian (Netherlands)|Language Tag=fy-NL|Language ID=1122|Primary Language ID=1122|Abbreviated Name=FYN|Enabled=No|');
        Observer.Expect('Language Selection row ga-IE', 'Name=Irish (Ireland)|Language Tag=ga-IE|Language ID=2108|Primary Language ID=1084|Abbreviated Name=IRE|Enabled=No|');
        Observer.Expect('Language Selection row gd-GB', 'Name=Scottish Gaelic (United Kingdom)|Language Tag=gd-GB|Language ID=1169|Primary Language ID=1169|Abbreviated Name=GLA|Enabled=No|');
        Observer.Expect('Language Selection row gl-ES', 'Name=Galician (Spain)|Language Tag=gl-ES|Language ID=1110|Primary Language ID=1110|Abbreviated Name=GLC|Enabled=No|');
        Observer.Expect('Language Selection row gsw-FR', 'Name=Swiss German (France)|Language Tag=gsw-FR|Language ID=1156|Primary Language ID=1156|Abbreviated Name=GSW|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'gu-IN~haw-US~he-IL~hi-IN~hr-BA~hr-HR~hsb-DE~hu-HU');
        Observer.Expect('Language Selection row gu-IN', 'Name=Gujarati (India)|Language Tag=gu-IN|Language ID=1095|Primary Language ID=1095|Abbreviated Name=GUJ|Enabled=No|');
        Observer.Expect('Language Selection row haw-US', 'Name=Hawaiian (United States)|Language Tag=haw-US|Language ID=1141|Primary Language ID=1141|Abbreviated Name=HAW|Enabled=No|');
        Observer.Expect('Language Selection row he-IL', 'Name=Hebrew (Israel)|Language Tag=he-IL|Language ID=1037|Primary Language ID=1037|Abbreviated Name=HEB|Enabled=No|');
        Observer.Expect('Language Selection row hi-IN', 'Name=Hindi (India)|Language Tag=hi-IN|Language ID=1081|Primary Language ID=1081|Abbreviated Name=HIN|Enabled=No|');
        Observer.Expect('Language Selection row hr-BA', 'Name=Croatian (Bosnia & Herzegovina)|Language Tag=hr-BA|Language ID=4122|Primary Language ID=1050|Abbreviated Name=HRB|Enabled=No|');
        Observer.Expect('Language Selection row hr-HR', 'Name=Croatian (Croatia)|Language Tag=hr-HR|Language ID=1050|Primary Language ID=1050|Abbreviated Name=HRV|Enabled=Yes|');
        Observer.Expect('Language Selection row hsb-DE', 'Name=Upper Sorbian (Germany)|Language Tag=hsb-DE|Language ID=1070|Primary Language ID=1070|Abbreviated Name=HSB|Enabled=No|');
        Observer.Expect('Language Selection row hu-HU', 'Name=Hungarian (Hungary)|Language Tag=hu-HU|Language ID=1038|Primary Language ID=1038|Abbreviated Name=HUN|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_14()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'hy-AM~ig-NG~ii-CN~is-IS~it-CH~it-IT~ja-JP~ka-GE');
        Observer.Expect('Language Selection row hy-AM', 'Name=Armenian (Armenia)|Language Tag=hy-AM|Language ID=1067|Primary Language ID=1067|Abbreviated Name=HYE|Enabled=No|');
        Observer.Expect('Language Selection row ig-NG', 'Name=Igbo (Nigeria)|Language Tag=ig-NG|Language ID=1136|Primary Language ID=1136|Abbreviated Name=IBO|Enabled=No|');
        Observer.Expect('Language Selection row ii-CN', 'Name=Sichuan Yi (China)|Language Tag=ii-CN|Language ID=1144|Primary Language ID=1144|Abbreviated Name=III|Enabled=No|');
        Observer.Expect('Language Selection row is-IS', 'Name=Icelandic (Iceland)|Language Tag=is-IS|Language ID=1039|Primary Language ID=1039|Abbreviated Name=ISL|Enabled=Yes|');
        Observer.Expect('Language Selection row it-CH', 'Name=Italian (Switzerland)|Language Tag=it-CH|Language ID=2064|Primary Language ID=1040|Abbreviated Name=ITS|Enabled=Yes|');
        Observer.Expect('Language Selection row it-IT', 'Name=Italian (Italy)|Language Tag=it-IT|Language ID=1040|Primary Language ID=1040|Abbreviated Name=ITA|Enabled=Yes|');
        Observer.Expect('Language Selection row ja-JP', 'Name=Japanese (Japan)|Language Tag=ja-JP|Language ID=1041|Primary Language ID=1041|Abbreviated Name=JPN|Enabled=Yes|');
        Observer.Expect('Language Selection row ka-GE', 'Name=Georgian (Georgia)|Language Tag=ka-GE|Language ID=1079|Primary Language ID=1079|Abbreviated Name=KAT|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'kk-KZ~kl-GL~km-KH~kn-IN~ko-KR~kok-IN~lb-LU~lo-LA');
        Observer.Expect('Language Selection row kk-KZ', 'Name=Kazakh (Kazakhstan)|Language Tag=kk-KZ|Language ID=1087|Primary Language ID=1087|Abbreviated Name=KKZ|Enabled=No|');
        Observer.Expect('Language Selection row kl-GL', 'Name=Kalaallisut (Greenland)|Language Tag=kl-GL|Language ID=1135|Primary Language ID=1135|Abbreviated Name=KAL|Enabled=No|');
        Observer.Expect('Language Selection row km-KH', 'Name=Khmer (Cambodia)|Language Tag=km-KH|Language ID=1107|Primary Language ID=1107|Abbreviated Name=KHM|Enabled=No|');
        Observer.Expect('Language Selection row kn-IN', 'Name=Kannada (India)|Language Tag=kn-IN|Language ID=1099|Primary Language ID=1099|Abbreviated Name=KDI|Enabled=No|');
        Observer.Expect('Language Selection row ko-KR', 'Name=Korean (South Korea)|Language Tag=ko-KR|Language ID=1042|Primary Language ID=1042|Abbreviated Name=KOR|Enabled=Yes|');
        Observer.Expect('Language Selection row kok-IN', 'Name=Konkani (India)|Language Tag=kok-IN|Language ID=1111|Primary Language ID=1111|Abbreviated Name=KNK|Enabled=No|');
        Observer.Expect('Language Selection row lb-LU', 'Name=Luxembourgish (Luxembourg)|Language Tag=lb-LU|Language ID=1134|Primary Language ID=1134|Abbreviated Name=LBX|Enabled=No|');
        Observer.Expect('Language Selection row lo-LA', 'Name=Lao (Laos)|Language Tag=lo-LA|Language ID=1108|Primary Language ID=1108|Abbreviated Name=LAO|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'lt-LT~lv-LV~mi-NZ~mk-MK~ml-IN~mn-MN~ms-BN~ms-MY');
        Observer.Expect('Language Selection row lt-LT', 'Name=Lithuanian (Lithuania)|Language Tag=lt-LT|Language ID=1063|Primary Language ID=1063|Abbreviated Name=LTH|Enabled=Yes|');
        Observer.Expect('Language Selection row lv-LV', 'Name=Latvian (Latvia)|Language Tag=lv-LV|Language ID=1062|Primary Language ID=1062|Abbreviated Name=LVI|Enabled=Yes|');
        Observer.Expect('Language Selection row mi-NZ', 'Name=Māori (New Zealand)|Language Tag=mi-NZ|Language ID=1153|Primary Language ID=1153|Abbreviated Name=MRI|Enabled=No|');
        Observer.Expect('Language Selection row mk-MK', 'Name=Macedonian (North Macedonia)|Language Tag=mk-MK|Language ID=1071|Primary Language ID=1071|Abbreviated Name=MKI|Enabled=No|');
        Observer.Expect('Language Selection row ml-IN', 'Name=Malayalam (India)|Language Tag=ml-IN|Language ID=1100|Primary Language ID=1100|Abbreviated Name=MYM|Enabled=No|');
        Observer.Expect('Language Selection row mn-MN', 'Name=Mongolian (Mongolia)|Language Tag=mn-MN|Language ID=1104|Primary Language ID=1104|Abbreviated Name=MNN|Enabled=No|');
        Observer.Expect('Language Selection row ms-BN', 'Name=Malay (Brunei)|Language Tag=ms-BN|Language ID=2110|Primary Language ID=1086|Abbreviated Name=MSB|Enabled=No|');
        Observer.Expect('Language Selection row ms-MY', 'Name=Malay (Malaysia)|Language Tag=ms-MY|Language ID=1086|Primary Language ID=1086|Abbreviated Name=MSL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_17()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'mt-MT~my-MM~nb-NO~ne-NP~nl-BE~nl-NL~nn-NO~oc-FR');
        Observer.Expect('Language Selection row mt-MT', 'Name=Maltese (Malta)|Language Tag=mt-MT|Language ID=1082|Primary Language ID=1082|Abbreviated Name=MLT|Enabled=No|');
        Observer.Expect('Language Selection row my-MM', 'Name=Burmese (Myanmar [Burma])|Language Tag=my-MM|Language ID=1109|Primary Language ID=1109|Abbreviated Name=MYA|Enabled=No|');
        Observer.Expect('Language Selection row nb-NO', 'Name=Norwegian Bokmål (Norway)|Language Tag=nb-NO|Language ID=1044|Primary Language ID=1044|Abbreviated Name=NOR|Enabled=Yes|');
        Observer.Expect('Language Selection row ne-NP', 'Name=Nepali (Nepal)|Language Tag=ne-NP|Language ID=1121|Primary Language ID=1121|Abbreviated Name=NEP|Enabled=No|');
        Observer.Expect('Language Selection row nl-BE', 'Name=Dutch (Belgium)|Language Tag=nl-BE|Language ID=2067|Primary Language ID=1043|Abbreviated Name=NLB|Enabled=Yes|');
        Observer.Expect('Language Selection row nl-NL', 'Name=Dutch (Netherlands)|Language Tag=nl-NL|Language ID=1043|Primary Language ID=1043|Abbreviated Name=NLD|Enabled=Yes|');
        Observer.Expect('Language Selection row nn-NO', 'Name=Norwegian Nynorsk (Norway)|Language Tag=nn-NO|Language ID=2068|Primary Language ID=1044|Abbreviated Name=NON|Enabled=No|');
        Observer.Expect('Language Selection row oc-FR', 'Name=Occitan (France)|Language Tag=oc-FR|Language ID=1154|Primary Language ID=1154|Abbreviated Name=OCI|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_18()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'om-ET~or-IN~pa-Arab-PK~pa-IN~pt-BR~pt-PT~rm-CH~ro-MD');
        Observer.Expect('Language Selection row om-ET', 'Name=Oromo (Ethiopia)|Language Tag=om-ET|Language ID=1138|Primary Language ID=1138|Abbreviated Name=ORM|Enabled=No|');
        Observer.Expect('Language Selection row or-IN', 'Name=Odia (India)|Language Tag=or-IN|Language ID=1096|Primary Language ID=1096|Abbreviated Name=ORI|Enabled=No|');
        Observer.Expect('Language Selection row pa-Arab-PK', 'Name=Punjabi (Arabic, Pakistan)|Language Tag=pa-Arab-PK|Language ID=2118|Primary Language ID=1094|Abbreviated Name=PAP|Enabled=No|');
#if BC29PLUS
        Observer.Expect('Language Selection row pa-IN', 'Name=Punjabi (India)|Language Tag=pa-IN|Language ID=1094|Primary Language ID=1094|Abbreviated Name=PAN|Enabled=No|');
#else
        Observer.Expect('Language Selection row pa-IN', '<absent>');
#endif
        Observer.Expect('Language Selection row pt-BR', 'Name=Portuguese (Brazil)|Language Tag=pt-BR|Language ID=1046|Primary Language ID=1046|Abbreviated Name=PTB|Enabled=Yes|');
        Observer.Expect('Language Selection row pt-PT', 'Name=Portuguese (Portugal)|Language Tag=pt-PT|Language ID=2070|Primary Language ID=1046|Abbreviated Name=PTG|Enabled=Yes|');
        Observer.Expect('Language Selection row rm-CH', 'Name=Romansh (Switzerland)|Language Tag=rm-CH|Language ID=1047|Primary Language ID=1047|Abbreviated Name=RMC|Enabled=No|');
        Observer.Expect('Language Selection row ro-MD', 'Name=Romanian (Moldova)|Language Tag=ro-MD|Language ID=2072|Primary Language ID=1048|Abbreviated Name=ROD|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_19()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'ro-RO~ru-MD~ru-RU~rw-RW~sah-RU~sd-Arab-PK~sd-Deva-IN~se-FI');
        Observer.Expect('Language Selection row ro-RO', 'Name=Romanian (Romania)|Language Tag=ro-RO|Language ID=1048|Primary Language ID=1048|Abbreviated Name=ROM|Enabled=Yes|');
        Observer.Expect('Language Selection row ru-MD', 'Name=Russian (Moldova)|Language Tag=ru-MD|Language ID=2073|Primary Language ID=1049|Abbreviated Name=RUM|Enabled=No|');
        Observer.Expect('Language Selection row ru-RU', 'Name=Russian (Russia)|Language Tag=ru-RU|Language ID=1049|Primary Language ID=1049|Abbreviated Name=RUS|Enabled=Yes|');
        Observer.Expect('Language Selection row rw-RW', 'Name=Kinyarwanda (Rwanda)|Language Tag=rw-RW|Language ID=1159|Primary Language ID=1159|Abbreviated Name=KIN|Enabled=No|');
        Observer.Expect('Language Selection row sah-RU', 'Name=Yakut (Russia)|Language Tag=sah-RU|Language ID=1157|Primary Language ID=1157|Abbreviated Name=SAH|Enabled=No|');
        Observer.Expect('Language Selection row sd-Arab-PK', 'Name=Sindhi (Arabic, Pakistan)|Language Tag=sd-Arab-PK|Language ID=2137|Primary Language ID=1113|Abbreviated Name=SIP|Enabled=No|');
#if BC29PLUS
        Observer.Expect('Language Selection row sd-Deva-IN', 'Name=Sindhi (Devanagari, India)|Language Tag=sd-Deva-IN|Language ID=1113|Primary Language ID=1113|Abbreviated Name=ZZZ|Enabled=No|');
#else
        Observer.Expect('Language Selection row sd-Deva-IN', '<absent>');
#endif
        Observer.Expect('Language Selection row se-FI', 'Name=Northern Sami (Finland)|Language Tag=se-FI|Language ID=3131|Primary Language ID=1083|Abbreviated Name=SMG|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_20()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'se-NO~se-SE~si-LK~sk-SK~sl-SI~smn-FI~so-SO~sq-AL');
        Observer.Expect('Language Selection row se-NO', 'Name=Northern Sami (Norway)|Language Tag=se-NO|Language ID=1083|Primary Language ID=1083|Abbreviated Name=SME|Enabled=No|');
        Observer.Expect('Language Selection row se-SE', 'Name=Northern Sami (Sweden)|Language Tag=se-SE|Language ID=2107|Primary Language ID=1083|Abbreviated Name=SMF|Enabled=No|');
        Observer.Expect('Language Selection row si-LK', 'Name=Sinhala (Sri Lanka)|Language Tag=si-LK|Language ID=1115|Primary Language ID=1115|Abbreviated Name=SIN|Enabled=No|');
        Observer.Expect('Language Selection row sk-SK', 'Name=Slovak (Slovakia)|Language Tag=sk-SK|Language ID=1051|Primary Language ID=1051|Abbreviated Name=SKY|Enabled=Yes|');
        Observer.Expect('Language Selection row sl-SI', 'Name=Slovenian (Slovenia)|Language Tag=sl-SI|Language ID=1060|Primary Language ID=1060|Abbreviated Name=SLV|Enabled=Yes|');
        Observer.Expect('Language Selection row smn-FI', 'Name=Inari Sami (Finland)|Language Tag=smn-FI|Language ID=9275|Primary Language ID=1083|Abbreviated Name=SMN|Enabled=No|');
        Observer.Expect('Language Selection row so-SO', 'Name=Somali (Somalia)|Language Tag=so-SO|Language ID=1143|Primary Language ID=1143|Abbreviated Name=SOM|Enabled=No|');
        Observer.Expect('Language Selection row sq-AL', 'Name=Albanian (Albania)|Language Tag=sq-AL|Language ID=1052|Primary Language ID=1052|Abbreviated Name=SQI|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_21()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'sr~sr-Cyrl-ME~sr-Cyrl-RS~sr-Latn-BA~sr-Latn-ME~sr-Latn-RS~sv-FI~sv-SE');
        Observer.Expect('Language Selection row sr', 'Name=Serbian|Language Tag=sr|Language ID=31770|Primary Language ID=1050|Abbreviated Name=SRB|Enabled=No|');
        Observer.Expect('Language Selection row sr-Cyrl-ME', 'Name=Serbian (Cyrillic, Montenegro)|Language Tag=sr-Cyrl-ME|Language ID=12314|Primary Language ID=1050|Abbreviated Name=SRQ|Enabled=No|');
        Observer.Expect('Language Selection row sr-Cyrl-RS', 'Name=Serbian (Cyrillic, Serbia)|Language Tag=sr-Cyrl-RS|Language ID=10266|Primary Language ID=1050|Abbreviated Name=SRO|Enabled=No|');
        Observer.Expect('Language Selection row sr-Latn-BA', 'Name=Serbian (Latin, Bosnia & Herzegovina)|Language Tag=sr-Latn-BA|Language ID=6170|Primary Language ID=1050|Abbreviated Name=SRS|Enabled=No|');
        Observer.Expect('Language Selection row sr-Latn-ME', 'Name=Serbian (Latin, Montenegro)|Language Tag=sr-Latn-ME|Language ID=11290|Primary Language ID=1050|Abbreviated Name=SRP|Enabled=No|');
        Observer.Expect('Language Selection row sr-Latn-RS', 'Name=Serbian (Latin, Serbia)|Language Tag=sr-Latn-RS|Language ID=9242|Primary Language ID=1050|Abbreviated Name=SRM|Enabled=Yes|');
        Observer.Expect('Language Selection row sv-FI', 'Name=Swedish (Finland)|Language Tag=sv-FI|Language ID=2077|Primary Language ID=1053|Abbreviated Name=SVF|Enabled=No|');
        Observer.Expect('Language Selection row sv-SE', 'Name=Swedish (Sweden)|Language Tag=sv-SE|Language ID=1053|Primary Language ID=1053|Abbreviated Name=SVE|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_22()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'sw-KE~syr-SY~ta-IN~ta-LK~te-IN~th-TH~ti-ER~ti-ET');
        Observer.Expect('Language Selection row sw-KE', 'Name=Swahili (Kenya)|Language Tag=sw-KE|Language ID=1089|Primary Language ID=1089|Abbreviated Name=SWK|Enabled=No|');
        Observer.Expect('Language Selection row syr-SY', 'Name=Syriac (Syria)|Language Tag=syr-SY|Language ID=1114|Primary Language ID=1114|Abbreviated Name=SYR|Enabled=No|');
        Observer.Expect('Language Selection row ta-IN', 'Name=Tamil (India)|Language Tag=ta-IN|Language ID=1097|Primary Language ID=1097|Abbreviated Name=TAI|Enabled=No|');
        Observer.Expect('Language Selection row ta-LK', 'Name=Tamil (Sri Lanka)|Language Tag=ta-LK|Language ID=2121|Primary Language ID=1097|Abbreviated Name=TAM|Enabled=No|');
        Observer.Expect('Language Selection row te-IN', 'Name=Telugu (India)|Language Tag=te-IN|Language ID=1098|Primary Language ID=1098|Abbreviated Name=TEL|Enabled=No|');
        Observer.Expect('Language Selection row th-TH', 'Name=Thai (Thailand)|Language Tag=th-TH|Language ID=1054|Primary Language ID=1054|Abbreviated Name=THA|Enabled=Yes|');
        Observer.Expect('Language Selection row ti-ER', 'Name=Tigrinya (Eritrea)|Language Tag=ti-ER|Language ID=2163|Primary Language ID=1139|Abbreviated Name=TIR|Enabled=No|');
        Observer.Expect('Language Selection row ti-ET', 'Name=Tigrinya (Ethiopia)|Language Tag=ti-ET|Language ID=1139|Primary Language ID=1139|Abbreviated Name=TIE|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_23()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'tk-TM~tr-TR~tt-RU~ug-CN~uk-UA~ur-IN~ur-PK~uz-Cyrl-UZ');
        Observer.Expect('Language Selection row tk-TM', 'Name=Turkmen (Turkmenistan)|Language Tag=tk-TM|Language ID=1090|Primary Language ID=1090|Abbreviated Name=TUK|Enabled=No|');
        Observer.Expect('Language Selection row tr-TR', 'Name=Turkish (Türkiye)|Language Tag=tr-TR|Language ID=1055|Primary Language ID=1055|Abbreviated Name=TRK|Enabled=Yes|');
        Observer.Expect('Language Selection row tt-RU', 'Name=Tatar (Russia)|Language Tag=tt-RU|Language ID=1092|Primary Language ID=1092|Abbreviated Name=TTT|Enabled=No|');
        Observer.Expect('Language Selection row ug-CN', 'Name=Uyghur (China)|Language Tag=ug-CN|Language ID=1152|Primary Language ID=1152|Abbreviated Name=UIG|Enabled=No|');
        Observer.Expect('Language Selection row uk-UA', 'Name=Ukrainian (Ukraine)|Language Tag=uk-UA|Language ID=1058|Primary Language ID=1058|Abbreviated Name=UKR|Enabled=Yes|');
        Observer.Expect('Language Selection row ur-IN', 'Name=Urdu (India)|Language Tag=ur-IN|Language ID=2080|Primary Language ID=1056|Abbreviated Name=URI|Enabled=No|');
        Observer.Expect('Language Selection row ur-PK', 'Name=Urdu (Pakistan)|Language Tag=ur-PK|Language ID=1056|Primary Language ID=1056|Abbreviated Name=URD|Enabled=No|');
        Observer.Expect('Language Selection row uz-Cyrl-UZ', 'Name=Uzbek (Cyrillic, Uzbekistan)|Language Tag=uz-Cyrl-UZ|Language ID=2115|Primary Language ID=1091|Abbreviated Name=UZC|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_24()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'vi-VN~xh-ZA~yo-NG~zh-CN~zh-Hant~zh-TW~zu-ZA');
        Observer.Expect('Language Selection row vi-VN', 'Name=Vietnamese (Vietnam)|Language Tag=vi-VN|Language ID=1066|Primary Language ID=1066|Abbreviated Name=VIT|Enabled=Yes|');
        Observer.Expect('Language Selection row xh-ZA', 'Name=Xhosa (South Africa)|Language Tag=xh-ZA|Language ID=1076|Primary Language ID=1076|Abbreviated Name=XHO|Enabled=No|');
        Observer.Expect('Language Selection row yo-NG', 'Name=Yoruba (Nigeria)|Language Tag=yo-NG|Language ID=1130|Primary Language ID=1130|Abbreviated Name=YOR|Enabled=No|');
        Observer.Expect('Language Selection row zh-CN', 'Name=Chinese (China)|Language Tag=zh-CN|Language ID=2052|Primary Language ID=1028|Abbreviated Name=CHS|Enabled=Yes|');
        Observer.Expect('Language Selection row zh-Hant', 'Name=Chinese (Traditional)|Language Tag=zh-Hant|Language ID=31748|Primary Language ID=1028|Abbreviated Name=ZHH|Enabled=No|');
#if BC29PLUS
        Observer.Expect('Language Selection row zh-TW', 'Name=Chinese (Taiwan)|Language Tag=zh-TW|Language ID=1028|Primary Language ID=1028|Abbreviated Name=CHT|Enabled=Yes|');
#else
        Observer.Expect('Language Selection row zh-TW', '<absent>');
#endif
        Observer.Expect('Language Selection row zu-ZA', 'Name=Zulu (South Africa)|Language Tag=zu-ZA|Language ID=1077|Primary Language ID=1077|Abbreviated Name=ZUL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_25()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'bn-BD~de-CH~de-LI~en-ID');
        Observer.Expect('Language Selection row bn-BD', 'Name=Bangla (Bangladesh)|Language Tag=bn-BD|Language ID=2117|Primary Language ID=1093|Abbreviated Name=BNB|Enabled=No|');
        Observer.Expect('Language Selection row de-CH', 'Name=German (Switzerland)|Language Tag=de-CH|Language ID=2055|Primary Language ID=1031|Abbreviated Name=DES|Enabled=Yes|');
        Observer.Expect('Language Selection row de-LI', 'Name=German (Liechtenstein)|Language Tag=de-LI|Language ID=5127|Primary Language ID=1031|Abbreviated Name=DEC|Enabled=No|');
        Observer.Expect('Language Selection row en-ID', 'Name=English (Indonesia)|Language Tag=en-ID|Language ID=14345|Primary Language ID=1033|Abbreviated Name=ZZZ|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_26()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'en-IE~es-MX~es-SV~et-EE');
        Observer.Expect('Language Selection row en-IE', 'Name=English (Ireland)|Language Tag=en-IE|Language ID=6153|Primary Language ID=1033|Abbreviated Name=ENI|Enabled=No|');
        Observer.Expect('Language Selection row es-MX', 'Name=Spanish (Mexico)|Language Tag=es-MX|Language ID=2058|Primary Language ID=1034|Abbreviated Name=ESM|Enabled=Yes|');
        Observer.Expect('Language Selection row es-SV', 'Name=Spanish (El Salvador)|Language Tag=es-SV|Language ID=17418|Primary Language ID=1034|Abbreviated Name=ESE|Enabled=No|');
        Observer.Expect('Language Selection row et-EE', 'Name=Estonian (Estonia)|Language Tag=et-EE|Language ID=1061|Primary Language ID=1061|Abbreviated Name=ETI|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_27()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'fo-FO~fr-MC~fr-ML~id-ID');
        Observer.Expect('Language Selection row fo-FO', 'Name=Faroese (Faroe Islands)|Language Tag=fo-FO|Language ID=1080|Primary Language ID=1080|Abbreviated Name=FOS|Enabled=No|');
        Observer.Expect('Language Selection row fr-MC', 'Name=French (Monaco)|Language Tag=fr-MC|Language ID=6156|Primary Language ID=1036|Abbreviated Name=FRM|Enabled=No|');
        Observer.Expect('Language Selection row fr-ML', 'Name=French (Mali)|Language Tag=fr-ML|Language ID=13324|Primary Language ID=1036|Abbreviated Name=FRF|Enabled=No|');
        Observer.Expect('Language Selection row id-ID', 'Name=Indonesian (Indonesia)|Language Tag=id-ID|Language ID=1057|Primary Language ID=1057|Abbreviated Name=IND|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_28()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'ky-KG~mr-IN~ne-IN~pl-PL');
        Observer.Expect('Language Selection row ky-KG', 'Name=Kyrgyz (Kyrgyzstan)|Language Tag=ky-KG|Language ID=1088|Primary Language ID=1088|Abbreviated Name=KYR|Enabled=No|');
        Observer.Expect('Language Selection row mr-IN', 'Name=Marathi (India)|Language Tag=mr-IN|Language ID=1102|Primary Language ID=1102|Abbreviated Name=MAR|Enabled=No|');
        Observer.Expect('Language Selection row ne-IN', 'Name=Nepali (India)|Language Tag=ne-IN|Language ID=2145|Primary Language ID=1121|Abbreviated Name=NEI|Enabled=No|');
        Observer.Expect('Language Selection row pl-PL', 'Name=Polish (Poland)|Language Tag=pl-PL|Language ID=1045|Primary Language ID=1045|Abbreviated Name=PLK|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_29()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'ps-AF~sa-IN~sr-Cyrl-BA~uz-Latn-UZ');
        Observer.Expect('Language Selection row ps-AF', 'Name=Pashto (Afghanistan)|Language Tag=ps-AF|Language ID=1123|Primary Language ID=1123|Abbreviated Name=PAS|Enabled=No|');
        Observer.Expect('Language Selection row sa-IN', 'Name=Sanskrit (India)|Language Tag=sa-IN|Language ID=1103|Primary Language ID=1103|Abbreviated Name=SAN|Enabled=No|');
        Observer.Expect('Language Selection row sr-Cyrl-BA', 'Name=Serbian (Cyrillic, Bosnia & Herzegovina)|Language Tag=sr-Cyrl-BA|Language ID=7194|Primary Language ID=1050|Abbreviated Name=SRN|Enabled=No|');
        Observer.Expect('Language Selection row uz-Latn-UZ', 'Name=Uzbek (Latin, Uzbekistan)|Language Tag=uz-Latn-UZ|Language ID=1091|Primary Language ID=1091|Abbreviated Name=UZB|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_30()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DumpKeys(Observer, 'Language Selection', 'Language Tag', 0, 'wo-SN');
        Observer.Expect('Language Selection row wo-SN', 'Name=Wolof (Senegal)|Language Tag=wo-SN|Language ID=1160|Primary Language ID=1160|Abbreviated Name=WOL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Count_LanguageSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(TableIdByName('Language Selection'));
        Observer.Observe('count', Format(RR.Count()));
#if BC29PLUS
        Observer.Expect('count', '212');
#else
        Observer.Expect('count', '208');
#endif
        Observer.Verify();
    end;
}
