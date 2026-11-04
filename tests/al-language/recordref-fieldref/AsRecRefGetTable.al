// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79902, 79904, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 2).
// Facts: B.GetTable(V) with V a Variant that holds a RecordRef A (B.GetTable(A) itself does not compile: must-not-compile case 1140): A open on a filtered table with a found row (what B holds, and whether a later change of A's
//   field value, filter or current row shows in B); A not open; B already open on another table.
// BC versions: 27-29

codeunit 79921 "LT AS RecRef GetTable Ref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    // B.GetTable(A) with A a RecordRef does not compile (AL0133, must-not-compile case 1140); a Variant that holds the RecordRef does.
    local procedure GetTableOf(var B: RecordRef; var A: RecordRef)
    var
        V: Variant;
    begin
        V := A;
        B.GetTable(V);
    end;

    local procedure OpenA(var A: RecordRef)
    begin
        Helper.SeedRows();
        A.Open(Database::"LT AS Row");
        A.Field(2).SetFilter('<>beta');
        A.FindLast();
    end;

    [Test]
    procedure FromFilteredFoundRow()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        OpenA(A);
        GetTableOf(B, A);
        Observer.Observe('number', Format(B.Number));
        Observer.Observe('filters', B.GetFilters());
        Observer.Observe('row', Format(B.Field(1).Value));
        Observer.Observe('count', Format(B.Count()));
        Observer.Expect('number', '79902');
        Observer.Expect('filters', 'Name: <>beta');
        Observer.Expect('row', 'C');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeValueOfA_ReadB()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        OpenA(A);
        GetTableOf(B, A);
        A.Field(2).Value := 'changed';
        Observer.Observe('b_name', Format(B.Field(2).Value));
        B.Field(3).Value := 42;
        Observer.Observe('a_amount', Format(A.Field(3).Value));
        Observer.Expect('b_name', 'gamma');
        Observer.Expect('a_amount', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeFilterAndRowOfA_ReadB()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        OpenA(A);
        GetTableOf(B, A);
        A.Field(2).SetRange();
        A.FindFirst();
        Observer.Observe('b_filters', B.GetFilters());
        Observer.Observe('b_row', Format(B.Field(1).Value));
        Observer.Expect('b_filters', 'Name: <>beta');
        Observer.Expect('b_row', 'C');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyThroughB_ReadA()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        OpenA(A);
        GetTableOf(B, A);
        B.Field(2).Value := 'via b';
        B.Modify();
        Observer.Observe('a_name', Format(A.Field(2).Value));
        A.Find('=');
        Observer.Observe('a_name_refind', Format(A.Field(2).Value));
        Observer.Expect('a_name', 'gamma');
        Observer.Expect('a_name_refind', 'via b');
        Observer.Verify();
    end;

    [Test]
    procedure FromNotOpen()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        Helper.SeedRows();
        ClearLastError();
        asserterror GetTableOf(B, A);
        Observer.Observe('error', Helper.LastError());
        Observer.Observe('b_open', Format(B.Number));
        Observer.Expect('error', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|Conversion');
        Observer.Expect('b_open', '0');
        Observer.Verify();
    end;

    [Test]
    procedure IntoRefOpenOnOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        A: RecordRef;
        B: RecordRef;
    begin
        OpenA(A);
        B.Open(Database::"LT AS Other");
        GetTableOf(B, A);
        Observer.Observe('number', Format(B.Number));
        Observer.Observe('row', Format(B.Field(1).Value));
        Observer.Observe('filters', B.GetFilters());
        Observer.Expect('number', '79902');
        Observer.Expect('row', 'C');
        Observer.Expect('filters', 'Name: <>beta');
        Observer.Verify();
    end;
}
