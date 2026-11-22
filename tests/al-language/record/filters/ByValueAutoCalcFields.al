// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78810..78818 (BVA Head, BVA Detail, BVA Buffer, BVA Callee,
//   BVA By Value AutoCalc Tests, BVA Holder, BVA Head Ext, BVA Stat, BVA Stat Callee)
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
//   Added: Get of the copy, Other.Copy of the copy then FindLast, the callee's own SetAutoCalcFields of another FlowField, a
//   FlowField whose formula reads a FlowFilter (none set), and Buffer.Proc(Head) from the OnInsert of a third table.
//   Added for the review of al-runner PR 8541: a FlowField of every method (Min, Max, Average, Exist, Lookup on BVA Stat), three
//   auto-calculated fields, and a Min FlowField a table extension declares (BVA Head Ext), through a codeunit procedure.
// Facts (observed on a local BC 29.1 OnPrem W1 container; 27.5 and 28.5 by the corpus CI):
//   - RecordRef.GetTable of the caller's own record keeps its SetAutoCalcFields (FindLast calculates 30);
//   - a by-value copy keeps the field values of the caller's current row, its calculated FlowFields included (total=10,
//     count=2 for two FlowFields), and has the view of a fresh record (no filters, primary key, ascending);
//   - the copy does not keep the caller's SetAutoCalcFields: its own FindLast, and a FindLast of a RecordRef that GetTable
//     took of it through a Variant, leave the FlowFields 0 (lastTotal=0 lastCount=0), for a codeunit procedure, a local
//     procedure of the test codeunit, a table procedure of another table and Head.Proc(Head); so do its Get, a FindLast of
//     another record that copied it with Copy, and a FlowFilter-dependent FlowField; a SetAutoCalcFields of its own
//     calculates only the field it names (total=0 count=1); every FlowField method behaves the same (min, max, average,
//     exist and lookup read 0 or No in the copy), with three fields, and for a FlowField a table extension declares;
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
        field(5; "Line Filter"; Integer) { FieldClass = FlowFilter; }
        field(6; "Filtered Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVA Detail".Amount where("Head No." = field("No."), "Line No." = field("Line Filter")));
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

    // Added for the review of the runtime change: other reads of the copy.
    procedure GetOfCopy(H: Record "BVA Head"): Text
    begin
        H.Get('H3');
        exit('get no=' + H."No." + ' total=' + Format(H."Line Total", 0, 9));
    end;

    procedure CopyOfCopy(H: Record "BVA Head"): Text
    var
        Other: Record "BVA Head";
    begin
        Other.Copy(H);
        Other.FindLast();
        exit('other no=' + Other."No." + ' total=' + Format(Other."Line Total", 0, 9));
    end;

    procedure AddAutoCalcOnCopy(H: Record "BVA Head"): Text
    begin
        H.SetAutoCalcFields("Line Count");
        H.FindLast();
        exit('no=' + H."No." + ' total=' + Format(H."Line Total", 0, 9) + ' count=' + Format(H."Line Count"));
    end;

    procedure FilteredTotalOfCopy(H: Record "BVA Head"): Text
    begin
        H.FindLast();
        exit('no=' + H."No." + ' filtered=' + Format(H."Filtered Total", 0, 9));
    end;
}

