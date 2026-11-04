// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al662
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 83551, enum 83552, test codeunit 83553
// Corpus issue 672 (odd AL behavior leads, part G):
//   item 38: a BigInteger field used in a property expression for an Integer or Enum field (CalcFormula and TableRelation
//            where(... = field(Big))). The compiler warns (AL0662 for Integer, AL0663 for Enum) and compiles; what happens at run
//            time when the BigInteger is above the Integer range?
//            BC 27.5 and 28.5 refuse the publish (server compiler, AL0204 "Field type Integer is not convertible to field type
//            BigInteger.", corpus CI runs 39233283044 and 39233352699), so those fields and tests are BC29PLUS; the BC 27/28 verdict
//            is pinned by tests/must-not-compile/cases/1540 to 1542 (@max-al 17).
//   item 37: DecimalPlaces beyond 18 (0:20 compiles), and whether DecimalPlaces = 0:2 rounds the stored value or only the display.
// Probe: values asserted below are what the corpus CI tiers (BC 27.5, 28.5, 29.0) produced.
// BC versions: 27, 28, 29

table 83551 "LT BU Conv Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; En; Enum "LT BU Conv Enum") { }
        field(4; FltBig; BigInteger) { FieldClass = FlowFilter; }
#if BC29PLUS
        field(5; CntById; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BU Conv Row" where(Id = field(Big)));
        }
        field(6; CntByEn; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BU Conv Row" where(En = field(Big)));
        }
        field(7; CntByFlt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BU Conv Row" where(Id = field(FltBig)));
        }
        field(8; RelId; Integer)
        {
            TableRelation = "LT BU Conv Row".Id where(Id = field(Big));
        }
