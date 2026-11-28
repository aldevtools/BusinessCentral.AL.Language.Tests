// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-field-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 73498 and 73610, enum 73610, helper codeunits 73498 and 73610, test codeunits 73499 and 73611
// Probe (AL Runner issue 9285): the value of RecordRef.Field(0), the record's timestamp field, converted into a Code and a Text
//   (exit from a Code[20] or Text procedure, and a direct assignment), into a BigInteger and through a Variant, and Format of it; the
//   FieldRef's Number, Name, Type and Class; the value of a row that is not inserted, of a temporary row, and before and after a
//   Modify.
//   The timestamp is the SQL rowversion of the row and changes from run to run, so no number is asserted: the cells record
//   relations (whether a text is a whole number, whether two readings are equal, whether the value grows after a Modify) and the
//   texts that do not depend on the row (errors, the Variant's kind, the FieldRef metadata).
//   Each cell runs in a TryFunction and records "ok: <reading>" or "E: <GetLastErrorText> | <GetLastErrorCode>".
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-27, with an invented app holding
//   these objects compiled by AL 18.0.43.1464 and run through the dev endpoint's TestRunnerHub (al runtests, AL tool
//   18.1.43.24897); the values are those runs' readings, turned into Expect and Verify by convert.py verbatim. That holds for
//   both test codeunits, 73499 and 73611. BC 27.5 gave the same readings in this pull request's CI observe runs 46057619272
//   (codeunit 73499) and 46059704991 (codeunit 73611), the same on both 27.5 legs, so one set of assertions holds on every
//   version.
//   Facts (BC 29.0): field 0 of an inserted row is a whole number in every reading: exit from a Code[20] and a Text procedure,
//   assignment to a Code[20], a Text and a BigInteger, Format and Format(.., 0, 9), and all of them give the same text. Through
//   a Variant (V := FR.Value) the Variant holds a BigInteger, and assigning that Variant to a Code[20] fails with 'The expression
//   Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.'
//   (TypeConversion). The value is greater than 999 (greater_than_999), so the whole-number readings are not the reading of
//   a small number. The FieldRef: Number 0, Name timestamp, Type BigInteger, Class Normal. A row that is not inserted and a
//   temporary row read 0. Rows differ from each other, and a Modify gives the row a greater value.
//   Neighbours (enum 73610, table 73610, helper 73610, test codeunit 73611): exit(FR.Value()) from a procedure that returns
//   Code[20], Text or Code[3], for an Integer (5), a BigInteger that is not field 0 (5000000000), a Decimal (1.5), an Enum (One,
//   caption 'One Caption'), an Option (Beta), a Boolean (true), a Date (2026-01-15) and a Duration (1500 ms) field. BC 29.0: the
//   value's formatted text (5, 5000000000, 1.5, the Enum's caption, the Option member, Yes, 01/15/26, 1 second 500 milliseconds),
//   upper-cased for Code; a text longer than the Code fails with 'The length of the string is <n>, but it must be less than or
//   equal to <m> characters. Value: <text>' (StringLengthExceeded).
// BC versions: 27, 28, 29 by CI
table 73498 "LT FTS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 73498 "LT FTS Probe"
{
    procedure CodeOfField(var RecRef: RecordRef; FieldNo: Integer): Code[20]
    var
        FRef: FieldRef;
    begin
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Value);
    end;

    procedure TextOfField(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FRef: FieldRef;
    begin
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Value);
    end;

    // 'number' when T is a whole number of digits (at least one), 'zero' for '0', else 'text <T>'.
    procedure Kind(T: Text): Text
    var
        B: BigInteger;
    begin
        if T = '0' then
            exit('zero');
        if (T <> '') and (DelChr(T, '=', '0123456789') = '') and Evaluate(B, T) then
            exit('number');
        exit('text ' + T);
    end;

    local procedure Outcome(Ok: Boolean; Result: Text): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok: ' + Result);
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TryCell(var RecRef: RecordRef; Cell: Text; var Result: Text)
    var
        FR: FieldRef;
        C: Code[20];
        T: Text;
        B: BigInteger;
        V: Variant;
    begin
        FR := RecRef.Field(0);
        case Cell of
            'code_exit':
                Result := Kind(CodeOfField(RecRef, 0));
            'text_exit':
                Result := Kind(TextOfField(RecRef, 0));
            'code_assign':
                begin
                    C := FR.Value();
                    Result := Kind(C);
                end;
            'text_assign':
                begin
                    T := FR.Value();
                    Result := Kind(T);
                end;
            'biginteger_assign':
                begin
                    B := FR.Value();
                    Result := Kind(Format(B, 0, 9));
                end;
            'format':
                Result := Kind(Format(FR.Value()));
            'format_9':
                Result := Kind(Format(FR.Value(), 0, 9));
            'variant_kind':
                begin
                    V := FR.Value();
                    Result := StrSubstNo('IsBigInteger %1 IsInteger %2 IsCode %3 IsText %4', V.IsBigInteger(), V.IsInteger(), V.IsCode(), V.IsText());
                end;
            'variant_to_code':
                begin
                    V := FR.Value();
                    C := V;
                    Result := Kind(C);
                end;
            'code_equals_text':
                Result := Format(CodeOfField(RecRef, 0) = TextOfField(RecRef, 0));
            'code_equals_format_biginteger':
                begin
                    B := FR.Value();
                    Result := Format(CodeOfField(RecRef, 0) = Format(B, 0, 9));
                end;
            'code_equals_format':
                Result := Format(CodeOfField(RecRef, 0) = Format(FR.Value()));
            'number':
                Result := Format(FR.Number());
            'name':
                Result := FR.Name();
            'type':
                Result := Format(FR.Type());
            'class':
                Result := Format(FR.Class());
            'code_field1':
                Result := CodeOfField(RecRef, 1);
            'greater_than_999':
                begin
                    B := FR.Value();
                    Result := Format(B > 999);
                end;
        end;
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; var RecRef: RecordRef; Name: Text)
    begin
        CellAs(Observer, RecRef, Name, Name);
    end;

    // The cell Name, observed under the name Label.
    procedure CellAs(var Observer: Codeunit "Probe Observer"; var RecRef: RecordRef; Name: Text; Label: Text)
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCell(RecRef, Name, Result);
        Observer.Observe(Label, Outcome(Ok, Result));
    end;

    [TryFunction]
    local procedure TryBig(var RecRef: RecordRef; var B: BigInteger)
    var
        FR: FieldRef;
    begin
        FR := RecRef.Field(0);
        B := FR.Value();
    end;

    // The timestamp of the row as a BigInteger, or -1 when reading it raises.
    procedure Stamp(var RecRef: RecordRef): BigInteger
    var
        B: BigInteger;
    begin
        if TryBig(RecRef, B) then
            exit(B);
        ClearLastError();
        exit(-1);
    end;

    // Rows PZ-A and PZ-B in the row table.
    procedure Seed()
    var
        Row: Record "LT FTS Row";
    begin
        Row.DeleteAll();
        Row."No." := 'PZ-A';
        Row.Insert();
        Row."No." := 'PZ-B';
        Row.Insert();
    end;
}

