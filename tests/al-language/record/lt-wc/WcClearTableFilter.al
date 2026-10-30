// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method-record
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90646, table 90647
// Probe: written against al-runner issue 6318 (Clear of a TableFilter field); every value asserted below is what the BC service tier produced.
// Facts: Clear on a TableFilter field of a record: an empty one, one that holds a filter, one read back from the database, and Clear of the whole record.
// BC versions: 27, 28, 29

table 90647 "LT WC Job"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Table No."; Integer) { }
        field(3; "Table Filter"; TableFilter) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 90646 "LT WC Clear Table Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup(var Job: Record "LT WC Job")
    var
        RecRef: RecordRef;
        TF: FieldRef;
    begin
        Job.DeleteAll();
        Job.Init();
        Job.Code := 'J1';
        Job."Table No." := Database::"LT WC Job";
        Job.Insert();
        RecRef.GetTable(Job);
        TF := RecRef.Field(3);
        TF.Value := 'LT WC Job: Code=1';
        RecRef.SetTable(Job);
    end;

    [Test]
    procedure WC_Clear_TableFilter_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Job: Record "LT WC Job";
    begin
        Job.Code := 'J1';
        Job."Table No." := Database::"LT WC Job";
        Clear(Job."Table Filter");
        Observer.Observe('after Clear', Format(Job."Table Filter"));
        Observer.Observe('table no kept', Format(Job."Table No."));
        Observer.Finish();
    end;

    [Test]
    procedure WC_Clear_TableFilter_WithValue()
    var
        Observer: Codeunit "Probe Observer";
        Job: Record "LT WC Job";
    begin
        Setup(Job);
        Observer.Observe('before Clear', Format(Job."Table Filter"));
        Clear(Job."Table Filter");
        Observer.Observe('after Clear', Format(Job."Table Filter"));
        Job.Modify();
        Job.Get('J1');
        Observer.Observe('after Modify and Get', Format(Job."Table Filter"));
        Observer.Finish();
    end;

    [Test]
    procedure WC_Clear_TableFilter_ReadFromDatabase()
    var
        Observer: Codeunit "Probe Observer";
        Job: Record "LT WC Job";
        Fresh: Record "LT WC Job";
    begin
        Setup(Job);
        Fresh.Get('J1');
        Observer.Observe('read', Format(Fresh."Table Filter"));
        Clear(Fresh."Table Filter");
        Observer.Observe('after Clear', Format(Fresh."Table Filter"));
        Job.Get('J1');
        Observer.Observe('stored row unchanged', Format(Job."Table Filter"));
        Clear(Job);
        Observer.Observe('after Clear of the record', Format(Job."Table Filter") + '|' + Job.Code + '|' + Format(Job."Table No."));
        Observer.Finish();
    end;
}
