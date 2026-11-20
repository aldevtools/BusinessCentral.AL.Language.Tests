// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78810..78814 (BVA Head, BVA Detail, BVA Buffer, BVA Callee,
//   BVA By Value AutoCalc Tests)
// local object: the FlowFields of the table, the callee table's procedures and the caller's SetAutoCalcFields are what is
//   under test.
// Probe (al-runner issue 8538): what a procedure sees of the caller's SetAutoCalcFields when it gets a record of a stored table
//   by value (a Record parameter without var). ByValueRecordView.al (codeunit 78728) and ByValueTableProcedureView.al
//   (codeunit 78794) measured the view of such a copy with no SetAutoCalcFields. Cells:
//   - the control: the caller's own reads with SetAutoCalcFields, and RecordRef.GetTable of the caller's record;
//   - a codeunit procedure: a filter in group 0 after FindFirst (the issue's shape), SetAutoCalcFields without a filter and
//     without a read, a declared secondary key without a filter, two FlowFields, and a rich view (secondary key, descending, a
//     filter in groups 0 and 2, a marked row);
//   - the copy handed on as a Variant to RecordRef.GetTable, from a codeunit procedure and from a local procedure of the test
//     codeunit (the issue's repro);
//   - a table procedure whose parameter is a record of another table (Buffer.Proc(Head)), with a filter and with a declared
//     secondary key and no filter;
//   - a table procedure whose parameter is a record of its own table, called on that record (Head.Proc(Head));
//   In each callee: the FlowField's value at entry, the filters, Count, the key, then FindLast and the FlowField's value of
//   the row it reads, and in every cell the caller's filters, key and FlowField after a FindLast of its own.
//   Each table procedure also has a rich view (secondary key, descending, filters in groups 0 and 2, two FlowFields, a mark).
// Facts (observed on a local BC 29.1 OnPrem W1 container; 27.5 and 28.5 by the corpus CI):
//   - RecordRef.GetTable of the caller's own record keeps its SetAutoCalcFields (FindLast calculates 30);
//   - a by-value copy keeps the field values of the caller's current row, its calculated FlowFields included (total=10,
//     count=2 for two FlowFields), and has the view of a fresh record (no filters, primary key, ascending);
//   - the copy does not keep the caller's SetAutoCalcFields: its own FindLast, and a FindLast of a RecordRef that GetTable
//     took of it through a Variant, leave the FlowFields 0 (lastTotal=0 lastCount=0), for a codeunit procedure, a local
//     procedure of the test codeunit, a table procedure of another table and Head.Proc(Head);
//   - the caller keeps its filters, key and SetAutoCalcFields after every call.
// BC versions: 27.5, 28.5, 29.0

table 78810 "BVA Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Code[10]) { }
        field(3; "Line Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVA Detail".Amount where("Head No." = field("No.")));
            Editable = false;
        }
        field(4; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("BVA Detail" where("Head No." = field("No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByKind; Kind) { }
    }

    procedure DescribeOwn(Copy: Record "BVA Head"): Text
    var
        Callee: Codeunit "BVA Callee";
    begin
        exit('self f={' + Rec.GetFilters() + '} copy ' + Callee.DescribeVar(Copy));
    end;
}

table 78811 "BVA Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys { key(PK; "Head No.", "Line No.") { Clustered = true; } }
}

table 78812 "BVA Buffer"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    procedure DescribeHead(H: Record "BVA Head"): Text
    var
        Callee: Codeunit "BVA Callee";
    begin
        exit(Callee.DescribeVar(H));
    end;
}

codeunit 78813 "BVA Callee"
{
    // Reads the copy as it arrives, then FindLast. The table procedures hand their by-value copy to DescribeVar by `var`, so
    // what it reads is that copy itself.
    procedure Describe(H: Record "BVA Head"): Text
    begin
        exit(DescribeVar(H));
    end;

    procedure DescribeVar(var H: Record "BVA Head"): Text
    var
        Result: Text;
    begin
        Result := 'no=' + H."No." + ' total=' + Format(H."Line Total", 0, 9) + ' count=' + Format(H."Line Count") + ' f={' + H.GetFilters() + '} n='
            + Format(H.Count()) + ' key=' + H.CurrentKey() + ' asc=' + Format(H.Ascending());
        if H.FindLast() then
            Result += ' last=' + H."No." + ' lastTotal=' + Format(H."Line Total", 0, 9) + ' lastCount=' + Format(H."Line Count")
        else
            Result += ' last=none';
        exit(Result);
    end;

    procedure DescribeVariant(Value: Variant): Text
    var
        RecRef: RecordRef;
        Rows: Integer;
    begin
        RecRef.GetTable(Value);
        Rows := RecRef.Count();
        RecRef.FindLast();
        exit(StrSubstNo('no=%1 f={%2} n=%3 lastTotal=%4', RecRef.Field(1).Value, RecRef.GetFilters(), Rows, Format(RecRef.Field(3).Value, 0, 9)));
    end;

    procedure DescribeCopyAsVariant(HeadCopy: Record "BVA Head"): Text
    begin
        exit(DescribeVariant(HeadCopy));
    end;
}