codeunit 73499 "LT FTS Timestamp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Field 0 of an inserted row (PZ-A), read through a RecordRef after FindFirst.
    [Test]
    procedure Field0_InsertedRow()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        RecRef: RecordRef;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.FindFirst();
        Probe.Cell(Observer, RecRef, 'code_exit');
        Probe.Cell(Observer, RecRef, 'text_exit');
        Probe.Cell(Observer, RecRef, 'code_assign');
        Probe.Cell(Observer, RecRef, 'text_assign');
        Probe.Cell(Observer, RecRef, 'biginteger_assign');
        Probe.Cell(Observer, RecRef, 'format');
        Probe.Cell(Observer, RecRef, 'format_9');
        Probe.Cell(Observer, RecRef, 'variant_kind');
        Probe.Cell(Observer, RecRef, 'variant_to_code');
        Probe.Cell(Observer, RecRef, 'code_equals_text');
        Probe.Cell(Observer, RecRef, 'code_equals_format_biginteger');
        Probe.Cell(Observer, RecRef, 'code_equals_format');
        Probe.Cell(Observer, RecRef, 'number');
        Probe.Cell(Observer, RecRef, 'name');
        Probe.Cell(Observer, RecRef, 'type');
        Probe.Cell(Observer, RecRef, 'class');
        Probe.Cell(Observer, RecRef, 'code_field1');
        Probe.Cell(Observer, RecRef, 'greater_than_999');
        Observer.Expect('code_exit', 'ok: number');
        Observer.Expect('text_exit', 'ok: number');
        Observer.Expect('code_assign', 'ok: number');
        Observer.Expect('text_assign', 'ok: number');
        Observer.Expect('biginteger_assign', 'ok: number');
        Observer.Expect('format', 'ok: number');
        Observer.Expect('format_9', 'ok: number');
        Observer.Expect('variant_kind', 'ok: IsBigInteger Yes IsInteger No IsCode No IsText No');
        Observer.Expect('variant_to_code', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value. | TypeConversion');
        Observer.Expect('code_equals_text', 'ok: Yes');
        Observer.Expect('code_equals_format_biginteger', 'ok: Yes');
        Observer.Expect('code_equals_format', 'ok: Yes');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('name', 'ok: timestamp');
        Observer.Expect('type', 'ok: BigInteger');
        Observer.Expect('class', 'ok: Normal');
        Observer.Expect('code_field1', 'ok: PZ-A');
        Observer.Expect('greater_than_999', 'ok: Yes');
        Observer.Verify();
    end;

    // Field 0 of a row that is not inserted (RecordRef.Init), and of a row inserted into a temporary RecordRef.
    [Test]
    procedure Field0_NotInsertedAndTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        RecRef: RecordRef;
        TempRef: RecordRef;
        FR: FieldRef;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.Init();
        Probe.CellAs(Observer, RecRef, 'code_exit', 'not_inserted_code_exit');
        Probe.CellAs(Observer, RecRef, 'text_assign', 'not_inserted_text_assign');
        TempRef.Open(Database::"LT FTS Row", true);
        FR := TempRef.Field(1);
        FR.Value := 'PZ-T';
        TempRef.Insert();
        TempRef.FindFirst();
        Probe.CellAs(Observer, TempRef, 'code_exit', 'temporary_code_exit');
        Probe.CellAs(Observer, TempRef, 'text_assign', 'temporary_text_assign');
        Probe.CellAs(Observer, TempRef, 'biginteger_assign', 'temporary_biginteger_assign');
        Observer.Expect('not_inserted_code_exit', 'ok: zero');
        Observer.Expect('not_inserted_text_assign', 'ok: zero');
        Observer.Expect('temporary_code_exit', 'ok: zero');
        Observer.Expect('temporary_text_assign', 'ok: zero');
        Observer.Expect('temporary_biginteger_assign', 'ok: zero');
        Observer.Verify();
    end;

    // The timestamp before and after a Modify of the row, and of another row.
    [Test]
    procedure Field0_AroundModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        Row: Record "LT FTS Row";
        RecRef: RecordRef;
        Before: BigInteger;
        After: BigInteger;
        Other: BigInteger;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.FindFirst();
        Before := Probe.Stamp(RecRef);
        RecRef.FindLast();
        Other := Probe.Stamp(RecRef);
        Row.Get('PZ-A');
        Row.Name := 'Changed';
        Row.Modify();
        RecRef.FindFirst();
        After := Probe.Stamp(RecRef);
        Observer.Observe('before_positive', Format(Before > 0));
        Observer.Observe('other_differs', Format(Other <> Before));
        Observer.Observe('after_differs', Format(After <> Before));
        Observer.Observe('after_greater', Format(After > Before));
        Observer.Observe('after_greater_than_other', Format(After > Other));
        Observer.Expect('before_positive', 'Yes');
        Observer.Expect('other_differs', 'Yes');
        Observer.Expect('after_differs', 'Yes');
        Observer.Expect('after_greater', 'Yes');
        Observer.Expect('after_greater_than_other', 'Yes');
        Observer.Verify();
    end;
}

