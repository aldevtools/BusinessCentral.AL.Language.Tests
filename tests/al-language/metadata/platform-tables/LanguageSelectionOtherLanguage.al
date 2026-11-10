// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-globallanguage-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 75118
// Probe (observe only): al-runner issue 7463. PlatformRowsLanguageSelection.al pins every row of the platform table Language Selection in session
//   language 1033. Base Application table 5050 Contact (UpdateFormatRegion) reads it with a filter on Language ID after the test switched the session
//   language to German. This probe asks what the table holds after GlobalLanguage(1031), GlobalLanguage(1036) and GlobalLanguage(1030):
//   the row count, how many rows have another Name than in 1033 (and the first three of them), every column of the rows de-DE, en-US, fr-FR,
//   de-AT and da-DK, the tags of the first three rows in read order, the row that FindFirst answers for Language ID = 1031 and = 1033
//   (the Contact shape), and whether the names are the 1033 names again after the language is set back. The same for the Name of rows 1031 and 1033 of Windows Language.
//   The tables are read through RecordRef by table name, as in PlatformRowsLanguageSelection.al.
// Linux suspect: the names come from the operating system's culture data. The 1033 rows had to be corrected from Windows containers
//   (aldevtools/MsDyn365Bc.On.Linux issue 223); check the values of this probe on a Windows container before asserting them.
// BC versions: 27, 28, 29

