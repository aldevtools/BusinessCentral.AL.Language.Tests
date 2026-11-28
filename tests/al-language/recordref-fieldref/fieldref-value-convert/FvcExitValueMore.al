// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 73380, table 73380, helper codeunit 73380, test codeunit 73381
// Probe (AL Runner pull request 9325, issues 9285 and 9305; the cells its review asks for): exit(FR.Value()) from a procedure
//   that returns Code[20], Text, Text[3] or Text[30], for a FieldRef on a field of another type: an Integer (5), Decimals of 1000
//   or more (1234.5, -1234.5, 1234567.89: does the thousands separator appear), an Option whose OptionCaption differs from its
//   OptionMembers, an Enum member without a Caption and one with a Caption, a Boolean and a Date. Neighbour of the exit cells in
//   FvcTimestampField.al (codeunit 73611: Code[20], Text and Code[3]).
//   Each cell runs in a TryFunction and records "ok: <result>" or "E: <GetLastErrorText> | <GetLastErrorCode>". A test is
//   ExitValue_<Field> and reads the four returns.
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-28 with an invented app holding
//   these objects (AL 18.0.43.1464, run by al runtests of AL tool 18.1.43.24897); the values are those readings, turned into
//   Expect and Verify by convert.py verbatim. This pull request's CI checks them on 27.5, 28.5 and 29.0; a version difference
//   gets a version guard.
//   Facts (BC 29.0.54011.57673): the return is the value's formatted text, upper-cased for Code. A Decimal keeps the thousands
//   separator (1,234.5, -1,234.5, 1,234,567.89). An Option gives its OptionCaption (Second / SECOND), not the member name (Beta). An
//   Enum member without a Caption gives its name (Plain), one with a Caption gives the Caption. A bounded return takes the text
//   when it fits (Text[3]: 5, Yes) and else fails with 'The length of the string is <n>, but it must be less than or equal to
//   <m> characters. Value: <text>' (StringLengthExceeded); Text[30] takes every text here.
// BC versions: 27, 28, 29 by CI
enum 73380 "LT FXM Kind"
{
    Extensible = false;
    value(0; Plain) { }
    value(1; Fancy) { Caption = 'Fancy Caption'; }
}

table 73380 "LT FXM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; IntF; Integer) { }
        field(3; DecF; Decimal) { }
        field(4; DecNegF; Decimal) { }
        field(5; DecBigF; Decimal) { }
        field(6; OptF; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'First,Second,Third'; }
        field(7; EnumPlainF; Enum "LT FXM Kind") { }
        field(8; EnumFancyF; Enum "LT FXM Kind") { }
        field(9; BoolF; Boolean) { }
        field(10; DateF; Date) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73380 "LT FXM Probe"
{
    local procedure Exit_code20(var FR: FieldRef): Code[20]
    begin
        exit(FR.Value());
    end;

    local procedure Exit_text(var FR: FieldRef): Text
    begin
        exit(FR.Value());
    end;

    local procedure Exit_text3(var FR: FieldRef): Text[3]
    begin
        exit(FR.Value());
    end;

    local procedure Exit_text30(var FR: FieldRef): Text[30]
    begin
        exit(FR.Value());
    end;

    [TryFunction]
    local procedure TryExit(var FR: FieldRef; Target: Text; var Result: Text)
    begin
        case Target of
            'code20':
                Result := Exit_code20(FR);
            'text':
                Result := Exit_text(FR);
            'text3':
                Result := Exit_text3(FR);
            'text30':
                Result := Exit_text30(FR);
        end;
    end;

    procedure Seed()
    var
        Row: Record "LT FXM Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.IntF := 5;
        Row.DecF := 1234.5;
        Row.DecNegF := -1234.5;
        Row.DecBigF := 1234567.89;
        Row.OptF := Row.OptF::Beta;
        Row.EnumPlainF := Row.EnumPlainF::Plain;
        Row.EnumFancyF := Row.EnumFancyF::Fancy;
        Row.BoolF := true;
        Row.DateF := 20260115D;
        Row.Insert();
    end;

    // exit(FR.Value()) of field FieldNo into each return type; names code20, text, text3, text30.
    procedure Cells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
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
        Targets.Add('text3');
        Targets.Add('text30');
        RecRef.Open(Database::"LT FXM Row");
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
            Observer.Observe(Target, T);
        end;
    end;
}