// A third table whose OnInsert hands a filtered record with SetAutoCalcFields to Buffer.Proc(Head).
table 78815 "BVA Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Info; Text[250]) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Head: Record "BVA Head";
        Buffer: Record "BVA Buffer";
    begin
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Info := CopyStr(Buffer.DescribeHead(Head), 1, MaxStrLen(Info));
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
        Holder: Record "BVA Holder";
        Stat: Record "BVA Stat";
    begin
        Head.DeleteAll();
        Detail.DeleteAll();
        Holder.DeleteAll();
        Stat.DeleteAll();
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

    [Test]
    procedure ByValueAutoCalc_Codeunit_GetOfCopy()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.GetOfCopy(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'get no=H3 total=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_CopyOfCopy()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.CopyOfCopy(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'other no=H3 total=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_CalleeAddsAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Line Total");
        Head.FindFirst();
        Observer.Observe('callee', Callee.AddAutoCalcOnCopy(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('callee', 'no=H3 total=0 count=1');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=10');
        Observer.Expect('caller findlast', 'no=H2 total=20 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_FlowFilterFormula()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Filtered Total");
        Head.FindFirst();
        Observer.Observe('caller filtered', Format(Head."Filtered Total", 0, 9));
        Observer.Observe('callee', Callee.FilteredTotalOfCopy(Head));
        ObserveCaller(Observer, Head);
        Observer.Expect('caller filtered', '10');
        Observer.Expect('callee', 'no=H3 filtered=0');
        Observer.Expect('caller after', 'f={Kind: A} key=No. total=0');
        Observer.Expect('caller findlast', 'no=H2 total=0 count=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_TableProcOtherTable_FromThirdTableTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "BVA Holder";
    begin
        Initialize();
        Holder."Line No." := 1;
        Holder.Insert(true);
        Holder.Get(1);
        Observer.Observe('callee', Holder.Info);
        Observer.Expect('callee', 'no=H1 total=10 count=0 f={} n=3 key=No. asc=Yes last=H3 lastTotal=0 lastCount=0');
        Observer.Verify();
    end;

    // Added for the review of al-runner PR 8541: every FlowField method, on the table (BVA Stat) and in a table extension
    // (BVA Head Ext), and three auto-calculated fields.
    local procedure AddStats()
    var
        Stat: Record "BVA Stat";
    begin
        Stat."No." := 'H1';
        Stat.Insert();
        Stat."No." := 'H2';
        Stat.Insert();
        Stat."No." := 'H3';
        Stat.Insert();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_MinMaxAverage()
    var
        Observer: Codeunit "Probe Observer";
        Stat: Record "BVA Stat";
        StatCallee: Codeunit "BVA Stat Callee";
    begin
        Initialize();
        AddStats();
        Stat.SetFilter("No.", '<>%1', 'H9');
        Stat.SetAutoCalcFields("Min Amount");
        Stat.FindFirst();
        Observer.Observe('caller min', Format(Stat."Min Amount", 0, 9));
        Observer.Observe('callee min', StatCallee.StatAfterFindLast(Stat));
        Stat.SetAutoCalcFields();
        Stat.SetAutoCalcFields("Max Amount");
        Stat.FindFirst();
        Observer.Observe('caller max', Format(Stat."Max Amount", 0, 9));
        Observer.Observe('callee max', StatCallee.StatAfterFindLast(Stat));
        Stat.SetAutoCalcFields();
        Stat.SetAutoCalcFields("Average Amount");
        Stat.FindFirst();
        Observer.Observe('caller average', Format(Stat."Average Amount", 0, 9));
        Observer.Observe('callee average', StatCallee.StatAfterFindLast(Stat));
        Stat.FindLast();
        Observer.Observe('caller findlast', Format(Stat."Average Amount", 0, 9));
        Observer.Expect('caller min', '4');
        Observer.Expect('callee min', 'no=H3 sum=0 count=0 min=0 max=0 avg=0 exist=No lookup=0');
        Observer.Expect('caller max', '6');
        Observer.Expect('callee max', 'no=H3 sum=0 count=0 min=0 max=0 avg=0 exist=No lookup=0');
        Observer.Expect('caller average', '5');
        Observer.Expect('callee average', 'no=H3 sum=0 count=0 min=0 max=0 avg=0 exist=No lookup=0');
        Observer.Expect('caller findlast', '30');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_ExistLookup()
    var
        Observer: Codeunit "Probe Observer";
        Stat: Record "BVA Stat";
        StatCallee: Codeunit "BVA Stat Callee";
    begin
        Initialize();
        AddStats();
        Stat.SetFilter("No.", '<>%1', 'H9');
        Stat.SetAutoCalcFields("Has Lines", "First Amount");
        Stat.FindFirst();
        Observer.Observe('caller', Format(Stat."Has Lines") + ' ' + Format(Stat."First Amount", 0, 9));
        Observer.Observe('callee', StatCallee.StatAfterFindLast(Stat));
        Stat.FindLast();
        Observer.Observe('caller findlast', Format(Stat."Has Lines") + ' ' + Format(Stat."First Amount", 0, 9));
        Observer.Expect('caller', 'Yes 4');
        Observer.Expect('callee', 'no=H3 sum=0 count=0 min=0 max=0 avg=0 exist=No lookup=0');
        Observer.Expect('caller findlast', 'Yes 30');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_ThreeFields()
    var
        Observer: Codeunit "Probe Observer";
        Stat: Record "BVA Stat";
        StatCallee: Codeunit "BVA Stat Callee";
    begin
        Initialize();
        AddStats();
        Stat.SetFilter("No.", '<>%1', 'H9');
        Stat.SetAutoCalcFields("Sum Amount", "Line Count", "Max Amount");
        Stat.FindFirst();
        Observer.Observe('caller', Format(Stat."Sum Amount", 0, 9) + ' ' + Format(Stat."Line Count") + ' ' + Format(Stat."Max Amount", 0, 9));
        Observer.Observe('callee', StatCallee.StatAfterFindLast(Stat));
        Stat.FindLast();
        Observer.Observe('caller findlast', Format(Stat."Sum Amount", 0, 9) + ' ' + Format(Stat."Line Count") + ' ' + Format(Stat."Max Amount", 0, 9));
        Observer.Expect('caller', '10 2 6');
        Observer.Expect('callee', 'no=H3 sum=0 count=0 min=0 max=0 avg=0 exist=No lookup=0');
        Observer.Expect('caller findlast', '30 1 30');
        Observer.Verify();
    end;

    [Test]
    procedure ByValueAutoCalc_Codeunit_ExtensionMinField()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "BVA Head";
        StatCallee: Codeunit "BVA Stat Callee";
    begin
        Initialize();
        Head.SetRange(Kind, 'A');
        Head.SetAutoCalcFields("Min Line Amount");
        Head.FindFirst();
        Observer.Observe('caller', 'no=' + Head."No." + ' min=' + Format(Head."Min Line Amount", 0, 9));
        Observer.Observe('callee', StatCallee.ExtMinAfterFindLast(Head));
        Observer.Observe('callee variant', StatCallee.ExtMinVariant(Head));
        Head.FindLast();
        Observer.Observe('caller findlast', 'no=' + Head."No." + ' min=' + Format(Head."Min Line Amount", 0, 9));
        Observer.Expect('caller', 'no=H1 min=4');
        Observer.Expect('callee', 'no=H3 min=0');
        Observer.Expect('callee variant', 'no=H3 min=0');
        Observer.Expect('caller findlast', 'no=H2 min=20');
        Observer.Verify();
    end;
}

// Every FlowField method over BVA Detail (Line No. 1 for the lookup).
table 78817 "BVA Stat"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Sum Amount"; Decimal) { FieldClass = FlowField; CalcFormula = sum("BVA Detail".Amount where("Head No." = field("No."))); Editable = false; }
        field(3; "Line Count"; Integer) { FieldClass = FlowField; CalcFormula = count("BVA Detail" where("Head No." = field("No."))); Editable = false; }
        field(4; "Min Amount"; Decimal) { FieldClass = FlowField; CalcFormula = min("BVA Detail".Amount where("Head No." = field("No."))); Editable = false; }
        field(5; "Max Amount"; Decimal) { FieldClass = FlowField; CalcFormula = max("BVA Detail".Amount where("Head No." = field("No."))); Editable = false; }
        field(6; "Average Amount"; Decimal) { FieldClass = FlowField; CalcFormula = average("BVA Detail".Amount where("Head No." = field("No."))); Editable = false; }
        field(7; "Has Lines"; Boolean) { FieldClass = FlowField; CalcFormula = exist("BVA Detail" where("Head No." = field("No."))); Editable = false; }
        field(8; "First Amount"; Decimal) { FieldClass = FlowField; CalcFormula = lookup("BVA Detail".Amount where("Head No." = field("No."), "Line No." = const(1))); Editable = false; }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

// A Min FlowField a table extension adds to BVA Head (the shape of a partner app's routing line).
tableextension 78816 "BVA Head Ext" extends "BVA Head"
{
    fields
    {
        field(78816; "Min Line Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("BVA Detail".Amount where("Head No." = field("No.")));
            Editable = false;
        }
    }
}

codeunit 78818 "BVA Stat Callee"
{
    procedure StatAfterFindLast(S: Record "BVA Stat"): Text
    begin
        S.FindLast();
        exit('no=' + S."No." + ' sum=' + Format(S."Sum Amount", 0, 9) + ' count=' + Format(S."Line Count") + ' min=' + Format(S."Min Amount", 0, 9)
            + ' max=' + Format(S."Max Amount", 0, 9) + ' avg=' + Format(S."Average Amount", 0, 9) + ' exist=' + Format(S."Has Lines")
            + ' lookup=' + Format(S."First Amount", 0, 9));
    end;

    procedure ExtMinAfterFindLast(H: Record "BVA Head"): Text
    begin
        H.FindLast();
        exit('no=' + H."No." + ' min=' + Format(H."Min Line Amount", 0, 9));
    end;

    procedure ExtMinVariant(H: Record "BVA Head"): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(H);
        RecRef.FindLast();
        exit('no=' + Format(RecRef.Field(1).Value) + ' min=' + Format(RecRef.Field(78816).Value, 0, 9));
    end;
}