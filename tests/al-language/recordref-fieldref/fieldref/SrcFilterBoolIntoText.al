// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 57981, helper codeunit 57981, test codeunit 57982
// Probe: observe form. CI records every cell on BC 27.5, 28.5 and 29.0; the next commit turns them into assertions.
// Facts: FieldRef.SetRange, FieldRef.SetFilter('%1', ...) and Record.SetRange on a Code or Text field with a Boolean value, and
//   FieldRef.Value := of the same value for comparison. Values: false and true. Fields: Code[20], Text[50], Code[2], Code[1] and
//   Text[1]. Routes: a FieldRef.SetRange(X) typed; b FieldRef.SetRange(V), V a Variant holding X; c FieldRef.SetRange(X, X);
//   e FieldRef.SetFilter('%1', X); f FieldRef.SetFilter('%1', V); gr Record.SetRange(Rec.<field>, V); v FieldRef.Value := X.
//   Each cell runs in a TryFunction on a fresh RecordRef or Record and records "ok: <GetFilter of the field>" (route v:
//   "ok: " + Format(F.Value, 0, 9)) or "E: <GetLastErrorText> | <GetLastErrorCode>". A test is Bool<Value>_<Field>.
//   Companion of SrcFilterConvertKinds.al (Boolean true into Code[20] and Text[50] there).
//   Asked by al-runner issue 9026.
// BC versions: 27, 28, 29 by CI
table 57981 "SBT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cod; Code[20]) { }
        field(3; Txt; Text[50]) { }
        field(4; Cod2; Code[2]) { }
        field(5; Cod1; Code[1]) { }
        field(6; Txt1; Text[1]) { }
        field(7; Cod3; Code[3]) { }
        field(8; Cod10; Code[10]) { }
        field(9; Cod50; Code[50]) { }
        field(10; Cod250; Code[250]) { }
        field(11; Txt2; Text[2]) { }
        field(12; Txt3; Text[3]) { }
        field(13; Txt100; Text[100]) { }
        field(14; Txt2048; Text[2048]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 57981 "SBT Probe"
{
    // Each test declares its own "SBT Probe" variable, so every test starts with an empty observer.
    var
        Obs: Codeunit "Probe Observer";

    procedure Finish()
    begin
        Obs.Finish();
    end;

    procedure Expect(Name: Text; Value: Text)
    begin
        Obs.Expect(Name, Value);
    end;

    procedure Verify()
    begin
        Obs.Verify();
    end;

    local procedure Outcome(Name: Text; Ok: Boolean; Filter: Text)
    begin
        if Ok then
            Obs.Observe(Name, 'ok: ' + Filter)
        else
            Obs.Observe(Name, 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        ClearLastError();
    end;

    // Route v records the field value; every other route records the filter of the field.
    local procedure Result(var F: FieldRef; Route: Text; Ok: Boolean): Text
    begin
        if not Ok then
            exit('');
        if Route = 'v' then
            exit(Format(F.Value, 0, 9));
        exit(F.GetFilter());
    end;

    local procedure RecFilter(var R: Record "SBT Row"; FieldNo: Integer): Text
    begin
        case FieldNo of
            2:
                exit(R.GetFilter(Cod));
            3:
                exit(R.GetFilter(Txt));
            4:
                exit(R.GetFilter(Cod2));
            5:
                exit(R.GetFilter(Cod1));
            6:
                exit(R.GetFilter(Txt1));
            7:
                exit(R.GetFilter(Cod3));
            8:
                exit(R.GetFilter(Cod10));
            9:
                exit(R.GetFilter(Cod50));
            10:
                exit(R.GetFilter(Cod250));
            11:
                exit(R.GetFilter(Txt2));
            12:
                exit(R.GetFilter(Txt3));
            13:
                exit(R.GetFilter(Txt100));
            14:
                exit(R.GetFilter(Txt2048));
        end;
    end;

    [TryFunction]
    local procedure TryBool(var F: FieldRef; Route: Text; X: Boolean)
    begin
        case Route of
            'a':
                F.SetRange(X);
            'c':
                F.SetRange(X, X);
            'e':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
        end;
    end;

    local procedure CellBool(Route: Text; FieldNo: Integer; X: Boolean)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SBT Row");
        F := RecRef.Field(FieldNo);
        Ok := TryBool(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryVar(var R: Record "SBT Row"; var F: FieldRef; Route: Text; V: Variant)
    begin
        case Route of
            'b':
                F.SetRange(V);
            'f':
                F.SetFilter('%1', V);
            'gr':
                case F.Number() of
                    2:
                        R.SetRange(Cod, V);
                    3:
                        R.SetRange(Txt, V);
                    4:
                        R.SetRange(Cod2, V);
                    5:
                        R.SetRange(Cod1, V);
                    6:
                        R.SetRange(Txt1, V);
                    7:
                        R.SetRange(Cod3, V);
                    8:
                        R.SetRange(Cod10, V);
                    9:
                        R.SetRange(Cod50, V);
                    10:
                        R.SetRange(Cod250, V);
                    11:
                        R.SetRange(Txt2, V);
                    12:
                        R.SetRange(Txt3, V);
                    13:
                        R.SetRange(Txt100, V);
                    14:
                        R.SetRange(Txt2048, V);
                end;
        end;
    end;

    local procedure CellVar(Route: Text; FieldNo: Integer; V: Variant)
    var
        R: Record "SBT Row";
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SBT Row");
        F := RecRef.Field(FieldNo);
        Ok := TryVar(R, F, Route, V);
        if Route = 'gr' then
            Outcome(Route, Ok, RecFilter(R, FieldNo))
        else
            Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryLiteral(var F: FieldRef; Route: Text; X: Boolean)
    begin
        // Literal Boolean constants, not a variable.
        case Route of
            'la':
                if X then
                    F.SetRange(true)
                else
                    F.SetRange(false);
            'le':
                if X then
                    F.SetFilter('%1', true)
                else
                    F.SetFilter('%1', false);
        end;
    end;

    local procedure CellLiteral(Route: Text; X: Boolean)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SBT Row");
        F := RecRef.Field(2);
        Ok := TryLiteral(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // Literal false or true into Code[20] (field 2): la FieldRef.SetRange(<literal>); le FieldRef.SetFilter('%1', <literal>).
    // Record.SetFilter(Cod, '%1', <literal>) does not compile (AL0193), so it has no route here.
    procedure CellsLiteral(X: Boolean)
    begin
        CellLiteral('la', X);
        CellLiteral('le', X);
    end;

    // All routes for one Boolean value on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsBool(FieldNo: Integer; X: Boolean)
    var
        V: Variant;
    begin
        V := X;
        CellBool('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellBool('c', FieldNo, X);
        CellBool('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellBool('v', FieldNo, X);
    end;
}

codeunit 57982 "SBT Bool Into Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BoolFalse_Cod()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(2, false);
        Probe.Expect('a', 'ok: NO');
        Probe.Expect('b', 'ok: NO');
        Probe.Expect('c', 'ok: NO');
        Probe.Expect('e', 'ok: NO');
        Probe.Expect('f', 'ok: NO');
        Probe.Expect('gr', 'ok: NO');
        Probe.Expect('v', 'ok: NO');
        Probe.Verify();
    end;

    [Test]
    procedure BoolFalse_Txt()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(3, false);
        Probe.Expect('a', 'ok: No');
        Probe.Expect('b', 'ok: No');
        Probe.Expect('c', 'ok: No');
        Probe.Expect('e', 'ok: No');
        Probe.Expect('f', 'ok: No');
        Probe.Expect('gr', 'ok: No');
        Probe.Expect('v', 'ok: No');
        Probe.Verify();
    end;

    [Test]
    procedure BoolFalse_Cod2()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(4, false);
        Probe.Expect('a', 'ok: NO');
        Probe.Expect('b', 'ok: NO');
        Probe.Expect('c', 'ok: NO');
        Probe.Expect('e', 'ok: NO');
        Probe.Expect('f', 'ok: NO');
        Probe.Expect('gr', 'ok: NO');
        Probe.Expect('v', 'ok: NO');
        Probe.Verify();
    end;

    [Test]
    procedure BoolFalse_Cod1()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(5, false);
        Probe.Expect('a', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('b', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('c', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('e', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('f', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('gr', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('v', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Verify();
    end;

    [Test]
    procedure BoolFalse_Txt1()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(6, false);
        Probe.Expect('a', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('b', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('c', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('e', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('f', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('gr', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Expect('v', 'E: The length of the string is 2, but it must be less than or equal to 1 characters. Value: No | StringLengthExceeded');
        Probe.Verify();
    end;

    [Test]
    procedure BoolTrue_Cod2()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(4, true);
        Probe.Expect('a', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('b', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('c', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('e', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('f', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('gr', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('v', 'E: The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes | StringLengthExceeded');
        Probe.Verify();
    end;

    [Test]
    procedure BoolTrue_Cod1()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(5, true);
        Probe.Expect('a', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('b', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('c', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('e', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('f', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('gr', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('v', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Verify();
    end;

    [Test]
    procedure BoolTrue_Txt1()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(6, true);
        Probe.Expect('a', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('b', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('c', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('e', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('f', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('gr', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Expect('v', 'E: The length of the string is 3, but it must be less than or equal to 1 characters. Value: Yes | StringLengthExceeded');
        Probe.Verify();
    end;
    [Test]
    procedure BoolFalse_Cod3()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(7, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Cod3()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(7, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Cod10()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(8, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Cod10()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(8, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Cod50()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(9, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Cod50()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(9, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Cod250()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(10, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Cod250()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(10, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Txt2()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(11, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Txt2()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(11, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Txt3()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(12, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Txt3()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(12, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Txt100()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(13, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Txt100()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(13, true);
        Probe.Finish();
    end;

    [Test]
    procedure BoolFalse_Txt2048()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(14, false);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Txt2048()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsBool(14, true);
        Probe.Finish();
    end;

    [Test]
    procedure LiteralFalse_Cod()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsLiteral(false);
        Probe.Finish();
    end;

    [Test]
    procedure LiteralTrue_Cod()
    var
        Probe: Codeunit "SBT Probe";
    begin
        Probe.CellsLiteral(true);
        Probe.Finish();
    end;
}
