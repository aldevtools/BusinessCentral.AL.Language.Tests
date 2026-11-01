// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-addloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93626-93627, codeunit 93628 (writer Y67, gap cycle 6 follow-up)
// Probe: AddLoadFields and SetLoadFields (statement and function form) on a Record and on a RecordRef with a normal field, a FlowField
//   (Count, Sum) and a FlowFilter field, alone and among several fields in both orders, no field at all, in four request states
//   (nothing requested, after SetLoadFields(Name), after SetLoadFields() and after SetLoadFields(Name, Qty)). Per call: whether it raised
//   (and the field it names), the Boolean it returned, and AreFieldsLoaded of Id, Name, Qty, Cnt, Tot, Flt after a FindFirst.
//   The single-argument Record cases are pinned by record/lt-priority-assumptions/PriorityAssumptions.al:282-338 and
//   record/lt-loadfields-pagesource-validate/P81LoadFields.al:991-1028.
// BC versions: 27, 28, 29

table 93626 "LT Y67 LF Row"
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
            CalcFormula = count("LT Y67 LF Line" where("Row Id" = field(Id), "Day" = field(Flt)));
        }
        field(5; Tot; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y67 LF Line".Amount where("Row Id" = field(Id)));
        }
        field(6; Flt; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93627 "LT Y67 LF Line"
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

codeunit 93628 "LT Y67 LF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y67 LF Row";
        Line: Record "LT Y67 LF Line";
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
        Line.Insert();
    end;

    local procedure SpecName(Spec: Integer): Text
    begin
        case Spec of
            1:
                exit('none');
            2:
                exit('Name');
            3:
                exit('Cnt');
            4:
                exit('Flt');
            5:
                exit('Name+Qty');
            6:
                exit('Name+Cnt');
            7:
                exit('Cnt+Name');
            8:
                exit('Cnt+Tot');
            9:
                exit('Name+Cnt+Qty');
            10:
                exit('Name+Flt');
            11:
                exit('Cnt+Flt');
            12:
                exit('Flt+Name+Tot');
        end;
    end;

    local procedure Flags(var Row: Record "LT Y67 LF Row"): Text
    begin
        exit('loaded=' + Format(Row.AreFieldsLoaded(Row.Id)) + Format(Row.AreFieldsLoaded(Row.Name)) + Format(Row.AreFieldsLoaded(Row.Qty)) + Format(Row.AreFieldsLoaded(Row.Cnt)) + Format(Row.AreFieldsLoaded(Row.Tot)) + Format(Row.AreFieldsLoaded(Row.Flt)));
    end;

    // What the call did: the field the error names with the code and the rest of the text, or the Boolean the function form returned.
    local procedure Outcome(Ok: Boolean; Res: Boolean; Method: Integer): Text
    var
        ErrText: Text;
        ErrCode: Text;
        Rest: Text;
        At: Integer;
    begin
        if Ok then begin
            if Method > 2 then
                exit('returned=' + Format(Res));
            exit('ok');
        end;
        ErrText := GetLastErrorText();
        ErrCode := GetLastErrorCode();
        ClearLastError();
        if CopyStr(ErrText, 1, 11) = 'The field ''' then begin
            Rest := CopyStr(ErrText, 12);
            At := StrPos(Rest, '''');
            Rest := CopyStr(Rest, 1, At - 1) + '|' + ErrCode + '|' + CopyStr(Rest, At);
            exit('raised:' + Rest.Replace('''' + ' in the ''LT Y67 LF Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.', '<std>'));
        end;
        exit('raised:' + ErrText + '|' + ErrCode);
    end;

    [TryFunction]
    local procedure ApplyTo(var Row: Record "LT Y67 LF Row"; Method: Integer; Spec: Integer; var Res: Boolean)
    begin
        case Method of
            1:
                case Spec of
                    1:
                        Row.SetLoadFields();
                    2:
                        Row.SetLoadFields(Row.Name);
                    3:
                        Row.SetLoadFields(Row.Cnt);
                    4:
                        Row.SetLoadFields(Row.Flt);
                    5:
                        Row.SetLoadFields(Row.Name, Row.Qty);
                    6:
                        Row.SetLoadFields(Row.Name, Row.Cnt);
                    7:
                        Row.SetLoadFields(Row.Cnt, Row.Name);
                    8:
                        Row.SetLoadFields(Row.Cnt, Row.Tot);
                    9:
                        Row.SetLoadFields(Row.Name, Row.Cnt, Row.Qty);
                    10:
                        Row.SetLoadFields(Row.Name, Row.Flt);
                    11:
                        Row.SetLoadFields(Row.Cnt, Row.Flt);
                    12:
                        Row.SetLoadFields(Row.Flt, Row.Name, Row.Tot);
                end;
            2:
                case Spec of
                    1:
                        Row.AddLoadFields();
                    2:
                        Row.AddLoadFields(Row.Name);
                    3:
                        Row.AddLoadFields(Row.Cnt);
                    4:
                        Row.AddLoadFields(Row.Flt);
                    5:
                        Row.AddLoadFields(Row.Name, Row.Qty);
                    6:
                        Row.AddLoadFields(Row.Name, Row.Cnt);
                    7:
                        Row.AddLoadFields(Row.Cnt, Row.Name);
                    8:
                        Row.AddLoadFields(Row.Cnt, Row.Tot);
                    9:
                        Row.AddLoadFields(Row.Name, Row.Cnt, Row.Qty);
                    10:
                        Row.AddLoadFields(Row.Name, Row.Flt);
                    11:
                        Row.AddLoadFields(Row.Cnt, Row.Flt);
                    12:
                        Row.AddLoadFields(Row.Flt, Row.Name, Row.Tot);
                end;
            3:
                case Spec of
                    1:
                        Res := Row.SetLoadFields();
                    2:
                        Res := Row.SetLoadFields(Row.Name);
                    3:
                        Res := Row.SetLoadFields(Row.Cnt);
                    4:
                        Res := Row.SetLoadFields(Row.Flt);
                    5:
                        Res := Row.SetLoadFields(Row.Name, Row.Qty);
                    6:
                        Res := Row.SetLoadFields(Row.Name, Row.Cnt);
                    7:
                        Res := Row.SetLoadFields(Row.Cnt, Row.Name);
                    8:
                        Res := Row.SetLoadFields(Row.Cnt, Row.Tot);
                    9:
                        Res := Row.SetLoadFields(Row.Name, Row.Cnt, Row.Qty);
                    10:
                        Res := Row.SetLoadFields(Row.Name, Row.Flt);
                    11:
                        Res := Row.SetLoadFields(Row.Cnt, Row.Flt);
                    12:
                        Res := Row.SetLoadFields(Row.Flt, Row.Name, Row.Tot);
                end;
            4:
                case Spec of
                    1:
                        Res := Row.AddLoadFields();
                    2:
                        Res := Row.AddLoadFields(Row.Name);
                    3:
                        Res := Row.AddLoadFields(Row.Cnt);
                    4:
                        Res := Row.AddLoadFields(Row.Flt);
                    5:
                        Res := Row.AddLoadFields(Row.Name, Row.Qty);
                    6:
                        Res := Row.AddLoadFields(Row.Name, Row.Cnt);
                    7:
                        Res := Row.AddLoadFields(Row.Cnt, Row.Name);
                    8:
                        Res := Row.AddLoadFields(Row.Cnt, Row.Tot);
                    9:
                        Res := Row.AddLoadFields(Row.Name, Row.Cnt, Row.Qty);
                    10:
                        Res := Row.AddLoadFields(Row.Name, Row.Flt);
                    11:
                        Res := Row.AddLoadFields(Row.Cnt, Row.Flt);
                    12:
                        Res := Row.AddLoadFields(Row.Flt, Row.Name, Row.Tot);
                end;
        end;
    end;

    [TryFunction]
    local procedure ApplyToRef(var RecRef: RecordRef; Method: Integer; Spec: Integer; var Res: Boolean)
    begin
        case Method of
            1:
                case Spec of
                    1:
                        RecRef.SetLoadFields();
                    2:
                        RecRef.SetLoadFields(2);
                    3:
                        RecRef.SetLoadFields(4);
                    4:
                        RecRef.SetLoadFields(6);
                    5:
                        RecRef.SetLoadFields(2, 3);
                    6:
                        RecRef.SetLoadFields(2, 4);
                    7:
                        RecRef.SetLoadFields(4, 2);
                    8:
                        RecRef.SetLoadFields(4, 5);
                    9:
                        RecRef.SetLoadFields(2, 4, 3);
                    10:
                        RecRef.SetLoadFields(2, 6);
                    11:
                        RecRef.SetLoadFields(4, 6);
                    12:
                        RecRef.SetLoadFields(6, 2, 5);
                end;
            2:
                case Spec of
                    1:
                        RecRef.AddLoadFields();
                    2:
                        RecRef.AddLoadFields(2);
                    3:
                        RecRef.AddLoadFields(4);
                    4:
                        RecRef.AddLoadFields(6);
                    5:
                        RecRef.AddLoadFields(2, 3);
                    6:
                        RecRef.AddLoadFields(2, 4);
                    7:
                        RecRef.AddLoadFields(4, 2);
                    8:
                        RecRef.AddLoadFields(4, 5);
                    9:
                        RecRef.AddLoadFields(2, 4, 3);
                    10:
                        RecRef.AddLoadFields(2, 6);
                    11:
                        RecRef.AddLoadFields(4, 6);
                    12:
                        RecRef.AddLoadFields(6, 2, 5);
                end;
            3:
                case Spec of
                    1:
                        Res := RecRef.SetLoadFields();
                    2:
                        Res := RecRef.SetLoadFields(2);
                    3:
                        Res := RecRef.SetLoadFields(4);
                    4:
                        Res := RecRef.SetLoadFields(6);
                    5:
                        Res := RecRef.SetLoadFields(2, 3);
                    6:
                        Res := RecRef.SetLoadFields(2, 4);
                    7:
                        Res := RecRef.SetLoadFields(4, 2);
                    8:
                        Res := RecRef.SetLoadFields(4, 5);
                    9:
                        Res := RecRef.SetLoadFields(2, 4, 3);
                    10:
                        Res := RecRef.SetLoadFields(2, 6);
                    11:
                        Res := RecRef.SetLoadFields(4, 6);
                    12:
                        Res := RecRef.SetLoadFields(6, 2, 5);
                end;
            4:
                case Spec of
                    1:
                        Res := RecRef.AddLoadFields();
                    2:
                        Res := RecRef.AddLoadFields(2);
                    3:
                        Res := RecRef.AddLoadFields(4);
                    4:
                        Res := RecRef.AddLoadFields(6);
                    5:
                        Res := RecRef.AddLoadFields(2, 3);
                    6:
                        Res := RecRef.AddLoadFields(2, 4);
                    7:
                        Res := RecRef.AddLoadFields(4, 2);
                    8:
                        Res := RecRef.AddLoadFields(4, 5);
                    9:
                        Res := RecRef.AddLoadFields(2, 4, 3);
                    10:
                        Res := RecRef.AddLoadFields(2, 6);
                    11:
                        Res := RecRef.AddLoadFields(4, 6);
                    12:
                        Res := RecRef.AddLoadFields(6, 2, 5);
                end;
        end;
    end;

    [Test]
    procedure Record_NoRequest_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Ok := ApplyTo(Row, 1, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_NoRequest_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Ok := ApplyTo(Row, 2, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_NoRequest_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Ok := ApplyTo(Row, 3, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_NoRequest_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Ok := ApplyTo(Row, 4, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetName_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name);
            Ok := ApplyTo(Row, 1, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetName_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name);
            Ok := ApplyTo(Row, 2, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetName_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name);
            Ok := ApplyTo(Row, 3, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetName_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name);
            Ok := ApplyTo(Row, 4, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetEmpty_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields();
            Ok := ApplyTo(Row, 1, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetEmpty_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields();
            Ok := ApplyTo(Row, 2, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetEmpty_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields();
            Ok := ApplyTo(Row, 3, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetEmpty_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields();
            Ok := ApplyTo(Row, 4, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetNameQty_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name, Row.Qty);
            Ok := ApplyTo(Row, 1, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetNameQty_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name, Row.Qty);
            Ok := ApplyTo(Row, 2, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetNameQty_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name, Row.Qty);
            Ok := ApplyTo(Row, 3, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure Record_AfterSetNameQty_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(Row);
            Row.SetLoadFields(Row.Name, Row.Qty);
            Ok := ApplyTo(Row, 4, i, Res);
            Row.FindFirst();
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_NoRequest_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            Ok := ApplyToRef(RecRef, 1, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_NoRequest_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            Ok := ApplyToRef(RecRef, 2, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_NoRequest_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            Ok := ApplyToRef(RecRef, 3, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_NoRequest_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            Ok := ApplyToRef(RecRef, 4, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetName_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2);
            Ok := ApplyToRef(RecRef, 1, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetName_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2);
            Ok := ApplyToRef(RecRef, 2, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetName_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2);
            Ok := ApplyToRef(RecRef, 3, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetName_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2);
            Ok := ApplyToRef(RecRef, 4, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetEmpty_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields();
            Ok := ApplyToRef(RecRef, 1, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetEmpty_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields();
            Ok := ApplyToRef(RecRef, 2, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetEmpty_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields();
            Ok := ApplyToRef(RecRef, 3, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetEmpty_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields();
            Ok := ApplyToRef(RecRef, 4, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetNameQty_SetStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2, 3);
            Ok := ApplyToRef(RecRef, 1, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 1) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'ok loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'ok loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'ok loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetNameQty_AddStatement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2, 3);
            Ok := ApplyToRef(RecRef, 2, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 2) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'ok loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'raised:Cnt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'raised:Flt|DB:Ok|<std> loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetNameQty_SetFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2, 3);
            Ok := ApplyToRef(RecRef, 3, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 3) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('3 Cnt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('4 Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=Yes loaded=YesNoNoYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=Yes loaded=YesYesNoYesYesYes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_AfterSetNameQty_AddFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y67 LF Row";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
        Res: Boolean;
    begin
        Seed();
        for i := 1 to 12 do begin
            Res := false;
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT Y67 LF Row");
            RecRef.SetLoadFields(2, 3);
            Ok := ApplyToRef(RecRef, 4, i, Res);
            RecRef.FindFirst();
            RecRef.SetTable(Row);
            Observer.Observe(Format(i) + ' ' + SpecName(i), Outcome(Ok, Res, 4) + ' ' + Flags(Row));
        end;
        Observer.Expect('1 none', 'returned=Yes loaded=YesYesYesYesYesYes');
        Observer.Expect('2 Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('3 Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('4 Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('5 Name+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('6 Name+Cnt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('7 Cnt+Name', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('8 Cnt+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('9 Name+Cnt+Qty', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('10 Name+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('11 Cnt+Flt', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Expect('12 Flt+Name+Tot', 'returned=No loaded=YesYesYesYesYesYes');
        Observer.Verify();
    end;
}