#endif
        field(10; D2; Decimal) { DecimalPlaces = 0 : 2; }
        field(11; D18; Decimal) { DecimalPlaces = 0 : 18; }
        field(12; D20; Decimal) { DecimalPlaces = 0 : 20; }
        field(13; D2Fixed; Decimal) { DecimalPlaces = 2 : 2; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 83552 "LT BU Conv Enum"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

codeunit 83553 "LT BU Property Conversions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Row: Record "LT BU Conv Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.En := Row.En::A;
        Row.Insert();
        Row.Id := 2;
        Row.En := Row.En::B;
        Row.Insert();
    end;

#if BC29PLUS
    local procedure CountById(var Observer: Codeunit "Probe Observer"; Name: Text; Big: BigInteger)
    var
        Row: Record "LT BU Conv Row";
    begin
        Row.Big := Big;
        ClearLastError();
        if TryCalc(Row, 5) then
            Observer.Observe(Name, Format(Row.CntById))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure CountByEn(var Observer: Codeunit "Probe Observer"; Name: Text; Big: BigInteger)
    var
        Row: Record "LT BU Conv Row";
    begin
        Row.Big := Big;
        ClearLastError();
        if TryCalc(Row, 6) then
            Observer.Observe(Name, Format(Row.CntByEn))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure CountByFlt(var Observer: Codeunit "Probe Observer"; Name: Text; Big: BigInteger)
    var
        Row: Record "LT BU Conv Row";
    begin
        Row.SetRange(FltBig, Big);
        ClearLastError();
        if TryCalc(Row, 7) then
            Observer.Observe(Name, Format(Row.CntByFlt))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCalc(var Row: Record "LT BU Conv Row"; FieldNo: Integer)
    begin
        case FieldNo of
            5:
                Row.CalcFields(CntById);
            6:
                Row.CalcFields(CntByEn);
            7:
                Row.CalcFields(CntByFlt);
        end;
    end;

    [Test]
    procedure LT_BU_CalcFormula_BigIntegerToInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        CountById(Observer, 'big 2', 2);
        CountById(Observer, 'big 3', 3);
        CountById(Observer, 'big 3000000000', 3000000000L);
        CountById(Observer, 'big 4294967298', 4294967298L);
        CountById(Observer, 'big -4294967295', -4294967295L);
        CountByFlt(Observer, 'flowfilter 2', 2);
        CountByFlt(Observer, 'flowfilter 4294967298', 4294967298L);
        Observer.Expect('big 2', '1');
        Observer.Expect('big 3', '0');
        Observer.Expect('big 3000000000', 'error:Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|ConversionCast');
        Observer.Expect('big 4294967298', 'error:Overflow under conversion of System.Int64 value 4294967298 to System.Int32.|ConversionCast');
        Observer.Expect('big -4294967295', 'error:Overflow under conversion of System.Int64 value -4294967295 to System.Int32.|ConversionCast');
        Observer.Expect('flowfilter 2', '1');
        Observer.Expect('flowfilter 4294967298', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure LT_BU_CalcFormula_BigIntegerToEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        CountByEn(Observer, 'enum 0', 0);
        CountByEn(Observer, 'enum 1', 1);
        CountByEn(Observer, 'enum 5', 5);
        CountByEn(Observer, 'enum 4294967297', 4294967297L);
        CountByEn(Observer, 'enum 3000000000', 3000000000L);
        Observer.Expect('enum 0', 'error:The following fields must have the same type:\\Field: En <-- Big\Table: LT BU Conv Row <-- LT BU Conv Row\Type: Option <-- BigInteger|DB:TypeMisMatch');
        Observer.Expect('enum 1', 'error:The following fields must have the same type:\\Field: En <-- Big\Table: LT BU Conv Row <-- LT BU Conv Row\Type: Option <-- BigInteger|DB:TypeMisMatch');
        Observer.Expect('enum 5', 'error:The following fields must have the same type:\\Field: En <-- Big\Table: LT BU Conv Row <-- LT BU Conv Row\Type: Option <-- BigInteger|DB:TypeMisMatch');
        Observer.Expect('enum 4294967297', 'error:The following fields must have the same type:\\Field: En <-- Big\Table: LT BU Conv Row <-- LT BU Conv Row\Type: Option <-- BigInteger|DB:TypeMisMatch');
        Observer.Expect('enum 3000000000', 'error:The following fields must have the same type:\\Field: En <-- Big\Table: LT BU Conv Row <-- LT BU Conv Row\Type: Option <-- BigInteger|DB:TypeMisMatch');
        Observer.Verify();
    end;

    [Test]
    procedure LT_BU_TableRelation_BigIntegerToInteger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BU Conv Row";
    begin
        Setup();
        Row.Big := 1;
        ClearLastError();
        if TryValidateRel(Row, 1) then
            Observer.Observe('big 1 rel 1', 'ok|' + Format(Row.RelId))
        else
            Observer.Observe('big 1 rel 1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Row.Big := 2;
        ClearLastError();
        if TryValidateRel(Row, 1) then
            Observer.Observe('big 2 rel 1', 'ok|' + Format(Row.RelId))
        else
            Observer.Observe('big 2 rel 1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Row.Big := 4294967297L;
        ClearLastError();
        if TryValidateRel(Row, 1) then
            Observer.Observe('big 4294967297 rel 1', 'ok|' + Format(Row.RelId))
        else
            Observer.Observe('big 4294967297 rel 1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('big 1 rel 1', 'ok|1');
        Observer.Expect('big 2 rel 1', 'error:The field RelId of table LT BU Conv Row contains a value (1) that cannot be found in the related table (LT BU Conv Row).|DB:PrimRecordNotFound');
        Observer.Expect('big 4294967297 rel 1', 'error:Overflow under conversion of System.Int64 value 4294967297 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateRel(var Row: Record "LT BU Conv Row"; Value: Integer)
    begin
        Row.Validate(RelId, Value);
    end;

#endif
    [Test]
    procedure LT_BU_DecimalPlaces_StoredAndShown()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BU Conv Row";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.D2 := 1.23456;
        Row.D2Fixed := 1.23456;
        Row.D18 := 1 / 3;
        Row.D20 := 1 / 3;
        Observer.Observe('d2 assigned xml', Format(Row.D2, 0, 9));
        Observer.Observe('d2 assigned format', Format(Row.D2));
        Observer.Observe('d2 = 1.23456', Format(Row.D2 = 1.23456));
        Observer.Observe('d2fixed format', Format(Row.D2Fixed));
        Observer.Observe('d18 format', Format(Row.D18));
        Observer.Observe('d18 xml', Format(Row.D18, 0, 9));
        Observer.Observe('d20 format', Format(Row.D20));
        Observer.Observe('d20 xml', Format(Row.D20, 0, 9));
        Row.Insert();
        Row.Get(10);
        Observer.Observe('d2 stored = 1.23456', Format(Row.D2 = 1.23456));
        Observer.Observe('d20 stored = 1/3', Format(Row.D20 = 1 / 3));
        Row.Validate(D2, 2.34567);
        Observer.Observe('d2 validated = 2.34567', Format(Row.D2 = 2.34567));
        Row.D2 := 5;
        Observer.Observe('d2 whole format', Format(Row.D2));
        Row.D2Fixed := 5;
        Observer.Observe('d2fixed whole format', Format(Row.D2Fixed));
        Observer.Expect('d2 assigned xml', '1.23');
        Observer.Expect('d2 assigned format', '1.23');
        Observer.Expect('d2 = 1.23456', 'Yes');
        Observer.Expect('d2fixed format', '1.23');
        Observer.Expect('d18 format', '0.333333333333333333');
        Observer.Expect('d18 xml', '0.333333333333333333');
        Observer.Expect('d20 format', '0.333333333333333333');
        Observer.Expect('d20 xml', '0.333333333333333333');
        Observer.Expect('d2 stored = 1.23456', 'Yes');
        Observer.Expect('d20 stored = 1/3', 'Yes');
        Observer.Expect('d2 validated = 2.34567', 'Yes');
        Observer.Expect('d2 whole format', '5');
        Observer.Expect('d2fixed whole format', '5.00');
        Observer.Verify();
    end;
}
