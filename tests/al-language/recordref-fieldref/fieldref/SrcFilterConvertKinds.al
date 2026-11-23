// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 57406, helper codeunit 57406, test codeunits 57407..57409
// Probe: observe form; the corpus CI matrix (27.5, 28.5, 29.0) observes every cell.
// Facts: FieldRef.SetRange, FieldRef.SetFilter('%1', ...) and Record.SetRange on a Code[20], Text[50], Integer, BigInteger, Decimal,
//   Boolean, Guid and Date field with a value of another type, and FieldRef.Value := of the same value for comparison.
//   Sources into Code and Text: Integer 5 and 0, BigInteger 5, Decimal 1.5, 1000.5 and -1.25, Boolean true.
//   Into Integer, BigInteger and Decimal: Code '123', 'ABC' and '1,000', Text 'XY', '1.5' and '' (empty).
//   Into Boolean: Code '123', '0' and 'ABC', Text 'Yes' and 'XY', Integer 1 and 0. Into Date: Code 'ABC', Text 'XY'.
//   Into Guid: Code 'ABC' and '123', Text 'XY' and Text '{1F2E3D4C-5B6A-4978-8695-A4B3C2D1E0F9}'.
//   Routes: a FieldRef.SetRange(X) typed; b FieldRef.SetRange(V), V a Variant holding X; c FieldRef.SetRange(X, X);
//   e FieldRef.SetFilter('%1', X); f FieldRef.SetFilter('%1', V); gr Record.SetRange(Rec.<field>, V); v FieldRef.Value := X.
//   Each cell runs in a TryFunction on a fresh RecordRef or Record and records "ok: <GetFilter of the field>" (route v:
//   "ok: " + Format(F.Value, 0, 9)) or "E: <GetLastErrorText> | <GetLastErrorCode>". A test is <Source>_<Field>.
//   Companion of SrcSetRangeConvert.al (Date, Time and DateTime fields).
//   Asked by al-runner issues 8857, 8867, 8868, 8869 and 8870.
// BC versions: 27, 28, 29 by CI
table 57406 "SFK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cod; Code[20]) { }
        field(3; Txt; Text[50]) { }
        field(4; Int; Integer) { }
        field(5; Big; BigInteger) { }
        field(6; Dec; Decimal) { }
        field(7; Bool; Boolean) { }
        field(8; G; Guid) { }
        field(9; D; Date) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 57406 "SFK Probe"
{
    // Each test declares its own "SFK Probe" variable, so every test starts with an empty observer.
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

    local procedure RecFilter(var R: Record "SFK Row"; FieldNo: Integer): Text
    begin
        case FieldNo of
            2:
                exit(R.GetFilter(Cod));
            3:
                exit(R.GetFilter(Txt));
            4:
                exit(R.GetFilter(Int));
            5:
                exit(R.GetFilter(Big));
            6:
                exit(R.GetFilter(Dec));
            7:
                exit(R.GetFilter(Bool));
            8:
                exit(R.GetFilter(G));
            9:
                exit(R.GetFilter(D));
        end;
    end;

    [TryFunction]
    local procedure TryInt(var F: FieldRef; Route: Text; X: Integer)
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

    local procedure CellInt(Route: Text; FieldNo: Integer; X: Integer)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryInt(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one Integer source on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsInt(FieldNo: Integer; X: Integer)
    var
        V: Variant;
    begin
        V := X;
        CellInt('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellInt('c', FieldNo, X);
        CellInt('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellInt('v', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryBig(var F: FieldRef; Route: Text; X: BigInteger)
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

    local procedure CellBig(Route: Text; FieldNo: Integer; X: BigInteger)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryBig(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one BigInteger source on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsBig(FieldNo: Integer; X: BigInteger)
    var
        V: Variant;
    begin
        V := X;
        CellBig('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellBig('c', FieldNo, X);
        CellBig('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellBig('v', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryDec(var F: FieldRef; Route: Text; X: Decimal)
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

    local procedure CellDec(Route: Text; FieldNo: Integer; X: Decimal)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryDec(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one Decimal source on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsDec(FieldNo: Integer; X: Decimal)
    var
        V: Variant;
    begin
        V := X;
        CellDec('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellDec('c', FieldNo, X);
        CellDec('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellDec('v', FieldNo, X);
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
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryBool(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one Boolean source on one field, in the order a, b, c, e, f, gr, v.
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

    [TryFunction]
    local procedure TryCode(var F: FieldRef; Route: Text; X: Code[20])
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

    local procedure CellCode(Route: Text; FieldNo: Integer; X: Code[20])
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryCode(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one Code[20] source on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsCode(FieldNo: Integer; X: Code[20])
    var
        V: Variant;
    begin
        V := X;
        CellCode('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellCode('c', FieldNo, X);
        CellCode('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellCode('v', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryTxt(var F: FieldRef; Route: Text; X: Text)
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

    local procedure CellTxt(Route: Text; FieldNo: Integer; X: Text)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryTxt(F, Route, X);
        Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;

    // All routes for one Text source on one field, in the order a, b, c, e, f, gr, v.
    procedure CellsTxt(FieldNo: Integer; X: Text)
    var
        V: Variant;
    begin
        V := X;
        CellTxt('a', FieldNo, X);
        CellVar('b', FieldNo, V);
        CellTxt('c', FieldNo, X);
        CellTxt('e', FieldNo, X);
        CellVar('f', FieldNo, V);
        CellVar('gr', FieldNo, V);
        CellTxt('v', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryVar(var R: Record "SFK Row"; var F: FieldRef; Route: Text; V: Variant)
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
                        R.SetRange(Int, V);
                    5:
                        R.SetRange(Big, V);
                    6:
                        R.SetRange(Dec, V);
                    7:
                        R.SetRange(Bool, V);
                    8:
                        R.SetRange(G, V);
                    9:
                        R.SetRange(D, V);
                end;
        end;
    end;

    local procedure CellVar(Route: Text; FieldNo: Integer; V: Variant)
    var
        R: Record "SFK Row";
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"SFK Row");
        F := RecRef.Field(FieldNo);
        Ok := TryVar(R, F, Route, V);
        if Route = 'gr' then
            Outcome(Route, Ok, RecFilter(R, FieldNo))
        else
            Outcome(Route, Ok, Result(F, Route, Ok));
        RecRef.Close();
    end;
}

codeunit 57407 "SFK Number To Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Int5_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 5;
        Probe.CellsInt(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure Int0_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 0;
        Probe.CellsInt(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure Big5_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: BigInteger;
    begin
        X := 5;
        Probe.CellsBig(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure Dec15_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure Dec10005_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := 1000.5;
        Probe.CellsDec(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure DecNeg125_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := -1.25;
        Probe.CellsDec(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Cod()
    var
        Probe: Codeunit "SFK Probe";
        X: Boolean;
    begin
        X := true;
        Probe.CellsBool(2, X);
        Probe.Finish();
    end;

    [Test]
    procedure Int5_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 5;
        Probe.CellsInt(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure Int0_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 0;
        Probe.CellsInt(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure Big5_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: BigInteger;
    begin
        X := 5;
        Probe.CellsBig(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure Dec15_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure Dec10005_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := 1000.5;
        Probe.CellsDec(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure DecNeg125_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Decimal;
    begin
        X := -1.25;
        Probe.CellsDec(3, X);
        Probe.Finish();
    end;

    [Test]
    procedure BoolTrue_Txt()
    var
        Probe: Codeunit "SFK Probe";
        X: Boolean;
    begin
        X := true;
        Probe.CellsBool(3, X);
        Probe.Finish();
    end;

}

codeunit 57408 "SFK Text To Number Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Code123_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure Txt15_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '1.5';
        Probe.CellsTxt(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtEmpty_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '';
        Probe.CellsTxt(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code1000_Int()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '1,000';
        Probe.CellsCode(4, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code123_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure Txt15_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '1.5';
        Probe.CellsTxt(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtEmpty_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '';
        Probe.CellsTxt(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code1000_Big()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '1,000';
        Probe.CellsCode(5, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code123_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(6, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(6, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(6, X);
        Probe.Finish();
    end;

    [Test]
    procedure Txt15_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '1.5';
        Probe.CellsTxt(6, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtEmpty_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '';
        Probe.CellsTxt(6, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code1000_Dec()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '1,000';
        Probe.CellsCode(6, X);
        Probe.Finish();
    end;

}

codeunit 57409 "SFK Other Kinds Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Code123_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code0_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '0';
        Probe.CellsCode(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtYes_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'Yes';
        Probe.CellsTxt(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure Int1_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 1;
        Probe.CellsInt(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure Int0_Bool()
    var
        Probe: Codeunit "SFK Probe";
        X: Integer;
    begin
        X := 0;
        Probe.CellsInt(7, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_D()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(9, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_D()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(9, X);
        Probe.Finish();
    end;

    [Test]
    procedure CodeABC_G()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(8, X);
        Probe.Finish();
    end;

    [Test]
    procedure Code123_G()
    var
        Probe: Codeunit "SFK Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(8, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtXY_G()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(8, X);
        Probe.Finish();
    end;

    [Test]
    procedure TxtGuid_G()
    var
        Probe: Codeunit "SFK Probe";
        X: Text;
    begin
        X := '{1F2E3D4C-5B6A-4978-8695-A4B3C2D1E0F9}';
        Probe.CellsTxt(8, X);
        Probe.Finish();
    end;

}
