// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 86140 and 86141, test codeunit 86142
// Probe (writer PW): which FlowFields SetCurrentKey sorts on and which it drops. SetCurrentKeyFlowFieldOrder.al:109 pins CurrentKey 'Cnt' for
//   count(other table where(OwnerId = field(Id))); records/W4SortKeys.al:471 pins CurrentKey 'Id' for count(own table) without a condition.
//   One FlowField per shape: own or other table, with or without a field() condition, a const() condition only, a FlowFilter condition,
//   sum and exist. Per shape: SetCurrentKey as a statement, the CurrentKey after it, the FindSet order, and the answer of SetCurrentKey.
// BC versions: 27.5, 28.5, 29.0 (CI matrix)

table 86140 "LT PW FK Owner"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; CntSelfAll; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Owner"); }
        field(4; CntSelfLinked; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Owner" where(Id = field(Id))); }
        field(5; CntOtherAll; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Line"); }
        field(6; CntOtherLinked; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Line" where(OwnerId = field(Id))); }
        field(7; CntOtherConst; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Line" where(OwnerId = const(1))); }
        field(8; CntOtherByFilter; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Line" where(OwnerId = field(IdFilter))); }
        field(9; SumOtherLinked; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT PW FK Line".Amt where(OwnerId = field(Id))); }
        field(10; ExistOtherLinked; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT PW FK Line" where(OwnerId = field(Id), Amt = filter(> 5))); }
        field(11; CntOtherLinkedNoEdit; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FK Line" where(OwnerId = field(Id))); Editable = false; }
        field(12; SumOtherAll; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT PW FK Line".Amt); }
        field(13; IdFilter; Integer) { FieldClass = FlowFilter; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86141 "LT PW FK Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
        field(3; Amt; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 86142 "LT PW FlowField Key Rule"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Owner: Record "LT PW FK Owner";
        Line: Record "LT PW FK Line";
        n: Integer;
    begin
        Owner.DeleteAll();
        Line.DeleteAll();
        // owner 1 has 3 lines (amounts 1, 2, 3), owner 2 has 1 (amount 10), owner 3 has 2 (amounts 4, 4): ascending count is 2, 3, 1,
        // ascending sum is 1 (6), 3 (8), 2 (10), exist(Amt > 5) is only owner 2
        Owner.Id := 1; Owner.Name := 'c'; Owner.Insert();
        Owner.Id := 2; Owner.Name := 'a'; Owner.Insert();
        Owner.Id := 3; Owner.Name := 'b'; Owner.Insert();
        for n := 1 to 3 do begin
            Line.Id := n; Line.OwnerId := 1; Line.Amt := n; Line.Insert();
        end;
        Line.Id := 4; Line.OwnerId := 2; Line.Amt := 10; Line.Insert();
        Line.Id := 5; Line.OwnerId := 3; Line.Amt := 4; Line.Insert();
        Line.Id := 6; Line.OwnerId := 3; Line.Amt := 4; Line.Insert();
    end;

    [TryFunction]
    local procedure TryKey(var Owner: Record "LT PW FK Owner"; Which: Integer)
    begin
        case Which of
            3: Owner.SetCurrentKey(CntSelfAll);
            4: Owner.SetCurrentKey(CntSelfLinked);
            5: Owner.SetCurrentKey(CntOtherAll);
            6: Owner.SetCurrentKey(CntOtherLinked);
            7: Owner.SetCurrentKey(CntOtherConst);
            8: Owner.SetCurrentKey(CntOtherByFilter);
            9: Owner.SetCurrentKey(SumOtherLinked);
            10: Owner.SetCurrentKey(ExistOtherLinked);
            11: Owner.SetCurrentKey(CntOtherLinkedNoEdit);
            12: Owner.SetCurrentKey(SumOtherAll);
        end;
    end;

    [TryFunction]
    local procedure TryKeyAnswer(var Owner: Record "LT PW FK Owner"; Which: Integer; var Answer: Boolean)
    begin
        case Which of
            3: Answer := Owner.SetCurrentKey(CntSelfAll);
            4: Answer := Owner.SetCurrentKey(CntSelfLinked);
            5: Answer := Owner.SetCurrentKey(CntOtherAll);
            6: Answer := Owner.SetCurrentKey(CntOtherLinked);
            7: Answer := Owner.SetCurrentKey(CntOtherConst);
            8: Answer := Owner.SetCurrentKey(CntOtherByFilter);
            9: Answer := Owner.SetCurrentKey(SumOtherLinked);
            10: Answer := Owner.SetCurrentKey(ExistOtherLinked);
            11: Answer := Owner.SetCurrentKey(CntOtherLinkedNoEdit);
            12: Answer := Owner.SetCurrentKey(SumOtherAll);
        end;
    end;

    [TryFunction]
    local procedure TryOrder(var Owner: Record "LT PW FK Owner"; var Order: Text)
    begin
        Order := '';
        if Owner.FindSet() then
            repeat
                Order += Format(Owner.Id) + ' ';
            until Owner.Next() = 0;
    end;

    local procedure Outcome(Which: Integer; UseAnswer: Boolean): Text
    var
        Owner: Record "LT PW FK Owner";
        Answer: Boolean;
        Ok: Boolean;
        Order: Text;
        Result: Text;
    begin
        ClearLastError();
        if UseAnswer then
            Ok := TryKeyAnswer(Owner, Which, Answer)
        else
            Ok := TryKey(Owner, Which);
        if not Ok then begin
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            exit(Result);
        end;
        if UseAnswer then
            Result := 'answer=' + Format(Answer) + ' ';
        Result += 'key=' + Owner.CurrentKey();
        if TryOrder(Owner, Order) then
            Result += ' order=' + Order
        else
            Result += ' findset error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure FlowFieldKey_Statement_PerShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('cntSelfAll', Outcome(3, false));
        Observer.Observe('cntSelfLinked', Outcome(4, false));
        Observer.Observe('cntOtherAll', Outcome(5, false));
        Observer.Observe('cntOtherLinked', Outcome(6, false));
        Observer.Observe('cntOtherConst', Outcome(7, false));
        Observer.Observe('cntOtherByFilter', Outcome(8, false));
        Observer.Observe('sumOtherLinked', Outcome(9, false));
        Observer.Observe('existOtherLinked', Outcome(10, false));
        Observer.Observe('cntOtherLinkedNoEdit', Outcome(11, false));
        Observer.Observe('sumOtherAll', Outcome(12, false));
        Observer.Expect('cntSelfAll', 'key=CntSelfAll order=1 2 3 ');
        Observer.Expect('cntSelfLinked', 'key=CntSelfLinked order=1 2 3 ');
        Observer.Expect('cntOtherAll', 'key=CntOtherAll order=1 2 3 ');
        Observer.Expect('cntOtherLinked', 'key=CntOtherLinked order=2 3 1 ');
        Observer.Expect('cntOtherConst', 'key=CntOtherConst order=1 2 3 ');
        Observer.Expect('cntOtherByFilter', 'key=CntOtherByFilter order=1 2 3 ');
        Observer.Expect('sumOtherLinked', 'key=SumOtherLinked order=1 3 2 ');
        Observer.Expect('existOtherLinked', 'key=ExistOtherLinked order=1 3 2 ');
        Observer.Expect('cntOtherLinkedNoEdit', 'key=CntOtherLinkedNoEdit order=2 3 1 ');
        Observer.Expect('sumOtherAll', 'key=SumOtherAll order=1 2 3 ');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldKey_Answer_PerShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('cntSelfAll', Outcome(3, true));
        Observer.Observe('cntSelfLinked', Outcome(4, true));
        Observer.Observe('cntOtherAll', Outcome(5, true));
        Observer.Observe('cntOtherLinked', Outcome(6, true));
        Observer.Observe('cntOtherConst', Outcome(7, true));
        Observer.Observe('cntOtherByFilter', Outcome(8, true));
        Observer.Observe('sumOtherLinked', Outcome(9, true));
        Observer.Observe('existOtherLinked', Outcome(10, true));
        Observer.Observe('cntOtherLinkedNoEdit', Outcome(11, true));
        Observer.Observe('sumOtherAll', Outcome(12, true));
        Observer.Expect('cntSelfAll', 'answer=Yes key=CntSelfAll order=1 2 3 ');
        Observer.Expect('cntSelfLinked', 'answer=Yes key=CntSelfLinked order=1 2 3 ');
        Observer.Expect('cntOtherAll', 'answer=Yes key=CntOtherAll order=1 2 3 ');
        Observer.Expect('cntOtherLinked', 'answer=Yes key=CntOtherLinked order=2 3 1 ');
        Observer.Expect('cntOtherConst', 'answer=Yes key=CntOtherConst order=1 2 3 ');
        Observer.Expect('cntOtherByFilter', 'answer=Yes key=CntOtherByFilter order=1 2 3 ');
        Observer.Expect('sumOtherLinked', 'answer=Yes key=SumOtherLinked order=1 3 2 ');
        Observer.Expect('existOtherLinked', 'answer=Yes key=ExistOtherLinked order=1 3 2 ');
        Observer.Expect('cntOtherLinkedNoEdit', 'answer=Yes key=CntOtherLinkedNoEdit order=2 3 1 ');
        Observer.Expect('sumOtherAll', 'answer=Yes key=SumOtherAll order=1 2 3 ');
        Observer.Verify();
    end;
    // records/W4SortKeys.al:459 reads CurrentKey through a by-value Record parameter (Outcome(Ok; R: Record "W4 Key Row")). The key after
    // SetCurrentKey on a FlowField and on a normal field, read on the variable itself, through a by-value parameter, through a var parameter,
    // after an assignment and after Copy; and the FindSet order of the by-value copy.
    local procedure ByValue(R: Record "LT PW FK Owner"): Text
    var
        Order: Text;
    begin
        if TryOrder(R, Order) then;
        exit(R.CurrentKey() + ' order=' + Order);
    end;

    local procedure ByVar(var R: Record "LT PW FK Owner"): Text
    begin
        exit(R.CurrentKey());
    end;

    local procedure Copies(var Owner: Record "LT PW FK Owner"): Text
    var
        Assigned: Record "LT PW FK Owner";
        Copied: Record "LT PW FK Owner";
    begin
        Assigned := Owner;
        Copied.Copy(Owner);
        exit('self=' + Owner.CurrentKey() + ' byValue=' + ByValue(Owner) + ' byVar=' + ByVar(Owner) + ' assigned=' + Assigned.CurrentKey() + ' copied=' + Copied.CurrentKey());
    end;

    [Test]
    procedure FlowFieldKey_ThroughCopiesAndParameters()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT PW FK Owner";
        Owner2: Record "LT PW FK Owner";
        Owner3: Record "LT PW FK Owner";
        Owner4: Record "LT PW FK Owner";
    begin
        Seed();
        Owner.SetCurrentKey(CntOtherLinked);
        Observer.Observe('flowFieldLinked', Copies(Owner));
        Owner2.SetCurrentKey(CntSelfAll);
        Observer.Observe('flowFieldSelfAll', Copies(Owner2));
        Owner3.SetCurrentKey(Name);
        Observer.Observe('normalField', Copies(Owner3));
        Owner4.SetCurrentKey(CntOtherLinked, Id);
        Observer.Observe('flowFieldThenId', Copies(Owner4));
        Observer.Expect('flowFieldLinked', 'self=CntOtherLinked byValue=Id order=1 2 3  byVar=CntOtherLinked assigned=Id copied=CntOtherLinked');
        Observer.Expect('flowFieldSelfAll', 'self=CntSelfAll byValue=Id order=1 2 3  byVar=CntSelfAll assigned=Id copied=CntSelfAll');
        Observer.Expect('normalField', 'self=Name byValue=Id order=1 2 3  byVar=Name assigned=Id copied=Name');
        Observer.Expect('flowFieldThenId', 'self=CntOtherLinked,Id byValue=Id order=1 2 3  byVar=CntOtherLinked,Id assigned=Id copied=CntOtherLinked,Id');
        Observer.Verify();
    end;
}