// AL Runner issue 9285, neighbours: exit(FR.Value()) from a procedure that returns Code[20], Text or Code[3], for a FieldRef on a
// field of another type than the return type.
enum 73610 "LT FTX Kind"
{
    Extensible = false;
    value(0; Zero) { }
    value(1; One) { Caption = 'One Caption'; }
}

table 73610 "LT FTX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; IntF; Integer) { }
        field(3; BigF; BigInteger) { }
        field(4; DecF; Decimal) { }
        field(5; EnumF; Enum "LT FTX Kind") { }
        field(6; OptF; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(7; BoolF; Boolean) { }
        field(8; DateF; Date) { }
        field(9; DurF; Duration) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73610 "LT FTX Probe"
{
    local procedure ExitCode20(var FR: FieldRef): Code[20]
    begin
        exit(FR.Value());
    end;

    local procedure ExitText(var FR: FieldRef): Text
    begin
        exit(FR.Value());
    end;

    local procedure ExitCode3(var FR: FieldRef): Code[3]
    begin
        exit(FR.Value());
    end;

    [TryFunction]
    local procedure TryExit(var FR: FieldRef; Target: Text; var Result: Text)
    begin
        case Target of
            'code20':
                Result := ExitCode20(FR);
            'text':
                Result := ExitText(FR);
            'code3':
                Result := ExitCode3(FR);
        end;
    end;

    // A row with a value in every field: 5, 5000000000, 1.5, One, Beta, true, 2026-01-15 and 1500 milliseconds; inserted.
    procedure Seed()
    var
        Row: Record "LT FTX Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.IntF := 5;
        Row.BigF := 5000000000L;
        Row.DecF := 1.5;
        Row.EnumF := Row.EnumF::One;
        Row.OptF := Row.OptF::Beta;
        Row.BoolF := true;
        Row.DateF := 20260115D;
        Row.DurF := 1500;
        Row.Insert();
    end;

    // exit(FR.Value()) of field FieldNo into Code[20], Text and Code[3]; names <Name>_code20, _text, _code3.
    procedure Cells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text)
    var
        RecRef: RecordRef;
        FR: FieldRef;
        Targets: List of [Text];
        Target: Text;
        Result: Text;
        T: Text;
    begin
        Targets.Add('code20');
        Targets.Add('text');
        Targets.Add('code3');
        RecRef.Open(Database::"LT FTX Row");
        RecRef.FindFirst();
        FR := RecRef.Field(FieldNo);
        foreach Target in Targets do begin
            ClearLastError();
            Result := '';
            if TryExit(FR, Target, Result) then
                T := 'ok: ' + Result
            else
                T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
            ClearLastError();
            Observer.Observe(Name + '_' + Target, T);
        end;
    end;
}

