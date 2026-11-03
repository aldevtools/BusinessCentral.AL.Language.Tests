// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: self-contained tables 72013 to 72015, test codeunits 72007 and 72008
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.CalcFields / CalcSums / SetAutoCalcFields with FlowFields Sum, Count, Exist, Lookup, Average, Min, Max, with CalcFormula where clauses (constant, field, filter),
// FieldClass FlowFilter, SetAutoCalcFields effect on Get/Find/Next, CalcFields of non flowfields (error), CalcSums over filters and with several fields, empty sets.
// BC versions: 29 (27 and 28 by CI)

table 72013 "LT RcB Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Amt; Decimal) { }
        field(4; Qty; Integer) { }
        field(5; Kind; Option) { OptionMembers = A,B,C; }
        field(6; Note; Text[30]) { }
        field(7; Dt; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; SumIndexFields = Amt, Qty; }
        key(ByOwner; Owner, Kind) { SumIndexFields = Amt; }
    }
}

table 72014 "LT RcB Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Total; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RcB Line".Amt where(Owner = field("No."))); Editable = false; }
        field(4; LineCount; Integer) { FieldClass = FlowField; CalcFormula = count("LT RcB Line" where(Owner = field("No."))); Editable = false; }
        field(5; HasLines; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT RcB Line" where(Owner = field("No."))); Editable = false; }
        field(6; FirstNote; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("LT RcB Line".Note where(Owner = field("No."))); Editable = false; }
        field(7; AvgAmt; Decimal) { FieldClass = FlowField; CalcFormula = average("LT RcB Line".Amt where(Owner = field("No."))); Editable = false; }
        field(8; MinAmt; Decimal) { FieldClass = FlowField; CalcFormula = min("LT RcB Line".Amt where(Owner = field("No."))); Editable = false; }
        field(9; MaxAmt; Decimal) { FieldClass = FlowField; CalcFormula = max("LT RcB Line".Amt where(Owner = field("No."))); Editable = false; }
        field(10; TotalB; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RcB Line".Amt where(Owner = field("No."), Kind = const(B))); Editable = false; }
        field(11; KindFilter; Option) { FieldClass = FlowFilter; OptionMembers = A,B,C; }
        field(12; TotalFiltered; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RcB Line".Amt where(Owner = field("No."), Kind = field(KindFilter))); Editable = false; }
        field(13; AmtFilter; Decimal) { FieldClass = FlowFilter; }
        field(14; CountByAmt; Integer) { FieldClass = FlowField; CalcFormula = count("LT RcB Line" where(Owner = field("No."), Amt = field(AmtFilter))); Editable = false; }
        field(15; QtySum; Integer) { FieldClass = FlowField; CalcFormula = sum("LT RcB Line".Qty where(Owner = field("No."))); Editable = false; }
        field(16; MinDate; Date) { FieldClass = FlowField; CalcFormula = min("LT RcB Line".Dt where(Owner = field("No."))); Editable = false; }
        field(17; NoLines; Boolean) { FieldClass = FlowField; CalcFormula = - exist("LT RcB Line" where(Owner = field("No."))); Editable = false; }
        field(18; NegTotal; Decimal) { FieldClass = FlowField; CalcFormula = - sum("LT RcB Line".Amt where(Owner = field("No."))); Editable = false; }
        field(19; Plain; Integer) { }
        field(20; HighCount; Integer) { FieldClass = FlowField; CalcFormula = count("LT RcB Line" where(Owner = field("No."), Amt = filter(>=20))); Editable = false; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 72015 "LT RcB Sums"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Amt; Decimal) { }
        field(4; Qty; Integer) { }
        field(5; Big; BigInteger) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; SumIndexFields = Amt, Qty; }
        key(ByGrp; Grp) { SumIndexFields = Amt, Qty, Big; }
    }
}

