// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78760..78764 (BVL Row, BVL Callee, BVL Caller, BVL By Value Load Tests, BVL Run Caller)
// local object: what a by-value copy holds of the caller's SetLoadFields and partly loaded row is what is under test, so the table's
//   fields and keys are part of the claim.
// Probe (al-runner issue 8839): a caller sets SetLoadFields, reads a row with it, then hands the record by value to a procedure (a
//   Record parameter without var). record/filters/ByValueRecordView.al measures a SetLoadFields set before any read only
//   (ByValue_SetLoadFields). Base Application's codeunit 5895 "Inventory Adjustment" does this for every applied inbound entry: it
//   sets a secondary key, a filter and its load fields, reads with FindSet, narrows the record to one document and hands it to
//   CalcInbndDocOldCost, a local procedure whose first call on the copy is SetCurrentKey.
//   Cells: SetLoadFields of one field then FindSet, FindFirst and Get; FindFirst then SetLoadFields; every field requested; no filter
//   on the primary key; a secondary key with a filter set after the read (the codeunit 5895 shape) from a codeunit that is not a test
//   codeunit, into another codeunit's procedure and into its own local procedure; a local procedure of the test codeunit; the caller
//   reading a field it did not load before the hand-off; a codeunit's OnRun trigger as the caller.
//   In each cell the callee reports, before it reads anything, which fields of the copy are loaded and the value of a field the
//   caller did not load; then the copy's view; then, after its own SetCurrentKey, SetRange and FindSet, which fields are loaded and
//   the sum it read. The caller reports its view, its loaded fields and its next row after the call.
// Facts (measured on a local BC 29.0.54011.55407; 27.5 and 28.5 by the corpus CI):
//   - the copy has the view of a fresh record (no filters, the primary key, ascending, filter group 0), as in
//     record/filters/ByValueRecordView.al;
//   - the copy as handed has the fields the caller's row has loaded: with SetLoadFields(Name) and then a read, Name is loaded and
//     Amount is not; with the read first and SetLoadFields after it, every field is; a read of an unloaded field of the copy
//     loads it with the row's value; a field the caller read before the hand-off (and so loaded) is loaded on the copy too;
//   - the caller's SetLoadFields is not handed on: after the copy's own FindSet every field of it is loaded;
//   - this holds from a test codeunit, from a codeunit that is not a test codeunit and from a codeunit's OnRun trigger, into another
//     codeunit's procedure, into a local procedure of the calling codeunit and with no filter on the primary key;
//   - the caller's filters, key, loaded fields and next row are unchanged after every call.
// BC versions: 27.5, 28.5, 29.0

table 78760 "BVL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Status; Option) { OptionMembers = Open,Posted; }
        field(4; Amount; Decimal) { }
        field(5; Doc; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByStatusDoc; Status, Doc) { }
    }
}

codeunit 78761 "BVL Callee"
{
    procedure Describe(R: Record "BVL Row"): Text
    begin
        exit(DescribeCopy(R));
    end;

    // Reads the by-value copy R of its caller; R is that copy, passed on by var so every read is a read of the copy.
    procedure DescribeCopy(var R: Record "BVL Row"): Text
    var
        Before: Text;
        View: Text;
        After: Text;
        Total: Decimal;
    begin
        Before := 'name loaded=' + Format(R.AreFieldsLoaded(R.Name)) + ' amount loaded=' + Format(R.AreFieldsLoaded(R.Amount))
            + ' id=' + Format(R.Id) + ' amount=' + Format(R.Amount) + ' amount loaded now=' + Format(R.AreFieldsLoaded(R.Amount));
        View := 'f={' + R.GetFilters() + '} key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending()) + ' grp=' + Format(R.FilterGroup())
            + ' n=' + Format(R.Count());
        R.SetCurrentKey(Status, Doc);
        R.SetRange(Status, R.Status::Posted);
        if R.FindSet() then begin
            After := 'first=' + Format(R.Id) + ' name loaded=' + Format(R.AreFieldsLoaded(R.Name)) + ' amount loaded='
                + Format(R.AreFieldsLoaded(R.Amount));
            repeat
                Total += R.Amount;
            until R.Next() = 0;
        end else
            After := 'none';
        exit(Before + ' | ' + View + ' | ' + After + ' total=' + Format(Total));
    end;
}

// Not a test codeunit: the codeunit 5895 shape, a codeunit that reads rows and hands each one on by value.
codeunit 78762 "BVL Caller"
{
    // Sets a secondary key, a filter and its load fields (through a procedure with a var parameter, as codeunit 5895 does), reads
    // with FindSet, narrows the record to the row's document and hands it to another codeunit's procedure (ToLocal = false) or to its
    // own local procedure (ToLocal = true). Returns what each callee read and the caller's state after the loop.
    procedure Run(ToLocal: Boolean): Text
    var
        Row: Record "BVL Row";
        Callee: Codeunit "BVL Callee";
        Result: Text;
    begin
        Row.SetCurrentKey(Status, Doc);
        Row.SetRange(Status, Row.Status::Posted);
        LoadFields(Row);
        if not Row.FindSet() then
            exit('none');
        repeat
            Row.SetRange(Doc, Row.Doc);
            if ToLocal then
                Result += DescribeLocal(Row) + ' ## '
            else
                Result += Callee.Describe(Row) + ' ## ';
            Result += 'caller f={' + Row.GetFilters() + '} key=' + Row.CurrentKey() + ' amount loaded='
                + Format(Row.AreFieldsLoaded(Row.Amount)) + ' ## ';
            Row.SetRange(Doc);
        until Row.Next() = 0;
        exit(Result);
    end;

    local procedure DescribeLocal(R: Record "BVL Row"): Text
    var
        Callee: Codeunit "BVL Callee";
    begin
        exit(Callee.DescribeCopy(R));
    end;

    local procedure LoadFields(var Row: Record "BVL Row")
    begin
        Row.SetLoadFields(Id, Status, Doc);
    end;
}