codeunit 73611 "LT FTX Exit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // exit(FR.Value()) of an Integer, a BigInteger (not field 0) and a Decimal field.
    [Test]
    procedure ExitValue_NumberFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTX Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 2, 'integer');
        Probe.Cells(Observer, 3, 'biginteger');
        Probe.Cells(Observer, 4, 'decimal');
        Observer.Expect('integer_code20', 'ok: 5');
        Observer.Expect('integer_text', 'ok: 5');
        Observer.Expect('integer_code3', 'ok: 5');
        Observer.Expect('biginteger_code20', 'ok: 5000000000');
        Observer.Expect('biginteger_text', 'ok: 5000000000');
        Observer.Expect('biginteger_code3', 'E: The length of the string is 10, but it must be less than or equal to 3 characters. Value: 5000000000 | StringLengthExceeded');
        Observer.Expect('decimal_code20', 'ok: 1.5');
        Observer.Expect('decimal_text', 'ok: 1.5');
        Observer.Expect('decimal_code3', 'ok: 1.5');
        Observer.Verify();
    end;

    // exit(FR.Value()) of an Enum and an Option field.
    [Test]
    procedure ExitValue_EnumOptionFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTX Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 5, 'enum');
        Probe.Cells(Observer, 6, 'option');
        Observer.Expect('enum_code20', 'ok: ONE CAPTION');
        Observer.Expect('enum_text', 'ok: One Caption');
        Observer.Expect('enum_code3', 'E: The length of the string is 11, but it must be less than or equal to 3 characters. Value: One Caption | StringLengthExceeded');
        Observer.Expect('option_code20', 'ok: BETA');
        Observer.Expect('option_text', 'ok: Beta');
        Observer.Expect('option_code3', 'E: The length of the string is 4, but it must be less than or equal to 3 characters. Value: Beta | StringLengthExceeded');
        Observer.Verify();
    end;

    // exit(FR.Value()) of a Boolean, a Date and a Duration field.
    [Test]
    procedure ExitValue_OtherFields()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTX Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 7, 'boolean');
        Probe.Cells(Observer, 8, 'date');
        Probe.Cells(Observer, 9, 'duration');
        Observer.Expect('boolean_code20', 'ok: YES');
        Observer.Expect('boolean_text', 'ok: Yes');
        Observer.Expect('boolean_code3', 'ok: YES');
        Observer.Expect('date_code20', 'ok: 01/15/26');
        Observer.Expect('date_text', 'ok: 01/15/26');
        Observer.Expect('date_code3', 'E: The length of the string is 8, but it must be less than or equal to 3 characters. Value: 01/15/26 | StringLengthExceeded');
        Observer.Expect('duration_code20', 'E: The length of the string is 25, but it must be less than or equal to 20 characters. Value: 1 second 500 milliseconds | StringLengthExceeded');
        Observer.Expect('duration_text', 'ok: 1 second 500 milliseconds');
        Observer.Expect('duration_code3', 'E: The length of the string is 25, but it must be less than or equal to 3 characters. Value: 1 second 500 milliseconds | StringLengthExceeded');
        Observer.Verify();
    end;
}
