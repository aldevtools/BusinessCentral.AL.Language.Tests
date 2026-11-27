// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73495, helper codeunit 73495, test codeunits 73496 and 73497
// Probe (AL Runner issue 9263): FieldRef.SetRange and FieldRef.SetFilter with a text that is not a number on an Integer, BigInteger and
//   Decimal field. Texts: 'AB00000000', 'A1', '1A', 'ABC', 'XY' and 'ABCDEFGHI', each as a Code[20] and as a Text. Calls: range
//   SetRange(X); range2 SetRange(X, X); f1 SetFilter('%1', X); ne '<>%1'; gt '>%1'; lt '<%1'; from '%1..'; upto '..%1'; or '%1|%2'
//   (X, X). Codeunit 73497: the same calls with X in a Variant (Code 'AB00000000', Text 'XY'), and Record.SetFilter(<field>, '<>%1', V).
//   Each cell runs in a TryFunction on a fresh RecordRef (or Record) and records "ok: <GetFilter>" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>". A test is <Field>_<Kind><Text>.
//   Already pinned: SetFilter('%1', X) with 'ABC' and 'XY' (SrcFilterConvertKinds.al), kept here as part of each row.
//   Measured on BC 29.0 (Linux, W1, en-US session, UTC) with an invented app holding these objects, through the dev endpoint's
//   TestRunnerHub; the values are that run's readings, turned into Expect and Verify by convert.py verbatim. This pull request's CI
//   checks them on 27.5, 28.5 and 29.0; a version difference gets a version guard.
//   Facts (BC 29.0): every cell fails with 'The value "<text>" can't be evaluated into type <Integer|BigInteger|Decimal>.'
//   (Evaluate:Format): every text, as Code or Text, typed or in a Variant, by every SetRange and SetFilter form and by
//   Record.SetFilter(<field>, '<>%1', V).
//   BC 27.5: CI run 46051422345 failed 43 tests of this file on 27.5 (both 27.5 legs alike). In those tests the BC 27.5 branch (#else)
//   is an observe round: it ends with Finish() and asserts nothing; the guard comment names the cell that run measured as
//   different and its 27.5 text. BC 28 and later (#if BC28PLUS) keep the BC 29 assertions.
// BC versions: 27, 28, 29 by CI
table 73495 "LT FTN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Int; Integer) { }
        field(3; Big; BigInteger) { }
        field(4; Dec; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73495 "LT FTN Probe"
{
    local procedure Outcome(var FR: FieldRef; Ok: Boolean): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok: ' + FR.GetFilter());
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    procedure Calls() Result: List of [Text]
    begin
        Result.Add('range');
        Result.Add('range2');
        Result.Add('f1');
        Result.Add('ne');
        Result.Add('gt');
        Result.Add('lt');
        Result.Add('from');
        Result.Add('upto');
        Result.Add('or');
    end;

    [TryFunction]
    local procedure TryCode(var FR: FieldRef; Call: Text; X: Code[20])
    begin
        case Call of
            'range':
                FR.SetRange(X);
            'range2':
                FR.SetRange(X, X);
            'f1':
                FR.SetFilter('%1', X);
            'ne':
                FR.SetFilter('<>%1', X);
            'gt':
                FR.SetFilter('>%1', X);
            'lt':
                FR.SetFilter('<%1', X);
            'from':
                FR.SetFilter('%1..', X);
            'upto':
                FR.SetFilter('..%1', X);
            'or':
                FR.SetFilter('%1|%2', X, X);
        end;
    end;

    // Every call with X on the field FieldNo, each on a fresh RecordRef.
    procedure CellsCode(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; X: Code[20])
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FTN Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryCode(FR, Call, X);
            Observer.Observe(Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryTxt(var FR: FieldRef; Call: Text; X: Text)
    begin
        case Call of
            'range':
                FR.SetRange(X);
            'range2':
                FR.SetRange(X, X);
            'f1':
                FR.SetFilter('%1', X);
            'ne':
                FR.SetFilter('<>%1', X);
            'gt':
                FR.SetFilter('>%1', X);
            'lt':
                FR.SetFilter('<%1', X);
            'from':
                FR.SetFilter('%1..', X);
            'upto':
                FR.SetFilter('..%1', X);
            'or':
                FR.SetFilter('%1|%2', X, X);
        end;
    end;

    // Every call with X on the field FieldNo, each on a fresh RecordRef.
    procedure CellsTxt(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; X: Text)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FTN Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryTxt(FR, Call, X);
            Observer.Observe(Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryVar(var FR: FieldRef; Call: Text; X: Variant)
    begin
        case Call of
            'range':
                FR.SetRange(X);
            'range2':
                FR.SetRange(X, X);
            'f1':
                FR.SetFilter('%1', X);
            'ne':
                FR.SetFilter('<>%1', X);
            'gt':
                FR.SetFilter('>%1', X);
            'lt':
                FR.SetFilter('<%1', X);
            'from':
                FR.SetFilter('%1..', X);
            'upto':
                FR.SetFilter('..%1', X);
            'or':
                FR.SetFilter('%1|%2', X, X);
        end;
    end;

    // Every call with X on the field FieldNo, each on a fresh RecordRef.
    procedure CellsVar(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; X: Variant)
    var
        RR: RecordRef;
        FR: FieldRef;
        Call: Text;
        Ok: Boolean;
    begin
        foreach Call in Calls() do begin
            RR.Open(Database::"LT FTN Row");
            FR := RR.Field(FieldNo);
            ClearLastError();
            Ok := TryVar(FR, Call, X);
            Observer.Observe(Call, Outcome(FR, Ok));
            RR.Close();
        end;
    end;

    [TryFunction]
    local procedure TryRecord(var Row: Record "LT FTN Row"; FieldNo: Integer; V: Variant)
    begin
        case FieldNo of
            2:
                Row.SetFilter(Int, '<>%1', V);
            3:
                Row.SetFilter(Big, '<>%1', V);
            4:
                Row.SetFilter(Dec, '<>%1', V);
        end;
    end;

    // Record.SetFilter(<field>, '<>%1', V) on a fresh record; records "ok: <GetFilter>" or the error.
    procedure RecordCell(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; V: Variant)
    var
        Row: Record "LT FTN Row";
        T: Text;
    begin
        ClearLastError();
        if TryRecord(Row, FieldNo, V) then
            case FieldNo of
                2:
                    T := 'ok: ' + Row.GetFilter(Int);
                3:
                    T := 'ok: ' + Row.GetFilter(Big);
                4:
                    T := 'ok: ' + Row.GetFilter(Dec);
            end
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        Observer.Observe(Name, T);
    end;
}

codeunit 73496 "LT FTN Typed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Code[20] 'AB00000000' into the Integer field.
    [Test]
    procedure Int_CodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'AB00000000';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'A1' into the Integer field.
    [Test]
    procedure Int_CodeA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'A1';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] '1A' into the Integer field.
    [Test]
    procedure Int_Code1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := '1A';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABC' into the Integer field.
    [Test]
    procedure Int_CodeABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'XY' into the Integer field.
    [Test]
    procedure Int_CodeXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'XY';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABCDEFGHI' into the Integer field.
    [Test]
    procedure Int_CodeABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABCDEFGHI';
        Probe.CellsCode(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'AB00000000' into the Integer field.
    [Test]
    procedure Int_TxtAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'AB00000000';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'A1' into the Integer field.
    [Test]
    procedure Int_TxtA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'A1';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text '1A' into the Integer field.
    [Test]
    procedure Int_Txt1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := '1A';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABC' into the Integer field.
    [Test]
    procedure Int_TxtABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABC';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'XY' into the Integer field.
    [Test]
    procedure Int_TxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABCDEFGHI' into the Integer field.
    [Test]
    procedure Int_TxtABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABCDEFGHI';
        Probe.CellsTxt(Observer, 2, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'AB00000000' into the BigInteger field.
    [Test]
    procedure Big_CodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'AB00000000';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'A1' into the BigInteger field.
    [Test]
    procedure Big_CodeA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'A1';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] '1A' into the BigInteger field.
    [Test]
    procedure Big_Code1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := '1A';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABC' into the BigInteger field.
    [Test]
    procedure Big_CodeABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'XY' into the BigInteger field.
    [Test]
    procedure Big_CodeXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'XY';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABCDEFGHI' into the BigInteger field.
    [Test]
    procedure Big_CodeABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABCDEFGHI';
        Probe.CellsCode(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'AB00000000' into the BigInteger field.
    [Test]
    procedure Big_TxtAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'AB00000000';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'A1' into the BigInteger field.
    [Test]
    procedure Big_TxtA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'A1';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text '1A' into the BigInteger field.
    [Test]
    procedure Big_Txt1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := '1A';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABC' into the BigInteger field.
    [Test]
    procedure Big_TxtABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABC';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'XY' into the BigInteger field.
    [Test]
    procedure Big_TxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABCDEFGHI' into the BigInteger field.
    [Test]
    procedure Big_TxtABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABCDEFGHI';
        Probe.CellsTxt(Observer, 3, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'AB00000000' into the Decimal field.
    [Test]
    procedure Dec_CodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'AB00000000';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'A1' into the Decimal field.
    [Test]
    procedure Dec_CodeA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'A1';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] '1A' into the Decimal field.
    [Test]
    procedure Dec_Code1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := '1A';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABC' into the Decimal field.
    [Test]
    procedure Dec_CodeABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'XY' into the Decimal field.
    [Test]
    procedure Dec_CodeXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'XY';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Code[20] 'ABCDEFGHI' into the Decimal field.
    [Test]
    procedure Dec_CodeABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
    begin
        X := 'ABCDEFGHI';
        Probe.CellsCode(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'AB00000000' into the Decimal field.
    [Test]
    procedure Dec_TxtAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'AB00000000';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'A1' into the Decimal field.
    [Test]
    procedure Dec_TxtA1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'A1';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "A1" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text '1A' into the Decimal field.
    [Test]
    procedure Dec_Txt1A()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := '1A';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "1A" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABC' into the Decimal field.
    [Test]
    procedure Dec_TxtABC()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABC';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABC" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'XY' into the Decimal field.
    [Test]
    procedure Dec_TxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Text 'ABCDEFGHI' into the Decimal field.
    [Test]
    procedure Dec_TxtABCDEFGHI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
    begin
        X := 'ABCDEFGHI';
        Probe.CellsTxt(Observer, 4, X);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "ABCDEFGHI" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;
}

codeunit 73497 "LT FTN Variant Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // A Variant holding the Code[20] 'AB00000000' into the Integer field.
    [Test]
    procedure Int_VariantCodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
        V: Variant;
    begin
        X := 'AB00000000';
        V := X;
        Probe.CellsVar(Observer, 2, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // A Variant holding the Text 'XY' into the Integer field.
    [Test]
    procedure Int_VariantTxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
        V: Variant;
    begin
        X := 'XY';
        V := X;
        Probe.CellsVar(Observer, 2, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // A Variant holding the Code[20] 'AB00000000' into the BigInteger field.
    [Test]
    procedure Big_VariantCodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
        V: Variant;
    begin
        X := 'AB00000000';
        V := X;
        Probe.CellsVar(Observer, 3, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // A Variant holding the Text 'XY' into the BigInteger field.
    [Test]
    procedure Big_VariantTxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
        V: Variant;
    begin
        X := 'XY';
        V := X;
        Probe.CellsVar(Observer, 3, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavBigInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // A Variant holding the Code[20] 'AB00000000' into the Decimal field.
    [Test]
    procedure Dec_VariantCodeAB00000000()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Code[20];
        V: Variant;
    begin
        X := 'AB00000000';
        V := X;
        Probe.CellsVar(Observer, 4, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // A Variant holding the Text 'XY' into the Decimal field.
    [Test]
    procedure Dec_VariantTxtXY()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        X: Text;
        V: Variant;
    begin
        X := 'XY';
        V := X;
        Probe.CellsVar(Observer, 4, V);
#if BC28PLUS
        Observer.Expect('range', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('range2', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('f1', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('ne', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('gt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('lt', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('from', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('upto', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('or', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured range = E: The type NavDecimal is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;

    // Record.SetFilter(<field>, '<>%1', V), V a Variant holding Code 'AB00000000' or Text 'XY', on each field.
    [Test]
    procedure Record_SetFilterNotEqual()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTN Probe";
        C: Code[20];
        T: Text;
        V: Variant;
    begin
        C := 'AB00000000';
        T := 'XY';
        V := C;
        Probe.RecordCell(Observer, 'Int_code', 2, V);
        V := T;
        Probe.RecordCell(Observer, 'Int_text', 2, V);
        V := C;
        Probe.RecordCell(Observer, 'Big_code', 3, V);
        V := T;
        Probe.RecordCell(Observer, 'Big_text', 3, V);
        V := C;
        Probe.RecordCell(Observer, 'Dec_code', 4, V);
        V := T;
        Probe.RecordCell(Observer, 'Dec_text', 4, V);
#if BC28PLUS
        Observer.Expect('Int_code', 'E: The value "AB00000000" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('Int_text', 'E: The value "XY" can''t be evaluated into type Integer. | Evaluate:Format');
        Observer.Expect('Big_code', 'E: The value "AB00000000" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('Big_text', 'E: The value "XY" can''t be evaluated into type BigInteger. | Evaluate:Format');
        Observer.Expect('Dec_code', 'E: The value "AB00000000" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Expect('Dec_text', 'E: The value "XY" can''t be evaluated into type Decimal. | Evaluate:Format');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; CI run 46051422345 measured Int_code = E: The type NavInteger is unknown. | NotSupportedType
        Observer.Finish();
#endif
    end;
}
