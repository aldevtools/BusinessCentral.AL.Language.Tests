// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-caption-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 85547, test codeunit 85548
// Probe: corpus issue 670 (AL issue 6303): a table whose Caption is 120 characters long. What TableMetadata.Caption (a Text[80] field),
// AllObjWithCaption."Object Caption" (Text[249]) and RecordRef.Caption return: the length and the text.
// Facts (BC 29 local): all three return the full 120 characters; TableMetadata.Caption is not cut to 80.
// BC versions: 27.5, 28.5, 29.0
table 85547 "LT CY Long Caption"
{
    Caption = 'CY long caption abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85548 "LT CY Long Caption Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTableMetadata(var Caption: Text)
    var
        TableMeta: Record "Table Metadata";
    begin
        TableMeta.Get(Database::"LT CY Long Caption");
        Caption := TableMeta.Caption;
    end;

    [Test]
    procedure CY_TableCaption_LongerThan80_PerSource()
    var
        Observer: Codeunit "Probe Observer";
        AllObj: Record AllObjWithCaption;
        RecRef: RecordRef;
        Caption: Text;
    begin
        ClearLastError();
        if TryTableMetadata(Caption) then
            Observer.Observe('table metadata', Format(StrLen(Caption)) + '|' + Caption)
        else
            Observer.Observe('table metadata', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        AllObj.Get(AllObj."Object Type"::Table, Database::"LT CY Long Caption");
        Observer.Observe('allobjwithcaption', Format(StrLen(AllObj."Object Caption")) + '|' + AllObj."Object Caption");
        RecRef.Open(Database::"LT CY Long Caption");
        Observer.Observe('recordref', Format(StrLen(RecRef.Caption())) + '|' + RecRef.Caption());
        RecRef.Close();
        Observer.Expect('table metadata', '120|CY long caption abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd');
        Observer.Expect('allobjwithcaption', '120|CY long caption abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd');
        Observer.Expect('recordref', '120|CY long caption abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd');
        Observer.Verify();
    end;
}
