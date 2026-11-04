// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (tables 74317 and 74318)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order FindSet gives after SetCurrentKey on a FlowField whose flowed values run against the primary key order, with Ascending(false), with SetCurrentKey(FlowField, Id), after a CalcFields of the loop record, and the key CurrentKey reports
// Settles docs/probes-needed.md row "SetCurrentKey on a FlowField" (Probe fixes): "accepted, orders by the primary key; the order of a FlowField key is not pinned" (the acceptance is pinned in records/W4SortKeys.al:459)
// BC versions: 29 (27 and 28 by CI)

table 74317 "LT P166 Key Owner"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P166 Key Line" where(OwnerId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74318 "LT P166 Key Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74319 "LT P166 Key Flow Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Owner: Record "LT P166 Key Owner";
        Line: Record "LT P166 Key Line";
        n: Integer;
    begin
        Owner.DeleteAll();
        Line.DeleteAll();
        // owner 1 has 3 lines, owner 2 has 1, owner 3 has 2: ascending Cnt order is 2, 3, 1
        Owner.Id := 1; Owner.Name := 'three'; Owner.Insert();
        Owner.Id := 2; Owner.Name := 'one'; Owner.Insert();
        Owner.Id := 3; Owner.Name := 'two'; Owner.Insert();
        for n := 1 to 3 do begin
            Line.Id := n; Line.OwnerId := 1; Line.Insert();
        end;
        Line.Id := 4; Line.OwnerId := 2; Line.Insert();
        Line.Id := 5; Line.OwnerId := 3; Line.Insert();
        Line.Id := 6; Line.OwnerId := 3; Line.Insert();
    end;

    [TryFunction]
    local procedure TryKey1(var Owner: Record "LT P166 Key Owner")
    begin
        Owner.SetCurrentKey(Cnt);
    end;

    [TryFunction]
    local procedure TryKey2(var Owner: Record "LT P166 Key Owner")
    begin
        Owner.SetCurrentKey(Cnt, Id);
    end;

    [TryFunction]
    local procedure TryLoop(var Owner: Record "LT P166 Key Owner"; CalcEach: Boolean; var Order: Text)
    begin
        Order := '';
        if Owner.FindSet() then
            repeat
                if CalcEach then
                    Owner.CalcFields(Cnt);
                Order += Format(Owner.Id) + ':' + Format(Owner.Cnt) + ' ';
            until Owner.Next() = 0;
    end;

    [Test]
    procedure SetCurrentKey_FlowField_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey1(Owner)));
        Observer.ObserveError('key');
        Observer.Observe('currentKey', Owner.CurrentKey());
        Observer.Observe('loopOk', Format(TryLoop(Owner, false, Order)));
        Observer.Observe('orderNoCalc', Order);
        Observer.Observe('loopCalcOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('orderCalc', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('key|text', '');
        Observer.Expect('key|code', '');
        Observer.Expect('currentKey', 'Cnt');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('orderNoCalc', '2:1 3:2 1:3 ');
        Observer.Expect('loopCalcOk', 'Yes');
        Observer.Expect('orderCalc', '2:1 3:2 1:3 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowField_Descending()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey1(Owner)));
        Owner.Ascending(false);
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.ObserveError('loop');
        Observer.Observe('order', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('loop|text', '');
        Observer.Expect('loop|code', '');
        Observer.Expect('order', '1:3 3:2 2:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowFieldThenPrimaryKey_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey2(Owner)));
        Observer.ObserveError('key');
        Observer.Observe('currentKey', Owner.CurrentKey());
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.ObserveError('loop');
        Observer.Observe('order', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('key|text', '');
        Observer.Expect('key|code', '');
        Observer.Expect('currentKey', 'Cnt,Id');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('loop|text', '');
        Observer.Expect('loop|code', '');
        Observer.Expect('order', '2:1 3:2 1:3 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_PrimaryKeyOrderForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Owner.SetCurrentKey(Id);
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('order', Order);
        Owner.Ascending(false);
        Observer.Observe('loopDescOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('orderDesc', Order);
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('order', '1:3 2:1 3:2 ');
        Observer.Expect('loopDescOk', 'Yes');
        Observer.Expect('orderDesc', '3:2 2:1 1:3 ');
        Observer.Verify();
    end;

    // Corpus issue 668 items 13 and 14 (writer BQ): the return value of SetCurrentKey on fields that cannot be sorted, and SetCurrentKey on a
    // Lookup FlowField of a temporary record (microsoft/AL issue 6948). LT BQ FG Owner (record/lt-bq-odd-leads/BqObjects.al): Total is a
    // sum FlowField, NestedTotal a lookup of Total (a FlowField over a FlowField), FirstTxt a lookup of a line text, IdFilter a FlowFilter.
    [TryFunction]
    local procedure BqTryKey(var Owner: Record "LT BQ FG Owner"; Which: Integer; var Ok: Boolean)
    begin
        case Which of
            1:
                Ok := Owner.SetCurrentKey(Total);
            2:
                Ok := Owner.SetCurrentKey(NestedTotal);
            3:
                Ok := Owner.SetCurrentKey(FirstTxt, Id);
            4:
                Ok := Owner.SetCurrentKey(IdFilter);
            5:
                Ok := Owner.SetCurrentKey(Name);
        end;
    end;

    [TryFunction]
    local procedure BqTryOrder(var Owner: Record "LT BQ FG Owner"; var Order: Text)
    begin
        Order := '';
        if Owner.FindSet() then
            repeat
                Order += Format(Owner.Id) + ' ';
            until Owner.Next() = 0;
    end;

    local procedure BqKeyOutcome(var Owner: Record "LT BQ FG Owner"; Which: Integer): Text
    var
        Ok: Boolean;
        Order: Text;
        Result: Text;
    begin
        if BqTryKey(Owner, Which, Ok) then
            Result := 'returned=' + Format(Ok) + ' key=' + Owner.CurrentKey()
        else begin
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            exit(Result);
        end;
        if BqTryOrder(Owner, Order) then
            Result += ' order=' + Order
        else
            Result += ' findSetError:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure SetCurrentKey_ReturnValue_On_Unsortable_Fields_BQ()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT BQ FG Owner";
        BqSeed: Codeunit "LT BQ Seed";
    begin
        BqSeed.Owners();
        Observer.Observe('sumFlowField', BqKeyOutcome(Owner, 1));
        Owner.Reset();
        Observer.Observe('nestedFlowField', BqKeyOutcome(Owner, 2));
        Owner.Reset();
        Observer.Observe('lookupFlowField', BqKeyOutcome(Owner, 3));
        Owner.Reset();
        Observer.Observe('flowFilter', BqKeyOutcome(Owner, 4));
        Owner.Reset();
        Observer.Observe('normalFieldNoKey', BqKeyOutcome(Owner, 5));
        Observer.Expect('sumFlowField', 'returned=Yes key=Total order=1 2 3 ');
        Observer.Expect('nestedFlowField', 'returned=No key=Id order=1 2 3 ');
        Observer.Expect('lookupFlowField', 'returned=Yes key=FirstTxt,Id order=1 3 2 ');
        Observer.Expect('flowFilter', 'returned=No key=Id order=1 2 3 ');
        Observer.Expect('normalFieldNoKey', 'returned=Yes key=Name order=2 1 3 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BqTryTempStep(var Owner: Record "LT BQ FG Owner"; Step: Integer; var Order: Text)
    begin
        case Step of
            1:
                Owner.CalcFields(FirstTxt);
            2:
                Owner.SetCurrentKey(FirstTxt, Id);
            3:
                Owner.SetFilter(Id, '>0');
            4:
                begin
                    Order := '';
                    if Owner.FindSet() then
                        repeat
                            Owner.CalcFields(FirstTxt);
                            Order += Format(Owner.Id) + ':' + Owner.FirstTxt + ' ';
                        until Owner.Next() = 0;
                end;
        end;
    end;

    local procedure BqTempSteps(var Owner: Record "LT BQ FG Owner"): Text
    var
        Step: Integer;
        Order: Text;
        Result: Text;
    begin
        for Step := 1 to 4 do
            if not BqTryTempStep(Owner, Step, Order) then begin
                Result += 'step' + Format(Step) + ' error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' ';
                ClearLastError();
            end;
        exit(Result + 'order=' + Order);
    end;

    // The steps of microsoft/AL issue 6948 on a temporary record and on the stored table: CalcFields, SetCurrentKey(lookup FlowField, Id),
    // SetFilter, FindSet. The temporary rows copy the stored owners; the FlowField of a temporary record reads the stored lines.
    [Test]
    procedure SetCurrentKey_LookupFlowField_TemporaryRecord_BQ()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT BQ FG Owner";
        TempOwner: Record "LT BQ FG Owner" temporary;
        BqSeed: Codeunit "LT BQ Seed";
    begin
        BqSeed.Owners();
        if Owner.FindSet() then
            repeat
                TempOwner := Owner;
                TempOwner.Insert();
            until Owner.Next() = 0;
        TempOwner.FindFirst();
        Observer.Observe('temporary', BqTempSteps(TempOwner));
        Owner.FindFirst();
        Observer.Observe('stored', BqTempSteps(Owner));
        Observer.Expect('temporary', 'step2 error:Sorting cannot be done based on the FirstTxt field(s) in the LT BQ FG Owner table.|DB:Ok order=1: 2:beta 3:alpha ');
        Observer.Expect('stored', 'order=1: 3:alpha 2:beta ');
        Observer.Verify();
    end;

    // Al-runner issue 6924 item 2.13: the order of FindSet under SetCurrentKey with a FlowField that is not the first field of the
    // key, with two FlowFields, and with FlowFields of the kinds max, min, average, exist and lookup first. Tables 95364 and 95365 below.
    // Owners (Id Grp: line amounts): 1 A: 5 5 5; 2 B: 30; 3 A: 1 20; 4 B: none; 5 A: 2.
    local procedure P6924_Seed()
    var
        Owner: Record "REC FlowKey Owner";
        Line: Record "REC FlowKey Line";
    begin
        Owner.DeleteAll();
        Line.DeleteAll();
        P6924_Owner(1, 'A');
        P6924_Owner(2, 'B');
        P6924_Owner(3, 'A');
        P6924_Owner(4, 'B');
        P6924_Owner(5, 'A');
        P6924_Line(1, 1, 5);
        P6924_Line(2, 1, 5);
        P6924_Line(3, 1, 5);
        P6924_Line(4, 2, 30);
        P6924_Line(5, 3, 1);
        P6924_Line(6, 3, 20);
        P6924_Line(7, 5, 2);
    end;

    local procedure P6924_Owner(Id: Integer; Grp: Code[10])
    var
        Owner: Record "REC FlowKey Owner";
    begin
        Owner.Id := Id;
        Owner.Grp := Grp;
        Owner.Insert();
    end;

    local procedure P6924_Line(Id: Integer; OwnerId: Integer; Amount: Decimal)
    var
        Line: Record "REC FlowKey Line";
    begin
        Line.Id := Id;
        Line.OwnerId := OwnerId;
        Line.Amount := Amount;
        Line.Insert();
    end;

    [TryFunction]
    local procedure P6924_TryKey(var Owner: Record "REC FlowKey Owner"; Which: Integer)
    begin
        case Which of
            1:
                Owner.SetCurrentKey(Grp, Cnt);
            2:
                Owner.SetCurrentKey(Grp, Total);
            3:
                Owner.SetCurrentKey(Grp, Cnt, Id);
            4:
                Owner.SetCurrentKey(Cnt, Total);
            5:
                Owner.SetCurrentKey(MaxAmt);
            6:
                Owner.SetCurrentKey(MinAmt);
            7:
                Owner.SetCurrentKey(AvgAmt);
            8:
                Owner.SetCurrentKey(HasLine);
            9:
                Owner.SetCurrentKey(FirstAmt);
            10:
                Owner.SetCurrentKey(Grp, MaxAmt);
            11:
                Owner.SetCurrentKey(Id, Cnt);
            12:
                Owner.SetCurrentKey(Total, Cnt);
        end;
    end;

    [TryFunction]
    local procedure P6924_TryOrder(var Owner: Record "REC FlowKey Owner"; var Order: Text)
    begin
        Order := '';
        if Owner.FindSet() then
            repeat
                Owner.CalcFields(Cnt, Total);
                Order += Format(Owner.Id) + ' ';
            until Owner.Next() = 0;
    end;

    [TryFunction]
    local procedure P6924_TryLast(var Owner: Record "REC FlowKey Owner"; var Order: Text)
    begin
        Order := '';
        if Owner.FindLast() then
            repeat
                Order += Format(Owner.Id) + ' ';
            until Owner.Next(-1) = 0;
    end;

    // 'key=<CurrentKey> order=<ids of FindSet> back=<ids from FindLast with Next(-1)>', or the error of the step that raised.
    local procedure P6924_Outcome(Which: Integer; Descending: Boolean): Text
    var
        Owner: Record "REC FlowKey Owner";
        Order: Text;
        Result: Text;
    begin
        ClearLastError();
        if not P6924_TryKey(Owner, Which) then begin
            Result := 'key error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            exit(Result);
        end;
        if Descending then
            Owner.Ascending(false);
        Result := 'key=' + Owner.CurrentKey();
        if P6924_TryOrder(Owner, Order) then
            Result += ' order=' + Order
        else
            Result += ' order error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        if P6924_TryLast(Owner, Order) then
            Result += 'back=' + Order
        else
            Result += ' back error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure SetCurrentKey_FlowFieldAfterStoredField_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Seed();
        Observer.Observe('grp_cnt', P6924_Outcome(1, false));
        Observer.Observe('grp_total', P6924_Outcome(2, false));
        Observer.Observe('grp_cnt_id', P6924_Outcome(3, false));
        Observer.Observe('grp_max', P6924_Outcome(10, false));
        Observer.Observe('id_cnt', P6924_Outcome(11, false));
        Observer.Expect('grp_cnt', 'key=Grp,Cnt order=5 3 1 4 2 back=2 4 1 3 5 ');
        Observer.Expect('grp_total', 'key=Grp,Total order=5 1 3 4 2 back=2 4 3 1 5 ');
        Observer.Expect('grp_cnt_id', 'key=Grp,Cnt,Id order=5 3 1 4 2 back=2 4 1 3 5 ');
        Observer.Expect('grp_max', 'key=Grp,MaxAmt order=5 1 3 4 2 back=2 4 3 1 5 ');
        Observer.Expect('id_cnt', 'key=Id,Cnt order=1 2 3 4 5 back=5 4 3 2 1 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowFieldAfterStoredField_Descending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Seed();
        Observer.Observe('grp_cnt_desc', P6924_Outcome(1, true));
        Observer.Observe('grp_total_desc', P6924_Outcome(2, true));
        Observer.Expect('grp_cnt_desc', 'key=Grp,Cnt order=2 4 1 3 5 back=5 3 1 4 2 ');
        Observer.Expect('grp_total_desc', 'key=Grp,Total order=2 4 3 1 5 back=5 1 3 4 2 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowFieldAfterStoredField_SetAscendingOnFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "REC FlowKey Owner";
        Order: Text;
    begin
        P6924_Seed();
        Owner.SetCurrentKey(Grp, Total);
        Owner.SetAscending(Total, false);
        Observer.Observe('ok', Format(P6924_TryOrder(Owner, Order)));
        Observer.ObserveError('order');
        Observer.Observe('order', Order);
        Owner.SetAscending(Total, true);
        Owner.SetAscending(Grp, false);
        Observer.Observe('ok_grp_desc', Format(P6924_TryOrder(Owner, Order)));
        Observer.Observe('order_grp_desc', Order);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('order|text', '');
        Observer.Expect('order|code', '');
        Observer.Expect('order', '3 1 5 2 4 ');
        Observer.Expect('ok_grp_desc', 'Yes');
        Observer.Expect('order_grp_desc', '4 2 5 1 3 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_TwoFlowFields_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Seed();
        Observer.Observe('cnt_total', P6924_Outcome(4, false));
        Observer.Observe('total_cnt', P6924_Outcome(12, false));
        Observer.Observe('cnt_total_desc', P6924_Outcome(4, true));
        Observer.Expect('cnt_total', 'key=Cnt,Total order=4 5 2 3 1 back=1 3 2 5 4 ');
        Observer.Expect('total_cnt', 'key=Total,Cnt order=4 5 1 3 2 back=2 3 1 5 4 ');
        Observer.Expect('cnt_total_desc', 'key=Cnt,Total order=1 3 2 5 4 back=4 5 2 3 1 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_OtherFlowFieldKinds_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        P6924_Seed();
        Observer.Observe('max', P6924_Outcome(5, false));
        Observer.Observe('min', P6924_Outcome(6, false));
        Observer.Observe('average', P6924_Outcome(7, false));
        Observer.Observe('exist', P6924_Outcome(8, false));
        Observer.Observe('lookup', P6924_Outcome(9, false));
        Observer.Expect('max', 'key=MaxAmt order=4 5 1 3 2 back=2 3 1 5 4 ');
        Observer.Expect('min', 'key=MinAmt order=4 3 5 1 2 back=2 1 5 3 4 ');
        Observer.Expect('average', 'key=AvgAmt order=4 5 1 3 2 back=2 3 1 5 4 ');
        Observer.Expect('exist', 'key=HasLine order=4 1 2 3 5 back=5 3 2 1 4 ');
        Observer.Expect('lookup', 'key=FirstAmt order=4 3 5 1 2 back=2 1 5 3 4 ');
        Observer.Verify();
    end;
}

// local object: the FlowFields of this table are the key fields under test (al-runner issue 6924 item 2.13).
table 95364 "REC FlowKey Owner"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Cnt; Integer) { FieldClass = FlowField; CalcFormula = count("REC FlowKey Line" where(OwnerId = field(Id))); }
        field(4; Total; Decimal) { FieldClass = FlowField; CalcFormula = sum("REC FlowKey Line".Amount where(OwnerId = field(Id))); }
        field(5; MaxAmt; Decimal) { FieldClass = FlowField; CalcFormula = max("REC FlowKey Line".Amount where(OwnerId = field(Id))); }
        field(6; MinAmt; Decimal) { FieldClass = FlowField; CalcFormula = min("REC FlowKey Line".Amount where(OwnerId = field(Id))); }
        field(7; AvgAmt; Decimal) { FieldClass = FlowField; CalcFormula = average("REC FlowKey Line".Amount where(OwnerId = field(Id))); }
        field(8; HasLine; Boolean) { FieldClass = FlowField; CalcFormula = exist("REC FlowKey Line" where(OwnerId = field(Id))); }
        field(9; FirstAmt; Decimal) { FieldClass = FlowField; CalcFormula = lookup("REC FlowKey Line".Amount where(OwnerId = field(Id))); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// local object: see table 95364.
table 95365 "REC FlowKey Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
