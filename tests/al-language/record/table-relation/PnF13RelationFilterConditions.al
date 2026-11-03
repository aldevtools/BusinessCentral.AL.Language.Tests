// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73890 to 73892, codeunit 73893
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A TableRelation with Field = filter(x) conditions" (Tests-SCM round 2)
// Facts: TableRelation = if (Zone = filter('')) Bin.Code where(Zone = filter('')) else if (Zone = filter(<> '')) Bin.Code where(Zone <> '' ...): Validate of a bin of each zone with the
//   zone blank and filled, FieldRef.Relation for each, and a plain three arm relation with const conditions beside it
// BC versions: 29 (27 and 28 by CI)

table 73890 "LT PnF RF Bin"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Zone; Code[10]) { }
    }

    keys { key(PK; "Code", Zone) { Clustered = true; } }
}

table 73891 "LT PnF RF Zone Bin"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Zone; Code[10]) { }
    }

    keys { key(PK; "Code", Zone) { Clustered = true; } }
}

table 73892 "LT PnF RF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Zone; Code[10]) { }
        field(3; "Bin Code"; Code[20])
        {
            TableRelation = if (Zone = filter('')) "LT PnF RF Bin"."Code" where(Zone = filter(''))
            else
            if (Zone = filter(<> '')) "LT PnF RF Zone Bin"."Code" where(Zone = field(Zone));
        }
        field(4; "Const Bin Code"; Code[20])
        {
            TableRelation = if (Zone = const('')) "LT PnF RF Bin"."Code" where(Zone = const(''))
            else
            if (Zone = const('Z1')) "LT PnF RF Zone Bin"."Code" where(Zone = const('Z1'));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73893 "LT PnF Relation Filter Cond"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Line: Record "LT PnF RF Line"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            3:
                Line.Validate("Bin Code", Value);
            4:
                Line.Validate("Const Bin Code", Value);
        end;
    end;

    local procedure Probe(Name: Text; ZoneValue: Code[10]; FieldNo: Integer; Value: Code[20]; var Observer: Codeunit "Probe Observer")
    var
        Line: Record "LT PnF RF Line";
    begin
        Line.Zone := ZoneValue;
        if TryValidate(Line, FieldNo, Value) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Seed()
    var
        Bin: Record "LT PnF RF Bin";
        ZoneBin: Record "LT PnF RF Zone Bin";
    begin
        Bin.DeleteAll();
        ZoneBin.DeleteAll();
        Bin.Code := 'PLAIN1';
        Bin.Zone := '';
        Bin.Insert();
        Bin.Code := 'INZONE';
        Bin.Zone := 'Z1';
        Bin.Insert();
        ZoneBin.Code := 'ZB1';
        ZoneBin.Zone := 'Z1';
        ZoneBin.Insert();
        ZoneBin.Code := 'ZB2';
        ZoneBin.Zone := 'Z2';
        ZoneBin.Insert();
    end;

    [Test]
    procedure RelationFilter_BlankZone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('blank_plain', '', 3, 'PLAIN1', Observer);
        Probe('blank_inzone_bin', '', 3, 'INZONE', Observer);
        Probe('blank_zone_bin', '', 3, 'ZB1', Observer);
        Probe('blank_missing', '', 3, 'NOPE', Observer);
        Probe('blank_empty_value', '', 3, '', Observer);
        Observer.Expect('blank_plain', 'ok');
        Observer.Expect('blank_inzone_bin|text', 'The field Bin Code of table LT PnF RF Line contains a value (INZONE) that cannot be found in the related table (LT PnF RF Bin).');
        Observer.Expect('blank_inzone_bin|code', 'DB:RecordNotFound');
        Observer.Expect('blank_zone_bin|text', 'The field Bin Code of table LT PnF RF Line contains a value (ZB1) that cannot be found in the related table (LT PnF RF Bin).');
        Observer.Expect('blank_zone_bin|code', 'DB:RecordNotFound');
        Observer.Expect('blank_missing|text', 'The field Bin Code of table LT PnF RF Line contains a value (NOPE) that cannot be found in the related table (LT PnF RF Bin).');
        Observer.Expect('blank_missing|code', 'DB:RecordNotFound');
        Observer.Expect('blank_empty_value', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure RelationFilter_FilledZone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('z1_zonebin', 'Z1', 3, 'ZB1', Observer);
        Probe('z1_other_zone_bin', 'Z1', 3, 'ZB2', Observer);
        Probe('z2_zonebin', 'Z2', 3, 'ZB2', Observer);
        Probe('z1_plain', 'Z1', 3, 'PLAIN1', Observer);
        Probe('z1_missing', 'Z1', 3, 'NOPE', Observer);
        Observer.Expect('z1_zonebin', 'ok');
        Observer.Expect('z1_other_zone_bin|text', 'The field Bin Code of table LT PnF RF Line contains a value (ZB2) that cannot be found in the related table (LT PnF RF Zone Bin).');
        Observer.Expect('z1_other_zone_bin|code', 'DB:RecordNotFound');
        Observer.Expect('z2_zonebin', 'ok');
        Observer.Expect('z1_plain|text', 'The field Bin Code of table LT PnF RF Line contains a value (PLAIN1) that cannot be found in the related table (LT PnF RF Zone Bin).');
        Observer.Expect('z1_plain|code', 'DB:RecordNotFound');
        Observer.Expect('z1_missing|text', 'The field Bin Code of table LT PnF RF Line contains a value (NOPE) that cannot be found in the related table (LT PnF RF Zone Bin).');
        Observer.Expect('z1_missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RelationConst_Arms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('const_blank_plain', '', 4, 'PLAIN1', Observer);
        Probe('const_blank_inzone', '', 4, 'INZONE', Observer);
        Probe('const_z1_zonebin', 'Z1', 4, 'ZB1', Observer);
        Probe('const_z1_plain', 'Z1', 4, 'PLAIN1', Observer);
        Probe('const_z2_zonebin', 'Z2', 4, 'ZB2', Observer);
        Observer.Expect('const_blank_plain', 'ok');
        Observer.Expect('const_blank_inzone|text', 'The field Const Bin Code of table LT PnF RF Line contains a value (INZONE) that cannot be found in the related table (LT PnF RF Bin).');
        Observer.Expect('const_blank_inzone|code', 'DB:RecordNotFound');
        Observer.Expect('const_z1_zonebin', 'ok');
        Observer.Expect('const_z1_plain|text', 'The field Const Bin Code of table LT PnF RF Line contains a value (PLAIN1) that cannot be found in the related table (LT PnF RF Zone Bin).');
        Observer.Expect('const_z1_plain|code', 'DB:RecordNotFound');
        Observer.Expect('const_z2_zonebin', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure RelationFilter_FieldRefRelation()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT PnF RF Line";
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        Seed();
        RecRef.GetTable(Line);
        FRef := RecRef.Field(3);
        Observer.Observe('blank_zone_relation', Format(FRef.Relation()));
        RecRef.Field(2).Value := 'Z1';
        FRef := RecRef.Field(3);
        Observer.Observe('z1_zone_relation', Format(FRef.Relation()));
        RecRef.Field(2).Value := 'Z9';
        FRef := RecRef.Field(3);
        Observer.Observe('z9_zone_relation', Format(FRef.Relation()));
        FRef := RecRef.Field(4);
        Observer.Observe('const_z9_relation', Format(FRef.Relation()));
        RecRef.Field(2).Value := '';
        FRef := RecRef.Field(4);
        Observer.Observe('const_blank_relation', Format(FRef.Relation()));
        Observer.Observe('bin_table_no_equals', Format(FRef.Relation() = Database::"LT PnF RF Bin"));
        Observer.Expect('blank_zone_relation', '73890');
        Observer.Expect('z1_zone_relation', '73891');
        Observer.Expect('z9_zone_relation', '73891');
        Observer.Expect('const_z9_relation', '0');
        Observer.Expect('const_blank_relation', '73890');
        Observer.Expect('bin_table_no_equals', 'Yes');
        Observer.Verify();
    end;
}
