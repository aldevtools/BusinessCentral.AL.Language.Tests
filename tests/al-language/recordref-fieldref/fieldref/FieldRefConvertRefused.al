// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setrange-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73470, helper codeunit 73470, test codeunits 73471..73473
// Probe (AL Runner issue 8219): a typed value of another type through a FieldRef, the cells AL Runner refuses ("conversion of <type>
//   <value> to <type>"). A RecordRef opens the row table; FR := RecRef.Field(n) is a BigInteger, Integer, Decimal, Code[20], Text[50], Date,
//   Boolean, Option (A,B,C) or Guid field. Values: Boolean false, Code[20] 'ABC', Code[20] '123', Text 'XY', Integer 5, BigInteger 5,
//   Decimal 1.5 and the Date 2026-01-17. Methods: r FR.SetRange(X); f FR.SetFilter('%1', X); v FR.Value := X; d FR.Validate(X);
//   dv FR.Validate(V), V a Variant holding X (the Guid tests only).
//   Each cell runs in a TryFunction on a fresh RecordRef and records "ok: <reading>" (r and f: FR.GetFilter(); v, d and dv:
//   Format(FR.Value, 0, 9)) or "E: <GetLastErrorText> | <GetLastErrorCode>". A test is <Value>_<Field> and runs r, f, v and d.
//   The cells: every (value, field) pair with a cell AL Runner refuses, all four methods, so the methods it runs stand next to the ones
//   it refuses. Pairs already pinned by SrcFilterConvertKinds.al (numbers into Code and Text, Code and Text into number and Boolean
//   fields, SetRange, SetFilter and Value := of a text into a Guid field) are not repeated; of the Guid text pairs only Validate is new.
//   Companion of SrcFilterConvertKinds.al and SrcSetRangeConvert.al.
//   Observe round: every test ends with Probe.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
table 73470 "LT FRC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; Int; Integer) { }
        field(4; Dec; Decimal) { }
        field(5; Cod; Code[20]) { }
        field(6; Txt; Text[50]) { }
        field(7; D; Date) { }
        field(8; Bool; Boolean) { }
        field(9; Opt; Option) { OptionMembers = A,B,C; }
        field(10; G; Guid) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// The cells. Each test declares its own "LT FRC Probe" variable, so every test starts with an empty observer.