codeunit 78814 "BVA By Value AutoCalc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Callee: Codeunit "BVA Callee";

    // Heads H1 (A, lines 4 and 6), H2 (A, line 20), H3 (B, line 30).
    local procedure Initialize()
    var
        Head: Record "BVA Head";
        Detail: Record "BVA Detail";
    begin
        Head.DeleteAll();
        Detail.DeleteAll();
        AddHead('H1', 'A');
        AddHead('H2', 'A');
        AddHead('H3', 'B');
        AddDetail('H1', 1, 4);
        AddDetail('H1', 2, 6);
        AddDetail('H2', 1, 20);
        AddDetail('H3', 1, 30);
    end;

    local procedure AddHead(No: Code[20]; Kind: Code[10])
    var
        Head: Record "BVA Head";
    begin
        Head."No." := No;
        Head.Kind := Kind;
        Head.Insert();
    end;

    local procedure AddDetail(HeadNo: Code[20]; LineNo: Integer; Amount: Decimal)
    var
        Detail: Record "BVA Detail";
    begin
        Detail."Head No." := HeadNo;
        Detail."Line No." := LineNo;
        Detail.Amount := Amount;
        Detail.Insert();
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Head: Record "BVA Head")
    begin
        Observer.Observe('caller after', 'f={' + Head.GetFilters() + '} key=' + Head.CurrentKey() + ' total=' + Format(Head."Line Total", 0, 9));
        Head.FindLast();
        Observer.Observe('caller findlast', 'no=' + Head."No." + ' total=' + Format(Head."Line Total", 0, 9) + ' count=' + Format(Head."Line Count"));
    end;

    local procedure DescribeCopyLocal(HeadCopy: Record "BVA Head"): Text
    begin
        exit(Callee.DescribeVariant(HeadCopy));
    end;

    [Test]
    procedure ByValueAutoCalc_Control_CallerAndRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
        RecRef: RecordRef;
    begin
        Initialize();
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('caller first', 'no=' + Head."No." + ' total=' + Format(Head."Line Total", 0, 9));
        RecRef.GetTable(Head);
        RecRef.FindLast();
        Observer.Observe('recref findlast', 'no=' + Format(RecRef.Field(1).Value) + ' total=' + Format(RecRef.Field(3).Value, 0, 9));
        Observer.Expect('caller first', 'no=H1 total=10');
        Observer.Expect('recref findlast', 'no=H3 total=30');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_Group0Filter_AfterFind()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.Describe(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_NoFilter_NoRead()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetAutoCalcFields("Line Total");
        Observer.Observe('callee', Callee.Describe(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no= total=0 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={} key=No. total=0');
        Observer.Expect('caller findlast', 'no=H3 total=30 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_SecondaryKey_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetCurrentKey(Kind);
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.Describe(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={} key=Kind total=10');
        Observer.Expect('caller findlast', 'no=H3 total=30 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_TwoFlowFields()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total", "Line Count");
        Head.FindFirst();
        Observer.Observe('callee', Callee.Describe(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H1 total=10 count=2 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=1');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetCurrentKey(Kind);
        Head.Ascending(false);
        Head.SetRange(Kind, 'A');
        Head.FilterGroup(2);
        Head.SetFilter("No.", '<>%1', 'H9');
        Head.FilterGroup(0);
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Head.Mark(true);
        Observer.Observe('callee', Callee.Describe(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H2 total=20 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=Kind total=20');
        Observer.Expect('caller findlast', 'no=H1 total=10 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_VariantGetTable()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.DescribeCopyAsVariant(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H3 f={} n=3 lastTotal=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_LocalProcedure_VariantGetTable()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', DescribeCopyLocal(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H3 f={} n=3 lastTotal=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOtherTable_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
        Buffer: Record "BVA Buffer";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Buffer.DescribeHead(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOtherTable_SecondaryKey_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
        Buffer: Record "BVA Buffer";
    begin
        Initialize();
        Head.SetCurrentKey(Kind);
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Buffer.DescribeHead(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={} key=Kind total=10');
        Observer.Expect('caller findlast', 'no=H3 total=30 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOwnRec_Group0Filter()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Head.DescribeOwn(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'self f={Kind: A} copy no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOtherTable_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
        Buffer: Record "BVA Buffer";
    begin
        Initialize();
        Head.SetCurrentKey(Kind);
        Head.Ascending(false);
        Head.SetRange(Kind, 'A');
        Head.FilterGroup(2);
        Head.SetFilter("No.", '<>%1', 'H9');
        Head.FilterGroup(0);
        Head.SetAutoCalcFields("Line Total", "Line Count");
        Head.FindFirst();
        Head.Mark(true);
        Observer.Observe('callee', Buffer.DescribeHead(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H2 total=20 count=1 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=Kind total=20');
        Observer.Expect('caller findlast', 'no=H1 total=10 count=2');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOwnRec_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetCurrentKey(Kind);
        Head.Ascending(false);
        Head.SetRange(Kind, 'A');
        Head.FilterGroup(2);
        Head.SetFilter("No.", '<>%1', 'H9');
        Head.FilterGroup(0);
        Head.SetAutoCalcFields("Line Total", "Line Count");
        Head.FindFirst();
        Head.Mark(true);
        Observer.Observe('callee', Head.DescribeOwn(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'self f={Kind: A} copy no=H2 total=20 count=1 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Expect('caller after', 'f={Kind: A} key=Kind total=20');
        Observer.Expect('caller findlast', 'no=H1 total=10 count=2');
        Observer.Verify();
    end;
}