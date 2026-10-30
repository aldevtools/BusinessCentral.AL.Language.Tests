// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: Record.Get(RecordId) with a RecordId of another table (al-runtime-rs docs/probes-needed.md, "`Record.Get(RecordId)`"; the text for tables
// without a Caption is pinned in GetRecordId.al:123-164): GetLastErrorText and GetLastErrorCode after the used form `if R.Get(O.RecordId) then;`
// (after ClearLastError and after an earlier error), and the error text of the unused form when both tables have a Caption that differs from the name.
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).

table 91410 "LT Y8 Get Row"
{
    Caption = 'Y8 Row Caption';
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

table 91411 "LT Y8 Get Other"
{
    Caption = 'Y8 Other Caption';
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

codeunit 91410 "LT Y8 Get RecordId Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y8_Get_OtherTable_Unused_WithCaptions()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 Get Row";
        O: Record "LT Y8 Get Other";
    begin
        O.DeleteAll();
        O.Id := 5;
        O.Insert();
        asserterror R.Get(O.RecordId);
        Observer.ObserveError('unused');
        Observer.Finish();
    end;

    [Test]
    procedure Y8_Get_OtherTable_Used_LastError()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 Get Row";
        O: Record "LT Y8 Get Other";
    begin
        O.DeleteAll();
        O.Id := 5;
        O.Insert();
        ClearLastError();
        if R.Get(O.RecordId) then;
        Observer.Observe('after_clear_text', GetLastErrorText());
        Observer.Observe('after_clear_code', GetLastErrorCode());
        asserterror Error('Y8 earlier error');
        if R.Get(O.RecordId) then;
        Observer.Observe('after_error_text', GetLastErrorText());
        Observer.Observe('after_error_code', GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure Y8_Get_MissingRow_Used_LastError()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 Get Row";
        Probe: Record "LT Y8 Get Row";
    begin
        R.DeleteAll();
        Probe.Id := 9;
        Probe.Insert();
        Probe.Delete();
        ClearLastError();
        if R.Get(Probe.RecordId) then;
        Observer.Observe('missing_text', GetLastErrorText());
        Observer.Observe('missing_code', GetLastErrorCode());
        Observer.Finish();
    end;
}
