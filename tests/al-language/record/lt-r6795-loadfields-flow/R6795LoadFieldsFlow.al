// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-loadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 94540-94541, codeunit 94542 (writer R6795, runner issue 6795)
// Probe: Record.LoadFields (statement and function form) with a FlowField, a FlowFilter field and stored fields, in five record states
//   (never fetched, after Get, after Get under SetLoadFields(Name), after FindFirst, key assigned and never fetched). Per call: whether it
//   raised (text and code), the Boolean the function form returned, AreFieldsLoaded of Id, Name, Qty, Cnt, Tot, Flt, the FlowField
//   values read without CalcFields, and for the unfetched states the values after a following Get and CalcFields.
// BC versions: 27, 28, 29 (values measured on BC 28.5; 27 and 29 by the CI matrix)

table 94540 "LT R6795 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Decimal) { }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6795 Line" where("Row Id" = field(Id)));
        }
        field(5; Tot; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT R6795 Line".Amount where("Row Id" = field(Id), "Day" = field(Flt)));
        }
        field(6; Flt; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94541 "LT R6795 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Row Id"; Integer) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; "Day"; Integer) { }
    }

    keys
    {
        key(PK; "Row Id", "Line No.") { Clustered = true; }
    }
}

codeunit 94542 "LT R6795 LoadFields Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT R6795 Row";
        Line: Record "LT R6795 Line";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Qty := 5;
        Row.Insert();
        Line."Row Id" := 1;
        Line."Line No." := 1;
        Line.Amount := 10;
        Line."Day" := 1;
        Line.Insert();
        Line."Line No." := 2;
        Line.Amount := 20;
        Line."Day" := 2;
        Line.Insert();
    end;

    local procedure Flags(var Row: Record "LT R6795 Row"): Text
    begin
        exit('loaded=' + Format(Row.AreFieldsLoaded(Row.Id)) + Format(Row.AreFieldsLoaded(Row.Name)) + Format(Row.AreFieldsLoaded(Row.Qty)) + Format(Row.AreFieldsLoaded(Row.Cnt)) + Format(Row.AreFieldsLoaded(Row.Tot)) + Format(Row.AreFieldsLoaded(Row.Flt)));
    end;

    [TryFunction]
    local procedure Apply(var Row: Record "LT R6795 Row"; Form: Integer; Spec: Integer; var Res: Boolean)
    begin
        case Form of
            1:
                case Spec of
                    1:
                        Row.LoadFields(Row.Cnt);
                    2:
                        Row.LoadFields(Row.Flt);
                    3:
                        Row.LoadFields(Row.Name, Row.Cnt);
                    4:
                        Row.LoadFields(Row.Cnt, Row.Name);
                    5:
                        Row.LoadFields(Row.Cnt, Row.Tot);
                    6:
                        Row.LoadFields(Row.Flt, Row.Name);
                    7:
                        Row.LoadFields(Row.Name);
                end;
            2:
                case Spec of
                    1:
                        Res := Row.LoadFields(Row.Cnt);
                    2:
                        Res := Row.LoadFields(Row.Flt);
                    3:
                        Res := Row.LoadFields(Row.Name, Row.Cnt);
                    4:
                        Res := Row.LoadFields(Row.Cnt, Row.Name);
                    5:
                        Res := Row.LoadFields(Row.Cnt, Row.Tot);
                    6:
                        Res := Row.LoadFields(Row.Flt, Row.Name);
                    7:
                        Res := Row.LoadFields(Row.Name);
                end;
        end;
    end;

    local procedure Prepare(var Row: Record "LT R6795 Row"; State: Integer)
    begin
        Clear(Row);
        case State of
            2:
                Row.Get(1);
            3:
                begin
                    Row.SetLoadFields(Row.Name);
                    Row.Get(1);
                end;
            4:
                Row.FindFirst();
            5:
                Row.Id := 1;
        end;
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; State: Integer; Form: Integer; Spec: Integer; SpecName: Text)
    var
        Row: Record "LT R6795 Row";
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        Prepare(Row, State);
        ClearLastError();
        Ok := Apply(Row, Form, Spec, Res);
        if Ok then begin
            if Form = 2 then
                Observer.Observe(SpecName + ' result', Format(Res))
            else
                Observer.Observe(SpecName + ' result', 'ok');
        end else
            Observer.ObserveError(SpecName + ' error');
        Observer.Observe(SpecName + ' flags', Flags(Row));
        Observer.Observe(SpecName + ' values', 'Cnt=' + Format(Row.Cnt) + ' Tot=' + Format(Row.Tot));
        if (State = 1) or (State = 5) then begin
            Row.Get(1);
            Observer.Observe(SpecName + ' after get', Row.Name + ' Cnt=' + Format(Row.Cnt));
            Row.CalcFields(Cnt, Tot);
            Observer.Observe(SpecName + ' after calc', 'Cnt=' + Format(Row.Cnt) + ' Tot=' + Format(Row.Tot));
        end else begin
            Row.CalcFields(Cnt);
            Observer.Observe(SpecName + ' after calc', 'Cnt=' + Format(Row.Cnt));
        end;
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 1, 'Cnt');
        Observer.Expect('Cnt result', 'ok');
        Observer.Expect('Cnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after get', 'one Cnt=0');
        Observer.Expect('Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 2, 'Flt');
        Observer.Expect('Flt result', 'ok');
        Observer.Expect('Flt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after get', 'one Cnt=0');
        Observer.Expect('Flt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'ok');
        Observer.Expect('Name+Cnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after get', 'one Cnt=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'ok');
        Observer.Expect('Cnt+Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after get', 'one Cnt=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'ok');
        Observer.Expect('Cnt+Tot flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after get', 'one Cnt=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'ok');
        Observer.Expect('Flt+Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after get', 'one Cnt=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_NeverFetched_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after get', 'one Cnt=0');
        Observer.Expect('Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 1, 'Cnt');
        Observer.Expect('Cnt result', 'No');
        Observer.Expect('Cnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after get', 'one Cnt=0');
        Observer.Expect('Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 2, 'Flt');
        Observer.Expect('Flt result', 'No');
        Observer.Expect('Flt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after get', 'one Cnt=0');
        Observer.Expect('Flt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'No');
        Observer.Expect('Name+Cnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after get', 'one Cnt=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'No');
        Observer.Expect('Cnt+Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after get', 'one Cnt=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'No');
        Observer.Expect('Cnt+Tot flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after get', 'one Cnt=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'No');
        Observer.Expect('Flt+Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after get', 'one Cnt=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_NeverFetched_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 7, 'Name');
        Observer.Expect('Name result', 'No');
        Observer.Expect('Name flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after get', 'one Cnt=0');
        Observer.Expect('Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 1, 'Cnt');
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt error|code', 'DB:Ok');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 2, 'Flt');
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt error|code', 'DB:Ok');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Name+Cnt error|code', 'DB:Ok');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Name error|code', 'DB:Ok');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Tot error|code', 'DB:Ok');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 6, 'Flt+Name');
        Observer.Expect('Flt+Name error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt+Name error|code', 'DB:Ok');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGet_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 1, 'Cnt');
        Observer.Expect('Cnt result', 'No');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 2, 'Flt');
        Observer.Expect('Flt result', 'No');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'No');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'No');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'No');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'No');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGet_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 7, 'Name');
        Observer.Expect('Name result', 'Yes');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 1, 'Cnt');
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt error|code', 'DB:Ok');
        Observer.Expect('Cnt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 2, 'Flt');
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt error|code', 'DB:Ok');
        Observer.Expect('Flt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Name+Cnt error|code', 'DB:Ok');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Name error|code', 'DB:Ok');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Tot error|code', 'DB:Ok');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 6, 'Flt+Name');
        Observer.Expect('Flt+Name error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt+Name error|code', 'DB:Ok');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 1, 'Cnt');
        Observer.Expect('Cnt result', 'No');
        Observer.Expect('Cnt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 2, 'Flt');
        Observer.Expect('Flt result', 'No');
        Observer.Expect('Flt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'No');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'No');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'No');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'No');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 7, 'Name');
        Observer.Expect('Name result', 'Yes');
        Observer.Expect('Name flags', 'loaded=YesYesNoYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 1, 'Cnt');
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt error|code', 'DB:Ok');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 2, 'Flt');
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt error|code', 'DB:Ok');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Name+Cnt error|code', 'DB:Ok');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Name error|code', 'DB:Ok');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot error|text', 'The field ''Cnt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt+Tot error|code', 'DB:Ok');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 6, 'Flt+Name');
        Observer.Expect('Flt+Name error|text', 'The field ''Flt'' in the ''LT R6795 Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt+Name error|code', 'DB:Ok');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_AfterFindFirst_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 1, 'Cnt');
        Observer.Expect('Cnt result', 'No');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 2, 'Flt');
        Observer.Expect('Flt result', 'No');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'No');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'No');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'No');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'No');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_AfterFindFirst_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 7, 'Name');
        Observer.Expect('Name result', 'Yes');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after calc', 'Cnt=2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 1, 'Cnt');
        Observer.Expect('Cnt result', 'ok');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after get', 'one Cnt=0');
        Observer.Expect('Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 2, 'Flt');
        Observer.Expect('Flt result', 'ok');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after get', 'one Cnt=0');
        Observer.Expect('Flt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'ok');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after get', 'one Cnt=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'ok');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after get', 'one Cnt=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'ok');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after get', 'one Cnt=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'ok');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after get', 'one Cnt=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after get', 'one Cnt=0');
        Observer.Expect('Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_Cnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 1, 'Cnt');
        Observer.Expect('Cnt result', 'No');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt after get', 'one Cnt=0');
        Observer.Expect('Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_Flt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 2, 'Flt');
        Observer.Expect('Flt result', 'No');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after get', 'one Cnt=0');
        Observer.Expect('Flt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 3, 'Name+Cnt');
        Observer.Expect('Name+Cnt result', 'No');
        Observer.Expect('Name+Cnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name+Cnt values', 'Cnt=0 Tot=0');
        Observer.Expect('Name+Cnt after get', 'one Cnt=0');
        Observer.Expect('Name+Cnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 4, 'Cnt+Name');
        Observer.Expect('Cnt+Name result', 'No');
        Observer.Expect('Cnt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Name after get', 'one Cnt=0');
        Observer.Expect('Cnt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 5, 'Cnt+Tot');
        Observer.Expect('Cnt+Tot result', 'No');
        Observer.Expect('Cnt+Tot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Cnt+Tot values', 'Cnt=0 Tot=0');
        Observer.Expect('Cnt+Tot after get', 'one Cnt=0');
        Observer.Expect('Cnt+Tot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 6, 'Flt+Name');
        Observer.Expect('Flt+Name result', 'No');
        Observer.Expect('Flt+Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt+Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt+Name after get', 'one Cnt=0');
        Observer.Expect('Flt+Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 7, 'Name');
        Observer.Expect('Name result', 'No');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Name values', 'Cnt=0 Tot=0');
        Observer.Expect('Name after get', 'one Cnt=0');
        Observer.Expect('Name after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;
}
