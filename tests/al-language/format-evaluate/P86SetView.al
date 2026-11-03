// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against BC 29 (P86); the final facts are measured on a local BC 29 tier and added later.
// Facts: Record.SetView with sorting/filter text naming fields that need an integer or do not exist, Record.SetAscending on a field that is not the only field of the current key: errors and the GetView/GetAscending state afterwards
// BC versions: 29

table 73534 "LT P86 View Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; "Code"; Code[10]) { }
        field(5; Posted; Date) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Name, Amount) { }
        key(K3; Amount, "Code", Posted) { }
    }
}

codeunit 73535 "LT P86 SetView"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryView(var R: Record "LT P86 View Rec"; V: Text)
    begin
        R.SetView(V);
    end;

    local procedure SV(var R: Record "LT P86 View Rec"; V: Text): Text
    begin
        if TryView(R, V) then
            exit('ok|' + R.GetView(false) + '|' + R.GetView(true) + '|' + Format(R.CurrentKey()));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R.GetView(false));
    end;

    [TryFunction]
    local procedure TryAsc(var R: Record "LT P86 View Rec"; Which: Integer; Asc: Boolean)
    begin
        case Which of
            1:
                R.SetAscending("No.", Asc);
            2:
                R.SetAscending(Name, Asc);
            3:
                R.SetAscending(Amount, Asc);
            4:
                R.SetAscending("Code", Asc);
            5:
                R.SetAscending(Posted, Asc);
        end;
    end;

    local procedure SA(var R: Record "LT P86 View Rec"; Which: Integer; Asc: Boolean): Text
    begin
        if TryAsc(R, Which, Asc) then
            exit('ok|' + R.GetView(false) + '|' + Asc2(R));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R.GetView(false) + '|' + Asc2(R));
    end;

    [TryFunction]
    local procedure TryGetAsc(var R: Record "LT P86 View Rec"; Which: Integer; var Res: Boolean)
    begin
        case Which of
            1:
                Res := R.GetAscending("No.");
            2:
                Res := R.GetAscending(Name);
            3:
                Res := R.GetAscending(Amount);
            4:
                Res := R.GetAscending("Code");
            5:
                Res := R.GetAscending(Posted);
        end;
    end;

    local procedure GA(var R: Record "LT P86 View Rec"; Which: Integer): Text
    var
        Res: Boolean;
    begin
        if TryGetAsc(R, Which, Res) then
            exit(Format(Res));
        exit('err:' + CopyStr(GetLastErrorText(), 1, 40));
    end;

    local procedure Asc2(var R: Record "LT P86 View Rec"): Text
    begin
        exit(Format(R.Ascending()) + '|' + GA(R, 1) + ',' + GA(R, 2) + ',' + GA(R, 3) + ',' + GA(R, 4) + ',' + GA(R, 5));
    end;

    [Test]
    procedure SetView_IntegerPlaces()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P86 View Rec";
    begin
        R.DeleteAll();
        Observer.Observe('v1', SV(R, 'WHERE("No."=CONST(5))'));
        R.Reset();
        Observer.Observe('v2', SV(R, 'WHERE("No."=CONST(abc))'));
        R.Reset();
        Observer.Observe('v3', SV(R, 'WHERE("No."=FILTER(1..x))'));
        R.Reset();
        Observer.Observe('v4', SV(R, 'WHERE("No."=CONST(1.5))'));
        R.Reset();
        Observer.Observe('v5', SV(R, 'WHERE(Name=CONST(5))'));
        R.Reset();
        Observer.Observe('v6', SV(R, 'WHERE(Amount=CONST(abc))'));
        R.Reset();
        Observer.Observe('v7', SV(R, 'WHERE(Posted=CONST(abc))'));
        R.Reset();
        Observer.Observe('v8', SV(R, 'WHERE("No."=CONST())'));
        R.Reset();
        Observer.Observe('v9', SV(R, 'WHERE("No."=CONST(99999999999))'));
        R.Reset();
        Observer.Observe('v10', SV(R, 'WHERE("No."=FILTER(<>0))'));
        R.Reset();
        Observer.Observe('v11', SV(R, 'WHERE("No."=FILTER(1|2|3))'));
        R.Reset();
        Observer.Observe('v12', SV(R, 'WHERE("No."=FILTER(a|b))'));
        Observer.Expect('v1', 'ok|VERSION(1) SORTING(Field1) WHERE(Field1=1(5))|VERSION(1) SORTING(No.) WHERE(No.=FILTER(5))|No.');
        Observer.Expect('v2', 'err:The value "abc" can''t be evaluated into type Integer.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v3', 'err:The value "x" can''t be evaluated into type Integer.|InvalidFilterExpression:Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v4', 'err:The value "1.5" can''t be evaluated into type Integer.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v5', 'ok|VERSION(1) SORTING(Field1) WHERE(Field2=1(5))|VERSION(1) SORTING(No.) WHERE(Name=FILTER(5))|No.');
        Observer.Expect('v6', 'err:The value "abc" can''t be evaluated into type Decimal.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v7', 'err:The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v8', 'err:The value "" can''t be evaluated into type Integer.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v9', 'err:The value "99999999999" can''t be evaluated into type Integer.|Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Expect('v10', 'ok|VERSION(1) SORTING(Field1) WHERE(Field1=1(<>0))|VERSION(1) SORTING(No.) WHERE(No.=FILTER(<>0))|No.');
        Observer.Expect('v11', 'ok|VERSION(1) SORTING(Field1) WHERE(Field1=1(1|2|3))|VERSION(1) SORTING(No.) WHERE(No.=FILTER(1|2|3))|No.');
        Observer.Expect('v12', 'err:The value "a" can''t be evaluated into type Integer.|InvalidFilterExpression:Evaluate|VERSION(1) SORTING(Field1)');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Sorting()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P86 View Rec";
    begin
        R.DeleteAll();
        Observer.Observe('v1', SV(R, 'SORTING(Name)'));
        R.Reset();
        Observer.Observe('v2', SV(R, 'SORTING(Name,Amount)'));
        R.Reset();
        Observer.Observe('v3', SV(R, 'SORTING(Amount,Code,Posted)'));
        R.Reset();
        Observer.Observe('v4', SV(R, 'SORTING(Code)'));
        R.Reset();
        Observer.Observe('v5', SV(R, 'SORTING(Posted)'));
        R.Reset();
        Observer.Observe('v6', SV(R, 'SORTING(Name) ORDER(Descending)'));
        R.Reset();
        Observer.Observe('v7', SV(R, 'SORTING(Name,Amount) ORDER(Descending)'));
        R.Reset();
        Observer.Observe('v8', SV(R, 'SORTING(Nonexistent)'));
        R.Reset();
        Observer.Observe('v9', SV(R, 'SORTING("No.") ORDER(Ascending)'));
        R.Reset();
        Observer.Observe('v10', SV(R, 'SORTING(Name,"No.")'));
        R.Reset();
        Observer.Observe('v11', SV(R, 'SORTING(Amount)'));
        R.Reset();
        Observer.Observe('v12', SV(R, 'SORTING(Name,Amount,"No.")'));
        Observer.Expect('v1', 'ok|VERSION(1) SORTING(Field2,Field3)|VERSION(1) SORTING(Name,Amount)|Name,Amount');
        Observer.Expect('v2', 'ok|VERSION(1) SORTING(Field2,Field3)|VERSION(1) SORTING(Name,Amount)|Name,Amount');
        Observer.Expect('v3', 'ok|VERSION(1) SORTING(Field3,Field4,Field5)|VERSION(1) SORTING(Amount,Code,Posted)|Amount,Code,Posted');
        Observer.Expect('v4', 'ok|VERSION(1) SORTING(Field4)|VERSION(1) SORTING(Code)|Code');
        Observer.Expect('v5', 'ok|VERSION(1) SORTING(Field5)|VERSION(1) SORTING(Posted)|Posted');
        Observer.Expect('v6', 'ok|VERSION(1) SORTING(Field2,Field3) ORDER(1)|VERSION(1) SORTING(Name,Amount) ORDER(Descending)|Name,Amount');
        Observer.Expect('v7', 'ok|VERSION(1) SORTING(Field2,Field3) ORDER(1)|VERSION(1) SORTING(Name,Amount) ORDER(Descending)|Name,Amount');
        Observer.Expect('v8', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(No.)|No.');
        Observer.Expect('v9', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(No.)|No.');
        Observer.Expect('v10', 'ok|VERSION(1) SORTING(Field2,Field1)|VERSION(1) SORTING(Name,No.)|Name,No.');
        Observer.Expect('v11', 'ok|VERSION(1) SORTING(Field3,Field4,Field5)|VERSION(1) SORTING(Amount,Code,Posted)|Amount,Code,Posted');
        Observer.Expect('v12', 'ok|VERSION(1) SORTING(Field2,Field3)|VERSION(1) SORTING(Name,Amount)|Name,Amount');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Malformed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P86 View Rec";
    begin
        R.DeleteAll();
        Observer.Observe('v1', SV(R, ''));
        R.Reset();
        Observer.Observe('v2', SV(R, 'SORTING('));
        R.Reset();
        Observer.Observe('v3', SV(R, 'WHERE(Nope=CONST(1))'));
        R.Reset();
        Observer.Observe('v4', SV(R, 'WHERE("No."=)'));
        R.Reset();
        Observer.Observe('v5', SV(R, 'garbage'));
        R.Reset();
        Observer.Observe('v6', SV(R, 'ORDER(Descending)'));
        R.Reset();
        Observer.Observe('v7', SV(R, 'ORDER(Sideways)'));
        R.Reset();
        Observer.Observe('v8', SV(R, 'SORTING(Name) WHERE("No."=CONST(1)) ORDER(Descending)'));
        R.Reset();
        Observer.Observe('v9', SV(R, 'WHERE("No."=CONST(1)) SORTING(Name)'));
        R.Reset();
        Observer.Observe('v10', SV(R, '  SORTING(Name)  '));
        R.Reset();
        Observer.Observe('v11', SV(R, 'sorting(name) order(descending) where("no."=const(1))'));
        Observer.Expect('v1', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(No.)|No.');
        Observer.Expect('v2', 'err:Invalid expression of type: table view.\SORTING(|DB:Ok|VERSION(1) SORTING(Field1)');
        Observer.Expect('v3', 'ok|VERSION(1) SORTING(Field1)|VERSION(1) SORTING(No.)|No.');
        Observer.Expect('v4', 'err:Invalid expression of type: table view.\WHERE("No."=)|DB:Ok|VERSION(1) SORTING(Field1)');
        Observer.Expect('v5', 'err:Invalid expression of type: table view.\garbage|DB:Ok|VERSION(1) SORTING(Field1)');
        Observer.Expect('v6', 'ok|VERSION(1) SORTING(Field1) ORDER(1)|VERSION(1) SORTING(No.) ORDER(Descending)|No.');
        Observer.Expect('v7', 'err:Invalid expression of type: table view.\ORDER(Sideways)|DB:Ok|VERSION(1) SORTING(Field1)');
        Observer.Expect('v8', 'ok|VERSION(1) SORTING(Field2,Field3) ORDER(1) WHERE(Field1=1(1))|VERSION(1) SORTING(Name,Amount) ORDER(Descending) WHERE(No.=FILTER(1))|Name,Amount');
        Observer.Expect('v9', 'ok|VERSION(1) SORTING(Field2,Field3) WHERE(Field1=1(1))|VERSION(1) SORTING(Name,Amount) WHERE(No.=FILTER(1))|Name,Amount');
        Observer.Expect('v10', 'ok|VERSION(1) SORTING(Field2,Field3)|VERSION(1) SORTING(Name,Amount)|Name,Amount');
        Observer.Expect('v11', 'ok|VERSION(1) SORTING(Field2,Field3) ORDER(1) WHERE(Field1=1(1))|VERSION(1) SORTING(Name,Amount) ORDER(Descending) WHERE(No.=FILTER(1))|Name,Amount');
        Observer.Verify();
    end;
}