codeunit 78763 "BVL By Value Load Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Callee: Codeunit "BVL Callee";

    local procedure Initialize()
    var
        Row: Record "BVL Row";
    begin
        Row.DeleteAll();
        Insert(1, 'A', 0, 10, 'D1');
        Insert(2, 'B', 1, 20, 'D2');
        Insert(3, 'C', 1, 30, 'D3');
    end;

    local procedure Insert(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal; Doc: Code[10])
    var
        Row: Record "BVL Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Doc := Doc;
        Row.Insert();
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Row: Record "BVL Row")
    var
        NextId: Text;
    begin
        Observer.Observe('caller after', 'f={' + Row.GetFilters() + '} key=' + Row.CurrentKey() + ' id=' + Format(Row.Id)
            + ' name loaded=' + Format(Row.AreFieldsLoaded(Row.Name)) + ' amount loaded=' + Format(Row.AreFieldsLoaded(Row.Amount)));
        if Row.Next() = 0 then
            NextId := 'none'
        else
            NextId := Format(Row.Id);
        Observer.Observe('caller next', NextId);
    end;

    local procedure DescribeLocal(R: Record "BVL Row"): Text
    begin
        exit(Callee.DescribeCopy(R));
    end;

    [Test]
    procedure ByValueLoad_LoadFieldsThenFindSet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.FindSet();
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=No');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_LoadFieldsThenFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=No');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_LoadFieldsThenGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.Get(2);
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=No');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_FindFirstThenLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.FindFirst();
        Row.SetLoadFields(Name);
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=Yes id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=Yes');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_EveryFieldThenFindSet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Id, Name, Status, Amount, Doc);
        Row.FindSet();
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=Yes id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=Yes');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_NoFilterThenFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=1 amount=10 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={} key=Id id=1 name loaded=Yes amount loaded=No');
        Observer.Expect('caller next', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_SecondaryKeyNarrowedThenFindSet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetCurrentKey(Status, Doc);
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Id, Status, Doc);
        Row.FindSet();
        Row.SetRange(Doc, Row.Doc);
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=No amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted, Doc: D2} key=Status,Doc id=2 name loaded=No amount loaded=No');
        Observer.Expect('caller next', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_LocalProcedureOfTestCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.FindSet();
        Observer.Observe('callee', DescribeLocal(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=No');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_CodeunitLoopToOtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Caller: Codeunit "BVL Caller";
    begin
        Initialize();
        Observer.Observe('loop', Caller.Run(false));
        Observer.Expect('loop', 'name loaded=No amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50 ## caller f={Status: Posted, Doc: D2} key=Status,Doc amount loaded=No ## name loaded=No amount loaded=No id=3 amount=30 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50 ## caller f={Status: Posted, Doc: D3} key=Status,Doc amount loaded=No ## ');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_CodeunitLoopToLocalProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Caller: Codeunit "BVL Caller";
    begin
        Initialize();
        Observer.Observe('loop', Caller.Run(true));
        Observer.Expect('loop', 'name loaded=No amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50 ## caller f={Status: Posted, Doc: D2} key=Status,Doc amount loaded=No ## name loaded=No amount loaded=No id=3 amount=30 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50 ## caller f={Status: Posted, Doc: D3} key=Status,Doc amount loaded=No ## ');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_CallerReadsUnloadedFieldFirst()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVL Row";
        Amount: Decimal;
    begin
        Initialize();
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Amount := Row.Amount;
        Observer.Observe('caller amount', Format(Amount));
        Observer.Observe('callee', Callee.Describe(Row));
        ObserveCaller(Observer, Row);
        Observer.Expect('caller amount', '20');
        Observer.Expect('callee', 'name loaded=Yes amount loaded=Yes id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Expect('caller after', 'f={Status: Posted} key=Id id=2 name loaded=Yes amount loaded=Yes');
        Observer.Expect('caller next', '3');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueLoad_FromCodeunitOnRun()
    var
        Observer: Codeunit "Probe Observer";
        RunCaller: Codeunit "BVL Run Caller";
    begin
        Initialize();
        RunCaller.Run();
        Observer.Observe('callee', RunCaller.Result());
        Observer.Expect('callee', 'name loaded=Yes amount loaded=No id=2 amount=20 amount loaded now=Yes | f={} key=Id asc=Yes grp=0 n=3 | first=2 name loaded=Yes amount loaded=Yes total=50');
        Observer.Verify();
    end;
}

// A codeunit whose OnRun trigger reads a row with SetLoadFields and hands it on by value: the caller is a trigger, not a
// procedure.
codeunit 78764 "BVL Run Caller"
{
    var
        Described: Text;

    trigger OnRun()
    var
        Row: Record "BVL Row";
        Callee: Codeunit "BVL Callee";
    begin
        Row.SetRange(Status, Row.Status::Posted);
        Row.SetLoadFields(Name);
        Row.FindSet();
        Described := Callee.Describe(Row);
    end;

    procedure Result(): Text
    begin
        exit(Described);
    end;
}