codeunit 75118 "LT LSO Language Selection Lang"
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

    local procedure FieldText(var RR: RecordRef; FieldName: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = FieldName then
                exit(Format(FR.Value(), 0, 9));
        end;
        exit('<no field ' + FieldName + '>');
    end;

    local procedure RowText(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Class() = FieldClass::Normal then
                Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure Names(TableName: Text; KeyField: Text; var Result: Dictionary of [Text, Text])
    var
        RR: RecordRef;
    begin
        Clear(Result);
        RR.Open(TableIdByName(TableName));
        if RR.FindSet() then
            repeat
                Result.Set(FieldText(RR, KeyField), FieldText(RR, 'Name'));
            until RR.Next() = 0;
        RR.Close();
    end;

    local procedure SetFieldFilter(var RR: RecordRef; FieldName: Text; Value: Integer)
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name() = FieldName then begin
                FR.SetRange(Value);
                exit;
            end;
        end;
    end;

    local procedure ObserveLanguageSelection(var Observer: Codeunit "Probe Observer"; Prefix: Text; var EnglishNames: Dictionary of [Text, Text])
    var
        RR: RecordRef;
        Rows: Dictionary of [Text, Text];
        Tag: Text;
        ReadOrder: Text;
        Different: Text;
        DifferentCount: Integer;
        Position: Integer;
    begin
        RR.Open(TableIdByName('Language Selection'));
        Observer.Observe(Prefix + ' count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Position += 1;
                Tag := FieldText(RR, 'Language Tag');
                Rows.Set(Tag, RowText(RR));
                if Position <= 3 then
                    ReadOrder += Tag + ';';
                if EnglishNames.ContainsKey(Tag) then
                    if EnglishNames.Get(Tag) <> FieldText(RR, 'Name') then begin
                        DifferentCount += 1;
                        if DifferentCount <= 3 then
                            Different += Tag + '=' + FieldText(RR, 'Name') + ';';
                    end;
            until RR.Next() = 0;
        Observer.Observe(Prefix + ' first three tags in read order', ReadOrder);
        Observer.Observe(Prefix + ' rows with another name than in 1033', Format(DifferentCount) + ' [' + Different + ']');
        foreach Tag in 'de-DE~en-US~fr-FR~de-AT~da-DK'.Split('~') do
            if Rows.ContainsKey(Tag) then
                Observer.Observe(Prefix + ' row ' + Tag, Rows.Get(Tag))
            else
                Observer.Observe(Prefix + ' row ' + Tag, '<absent>');
        RR.Reset();
        SetFieldFilter(RR, 'Language ID', 1031);
        if RR.FindFirst() then
            Observer.Observe(Prefix + ' FindFirst for Language ID 1031', FieldText(RR, 'Language Tag') + ' of ' + Format(RR.Count()))
        else
            Observer.Observe(Prefix + ' FindFirst for Language ID 1031', 'not found');
        RR.Reset();
        SetFieldFilter(RR, 'Language ID', 1033);
        if RR.FindFirst() then
            Observer.Observe(Prefix + ' FindFirst for Language ID 1033', FieldText(RR, 'Language Tag') + ' of ' + Format(RR.Count()))
        else
            Observer.Observe(Prefix + ' FindFirst for Language ID 1033', 'not found');
        RR.Close();
    end;

    local procedure RunIn(LanguageId: Integer)
    var
        Observer: Codeunit "Probe Observer";
        EnglishNames: Dictionary of [Text, Text];
        NamesAfter: Dictionary of [Text, Text];
        Tag: Text;
        Before: Integer;
        Changed: Integer;
    begin
        Before := GlobalLanguage();
        GlobalLanguage(1033);
        Names('Language Selection', 'Language Tag', EnglishNames);
        GlobalLanguage(LanguageId);
        Observer.Observe('GlobalLanguage', Format(GlobalLanguage()));
        ObserveLanguageSelection(Observer, 'in ' + Format(LanguageId), EnglishNames);
        GlobalLanguage(1033);
        Names('Language Selection', 'Language Tag', NamesAfter);
        foreach Tag in EnglishNames.Keys() do
            if NamesAfter.ContainsKey(Tag) then
                if NamesAfter.Get(Tag) <> EnglishNames.Get(Tag) then
                    Changed += 1;
        Observer.Observe('back in 1033 count', Format(NamesAfter.Count()));
        Observer.Observe('back in 1033 rows with another name than before', Format(Changed));
        GlobalLanguage(Before);
        Observer.Finish();
    end;

    [Test]
    procedure LanguageSelection_AfterGlobalLanguage1031()
    begin
        RunIn(1031);
    end;

    [Test]
    procedure LanguageSelection_AfterGlobalLanguage1036()
    begin
        RunIn(1036);
    end;

    [Test]
    procedure LanguageSelection_AfterGlobalLanguage1030()
    begin
        RunIn(1030);
    end;

    [Test]
    procedure WindowsLanguage_Names_AfterGlobalLanguage1031()
    var
        Observer: Codeunit "Probe Observer";
        English: Dictionary of [Text, Text];
        German: Dictionary of [Text, Text];
        LanguageKey: Text;
        Before: Integer;
        DifferentCount: Integer;
    begin
        Before := GlobalLanguage();
        GlobalLanguage(1033);
        Names('Windows Language', 'Language ID', English);
        GlobalLanguage(1031);
        Names('Windows Language', 'Language ID', German);
        GlobalLanguage(Before);
        Observer.Observe('count in 1033', Format(English.Count()));
        Observer.Observe('count in 1031', Format(German.Count()));
        foreach LanguageKey in English.Keys() do
            if German.ContainsKey(LanguageKey) then
                if German.Get(LanguageKey) <> English.Get(LanguageKey) then
                    DifferentCount += 1;
        Observer.Observe('rows with another name in 1031', Format(DifferentCount));
        foreach LanguageKey in '1031~1033~1036~3079'.Split('~') do begin
            if English.ContainsKey(LanguageKey) then
                Observer.Observe('1033 name of ' + LanguageKey, English.Get(LanguageKey))
            else
                Observer.Observe('1033 name of ' + LanguageKey, '<absent>');
            if German.ContainsKey(LanguageKey) then
                Observer.Observe('1031 name of ' + LanguageKey, German.Get(LanguageKey))
            else
                Observer.Observe('1031 name of ' + LanguageKey, '<absent>');
        end;
        Observer.Finish();
    end;
}
