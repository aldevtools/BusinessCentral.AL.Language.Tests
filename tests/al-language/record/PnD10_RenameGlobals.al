// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72053, codeunit 72054
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Table globals (above the Page Insert and Modify row): Rename - OnRename runs on the variable's instance like the other write triggers; not probed
// Facts: the table global Trace after Insert, Rename and Modify on the same variable, on a copy of the variable, and after a failing Rename (key already taken); what Rec and xRec hold in OnRename
// BC versions: 29 (27 and 28 by CI)

table 72053 "LT PnD Rename Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Trace: Text;

    procedure GetTrace(): Text
    begin
        exit(Trace);
    end;

    procedure SetTrace(NewTrace: Text)
    begin
        Trace := NewTrace;
    end;

    trigger OnInsert()
    begin
        Trace += 'insert(' + Format(Id) + ');';
    end;

    trigger OnModify()
    begin
        Trace += 'modify(' + Format(Id) + ' x=' + Format(xRec.Id) + ');';
    end;

    trigger OnRename()
    begin
        Trace += 'rename(' + Format(Id) + ' x=' + Format(xRec.Id) + ');';
    end;
}

codeunit 72054 "LT PnD Rename Globals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Rename_SameVariable_SeesGlobalsOfInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('afterInsert', Row.GetTrace());
        Row.Rename(2);
        Observer.Observe('afterRename', Row.GetTrace());
        Observer.Observe('idAfterRename', Format(Row.Id));
        Row.Name := 'x';
        Row.Modify(true);
        Observer.Observe('afterModify', Row.GetTrace());
        Observer.Expect('afterInsert', 'insert(1);');
        Observer.Expect('afterRename', 'insert(1);rename(2 x=1);');
        Observer.Expect('idAfterRename', '2');
        Observer.Expect('afterModify', 'insert(1);rename(2 x=1);modify(2 x=2);');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_FreshVariable_SeesOnlyItsOwn()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
        Other: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert(true);
        Other.Get(1);
        Observer.Observe('otherBefore', Other.GetTrace());
        Other.Rename(5);
        Observer.Observe('otherAfter', Other.GetTrace());
        Observer.Observe('rowAfter', Row.GetTrace());
        Observer.Expect('otherBefore', '');
        Observer.Expect('otherAfter', 'rename(5 x=1);');
        Observer.Expect('rowAfter', 'insert(1);');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_CopyOfVariable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
        CopyRow: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert(true);
        CopyRow := Row;
        Observer.Observe('copyTrace', CopyRow.GetTrace());
        CopyRow.Rename(7);
        Observer.Observe('copyAfterRename', CopyRow.GetTrace());
        Observer.Observe('rowTrace', Row.GetTrace());
        Observer.Expect('copyTrace', '');
        Observer.Expect('copyAfterRename', 'rename(7 x=1);');
        Observer.Expect('rowTrace', 'insert(1);');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_ClearAndReset_ResetTheGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert(true);
        Row.Rename(2);
        Row.Reset();
        Observer.Observe('afterReset', Row.GetTrace());
        Row.Rename(3);
        Observer.Observe('renameAfterReset', Row.GetTrace());
        Clear(Row);
        Observer.Observe('afterClear', Row.GetTrace());
        Observer.Expect('afterReset', '');
        Observer.Expect('renameAfterReset', 'rename(3 x=2);');
        Observer.Expect('afterClear', '');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_AfterSetTraceEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetTrace('');
        Row.Rename(2);
        Observer.Observe('renameAfterEmptyTrace', Row.GetTrace());
        Observer.Expect('renameAfterEmptyTrace', 'rename(2 x=1);');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_KeyTaken_Fails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Get(1);
        Row.SetTrace('');
        asserterror Row.Rename(2);
        Observer.ObserveError('keyTaken');
        Observer.Observe('traceAfterFailure', Row.GetTrace());
        Observer.Expect('keyTaken|text', 'The record in table LT PnD Rename Row already exists. Identification fields and values: Id=''2''');
        Observer.Expect('keyTaken|code', 'DB:RecordExists');
        Observer.Expect('traceAfterFailure', 'rename(2 x=1);');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_TriggerSeesIdAndXRec()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rename Row";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Insert();
        Row.SetTrace('');
        Row.Rename(11);
        Row.Rename(12);
        Observer.Observe('trace', Row.GetTrace());
        Observer.Expect('trace', 'rename(11 x=10);rename(12 x=11);');
        Observer.Verify();
    end;
}
