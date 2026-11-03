// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 92356 (LT Y35 UN Table, CustomerContent), 95020, 95021
// Probe (al-runner issue 6890): the Field rows of SystemId and the audit fields (No. 2000000000-2000000004): what DataClassification, Class,
//   Type, FieldName, Enabled and ObsoleteState they carry in a table that declares CustomerContent, ToBeClassified or no DataClassification, by
//   Field.Get and in a SetRange(TableNo) walk. The user-name rows 2000000005-2000000008 are pinned in Y35UserNameFieldRows.al.

table 95020 "LT R6890 No Class Table"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95021 "LT R6890 ToBeClass Table"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 95022 "LT R6890 System Field Class"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RowText(var F: Record Field): Text
    begin
        exit(F.FieldName + ': DataClassification=' + Format(F.DataClassification, 0, 9) + '; Class=' + Format(F.Class, 0, 9) + '; Type=' + Format(F.Type, 0, 9) +
            '; Enabled=' + Format(F.Enabled) + '; ObsoleteState=' + Format(F.ObsoleteState, 0, 9));
    end;

    local procedure ObserveRows(Prefix: Text; TableNo: Integer)
    var
        F: Record Field;
        No: Integer;
    begin
        for No := 0 to 2000000004 do begin
            if No = 5 then
                No := 2000000000;
            if F.Get(TableNo, No) then
                Observer.Observe(Prefix + ' get ' + Format(No), RowText(F))
            else
                Observer.Observe(Prefix + ' get ' + Format(No), 'not found');
        end;
    end;

    local procedure Walk(Prefix: Text; TableNo: Integer)
    var
        F: Record Field;
        Result: Text;
    begin
        F.SetRange(TableNo, TableNo);
        F.SetFilter("No.", '>=%1&<=%2', 2000000000, 2000000004);
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + '=' + Format(F.DataClassification, 0, 9) + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk', Result);
        F.SetRange(DataClassification, F.DataClassification::SystemMetadata);
        Result := '';
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk SystemMetadata', Result);
        F.SetRange(DataClassification, F.DataClassification::EndUserPseudonymousIdentifiers);
        Result := '';
        if F.FindSet() then
            repeat
                Result += Format(F."No.") + ',';
            until F.Next() = 0;
        Observer.Observe(Prefix + ' walk EndUserPseudonymousIdentifiers', Result);
    end;

    [Test]
    procedure R6890_SystemFieldRows_CustomerContentTable()
    begin
        ObserveRows('cc', Database::"LT Y35 UN Table");
        Walk('cc', Database::"LT Y35 UN Table");
        Observer.Finish();
    end;

    [Test]
    procedure R6890_SystemFieldRows_NoClassificationTable()
    begin
        ObserveRows('none', Database::"LT R6890 No Class Table");
        Walk('none', Database::"LT R6890 No Class Table");
        Observer.Finish();
    end;

    [Test]
    procedure R6890_SystemFieldRows_ToBeClassifiedTable()
    begin
        ObserveRows('tbc', Database::"LT R6890 ToBeClass Table");
        Walk('tbc', Database::"LT R6890 ToBeClass Table");
        Observer.Finish();
    end;
}
