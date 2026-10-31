// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against the BC 29 SaaS sandbox; every literal asserted below is what that tier produced. Other BC versions are checked by
// the corpus CI matrix.
// Facts: RecordRef.GetTable(Variant) after the Variant was given a second record of the same table (al-runner issue 6503): which record's view
//   (filters, current key, marks, temporary flag, field values) GetTable sees, inline and with the Variant passed by var or by value to a
//   procedure; whether a Variant holds a copy of the record or a reference to it (Rec.SetRange / field change after V := Rec, read through
//   GetTable and through Back := V); whether a change made through RecordRef/FieldRef after GetTable(V) reaches V or the record; V given a
//   record of another table. recordref/TestRecordRefVariantGetTable.al pins the first GetTable(Variant) only; record/TestRecordVariantRoundTrip.al
//   pins field values through by-value/var Variant parameters.
// Describe(V) shape: table=<number> temp=<IsTemporary> count=<Count> filters=[<GetFilters>] key=[<CurrentKey>] markedonly=<MarkedOnly>
//   no=<field 1> name=<field 2>.
// BC versions: 29 (27 and 28 by CI)

table 92200 "LT Y23 VView Row"
{
    fields
    {
        field(1; No; Code[20]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
        key(ByName; Name) { }
    }
}

table 92201 "LT Y23 VView Other"
{
    fields
    {
        field(1; No; Code[20]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

codeunit 92202 "LT Y23 Variant Record View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y23 VView Row";
        Other: Record "LT Y23 VView Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.No := 'A';
        Row.Name := 'Zeta';
        Row.Insert();
        Row.No := 'B';
        Row.Name := 'Beta';
        Row.Insert();
        Row.No := 'C';
        Row.Name := 'Alpha';
        Row.Insert();
        Other.No := 'X';
        Other.Name := 'Other X';
        Other.Insert();
        Other.No := 'Y';
        Other.Name := 'Other Y';
        Other.Insert();
    end;

    local procedure Describe(var RR: RecordRef): Text
    begin
        exit(StrSubstNo('table=%1 temp=%2 count=%3 filters=[%4] key=[%5] markedonly=%6 no=%7 name=%8',
            RR.Number(), RR.IsTemporary(), RR.Count(), RR.GetFilters(), RR.CurrentKey(), RR.MarkedOnly(), RR.Field(1).Value(), RR.Field(2).Value()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    var
        RR: RecordRef;
    begin
        RR.GetTable(V);
        exit(Describe(RR));
    end;

    local procedure DescribeValue(V: Variant): Text
    var
        RR: RecordRef;
    begin
        RR.GetTable(V);
        exit(Describe(RR));
    end;

    local procedure BackOf(V: Variant): Text
    var
        Back: Record "LT Y23 VView Row";
    begin
        Back := V;
        exit(StrSubstNo('count=%1 filters=[%2] key=[%3] markedonly=%4 temp=%5 no=%6 name=%7',
            Back.Count(), Back.GetFilters(), Back.CurrentKey(), Back.MarkedOnly(), Back.IsTemporary(), Back.No, Back.Name));
    end;

    local procedure AssignVar(var V: Variant; var Rec: Record "LT Y23 VView Row")
    begin
        V := Rec;
    end;

    local procedure AssignAndDescribe(var V: Variant; var Rec: Record "LT Y23 VView Row"): Text
    begin
        V := Rec;
        exit(DescribeVar(V));
    end;

    [Test]
    procedure Y23_ReporterRepro_ThreeReads()
    // The reporter's body (al-runner issue 6503) with the three reads, inline.
    var
        Row: Record "LT Y23 VView Row";
        First: Record "LT Y23 VView Row";
        Filtered: Record "LT Y23 VView Row";
        Back: Record "LT Y23 VView Row";
        V: Variant;
        RR: RecordRef;
    begin
        Row.DeleteAll();
        Row.No := 'A';
        Row.Insert();
        First.Get('A');
        First.SetRecFilter();
        V := First;
        RR.GetTable(V);
        Observer.Observe('first', StrSubstNo('count=%1 filters=[%2]', RR.Count(), RR.GetFilters()));
        Filtered.SetRange(No, 'NONE');
        V := Filtered;
        Clear(RR);
        RR.GetTable(V);
        Observer.Observe('second', StrSubstNo('count=%1 filters=[%2]', RR.Count(), RR.GetFilters()));
        Back := V;
        Observer.Observe('back', StrSubstNo('count=%1 filters=[%2] no=%3', Back.Count(), Back.GetFilters(), Back.No));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_SecondRecordWithoutFilters()
    var
        First: Record "LT Y23 VView Row";
        Plain: Record "LT Y23 VView Row";
        V: Variant;
        Fresh: Variant;
        RR: RecordRef;
    begin
        Seed();
        First.Get('A');
        First.SetRecFilter();
        V := First;
        Observer.Observe('first', DescribeVar(V));
        V := Plain;
        RR.GetTable(V);
        Observer.Observe('second inline', Describe(RR));
        Observer.Observe('second var', DescribeVar(V));
        Observer.Observe('second value', DescribeValue(V));
        Observer.Observe('second back', BackOf(V));
        Fresh := Plain;
        Observer.Observe('fresh variant', DescribeVar(Fresh));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_SecondRecordFilterSetFilterAndReuse()
    // Filtered by SetFilter; then the first record itself reused (Reset, SetRange) for the next assignment.
    var
        First: Record "LT Y23 VView Row";
        Second: Record "LT Y23 VView Row";
        V: Variant;
    begin
        Seed();
        First.SetRange(No, 'A');
        V := First;
        Observer.Observe('first', DescribeVar(V));
        Second.SetFilter(No, '%1|%2', 'B', 'C');
        V := Second;
        Observer.Observe('setfilter', DescribeVar(V));
        First.Reset();
        First.SetRange(No, 'NONE');
        V := First;
        Observer.Observe('first reused', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_SecondRecordOtherCurrentKey()
    var
        First: Record "LT Y23 VView Row";
        Second: Record "LT Y23 VView Row";
        Third: Record "LT Y23 VView Row";
        V: Variant;
    begin
        Seed();
        First.SetRange(No, 'A');
        V := First;
        Observer.Observe('first', DescribeVar(V));
        Second.SetCurrentKey(Name);
        Second.FindFirst();
        V := Second;
        Observer.Observe('second by name', DescribeVar(V));
        Observer.Observe('second back', BackOf(V));
        Third.SetCurrentKey(No);
        Third.SetRange(Name, 'Beta');
        V := Third;
        Observer.Observe('third pk', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_SecondRecordWithMarks()
    var
        First: Record "LT Y23 VView Row";
        Marked: Record "LT Y23 VView Row";
        Plain: Record "LT Y23 VView Row";
        V: Variant;
        Fresh: Variant;
    begin
        Seed();
        First.SetRange(No, 'A');
        V := First;
        Observer.Observe('first', DescribeVar(V));
        Marked.Get('B');
        Marked.Mark(true);
        Marked.Get('C');
        Marked.Mark(true);
        Marked.MarkedOnly(true);
        V := Marked;
        Observer.Observe('marked', DescribeVar(V));
        Observer.Observe('marked back', BackOf(V));
        Fresh := Marked;
        Observer.Observe('marked fresh variant', DescribeVar(Fresh));
        V := Plain;
        Observer.Observe('plain after marked', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_SecondRecordTemporary()
    var
        First: Record "LT Y23 VView Row";
        Temp: Record "LT Y23 VView Row" temporary;
        Real: Record "LT Y23 VView Row";
        V: Variant;
        Fresh: Variant;
    begin
        Seed();
        Temp.No := 'T1';
        Temp.Name := 'Temp one';
        Temp.Insert();
        Temp.No := 'T2';
        Temp.Name := 'Temp two';
        Temp.Insert();
        First.SetRange(No, 'A');
        V := First;
        Observer.Observe('first', DescribeVar(V));
        Temp.FindFirst();
        V := Temp;
        Observer.Observe('temp', DescribeVar(V));
        Observer.Observe('temp back', BackOf(V));
        Fresh := Temp;
        Observer.Observe('temp fresh variant', DescribeVar(Fresh));
        Temp.SetRange(No, 'T2');
        V := Temp;
        Observer.Observe('temp filtered', DescribeVar(V));
        V := Real;
        Observer.Observe('real after temp', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_VariantPassedByVarToProcedure()
    var
        First: Record "LT Y23 VView Row";
        Filtered: Record "LT Y23 VView Row";
        Plain: Record "LT Y23 VView Row";
        V: Variant;
    begin
        Seed();
        First.SetRange(No, 'A');
        AssignVar(V, First);
        Observer.Observe('first', DescribeVar(V));
        Filtered.SetRange(No, 'NONE');
        AssignVar(V, Filtered);
        Observer.Observe('assigned in callee, read var', DescribeVar(V));
        Observer.Observe('assigned in callee, read value', DescribeValue(V));
        Observer.Observe('assign and read in callee', AssignAndDescribe(V, Plain));
        Observer.Observe('after callee, read in caller', DescribeVar(V));
        Filtered.SetRange(No, 'B');
        V := Filtered;
        Observer.Observe('assigned in caller, read in callee by var', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_RecordChangedAfterAssignment()
    // V := Rec, then Rec's view and fields change: is the Variant a copy or a reference?
    var
        Rec: Record "LT Y23 VView Row";
        V: Variant;
    begin
        Seed();
        Rec.Get('A');
        Rec.SetRange(No, 'A');
        V := Rec;
        Rec.SetRange(No, 'B', 'C');
        Rec.SetCurrentKey(Name);
        Observer.Observe('getTable after setrange', DescribeVar(V));
        Observer.Observe('back after setrange', BackOf(V));
        Rec.Name := 'changed in rec';
        Observer.Observe('getTable after field change', DescribeVar(V));
        Observer.Observe('back after field change', BackOf(V));
        Rec.Get('C');
        Observer.Observe('getTable after get', DescribeVar(V));
        Rec.Reset();
        Rec.Get('B');
        Rec.Mark(true);
        Rec.MarkedOnly(true);
        Observer.Observe('getTable after marks', DescribeVar(V));
        Observer.Observe('rec itself', StrSubstNo('count=%1 filters=[%2] no=%3', Rec.Count(), Rec.GetFilters(), Rec.No));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_ChangeThroughRecordRefAfterGetTable()
    // RR.GetTable(V), then a filter and a field value set through FieldRef: does V (or the record) change?
    var
        Rec: Record "LT Y23 VView Row";
        V: Variant;
        RR: RecordRef;
        FR: FieldRef;
    begin
        Seed();
        Rec.Get('A');
        V := Rec;
        RR.GetTable(V);
        FR := RR.Field(1);
        FR.SetRange('B', 'C');
        FR := RR.Field(2);
        FR.Value := 'set through fieldref';
        RR.SetView('SORTING(Name)');
        RR.Field(1).SetRange('B', 'C');
        Observer.Observe('rr itself', Describe(RR));
        Observer.Observe('getTable again', DescribeVar(V));
        Observer.Observe('back', BackOf(V));
        Observer.Observe('rec', StrSubstNo('count=%1 filters=[%2] no=%3 name=%4', Rec.Count(), Rec.GetFilters(), Rec.No, Rec.Name));
        RR.FindFirst();
        RR.Field(2).Value := 'modified through rr';
        RR.Modify();
        Observer.Observe('getTable after rr modify', DescribeVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure Y23_VariantGetsRecordOfOtherTable()
    var
        First: Record "LT Y23 VView Row";
        Other: Record "LT Y23 VView Other";
        Plain: Record "LT Y23 VView Row";
        V: Variant;
        I: Integer;
    begin
        Seed();
        First.SetRange(No, 'A');
        V := First;
        Observer.Observe('first', DescribeVar(V));
        Other.SetRange(No, 'Y');
        Other.FindFirst();
        V := Other;
        Observer.Observe('other table', DescribeVar(V));
        V := Plain;
        Observer.Observe('back to row table', DescribeVar(V));
        I := 7;
        V := I;
        V := First;
        Observer.Observe('integer then filtered', DescribeVar(V));
        Observer.Finish();
    end;
}
