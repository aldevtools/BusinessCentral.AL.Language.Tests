// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-loadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 94653-94654, codeunits 94655-94656 (writer Y87, from rt-6795)
// Probe (writer Y87): RecordRef.LoadFields (statement and function form) with a FlowField, a FlowFilter field and stored fields, in five record
//   states (never fetched, after Get, after Get under SetLoadFields(Name), after FindFirst, key assigned and never fetched), the same matrix as the
//   Record probe of runner issue 6795 (record/lt-r6795-loadfields-flow, not merged when this was written). Per call: whether it raised (text
//   and code), the Boolean the function form returned, AreFieldsLoaded of each field, the FlowField values read without CalcFields, and for the
//   unfetched states the values after a following Get and CalcFields. Codeunit 94656: AreFieldsLoaded on a Clear'd record (Record and RecordRef)
//   that never passed through LoadFields, with every field alone, FlowFields and FlowFilter, several fields at once, after Init, after
//   Open, under SetLoadFields.
// BC versions: 27, 28, 29

table 94653 "LT Y87 LF Row"
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
            CalcFormula = count("LT Y87 LF Line" where("Row Id" = field(Id)));
        }
        field(5; Tot; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y87 LF Line".Amount where("Row Id" = field(Id), "Day" = field(Flt)));
        }
        field(6; Flt; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 94654 "LT Y87 LF Line"
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

codeunit 94655 "LT Y87 RecordRef LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y87 LF Row";
        Line: Record "LT Y87 LF Line";
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

    local procedure Flags(var R: RecordRef): Text
    var
        I: Integer;
        Result: Text;
    begin
        for I := 1 to 6 do
            Result += Format(R.AreFieldsLoaded(I));
        exit('loaded=' + Result);
    end;

    local procedure Cnt(var R: RecordRef): Text
    begin
        exit('Cnt=' + Format(R.Field(4).Value) + ' Tot=' + Format(R.Field(5).Value));
    end;

    [TryFunction]
    local procedure Apply(var R: RecordRef; Form: Integer; Spec: Integer; var Res: Boolean)
    begin
        case Form of
            1:
                case Spec of
                    1:
                        R.LoadFields(4);
                    2:
                        R.LoadFields(6);
                    3:
                        R.LoadFields(2, 4);
                    4:
                        R.LoadFields(4, 2);
                    5:
                        R.LoadFields(4, 5);
                    6:
                        R.LoadFields(6, 2);
                    7:
                        R.LoadFields(2);
                end;
            2:
                case Spec of
                    1:
                        Res := R.LoadFields(4);
                    2:
                        Res := R.LoadFields(6);
                    3:
                        Res := R.LoadFields(2, 4);
                    4:
                        Res := R.LoadFields(4, 2);
                    5:
                        Res := R.LoadFields(4, 5);
                    6:
                        Res := R.LoadFields(6, 2);
                    7:
                        Res := R.LoadFields(2);
                end;
        end;
    end;

    local procedure GetOne(var R: RecordRef)
    var
        Row: Record "LT Y87 LF Row";
    begin
        Row.Get(1);
        R.Get(Row.RecordId());
    end;

    local procedure Prepare(var R: RecordRef; State: Integer)
    begin
        R.Close();
        R.Open(94653);
        case State of
            2:
                GetOne(R);
            3:
                begin
                    R.SetLoadFields(2);
                    GetOne(R);
                end;
            4:
                R.FindFirst();
            5:
                R.Field(1).Value := 1;
        end;
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; State: Integer; Form: Integer; Spec: Integer; SpecName: Text)
    var
        R: RecordRef;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        Prepare(R, State);
        ClearLastError();
        Ok := Apply(R, Form, Spec, Res);
        if Ok then begin
            if Form = 2 then
                Observer.Observe(SpecName + ' result', Format(Res))
            else
                Observer.Observe(SpecName + ' result', 'ok');
        end else
            Observer.ObserveError(SpecName + ' error');
        Observer.Observe(SpecName + ' flags', Flags(R));
        Observer.Observe(SpecName + ' values', Cnt(R));
        if (State = 1) or (State = 5) then begin
            GetOne(R);
            Observer.Observe(SpecName + ' after get', Format(R.Field(2).Value) + ' ' + Cnt(R).Split(' ').Get(1));
            R.Field(4).CalcField();
            R.Field(5).CalcField();
            Observer.Observe(SpecName + ' after calc', Cnt(R));
        end else begin
            R.Field(4).CalcField();
            Observer.Observe(SpecName + ' after calc', Cnt(R).Split(' ').Get(1));
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
        Cell(Observer, 1, 1, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'ok');
        Observer.Expect('NameCnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after get', 'one Cnt=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_NeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 4, 'CntName');
        Observer.Expect('CntName result', 'ok');
        Observer.Expect('CntName flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after get', 'one Cnt=0');
        Observer.Expect('CntName after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_NeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 5, 'CntTot');
        Observer.Expect('CntTot result', 'ok');
        Observer.Expect('CntTot flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after get', 'one Cnt=0');
        Observer.Expect('CntTot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_NeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 1, 6, 'FltName');
        Observer.Expect('FltName result', 'ok');
        Observer.Expect('FltName flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after get', 'one Cnt=0');
        Observer.Expect('FltName after calc', 'Cnt=2 Tot=30');
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
        Cell(Observer, 1, 2, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'No');
        Observer.Expect('NameCnt flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after get', 'one Cnt=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_NeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 4, 'CntName');
        Observer.Expect('CntName result', 'No');
        Observer.Expect('CntName flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after get', 'one Cnt=0');
        Observer.Expect('CntName after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_NeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 5, 'CntTot');
        Observer.Expect('CntTot result', 'No');
        Observer.Expect('CntTot flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after get', 'one Cnt=0');
        Observer.Expect('CntTot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_NeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 1, 2, 6, 'FltName');
        Observer.Expect('FltName result', 'No');
        Observer.Expect('FltName flags', 'loaded=NoNoNoNoNoNo');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after get', 'one Cnt=0');
        Observer.Expect('FltName after calc', 'Cnt=2 Tot=30');
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
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
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
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
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
        Cell(Observer, 2, 1, 3, 'NameCnt');
        Observer.Expect('NameCnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('NameCnt error|code', 'DB:Ok');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGet_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 4, 'CntName');
        Observer.Expect('CntName error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntName error|code', 'DB:Ok');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGet_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 5, 'CntTot');
        Observer.Expect('CntTot error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntTot error|code', 'DB:Ok');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGet_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 1, 6, 'FltName');
        Observer.Expect('FltName error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('FltName error|code', 'DB:Ok');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
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
        Cell(Observer, 2, 2, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'No');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGet_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 4, 'CntName');
        Observer.Expect('CntName result', 'No');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGet_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 5, 'CntTot');
        Observer.Expect('CntTot result', 'No');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGet_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 2, 2, 6, 'FltName');
        Observer.Expect('FltName result', 'No');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
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
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Cnt error|code', 'DB:Ok');
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
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
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('Flt error|code', 'DB:Ok');
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 3, 'NameCnt');
        Observer.Expect('NameCnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('NameCnt error|code', 'DB:Ok');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 4, 'CntName');
        Observer.Expect('CntName error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntName error|code', 'DB:Ok');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 5, 'CntTot');
        Observer.Expect('CntTot error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntTot error|code', 'DB:Ok');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 6, 'FltName');
        Observer.Expect('FltName error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('FltName error|code', 'DB:Ok');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterGetUnderSetLoadFieldsName_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 1, 7, 'Name');
        Observer.Expect('Name result', 'ok');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
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
        Observer.Expect('Cnt flags', 'loaded=YesYesYesYesYesYes');
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
        Observer.Expect('Flt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('Flt values', 'Cnt=0 Tot=0');
        Observer.Expect('Flt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_NameCnt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'No');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 4, 'CntName');
        Observer.Expect('CntName result', 'No');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 5, 'CntTot');
        Observer.Expect('CntTot result', 'No');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 6, 'FltName');
        Observer.Expect('FltName result', 'No');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterGetUnderSetLoadFieldsName_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 3, 2, 7, 'Name');
        Observer.Expect('Name result', 'Yes');
        Observer.Expect('Name flags', 'loaded=YesYesYesYesYesYes');
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
        Observer.Expect('Cnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
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
        Observer.Expect('Flt error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
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
        Cell(Observer, 4, 1, 3, 'NameCnt');
        Observer.Expect('NameCnt error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('NameCnt error|code', 'DB:Ok');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterFindFirst_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 4, 'CntName');
        Observer.Expect('CntName error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntName error|code', 'DB:Ok');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterFindFirst_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 5, 'CntTot');
        Observer.Expect('CntTot error|text', 'The field ''Cnt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('CntTot error|code', 'DB:Ok');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_AfterFindFirst_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 1, 6, 'FltName');
        Observer.Expect('FltName error|text', 'The field ''Flt'' in the ''LT Y87 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('FltName error|code', 'DB:Ok');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
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
        Cell(Observer, 4, 2, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'No');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterFindFirst_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 4, 'CntName');
        Observer.Expect('CntName result', 'No');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterFindFirst_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 5, 'CntTot');
        Observer.Expect('CntTot result', 'No');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after calc', 'Cnt=2');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_AfterFindFirst_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 4, 2, 6, 'FltName');
        Observer.Expect('FltName result', 'No');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after calc', 'Cnt=2');
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
        Cell(Observer, 5, 1, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'ok');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after get', 'one Cnt=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 4, 'CntName');
        Observer.Expect('CntName result', 'ok');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after get', 'one Cnt=0');
        Observer.Expect('CntName after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 5, 'CntTot');
        Observer.Expect('CntTot result', 'ok');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after get', 'one Cnt=0');
        Observer.Expect('CntTot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Statement_KeyAssignedNeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 1, 6, 'FltName');
        Observer.Expect('FltName result', 'ok');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after get', 'one Cnt=0');
        Observer.Expect('FltName after calc', 'Cnt=2 Tot=30');
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
        Cell(Observer, 5, 2, 3, 'NameCnt');
        Observer.Expect('NameCnt result', 'No');
        Observer.Expect('NameCnt flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('NameCnt values', 'Cnt=0 Tot=0');
        Observer.Expect('NameCnt after get', 'one Cnt=0');
        Observer.Expect('NameCnt after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_CntName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 4, 'CntName');
        Observer.Expect('CntName result', 'No');
        Observer.Expect('CntName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntName values', 'Cnt=0 Tot=0');
        Observer.Expect('CntName after get', 'one Cnt=0');
        Observer.Expect('CntName after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_CntTot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 5, 'CntTot');
        Observer.Expect('CntTot result', 'No');
        Observer.Expect('CntTot flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('CntTot values', 'Cnt=0 Tot=0');
        Observer.Expect('CntTot after get', 'one Cnt=0');
        Observer.Expect('CntTot after calc', 'Cnt=2 Tot=30');
        Observer.Verify();
    end;


    [Test]
    procedure LoadFields_Function_KeyAssignedNeverFetched_FltName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cell(Observer, 5, 2, 6, 'FltName');
        Observer.Expect('FltName result', 'No');
        Observer.Expect('FltName flags', 'loaded=YesYesYesYesYesYes');
        Observer.Expect('FltName values', 'Cnt=0 Tot=0');
        Observer.Expect('FltName after get', 'one Cnt=0');
        Observer.Expect('FltName after calc', 'Cnt=2 Tot=30');
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

codeunit 94656 "LT Y87 AreFieldsLoaded Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y87 LF Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Qty := 5;
        Row.Insert();
    end;

    local procedure RecFlags(var Row: Record "LT Y87 LF Row"): Text
    begin
        exit(Format(Row.AreFieldsLoaded(Row.Id)) + Format(Row.AreFieldsLoaded(Row.Name)) + Format(Row.AreFieldsLoaded(Row.Qty)) + Format(Row.AreFieldsLoaded(Row.Cnt)) + Format(Row.AreFieldsLoaded(Row.Tot)) + Format(Row.AreFieldsLoaded(Row.Flt)));
    end;

    local procedure RecMulti(var Row: Record "LT Y87 LF Row"): Text
    begin
        exit(Format(Row.AreFieldsLoaded(Row.Id, Row.Name)) + Format(Row.AreFieldsLoaded(Row.Cnt, Row.Tot)) + Format(Row.AreFieldsLoaded(Row.Id, Row.Cnt)) + Format(Row.AreFieldsLoaded(Row.Cnt, Row.Flt)));
    end;

    local procedure GetOne(var R: RecordRef)
    var
        Row: Record "LT Y87 LF Row";
    begin
        Row.Get(1);
        R.Get(Row.RecordId());
    end;

    local procedure RefFlags(var R: RecordRef): Text
    var
        I: Integer;
        Result: Text;
    begin
        for I := 1 to 6 do
            Result += Format(R.AreFieldsLoaded(I));
        exit(Result);
    end;

    local procedure RefMulti(var R: RecordRef): Text
    begin
        exit(Format(R.AreFieldsLoaded(1, 2)) + Format(R.AreFieldsLoaded(4, 5)) + Format(R.AreFieldsLoaded(1, 4)) + Format(R.AreFieldsLoaded(4, 6)));
    end;


    [Test]
    procedure Rec_Cleared()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_Init()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Init();
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_KeyAssigned()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Id := 1;
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_Get()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Get(1);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_SetLoadFieldsName()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.SetLoadFields(Row.Name);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_SetLoadFieldsCnt()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.SetLoadFields(Row.Cnt);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_SetLoadFieldsNameThenGet()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.SetLoadFields(Row.Name);
        Row.Get(1);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesNoYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_SetLoadFieldsCntThenGet()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.SetLoadFields(Row.Cnt);
        Row.Get(1);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesNoNoYesYesYes');
        Observer.Expect('multi', 'NoYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_ClearedThenCalcFields()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Id := 1;
        Row.CalcFields(Row.Cnt);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_AfterGetCalcFields()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Get(1);
        Row.CalcFields(Row.Cnt);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_AfterReset()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Get(1);
        Row.Reset();
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_AfterClearOfFetched()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Get(1);
        Clear(Row);
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Rec_AfterTransferFieldsFrom()
    var
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        Row.Init();
        Row.Name := 'x';
        Observer.Observe('single', RecFlags(Row));
        Observer.Observe('multi', RecMulti(Row));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_Opened()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_Init()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        R.Init();
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_KeyAssigned()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        R.Field(1).Value := 1;
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_Get()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        GetOne(R);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_SetLoadFieldsName()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        R.SetLoadFields(2);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_SetLoadFieldsNameThenGet()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        R.SetLoadFields(2);
        GetOne(R);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_SetLoadFieldsCntThenGet()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        R.SetLoadFields(4);
        GetOne(R);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_GetCalcField()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Open(94653);
        GetOne(R);
        R.Field(4).CalcField();
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'YesYesYesYesYesYes');
        Observer.Expect('multi', 'YesYesYesYes');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryRefFlags(var R: RecordRef; var Result: Text)
    begin
        Result := RefFlags(R);
    end;

    [Test]
    procedure Ref_AfterClose()
    var
        R: RecordRef;
        Observer: Codeunit "Probe Observer";
        Flags: Text;
    begin
        Seed();
        R.Open(94653);
        GetOne(R);
        R.Close();
        Observer.Observe('single ok', Format(TryRefFlags(R, Flags)));
        Observer.ObserveError('single');
        Observer.Observe('single flags', Flags);
        Observer.Expect('single ok', 'No');
        Observer.Expect('single|text', 'The record is not open.');
        Observer.Expect('single|code', 'RecordNotOpened');
        Observer.Expect('single flags', '');
        Observer.Verify();
    end;


    [Test]
    procedure Ref_GetTable()
    var
        R: RecordRef;
        Row: Record "LT Y87 LF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Row);
        R.GetTable(Row);
        Observer.Observe('single', RefFlags(R));
        Observer.Observe('multi', RefMulti(R));
        Observer.Expect('single', 'NoNoNoNoNoNo');
        Observer.Expect('multi', 'NoNoNoNo');
        Observer.Verify();
    end;

}