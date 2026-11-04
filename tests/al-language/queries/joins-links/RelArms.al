// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own tables 70780 to 70783, test codeunit 70784
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: conditional TableRelation arms not covered by types/lt-filter-enum-relation-duration-guid/C_TableRelation.al: arms keyed on an Option (const), arms with filter('A') / filter('B') where a third value matches neither, KindPlace and ZoneArms-style fields, the blank-or-nonblank pair with a different second target, and the error when neither arm applies
// BC versions: 29 (27 and 28 by CI)

table 70780 "LT P100 Loc"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 70781 "LT P100 Bin"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } field(2; Zone; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 70782 "LT P100 Cust"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 70783 "LT P100 Arm"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Zone; Code[10]) { }
        field(3; Kind; Option) { OptionMembers = A,B,C; }
        field(4; Place; Code[10])
        {
            TableRelation = if (Zone = filter('')) "LT P100 Loc".Code
            else if (Zone = filter(<> '')) "LT P100 Bin".Code;
        }
        field(5; KindPlace; Code[10])
        {
            TableRelation = if (Kind = const(A)) "LT P100 Loc".Code
            else if (Kind = const(B)) "LT P100 Bin".Code;
        }
        field(6; ZonePlace; Code[10])
        {
            TableRelation = if (Zone = filter('A|B')) "LT P100 Loc".Code
            else if (Zone = filter('C')) "LT P100 Cust".Code;
        }
        field(7; ThreeArms; Code[10])
        {
            TableRelation = if (Kind = const(A)) "LT P100 Loc".Code
            else if (Kind = const(B)) "LT P100 Bin".Code
            else if (Kind = const(C)) "LT P100 Cust".Code;
        }
        field(8; ArmWhere; Code[10])
        {
            TableRelation = if (Zone = filter('')) "LT P100 Bin".Code where(Zone = const(''))
            else if (Zone = filter(<> '')) "LT P100 Bin".Code where(Zone = field(Zone));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70784 "LT P100 Relation Arms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Loc: Record "LT P100 Loc";
        Bin: Record "LT P100 Bin";
        Cust: Record "LT P100 Cust";
    begin
        Loc.DeleteAll();
        Bin.DeleteAll();
        Cust.DeleteAll();
        Loc.Code := 'LOC1';
        Loc.Insert();
        Bin.Code := 'BIN1';
        Bin.Zone := 'Z1';
        Bin.Insert();
        Bin.Code := 'BIN0';
        Bin.Zone := '';
        Bin.Insert();
        Cust.Code := 'CUST1';
        Cust.Insert();
    end;

    [TryFunction]
    local procedure TryKindPlace(var R: Record "LT P100 Arm"; V: Code[10])
    begin
        R.Validate(KindPlace, V);
    end;

    [TryFunction]
    local procedure TryZonePlace(var R: Record "LT P100 Arm"; V: Code[10])
    begin
        R.Validate(ZonePlace, V);
    end;

    [TryFunction]
    local procedure TryThree(var R: Record "LT P100 Arm"; V: Code[10])
    begin
        R.Validate(ThreeArms, V);
    end;

    [TryFunction]
    local procedure TryArmWhere(var R: Record "LT P100 Arm"; V: Code[10])
    begin
        R.Validate(ArmWhere, V);
    end;

    local procedure Err(): Text
    begin
        exit('error:' + CopyStr(GetLastErrorText(), 1, 100) + '|' + GetLastErrorCode());
    end;

    local procedure KindOutcome(Kind: Integer; V: Code[10]): Text
    var
        R: Record "LT P100 Arm";
    begin
        R.Init();
        R.Kind := Kind;
        if TryKindPlace(R, V) then
            exit('ok:' + R.KindPlace);
        exit(Err());
    end;

    local procedure ZoneOutcome(Zone: Code[10]; V: Code[10]): Text
    var
        R: Record "LT P100 Arm";
    begin
        R.Init();
        R.Zone := Zone;
        if TryZonePlace(R, V) then
            exit('ok:' + R.ZonePlace);
        exit(Err());
    end;

    local procedure ThreeOutcome(Kind: Integer; V: Code[10]): Text
    var
        R: Record "LT P100 Arm";
    begin
        R.Init();
        R.Kind := Kind;
        if TryThree(R, V) then
            exit('ok:' + R.ThreeArms);
        exit(Err());
    end;

    local procedure WhereOutcome(Zone: Code[10]; V: Code[10]): Text
    var
        R: Record "LT P100 Arm";
    begin
        R.Init();
        R.Zone := Zone;
        if TryArmWhere(R, V) then
            exit('ok:' + R.ArmWhere);
        exit(Err());
    end;

    [Test]
    procedure P100_KindArms_A_And_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('a_loc1', KindOutcome(0, 'LOC1'));
        Observer.Observe('a_bin1', KindOutcome(0, 'BIN1'));
        Observer.Observe('a_blank', KindOutcome(0, ''));
        Observer.Observe('b_bin1', KindOutcome(1, 'BIN1'));
        Observer.Observe('b_loc1', KindOutcome(1, 'LOC1'));
        Observer.Observe('b_blank', KindOutcome(1, ''));
        Observer.Observe('b_unknown', KindOutcome(1, 'NOPE'));
        Observer.Expect('a_loc1', 'ok:LOC1');
        Observer.Expect('a_bin1', 'error:The field KindPlace of table LT P100 Arm contains a value (BIN1) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('a_blank', 'ok:');
        Observer.Expect('b_bin1', 'ok:BIN1');
        Observer.Expect('b_loc1', 'error:The field KindPlace of table LT P100 Arm contains a value (LOC1) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('b_blank', 'ok:');
        Observer.Expect('b_unknown', 'error:The field KindPlace of table LT P100 Arm contains a value (NOPE) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P100_KindArms_NeitherApplies()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Arm";
    begin
        Seed();
        Observer.Observe('c_loc1', KindOutcome(2, 'LOC1'));
        Observer.Observe('c_bin1', KindOutcome(2, 'BIN1'));
        Observer.Observe('c_unknown', KindOutcome(2, 'NOPE'));
        Observer.Observe('c_blank', KindOutcome(2, ''));
        R.Init();
        R.Kind := R.Kind::C;
        R.Validate(KindPlace, 'LOC1');
        Observer.Observe('c_asserterror', 'no error');
        R.Kind := R.Kind::C;
        R.KindPlace := 'ANY';
        Observer.Observe('c_plain_assign', R.KindPlace);
        Observer.Expect('c_loc1', 'ok:LOC1');
        Observer.Expect('c_bin1', 'ok:BIN1');
        Observer.Expect('c_unknown', 'ok:NOPE');
        Observer.Expect('c_blank', 'ok:');
        Observer.Expect('c_asserterror', 'no error');
        Observer.Expect('c_plain_assign', 'ANY');
        Observer.Verify();
    end;

    [Test]
    procedure P100_ZoneFilterArms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('za_loc1', ZoneOutcome('A', 'LOC1'));
        Observer.Observe('zb_loc1', ZoneOutcome('B', 'LOC1'));
        Observer.Observe('zc_cust1', ZoneOutcome('C', 'CUST1'));
        Observer.Observe('zc_loc1', ZoneOutcome('C', 'LOC1'));
        Observer.Observe('za_cust1', ZoneOutcome('A', 'CUST1'));
        Observer.Observe('za_unknown', ZoneOutcome('A', 'NOPE'));
        Observer.Observe('zc_unknown', ZoneOutcome('C', 'NOPE'));
        Observer.Expect('za_loc1', 'ok:LOC1');
        Observer.Expect('zb_loc1', 'ok:LOC1');
        Observer.Expect('zc_cust1', 'ok:CUST1');
        Observer.Expect('zc_loc1', 'error:The field ZonePlace of table LT P100 Arm contains a value (LOC1) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('za_cust1', 'error:The field ZonePlace of table LT P100 Arm contains a value (CUST1) that cannot be found in the relate|DB:PrimRecordNotFound');
        Observer.Expect('za_unknown', 'error:The field ZonePlace of table LT P100 Arm contains a value (NOPE) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('zc_unknown', 'error:The field ZonePlace of table LT P100 Arm contains a value (NOPE) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P100_ZoneFilterArms_NeitherApplies()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Arm";
    begin
        Seed();
        Observer.Observe('zd_loc1', ZoneOutcome('D', 'LOC1'));
        Observer.Observe('zd_cust1', ZoneOutcome('D', 'CUST1'));
        Observer.Observe('zd_blank', ZoneOutcome('D', ''));
        Observer.Observe('zblank_loc1', ZoneOutcome('', 'LOC1'));
        Observer.Observe('zblank_blank', ZoneOutcome('', ''));
        Observer.Observe('zlower_loc1', ZoneOutcome('a', 'LOC1'));
        R.Init();
        R.Zone := 'D';
        R.Validate(ZonePlace, 'LOC1');
        Observer.Observe('zd_asserterror', 'no error');
        Observer.Expect('zd_loc1', 'ok:LOC1');
        Observer.Expect('zd_cust1', 'ok:CUST1');
        Observer.Expect('zd_blank', 'ok:');
        Observer.Expect('zblank_loc1', 'ok:LOC1');
        Observer.Expect('zblank_blank', 'ok:');
        Observer.Expect('zlower_loc1', 'ok:LOC1');
        Observer.Expect('zd_asserterror', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P100_ThreeArms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('a_loc1', ThreeOutcome(0, 'LOC1'));
        Observer.Observe('b_bin1', ThreeOutcome(1, 'BIN1'));
        Observer.Observe('c_cust1', ThreeOutcome(2, 'CUST1'));
        Observer.Observe('c_loc1', ThreeOutcome(2, 'LOC1'));
        Observer.Observe('a_cust1', ThreeOutcome(0, 'CUST1'));
        Observer.Observe('b_loc1', ThreeOutcome(1, 'LOC1'));
        Observer.Observe('c_unknown', ThreeOutcome(2, 'NOPE'));
        Observer.Expect('a_loc1', 'ok:LOC1');
        Observer.Expect('b_bin1', 'ok:BIN1');
        Observer.Expect('c_cust1', 'ok:CUST1');
        Observer.Expect('c_loc1', 'error:The field ThreeArms of table LT P100 Arm contains a value (LOC1) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('a_cust1', 'error:The field ThreeArms of table LT P100 Arm contains a value (CUST1) that cannot be found in the relate|DB:PrimRecordNotFound');
        Observer.Expect('b_loc1', 'error:The field ThreeArms of table LT P100 Arm contains a value (LOC1) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Expect('c_unknown', 'error:The field ThreeArms of table LT P100 Arm contains a value (NOPE) that cannot be found in the related|DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P100_ArmsWithOwnWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('blank_bin0', WhereOutcome('', 'BIN0'));
        Observer.Observe('blank_bin1', WhereOutcome('', 'BIN1'));
        Observer.Observe('z1_bin1', WhereOutcome('Z1', 'BIN1'));
        Observer.Observe('z1_bin0', WhereOutcome('Z1', 'BIN0'));
        Observer.Observe('z2_bin1', WhereOutcome('Z2', 'BIN1'));
        Observer.Observe('z1_unknown', WhereOutcome('Z1', 'NOPE'));
        Observer.Observe('blank_blank', WhereOutcome('', ''));
        Observer.Expect('blank_bin0', 'ok:BIN0');
        Observer.Expect('blank_bin1', 'error:The field ArmWhere of table LT P100 Arm contains a value (BIN1) that cannot be found in the related |DB:NothingInsideFilter');
        Observer.Expect('z1_bin1', 'ok:BIN1');
        Observer.Expect('z1_bin0', 'error:The field ArmWhere of table LT P100 Arm contains a value (BIN0) that cannot be found in the related |DB:NothingInsideFilter');
        Observer.Expect('z2_bin1', 'error:The field ArmWhere of table LT P100 Arm contains a value (BIN1) that cannot be found in the related |DB:NothingInsideFilter');
        Observer.Expect('z1_unknown', 'error:The field ArmWhere of table LT P100 Arm contains a value (NOPE) that cannot be found in the related |DB:NothingInsideFilter');
        Observer.Expect('blank_blank', 'ok:');
        Observer.Verify();
    end;
}