codeunit 72007 "LT RcB FlowFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT RcB Head";
        Line: Record "LT RcB Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        Head."No." := 'H3';
        Head.Insert();
        AddLine(1, 'H1', 10, 1, Line.Kind::A, 'first', 20250101D);
        AddLine(2, 'H1', 20, 2, Line.Kind::B, 'second', 20250102D);
        AddLine(3, 'H1', 30, 3, Line.Kind::B, 'third', 20250103D);
        AddLine(4, 'H2', 5.5, 4, Line.Kind::C, 'other', 20240101D);
    end;

    local procedure AddLine(Id: Integer; Owner: Code[10]; Amt: Decimal; Qty: Integer; Kind: Option; Note: Text[30]; Dt: Date)
    var
        Line: Record "LT RcB Line";
    begin
        Line.Id := Id;
        Line.Owner := Owner;
        Line.Amt := Amt;
        Line.Qty := Qty;
        Line.Kind := Kind;
        Line.Note := Note;
        Line.Dt := Dt;
        Line.Insert();
    end;

    [Test]
    procedure FlowField_BeforeCalc_IsDefault()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Observer.Observe('Total', Format(Head.Total));
        Observer.Observe('LineCount', Format(Head.LineCount));
        Observer.Observe('HasLines', Format(Head.HasLines));
        Observer.Observe('FirstNote', '[' + Head.FirstNote + ']');
        Observer.Expect('Total', '0');
        Observer.Expect('LineCount', '0');
        Observer.Expect('HasLines', 'No');
        Observer.Expect('FirstNote', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_Each_Kind()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Head.CalcFields(Total, LineCount, HasLines, FirstNote, AvgAmt, MinAmt, MaxAmt);
        Observer.Observe('Total', Format(Head.Total));
        Observer.Observe('LineCount', Format(Head.LineCount));
        Observer.Observe('HasLines', Format(Head.HasLines));
        Observer.Observe('FirstNote', Head.FirstNote);
        Observer.Observe('AvgAmt', Format(Head.AvgAmt));
        Observer.Observe('MinAmt', Format(Head.MinAmt));
        Observer.Observe('MaxAmt', Format(Head.MaxAmt));
        Head.CalcFields(QtySum, MinDate, TotalB, HighCount);
        Observer.Observe('QtySum', Format(Head.QtySum));
        Observer.Observe('MinDate', Format(Head.MinDate, 0, 9));
        Observer.Observe('TotalB', Format(Head.TotalB));
        Observer.Observe('HighCount', Format(Head.HighCount));
        Observer.Expect('Total', '60');
        Observer.Expect('LineCount', '3');
        Observer.Expect('HasLines', 'Yes');
        Observer.Expect('FirstNote', 'first');
        Observer.Expect('AvgAmt', '20');
        Observer.Expect('MinAmt', '10');
        Observer.Expect('MaxAmt', '30');
        Observer.Expect('QtySum', '6');
        Observer.Expect('MinDate', '2025-01-01');
        Observer.Expect('TotalB', '50');
        Observer.Expect('HighCount', '2');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_NoMatchingRows()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H3');
        Head.CalcFields(Total, LineCount, HasLines, FirstNote, AvgAmt, MinAmt, MaxAmt, QtySum, MinDate, NoLines, NegTotal);
        Observer.Observe('Total', Format(Head.Total));
        Observer.Observe('LineCount', Format(Head.LineCount));
        Observer.Observe('HasLines', Format(Head.HasLines));
        Observer.Observe('FirstNote', '[' + Head.FirstNote + ']');
        Observer.Observe('AvgAmt', Format(Head.AvgAmt));
        Observer.Observe('MinAmt', Format(Head.MinAmt));
        Observer.Observe('MaxAmt', Format(Head.MaxAmt));
        Observer.Observe('QtySum', Format(Head.QtySum));
        Observer.Observe('MinDate', Format(Head.MinDate, 0, 9));
        Observer.Observe('NoLines', Format(Head.NoLines));
        Observer.Observe('NegTotal', Format(Head.NegTotal));
        Observer.Expect('Total', '0');
        Observer.Expect('LineCount', '0');
        Observer.Expect('HasLines', 'No');
        Observer.Expect('FirstNote', '[]');
        Observer.Expect('AvgAmt', '0');
        Observer.Expect('MinAmt', '0');
        Observer.Expect('MaxAmt', '0');
        Observer.Expect('QtySum', '0');
        Observer.Expect('MinDate', '');
        Observer.Expect('NoLines', 'Yes');
        Observer.Expect('NegTotal', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_Negated()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Head.CalcFields(NoLines, NegTotal);
        Observer.Observe('NoLines H1', Format(Head.NoLines));
        Observer.Observe('NegTotal H1', Format(Head.NegTotal));
        Observer.Expect('NoLines H1', 'No');
        Observer.Expect('NegTotal H1', '-60');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_RecalculatesAfterChange()
    var
        Head: Record "LT RcB Head";
        Line: Record "LT RcB Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Head.CalcFields(Total, LineCount);
        Observer.Observe('before', Format(Head.Total) + '/' + Format(Head.LineCount));
        Line.Get(1);
        Line.Delete();
        Observer.Observe('stale', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.CalcFields(Total, LineCount);
        Observer.Observe('after', Format(Head.Total) + '/' + Format(Head.LineCount));
        Line.Init();
        Line.Id := 9;
        Line.Owner := 'H1';
        Line.Amt := 1;
        Line.Insert();
        Head.CalcFields(Total);
        Observer.Observe('after insert', Format(Head.Total));
        Observer.Expect('before', '60/3');
        Observer.Expect('stale', '60/3');
        Observer.Expect('after', '50/2');
        Observer.Expect('after insert', '51');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_FlowFilters()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Head.CalcFields(TotalFiltered);
        Observer.Observe('no flowfilter', Format(Head.TotalFiltered));
        Head.SetRange(KindFilter, Head.KindFilter::B);
        Head.CalcFields(TotalFiltered);
        Observer.Observe('kind B', Format(Head.TotalFiltered));
        Head.SetRange(KindFilter, Head.KindFilter::C);
        Head.CalcFields(TotalFiltered);
        Observer.Observe('kind C', Format(Head.TotalFiltered));
        Head.SetFilter(KindFilter, '%1|%2', Head.KindFilter::A, Head.KindFilter::B);
        Head.CalcFields(TotalFiltered);
        Observer.Observe('kind A or B', Format(Head.TotalFiltered));
        Head.SetRange(KindFilter);
        Head.SetFilter(AmtFilter, '>=20');
        Head.CalcFields(CountByAmt);
        Observer.Observe('amt filter count', Format(Head.CountByAmt));
        Observer.Observe('flowfilter text', Head.GetFilter(AmtFilter));
        Observer.Expect('no flowfilter', '60');
        Observer.Expect('kind B', '50');
        Observer.Expect('kind C', '0');
        Observer.Expect('kind A or B', '60');
        Observer.Expect('amt filter count', '2');
        Observer.Expect('flowfilter text', '>=20');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_AllFlowFieldsOfRecord_NoArgs()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H2');
        Head.CalcFields(Total, LineCount);
        Observer.Observe('H2', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.Get('H1');
        Observer.Observe('after get resets', Format(Head.Total) + '/' + Format(Head.LineCount));
        Observer.Expect('H2', '5.5/1');
        Observer.Expect('after get resets', '0/0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_Returns_Nothing_OnModifyKeepsValue()
    var
        Head: Record "LT RcB Head";
        Head2: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.Get('H1');
        Head.CalcFields(Total);
        Head.Name := 'modified';
        Head.Modify();
        Head2.Get('H1');
        Observer.Observe('stored name', Head2.Name);
        Observer.Observe('flowfield not stored', Format(Head2.Total));
        Observer.Expect('stored name', 'modified');
        Observer.Expect('flowfield not stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_Get()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.SetAutoCalcFields(Total, LineCount);
        Head.Get('H1');
        Observer.Observe('Get', Format(Head.Total) + '/' + Format(Head.LineCount));
        Observer.Observe('not requested', Format(Head.MaxAmt));
        Head.FindFirst();
        Observer.Observe('FindFirst', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.Next();
        Observer.Observe('Next', Head."No." + ':' + Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.FindLast();
        Observer.Observe('FindLast empty', Head."No." + ':' + Format(Head.Total) + '/' + Format(Head.LineCount));
        Observer.Expect('Get', '60/3');
        Observer.Expect('not requested', '0');
        Observer.Expect('FindFirst', '60/3');
        Observer.Expect('Next', 'H2:5.5/1');
        Observer.Expect('FindLast empty', 'H3:0/0');
        Observer.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_FindSet_Loop()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        Head.SetAutoCalcFields(Total, HasLines);
        if Head.FindSet() then
            repeat
                Result += Head."No." + '=' + Format(Head.Total) + '/' + Format(Head.HasLines) + ';';
            until Head.Next() = 0;
        Observer.Observe('loop', Result);
        Observer.Expect('loop', 'H1=60/Yes;H2=5.5/Yes;H3=0/No;');
        Observer.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_Reset_And_Replace()
    var
        Head: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.SetAutoCalcFields(Total);
        Head.Get('H1');
        Observer.Observe('set', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.SetAutoCalcFields(LineCount);
        Head.Get('H1');
        Observer.Observe('replaced', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.SetAutoCalcFields();
        Head.Get('H1');
        Observer.Observe('cleared', Format(Head.Total) + '/' + Format(Head.LineCount));
        Head.SetAutoCalcFields(Total);
        Head.Reset();
        Head.Get('H1');
        Observer.Observe('after reset', Format(Head.Total));
        Observer.Expect('set', '60/0');
        Observer.Expect('replaced', '60/3');
        Observer.Expect('cleared', '0/0');
        Observer.Expect('after reset', '60');
        Observer.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_AfterInsertRead()
    var
        Head: Record "LT RcB Head";
        Head2: Record "LT RcB Head";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Head.SetAutoCalcFields(Total);
        Head.SetRange("No.", 'H1');
        Head.FindFirst();
        Observer.Observe('find', Format(Head.Total));
        Head2.Copy(Head);
        Head2.FindFirst();
        Observer.Observe('copy keeps autocalc', Format(Head2.Total));
        Observer.Expect('find', '60');
        Observer.Expect('copy keeps autocalc', '60');
        Observer.Verify();
    end;
}

codeunit 72008 "LT RcB CalcSums"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Rec: Record "LT RcB Sums";
        i: Integer;
    begin
        Rec.DeleteAll();
        for i := 1 to 5 do begin
            Rec.Init();
            Rec.Id := i;
            Rec.Grp := CopyStr('G' + Format(i mod 2), 1, 10);
            Rec.Amt := i * 1.5;
            Rec.Qty := i;
            Rec.Big := i * 10000000000L;
            Rec.Insert();
        end;
    end;

    [Test]
    procedure CalcSums_All()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.CalcSums(Amt);
        Observer.Observe('Amt', Format(Rec.Amt));
        Rec.CalcSums(Qty);
        Observer.Observe('Qty', Format(Rec.Qty));
        Observer.Expect('Amt', '22.5');
        Observer.Expect('Qty', '15');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_Multiple()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.SetCurrentKey(Grp);
        Rec.CalcSums(Amt, Qty, Big);
        Observer.Observe('Amt', Format(Rec.Amt));
        Observer.Observe('Qty', Format(Rec.Qty));
        Observer.Observe('Big', Format(Rec.Big));
        Observer.Expect('Amt', '22.5');
        Observer.Expect('Qty', '15');
        Observer.Expect('Big', '150000000000');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_Filtered()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.SetRange(Grp, 'G1');
        Rec.CalcSums(Amt, Qty);
        Observer.Observe('G1', Format(Rec.Amt) + '/' + Format(Rec.Qty));
        Rec.SetRange(Grp, 'G0');
        Rec.CalcSums(Amt, Qty);
        Observer.Observe('G0', Format(Rec.Amt) + '/' + Format(Rec.Qty));
        Rec.SetRange(Grp, 'NONE');
        Rec.CalcSums(Amt, Qty);
        Observer.Observe('empty', Format(Rec.Amt) + '/' + Format(Rec.Qty));
        Rec.SetRange(Grp);
        Rec.SetFilter(Id, '2..4');
        Rec.CalcSums(Amt);
        Observer.Observe('id range', Format(Rec.Amt));
        Observer.Expect('G1', '13.5/9');
        Observer.Expect('G0', '9/6');
        Observer.Expect('empty', '0/0');
        Observer.Expect('id range', '13.5');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_OverwritesField_NotRow()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.Get(1);
        Observer.Observe('before', Format(Rec.Amt));
        Rec.CalcSums(Amt);
        Observer.Observe('after', Format(Rec.Amt));
        Rec.Get(1);
        Observer.Observe('row unchanged', Format(Rec.Amt));
        Observer.Expect('before', '1.5');
        Observer.Expect('after', '22.5');
        Observer.Expect('row unchanged', '1.5');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_OnTemporary()
    var
        Rec: Record "LT RcB Sums" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Rec.Amt := 2.5;
        Rec.Qty := 2;
        Rec.Insert();
        Rec.Id := 2;
        Rec.Amt := 3;
        Rec.Qty := 4;
        Rec.Insert();
        Rec.CalcSums(Amt, Qty);
        Observer.Observe('sum', Format(Rec.Amt) + '/' + Format(Rec.Qty));
        Observer.Expect('sum', '5.5/6');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_NonSumField_Compile_Runtime()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.SetCurrentKey(Grp);
        Rec.CalcSums(Amt);
        Observer.Observe('with key Grp', Format(Rec.Amt));
        Rec.SetCurrentKey(Id);
        Rec.SetRange(Grp, 'G1');
        Rec.CalcSums(Amt);
        Observer.Observe('filter on other key', Format(Rec.Amt));
        Observer.Expect('with key Grp', '22.5');
        Observer.Expect('filter on other key', '13.5');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_Negative_Decimals()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Amt := -1.25;
        Rec.Insert();
        Rec.Id := 2;
        Rec.Amt := 0.125;
        Rec.Insert();
        Rec.Id := 3;
        Rec.Amt := 100000000000.5;
        Rec.Insert();
        Rec.CalcSums(Amt);
        Observer.Observe('sum', Format(Rec.Amt, 0, 9));
        Observer.Expect('sum', '99999999999.375');
        Observer.Verify();
    end;

    // Corpus issue 668 item 60 (writer br): CalcSums of a field that is a SumIndexField of another key but not of the current key.
    [Test]
    procedure CalcSums_FieldNotInCurrentKeySumIndexFields()
    var
        Rec: Record "LT RcB Sums";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rec.CalcSums(Big);
        Observer.Observe('pk current, Big', Format(Rec.Big));
        Rec.SetRange(Grp, 'G1');
        Rec.CalcSums(Big);
        Observer.Observe('pk current, Big, Grp G1', Format(Rec.Big));
        Rec.Reset();
        Rec.SetCurrentKey(Grp);
        Rec.SetRange(Id, 2, 4);
        Rec.CalcSums(Amt, Big);
        Observer.Observe('grp current, Amt Big, Id 2..4', Format(Rec.Amt) + '|' + Format(Rec.Big));
        Observer.Expect('pk current, Big', '150000000000');
        Observer.Expect('pk current, Big, Grp G1', '90000000000');
        Observer.Expect('grp current, Amt Big, Id 2..4', '13.5|90000000000');
        Observer.Verify();
    end;
}
