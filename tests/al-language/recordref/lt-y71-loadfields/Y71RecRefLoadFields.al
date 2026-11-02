// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93800, test codeunit 93801, card page 93802, log 93803, page test codeunit 93804 (writer Y71, gap cycle 7 spec G7-01)
// Probe: RecordRef.SetLoadFields, AddLoadFields, SetAutoCalcFields and AreFieldsLoaded with the field number 0, with an unknown number among known
//        ones, and the call shape a partner app makes (a few real numbers followed by many zeros, every argument a function result).
//        Per call: ok and which fields AreFieldsLoaded reports after FindFirst, the formatted value of each field, or the error text and code.
//        Already pinned nearby: one unknown number alone (misc/lt-open-overloads-collections-isolated/P107RecRefNames.al, record/TestRecordPartialLoad.al).

table 93800 "LT Y71 LF Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Decimal) { }
        field(4; Cat; Code[10]) { }
        field(5; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y71 LF Tab" where(Cat = field(Cat)));
            Editable = false;
        }
        field(50; Far; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93801 "LT Y71 RecRef LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Numbers: List of [Integer];

    local procedure Seed()
    var
        Row: Record "LT Y71 LF Tab";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Qty := 1.5;
        Row.Cat := 'A';
        Row.Far := 11;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Qty := 2.5;
        Row.Cat := 'A';
        Row.Far := 22;
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Qty := 3.5;
        Row.Cat := 'B';
        Row.Far := 33;
        Row.Insert();
        Clear(Numbers);
        Numbers.Add(2);
        Numbers.Add(3);
    end;

    // The partner's TryGetFieldNo: the number at the position, 0 past the end of the list.
    local procedure Nth(Position: Integer): Integer
    begin
        if Position > Numbers.Count() then
            exit(0);
        exit(Numbers.Get(Position));
    end;

    [TryFunction]
    local procedure TryShape(var RR: RecordRef; Shape: Integer)
    begin
        case Shape of
            // SetLoadFields
            101:
                RR.SetLoadFields(0);
            102:
                RR.SetLoadFields(1, 0);
            103:
                RR.SetLoadFields(2, 0, 0, 0);
            104:
                RR.SetLoadFields(0, 2);
            105:
                RR.SetLoadFields(Nth(1), Nth(2), Nth(3), Nth(4), Nth(5));
            106:
                RR.SetLoadFields(Nth(1), Nth(2), Nth(3), Nth(4), Nth(5), Nth(6), Nth(7), Nth(8), Nth(9), Nth(10), Nth(11), Nth(12), Nth(13), Nth(14), Nth(15), Nth(16), Nth(17), Nth(18), Nth(19), Nth(20));
            107:
                RR.SetLoadFields(2, 99);
            108:
                RR.SetLoadFields(99, 2);
            109:
                RR.SetLoadFields(98, 99);
            110:
                RR.SetLoadFields(2, 99, 0);
            111:
                RR.SetLoadFields(2, 3);
            112:
                RR.SetLoadFields(2, 2, 2);
            113:
                RR.SetLoadFields(5);
            114:
                RR.SetLoadFields(50, 0);
            // SetLoadFields(2) first, then AddLoadFields
            201:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(0);
                end;
            202:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(3, 0);
                end;
            203:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(3, 99);
                end;
            204:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(99, 3);
                end;
            205:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(3);
                end;
            206:
                RR.AddLoadFields(3, 0);
            207:
                begin
                    RR.SetLoadFields(2);
                    RR.AddLoadFields(Nth(1), Nth(2), Nth(3), Nth(4), Nth(5));
                end;
            // SetAutoCalcFields
            301:
                RR.SetAutoCalcFields(0);
            302:
                RR.SetAutoCalcFields(5, 0);
            303:
                RR.SetAutoCalcFields(99);
            304:
                RR.SetAutoCalcFields(5, 99);
            305:
                RR.SetAutoCalcFields(2);
            306:
                RR.SetAutoCalcFields(5);
            307:
                RR.SetAutoCalcFields(0, 5);
            308:
                RR.SetAutoCalcFields(Nth(1), Nth(2), Nth(3), 5);
        end;
    end;

    local procedure Flags(var RR: RecordRef) Result: Text
    var
        FieldNos: List of [Integer];
        N: Integer;
    begin
        FieldNos.Add(1);
        FieldNos.Add(2);
        FieldNos.Add(3);
        FieldNos.Add(4);
        FieldNos.Add(5);
        FieldNos.Add(50);
        foreach N in FieldNos do begin
            if Result <> '' then
                Result += ' ';
            Result += Format(N) + ':';
            if RR.AreFieldsLoaded(N) then
                Result += 'Y'
            else
                Result += 'N';
        end;
    end;

    local procedure Values(var RR: RecordRef) Result: Text
    var
        FieldNos: List of [Integer];
        N: Integer;
    begin
        FieldNos.Add(1);
        FieldNos.Add(2);
        FieldNos.Add(3);
        FieldNos.Add(4);
        FieldNos.Add(5);
        FieldNos.Add(50);
        foreach N in FieldNos do begin
            if Result <> '' then
                Result += ' ';
            Result += Format(N) + '=' + Format(RR.Field(N).Value);
        end;
    end;

    // One call shape on a fresh RecordRef: ok plus what is loaded after FindFirst and the values, or the error.
    local procedure Probe(Name: Text; Shape: Integer)
    var
        RR: RecordRef;
    begin
        RR.Open(Database::"LT Y71 LF Tab");
        if TryShape(RR, Shape) then begin
            Obs.Observe(Name, 'ok');
            if RR.FindFirst() then begin
                Obs.Observe(Name + '|loaded', Flags(RR));
                Obs.Observe(Name + '|values', Values(RR));
            end else
                Obs.Observe(Name + '|find', 'no row');
        end else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
        RR.Close();
    end;

    [Test]
    procedure SetLoadFields_FieldZero()
    begin
        Seed();
        Probe('zero', 101);
        Probe('one_zero', 102);
        Probe('two_zero_zero_zero', 103);
        Probe('zero_two', 104);
        Probe('far_zero', 114);
        Obs.Expect('zero', 'ok');
        Obs.Expect('zero|loaded', '1:Y 2:N 3:N 4:N 5:Y 50:N');
        Obs.Expect('zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('one_zero', 'ok');
        Obs.Expect('one_zero|loaded', '1:Y 2:N 3:N 4:N 5:Y 50:N');
        Obs.Expect('one_zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('two_zero_zero_zero', 'ok');
        Obs.Expect('two_zero_zero_zero|loaded', '1:Y 2:Y 3:N 4:N 5:Y 50:N');
        Obs.Expect('two_zero_zero_zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('zero_two', 'ok');
        Obs.Expect('zero_two|loaded', '1:Y 2:Y 3:N 4:N 5:Y 50:N');
        Obs.Expect('zero_two|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('far_zero', 'ok');
        Obs.Expect('far_zero|loaded', '1:Y 2:N 3:N 4:N 5:Y 50:Y');
        Obs.Expect('far_zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Verify();
    end;

    [Test]
    procedure SetLoadFields_PartnerShape()
    begin
        Seed();
        Probe('nth5', 105);
        Probe('nth20', 106);
        Probe('two_three', 111);
        Probe('two_two_two', 112);
        Probe('flowfield', 113);
        Obs.Expect('nth5', 'ok');
        Obs.Expect('nth5|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('nth5|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('nth20', 'ok');
        Obs.Expect('nth20|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('nth20|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('two_three', 'ok');
        Obs.Expect('two_three|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('two_three|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('two_two_two', 'ok');
        Obs.Expect('two_two_two|loaded', '1:Y 2:Y 3:N 4:N 5:Y 50:N');
        Obs.Expect('two_two_two|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('flowfield', 'ok');
        Obs.Expect('flowfield|loaded', '1:Y 2:N 3:N 4:N 5:Y 50:N');
        Obs.Expect('flowfield|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Verify();
    end;

    [Test]
    procedure SetLoadFields_UnknownAmongKnown()
    begin
        Seed();
        Probe('two_99', 107);
        Probe('99_two', 108);
        Probe('98_99', 109);
        Probe('two_99_zero', 110);
        Obs.Expect('two_99', 'error');
        Obs.Expect('two_99|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('two_99|code', 'FieldNotFound');
        Obs.Expect('99_two', 'error');
        Obs.Expect('99_two|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('99_two|code', 'FieldNotFound');
        Obs.Expect('98_99', 'error');
        Obs.Expect('98_99|text', 'The supplied field number ''98'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('98_99|code', 'FieldNotFound');
        Obs.Expect('two_99_zero', 'error');
        Obs.Expect('two_99_zero|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('two_99_zero|code', 'FieldNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure AddLoadFields_ZeroAndUnknown()
    begin
        Seed();
        Probe('add_zero', 201);
        Probe('add_three_zero', 202);
        Probe('add_three_99', 203);
        Probe('add_99_three', 204);
        Probe('add_three', 205);
        Probe('add_without_set', 206);
        Probe('add_nth5', 207);
        Obs.Expect('add_zero', 'ok');
        Obs.Expect('add_zero|loaded', '1:Y 2:Y 3:N 4:N 5:Y 50:N');
        Obs.Expect('add_zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('add_three_zero', 'ok');
        Obs.Expect('add_three_zero|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('add_three_zero|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('add_three_99', 'error');
        Obs.Expect('add_three_99|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('add_three_99|code', 'FieldNotFound');
        Obs.Expect('add_99_three', 'error');
        Obs.Expect('add_99_three|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('add_99_three|code', 'FieldNotFound');
        Obs.Expect('add_three', 'ok');
        Obs.Expect('add_three|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('add_three|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('add_without_set', 'ok');
        Obs.Expect('add_without_set|loaded', '1:Y 2:Y 3:Y 4:Y 5:Y 50:Y');
        Obs.Expect('add_without_set|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Expect('add_nth5', 'ok');
        Obs.Expect('add_nth5|loaded', '1:Y 2:Y 3:Y 4:N 5:Y 50:N');
        Obs.Expect('add_nth5|values', '1=1 2=one 3=1.5 4=A 5=0 50=11');
        Obs.Verify();
    end;

    [Test]
    procedure SetAutoCalcFields_ZeroAndUnknown()
    begin
        Seed();
        Probe('calc_zero', 301);
        Probe('calc_five_zero', 302);
        Probe('calc_99', 303);
        Probe('calc_five_99', 304);
        Probe('calc_two', 305);
        Probe('calc_five', 306);
        Probe('calc_zero_five', 307);
        Probe('calc_nth_five', 308);
        Obs.Expect('calc_zero', 'error');
        Obs.Expect('calc_zero|text', 'The timestamp field in the LT Y71 LF Tab table must be a FlowField.');
        Obs.Expect('calc_zero|code', 'DB:Ok');
        Obs.Expect('calc_five_zero', 'error');
        Obs.Expect('calc_five_zero|text', 'The timestamp field in the LT Y71 LF Tab table must be a FlowField.');
        Obs.Expect('calc_five_zero|code', 'DB:Ok');
        Obs.Expect('calc_99', 'error');
        Obs.Expect('calc_99|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('calc_99|code', 'FieldNotFound');
        Obs.Expect('calc_five_99', 'error');
        Obs.Expect('calc_five_99|text', 'The supplied field number ''99'' cannot be found in the ''LT Y71 LF Tab'' table.');
        Obs.Expect('calc_five_99|code', 'FieldNotFound');
        Obs.Expect('calc_two', 'error');
        Obs.Expect('calc_two|text', 'The Name field in the LT Y71 LF Tab table must be a FlowField.');
        Obs.Expect('calc_two|code', 'DB:Ok');
        Obs.Expect('calc_five', 'ok');
        Obs.Expect('calc_five|loaded', '1:Y 2:Y 3:Y 4:Y 5:Y 50:Y');
        Obs.Expect('calc_five|values', '1=1 2=one 3=1.5 4=A 5=2 50=11');
        Obs.Expect('calc_zero_five', 'error');
        Obs.Expect('calc_zero_five|text', 'The timestamp field in the LT Y71 LF Tab table must be a FlowField.');
        Obs.Expect('calc_zero_five|code', 'DB:Ok');
        Obs.Expect('calc_nth_five', 'error');
        Obs.Expect('calc_nth_five|text', 'The Name field in the LT Y71 LF Tab table must be a FlowField.');
        Obs.Expect('calc_nth_five|code', 'DB:Ok');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryAreLoaded(var RR: RecordRef; Shape: Integer; var Answer: Boolean)
    begin
        case Shape of
            1:
                Answer := RR.AreFieldsLoaded(0);
            2:
                Answer := RR.AreFieldsLoaded(2, 0);
            3:
                Answer := RR.AreFieldsLoaded(99);
            4:
                Answer := RR.AreFieldsLoaded(2, 99);
            5:
                Answer := RR.AreFieldsLoaded(2);
            6:
                Answer := RR.AreFieldsLoaded(2, 3);
            7:
                Answer := RR.AreFieldsLoaded(0, 2);
            8:
                Answer := RR.AreFieldsLoaded(99, 2);
            9:
                Answer := RR.AreFieldsLoaded(Nth(1), Nth(2), Nth(3));
        end;
    end;

    local procedure AreLoaded(Name: Text; Shape: Integer)
    var
        RR: RecordRef;
        Answer: Boolean;
    begin
        RR.Open(Database::"LT Y71 LF Tab");
        RR.SetLoadFields(2);
        RR.FindFirst();
        if TryAreLoaded(RR, Shape, Answer) then
            Obs.Observe(Name, Format(Answer))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
        RR.Close();
    end;

    [Test]
    procedure AreFieldsLoaded_ZeroAndUnknown()
    begin
        Seed();
        AreLoaded('zero', 1);
        AreLoaded('two_zero', 2);
        AreLoaded('99', 3);
        AreLoaded('two_99', 4);
        AreLoaded('two', 5);
        AreLoaded('two_three', 6);
        AreLoaded('zero_two', 7);
        AreLoaded('99_two', 8);
        AreLoaded('nth3', 9);
        Obs.Expect('zero', 'Yes');
        Obs.Expect('two_zero', 'Yes');
        Obs.Expect('99', 'No');
        Obs.Expect('two_99', 'No');
        Obs.Expect('two', 'Yes');
        Obs.Expect('two_three', 'No');
        Obs.Expect('zero_two', 'Yes');
        Obs.Expect('99_two', 'No');
        Obs.Expect('nth3', 'No');
        Obs.Verify();
    end;
}

page 93802 "LT Y71 LF Card"
{
    PageType = Card;
    SourceTable = "LT Y71 LF Tab";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y71 LF Log";
        RR: RecordRef;
        Numbers: List of [Integer];
    begin
        Numbers.Add(2);
        Numbers.Add(3);
        Log.Add('query close');
        RR.Open(Database::"LT Y71 LF Tab");
        RR.SetLoadFields(Nth(Numbers, 1), Nth(Numbers, 2), Nth(Numbers, 3), Nth(Numbers, 4), Nth(Numbers, 5));
        Log.Add('set load fields done');
        if RR.FindFirst() then
            Log.Add('first row ' + Format(RR.Field(2).Value));
        RR.Close();
        exit(true);
    end;

    local procedure Nth(Numbers: List of [Integer]; Position: Integer): Integer
    begin
        if Position > Numbers.Count() then
            exit(0);
        exit(Numbers.Get(Position));
    end;
}

codeunit 93803 "LT Y71 LF Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ';';
        Lines += Line;
    end;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;
}

codeunit 93804 "LT Y71 RecRef LoadFields Pg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y71 LF Log";

    [TryFunction]
    local procedure TryOk(var Card: TestPage "LT Y71 LF Card")
    begin
        Card.OK().Invoke();
    end;

    [Test]
    procedure OnQueryClosePage_LoadFieldsWithZeros()
    var
        Row: Record "LT Y71 LF Tab";
        Card: TestPage "LT Y71 LF Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Reset();
        Card.OpenView();
        Card.First();
        if TryOk(Card) then
            Obs.Observe('close', 'ok')
        else begin
            Obs.Observe('close', 'error');
            Obs.ObserveError('close');
        end;
        Obs.Observe('log', Log.Text());
        Obs.Expect('close', 'ok');
        Obs.Expect('log', 'query close;set load fields done;first row one');
        Obs.Verify();
    end;
}