codeunit 73470 "LT FRC Probe"
{
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

    // "ok: " and the reading (GetFilter for r and f, Format(Value, 0, 9) for v, d and dv), or "E: " and the error text and code.
    local procedure Outcome(var F: FieldRef; Method: Text; Ok: Boolean)
    begin
        if not Ok then
            Obs.Observe(Method, 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode())
        else
            if Method in ['r', 'f'] then
                Obs.Observe(Method, 'ok: ' + F.GetFilter())
            else
                Obs.Observe(Method, 'ok: ' + Format(F.Value, 0, 9));
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryBool(var F: FieldRef; Method: Text; X: Boolean)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellBool(Method: Text; FieldNo: Integer; X: Boolean)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryBool(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsBool(FieldNo: Integer; X: Boolean)
    begin
        CellBool('r', FieldNo, X);
        CellBool('f', FieldNo, X);
        CellBool('v', FieldNo, X);
        CellBool('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryCode(var F: FieldRef; Method: Text; X: Code[20])
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellCode(Method: Text; FieldNo: Integer; X: Code[20])
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryCode(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsCode(FieldNo: Integer; X: Code[20])
    begin
        CellCode('r', FieldNo, X);
        CellCode('f', FieldNo, X);
        CellCode('v', FieldNo, X);
        CellCode('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryTxt(var F: FieldRef; Method: Text; X: Text)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellTxt(Method: Text; FieldNo: Integer; X: Text)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryTxt(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsTxt(FieldNo: Integer; X: Text)
    begin
        CellTxt('r', FieldNo, X);
        CellTxt('f', FieldNo, X);
        CellTxt('v', FieldNo, X);
        CellTxt('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryInt(var F: FieldRef; Method: Text; X: Integer)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellInt(Method: Text; FieldNo: Integer; X: Integer)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryInt(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsInt(FieldNo: Integer; X: Integer)
    begin
        CellInt('r', FieldNo, X);
        CellInt('f', FieldNo, X);
        CellInt('v', FieldNo, X);
        CellInt('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryBig(var F: FieldRef; Method: Text; X: BigInteger)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellBig(Method: Text; FieldNo: Integer; X: BigInteger)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryBig(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsBig(FieldNo: Integer; X: BigInteger)
    begin
        CellBig('r', FieldNo, X);
        CellBig('f', FieldNo, X);
        CellBig('v', FieldNo, X);
        CellBig('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryDec(var F: FieldRef; Method: Text; X: Decimal)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellDec(Method: Text; FieldNo: Integer; X: Decimal)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryDec(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsDec(FieldNo: Integer; X: Decimal)
    begin
        CellDec('r', FieldNo, X);
        CellDec('f', FieldNo, X);
        CellDec('v', FieldNo, X);
        CellDec('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryDate(var F: FieldRef; Method: Text; X: Date)
    begin
        case Method of
            'r':
                F.SetRange(X);
            'f':
                F.SetFilter('%1', X);
            'v':
                F.Value := X;
            'd':
                F.Validate(X);
        end;
    end;

    // One cell: a fresh RecordRef on the row table, the field FieldNo, one method with X.
    procedure CellDate(Method: Text; FieldNo: Integer; X: Date)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryDate(F, Method, X);
        Outcome(F, Method, Ok);
        RecRef.Close();
    end;

    // The four methods for one value on one field, in the order r (SetRange), f (SetFilter('%1')), v (Value :=), d (Validate).
    procedure CellsDate(FieldNo: Integer; X: Date)
    begin
        CellDate('r', FieldNo, X);
        CellDate('f', FieldNo, X);
        CellDate('v', FieldNo, X);
        CellDate('d', FieldNo, X);
    end;

    [TryFunction]
    local procedure TryValidateVariant(var F: FieldRef; V: Variant)
    begin
        F.Validate(V);
    end;

    // Validate with a Variant that holds the value (method dv), next to the typed Validate (d).
    procedure CellValidateVariant(FieldNo: Integer; V: Variant)
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"LT FRC Row");
        F := RecRef.Field(FieldNo);
        Ok := TryValidateVariant(F, V);
        Outcome(F, 'dv', Ok);
        RecRef.Close();
    end;
}

// Boolean false and the Date 2026-01-17 into other field types.
codeunit 73471 "LT FRC Bool Date Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Boolean false into the BigInteger field Big.
    [Test]
    procedure BoolFalse_Big()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(2, X);
        Probe.Finish();
    end;

    // Boolean false into the Integer field Int.
    [Test]
    procedure BoolFalse_Int()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(3, X);
        Probe.Finish();
    end;

    // Boolean false into the Decimal field Dec.
    [Test]
    procedure BoolFalse_Dec()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(4, X);
        Probe.Finish();
    end;

    // Boolean false into the Date field D.
    [Test]
    procedure BoolFalse_D()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(7, X);
        Probe.Finish();
    end;

    // Boolean false into the Option A,B,C field Opt.
    [Test]
    procedure BoolFalse_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(9, X);
        Probe.Finish();
    end;

    // Boolean false into the Guid field G.
    [Test]
    procedure BoolFalse_G()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Boolean;
    begin
        X := false;
        Probe.CellsBool(10, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the BigInteger field Big.
    [Test]
    procedure Date_Big()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(2, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the Integer field Int.
    [Test]
    procedure Date_Int()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(3, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the Decimal field Dec.
    [Test]
    procedure Date_Dec()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(4, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the Boolean field Bool.
    [Test]
    procedure Date_Bool()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(8, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the Option A,B,C field Opt.
    [Test]
    procedure Date_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(9, X);
        Probe.Finish();
    end;

    // Date 2026-01-17 into the Guid field G.
    [Test]
    procedure Date_G()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Date;
    begin
        X := 20260117D;
        Probe.CellsDate(10, X);
        Probe.Finish();
    end;
}

// Integer 5, BigInteger 5 and Decimal 1.5 into other field types.
codeunit 73472 "LT FRC Number Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Integer 5 into the Date field D.
    [Test]
    procedure Int5_D()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Integer;
    begin
        X := 5;
        Probe.CellsInt(7, X);
        Probe.Finish();
    end;

    // Integer 5 into the Boolean field Bool.
    [Test]
    procedure Int5_Bool()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Integer;
    begin
        X := 5;
        Probe.CellsInt(8, X);
        Probe.Finish();
    end;

    // Integer 5 into the Guid field G.
    [Test]
    procedure Int5_G()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Integer;
    begin
        X := 5;
        Probe.CellsInt(10, X);
        Probe.Finish();
    end;

    // BigInteger 5 into the Date field D.
    [Test]
    procedure Big5_D()
    var
        Probe: Codeunit "LT FRC Probe";
        X: BigInteger;
    begin
        X := 5;
        Probe.CellsBig(7, X);
        Probe.Finish();
    end;

    // BigInteger 5 into the Boolean field Bool.
    [Test]
    procedure Big5_Bool()
    var
        Probe: Codeunit "LT FRC Probe";
        X: BigInteger;
    begin
        X := 5;
        Probe.CellsBig(8, X);
        Probe.Finish();
    end;

    // BigInteger 5 into the Guid field G.
    [Test]
    procedure Big5_G()
    var
        Probe: Codeunit "LT FRC Probe";
        X: BigInteger;
    begin
        X := 5;
        Probe.CellsBig(10, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the BigInteger field Big.
    [Test]
    procedure Dec15_Big()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(2, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the Integer field Int.
    [Test]
    procedure Dec15_Int()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(3, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the Boolean field Bool.
    [Test]
    procedure Dec15_Bool()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(8, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the Option A,B,C field Opt.
    [Test]
    procedure Dec15_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(9, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the Date field D.
    [Test]
    procedure Dec15_D()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(7, X);
        Probe.Finish();
    end;

    // Decimal 1.5 into the Guid field G.
    [Test]
    procedure Dec15_G()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Decimal;
    begin
        X := 1.5;
        Probe.CellsDec(10, X);
        Probe.Finish();
    end;
}

// Code 'ABC', Code '123' and Text 'XY' into an Option, a Date and a Guid field.
codeunit 73473 "LT FRC Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Code 'ABC' into the Option A,B,C field Opt.
    [Test]
    procedure CodeABC_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Code[20];
    begin
        X := 'ABC';
        Probe.CellsCode(9, X);
        Probe.Finish();
    end;

    // Code '123' into the Option A,B,C field Opt.
    [Test]
    procedure Code123_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(9, X);
        Probe.Finish();
    end;

    // Text 'XY' into the Option A,B,C field Opt.
    [Test]
    procedure TxtXY_Opt()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Text;
    begin
        X := 'XY';
        Probe.CellsTxt(9, X);
        Probe.Finish();
    end;

    // Code '123' into the Date field D.
    [Test]
    procedure Code123_D()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Code[20];
    begin
        X := '123';
        Probe.CellsCode(7, X);
        Probe.Finish();
    end;

    // Code 'ABC' into the Guid field G by Validate, typed (d) and through a Variant (dv).
    [Test]
    procedure CodeABC_G_Validate()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Code[20];
        V: Variant;
    begin
        X := 'ABC';
        V := X;
        Probe.CellCode('d', 10, X);
        Probe.CellValidateVariant(10, V);
        Probe.Finish();
    end;

    // Code '123' into the Guid field G by Validate, typed (d) and through a Variant (dv).
    [Test]
    procedure Code123_G_Validate()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Code[20];
        V: Variant;
    begin
        X := '123';
        V := X;
        Probe.CellCode('d', 10, X);
        Probe.CellValidateVariant(10, V);
        Probe.Finish();
    end;

    // Text 'XY' into the Guid field G by Validate, typed (d) and through a Variant (dv).
    [Test]
    procedure TxtXY_G_Validate()
    var
        Probe: Codeunit "LT FRC Probe";
        X: Text;
        V: Variant;
    begin
        X := 'XY';
        V := X;
        Probe.CellTxt('d', 10, X);
        Probe.CellValidateVariant(10, V);
        Probe.Finish();
    end;
}
