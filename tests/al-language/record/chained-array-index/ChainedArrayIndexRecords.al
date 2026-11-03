// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): A[x][y] on a two-dimensional array of Record and of RecordRef; own file so a compile error drops only this one.
// Facts: the chained form on an array of records (Backup Storage test library: array[20, 1000] of RecordRef pattern) -- here a two-dimensional array of Record.
// BC versions: 29 (27 and 28 by CI)

table 74837 "LT P168 Chain Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74838 "LT P168 Chained Array Rec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P168_Chained_ArrayOfRecords()
    var
        Observer: Codeunit "Probe Observer";
        R: array[2, 3] of Record "LT P168 Chain Row" temporary;
        RR: array[2, 3] of RecordRef;
    begin
        R[2][3].Id := 7;
        R[2][3].Insert();
        Observer.Observe('rec-chained', Format(R[2][3].Id));
        Observer.Observe('rec-comma', Format(R[2, 3].Id));
        Observer.Observe('rec-count-chained', Format(R[2][3].Count()));
        Observer.Observe('rec-other-empty', Format(R[1][1].Count()));
        RR[1][2].Open(Database::"LT P168 Chain Row", true);
        Observer.Observe('rr-chained-open', Format(RR[1][2].Number()));
        Observer.Observe('rr-comma-open', Format(RR[1, 2].Number()));
        Observer.Expect('rec-chained', '7');
        Observer.Expect('rec-comma', '7');
        Observer.Expect('rec-count-chained', '1');
        Observer.Expect('rec-other-empty', '1');
        Observer.Expect('rr-chained-open', '74837');
        Observer.Expect('rr-comma-open', '74837');
        Observer.Verify();
    end;
}