codeunit 73381 "LT FXM Exit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // exit(FR.Value()) of an Integer 5.
    [Test]
    procedure ExitValue_Integer5()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 2);
        Observer.Expect('code20', 'ok: 5');
        Observer.Expect('text', 'ok: 5');
        Observer.Expect('text3', 'ok: 5');
        Observer.Expect('text30', 'ok: 5');
        Observer.Verify();
    end;

    // exit(FR.Value()) of a Decimal 1234.5.
    [Test]
    procedure ExitValue_Decimal1234_5()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 3);
        Observer.Expect('code20', 'ok: 1,234.5');
        Observer.Expect('text', 'ok: 1,234.5');
        Observer.Expect('text3', 'E: The length of the string is 7, but it must be less than or equal to 3 characters. Value: 1,234.5 | StringLengthExceeded');
        Observer.Expect('text30', 'ok: 1,234.5');
        Observer.Verify();
    end;

    // exit(FR.Value()) of a Decimal -1234.5.
    [Test]
    procedure ExitValue_DecimalNeg1234_5()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 4);
        Observer.Expect('code20', 'ok: -1,234.5');
        Observer.Expect('text', 'ok: -1,234.5');
        Observer.Expect('text3', 'E: The length of the string is 8, but it must be less than or equal to 3 characters. Value: -1,234.5 | StringLengthExceeded');
        Observer.Expect('text30', 'ok: -1,234.5');
        Observer.Verify();
    end;

    // exit(FR.Value()) of a Decimal 1234567.89.
    [Test]
    procedure ExitValue_Decimal1234567_89()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 5);
        Observer.Expect('code20', 'ok: 1,234,567.89');
        Observer.Expect('text', 'ok: 1,234,567.89');
        Observer.Expect('text3', 'E: The length of the string is 12, but it must be less than or equal to 3 characters. Value: 1,234,567.89 | StringLengthExceeded');
        Observer.Expect('text30', 'ok: 1,234,567.89');
        Observer.Verify();
    end;

    // exit(FR.Value()) of an Option Beta whose OptionCaption is 'First,Second,Third'.
    [Test]
    procedure ExitValue_OptionCaptioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 6);
        Observer.Expect('code20', 'ok: SECOND');
        Observer.Expect('text', 'ok: Second');
        Observer.Expect('text3', 'E: The length of the string is 6, but it must be less than or equal to 3 characters. Value: Second | StringLengthExceeded');
        Observer.Expect('text30', 'ok: Second');
        Observer.Verify();
    end;

    // exit(FR.Value()) of an Enum member Plain without a Caption.
    [Test]
    procedure ExitValue_EnumNoCaption()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 7);
        Observer.Expect('code20', 'ok: PLAIN');
        Observer.Expect('text', 'ok: Plain');
        Observer.Expect('text3', 'E: The length of the string is 5, but it must be less than or equal to 3 characters. Value: Plain | StringLengthExceeded');
        Observer.Expect('text30', 'ok: Plain');
        Observer.Verify();
    end;

    // exit(FR.Value()) of an Enum member Fancy with Caption 'Fancy Caption'.
    [Test]
    procedure ExitValue_EnumCaptioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 8);
        Observer.Expect('code20', 'ok: FANCY CAPTION');
        Observer.Expect('text', 'ok: Fancy Caption');
        Observer.Expect('text3', 'E: The length of the string is 13, but it must be less than or equal to 3 characters. Value: Fancy Caption | StringLengthExceeded');
        Observer.Expect('text30', 'ok: Fancy Caption');
        Observer.Verify();
    end;

    // exit(FR.Value()) of a Boolean true.
    [Test]
    procedure ExitValue_BooleanTrue()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 9);
        Observer.Expect('code20', 'ok: YES');
        Observer.Expect('text', 'ok: Yes');
        Observer.Expect('text3', 'ok: Yes');
        Observer.Expect('text30', 'ok: Yes');
        Observer.Verify();
    end;

    // exit(FR.Value()) of the Date 2026-01-15.
    [Test]
    procedure ExitValue_Date()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FXM Probe";
    begin
        Probe.Seed();
        Probe.Cells(Observer, 10);
        Observer.Expect('code20', 'ok: 01/15/26');
        Observer.Expect('text', 'ok: 01/15/26');
        Observer.Expect('text3', 'E: The length of the string is 8, but it must be less than or equal to 3 characters. Value: 01/15/26 | StringLengthExceeded');
        Observer.Expect('text30', 'ok: 01/15/26');
        Observer.Verify();
    end;
}
