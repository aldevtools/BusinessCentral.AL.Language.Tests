// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 74938 to 74945, codeunit 74946
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Validate of a value against a TableRelation with several where() conditions: the error code and text of a missing value and of a value that the filter excludes, for two key conditions, two non-key conditions, a key and a non-key condition, and three conditions.
// BC versions: 29 (27 and 28 by CI)

table 74938 "LT RM Key Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Code[10]) { }
        field(3; C; Code[10]) { }
    }

    keys { key(PK; A, B, C) { Clustered = true; } }
}

table 74939 "LT RM NonKey Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; N1; Code[10]) { }
        field(3; N2; Code[10]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 74940 "LT RM Mixed Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ItemNo; Code[10]) { }
        field(2; Code; Code[10]) { }
        field(3; Kind; Option) { OptionMembers = Input,Output; }
    }

    keys { key(PK; ItemNo, Code) { Clustered = true; } }
}

table 74941 "LT RM Three Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ItemNo; Code[10]) { }
        field(2; Code; Code[10]) { }
        field(3; Kind; Option) { OptionMembers = Input,Output; }
        field(4; Zone; Code[10]) { }
    }

    keys { key(PK; ItemNo, Code) { Clustered = true; } }
}

table 74942 "LT RM Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; X; Code[10]) { }
        field(3; Y; Code[10]) { }
        field(4; ItemNo; Code[10]) { }
        field(10; TwoKey; Code[10])
        {
            TableRelation = "LT RM Key Rel".C where(A = field(X), B = const('1'));
        }
        field(11; TwoNonKey; Code[10])
        {
            TableRelation = "LT RM NonKey Rel".Code where(N1 = field(X), N2 = const('1'));
        }
        field(12; MixedKeyNonKey; Code[10])
        {
            TableRelation = "LT RM Mixed Rel".Code where(ItemNo = field(ItemNo), Kind = filter(<> Output));
        }
        field(13; ThreeCond; Code[10])
        {
            TableRelation = "LT RM Three Rel".Code where(ItemNo = field(ItemNo), Kind = filter(<> Output), Zone = field(X));
        }
        field(14; ThreeKeyOnly; Code[10])
        {
            TableRelation = "LT RM Key Rel".C where(A = field(X), B = field(Y), C = filter(<> 'ZZ'));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74946 "LT Relation Where Multi"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        K: Record "LT RM Key Rel";
        N: Record "LT RM NonKey Rel";
        M: Record "LT RM Mixed Rel";
        T: Record "LT RM Three Rel";
    begin
        K.DeleteAll();
        N.DeleteAll();
        M.DeleteAll();
        T.DeleteAll();
        K.A := 'X1'; K.B := '1'; K.C := 'C1'; K.Insert();
        K.A := 'X1'; K.B := '2'; K.C := 'C2'; K.Insert();
        K.A := 'X2'; K.B := '1'; K.C := 'C3'; K.Insert();
        K.A := 'X1'; K.B := '1'; K.C := 'ZZ'; K.Insert();
        N.Code := 'N1'; N.N1 := 'X1'; N.N2 := '1'; N.Insert();
        N.Code := 'N2'; N.N1 := 'X1'; N.N2 := '2'; N.Insert();
        N.Code := 'N3'; N.N1 := 'X2'; N.N2 := '1'; N.Insert();
        M.ItemNo := 'I1'; M.Code := 'V1'; M.Kind := M.Kind::Input; M.Insert();
        M.ItemNo := 'I1'; M.Code := 'V2'; M.Kind := M.Kind::Output; M.Insert();
        M.ItemNo := 'I2'; M.Code := 'V3'; M.Kind := M.Kind::Input; M.Insert();
        T.ItemNo := 'I1'; T.Code := 'V1'; T.Kind := T.Kind::Input; T.Zone := 'X1'; T.Insert();
        T.ItemNo := 'I1'; T.Code := 'V2'; T.Kind := T.Kind::Output; T.Zone := 'X1'; T.Insert();
        T.ItemNo := 'I1'; T.Code := 'V3'; T.Kind := T.Kind::Input; T.Zone := 'X2'; T.Insert();
        T.ItemNo := 'I2'; T.Code := 'V4'; T.Kind := T.Kind::Input; T.Zone := 'X1'; T.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var Line: Record "LT RM Line"; FieldNo: Integer; Value: Code[10])
    begin
        case FieldNo of
            10:
                Line.Validate(TwoKey, Value);
            11:
                Line.Validate(TwoNonKey, Value);
            12:
                Line.Validate(MixedKeyNonKey, Value);
            13:
                Line.Validate(ThreeCond, Value);
            14:
                Line.Validate(ThreeKeyOnly, Value);
        end;
    end;

    local procedure Probe(Name: Text; FieldNo: Integer; Value: Code[10]; var Line: Record "LT RM Line"; var Observer: Codeunit "Probe Observer")
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryValidate(Line, FieldNo, Value);
        Observer.Observe(Name, Format(Ok) + '|' + GetLastErrorCode() + '|' + GetLastErrorText());
        ClearLastError();
    end;

    [Test]
    procedure TwoKeyConditions_Validate()
    var
        Line: Record "LT RM Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Line.Id := 1;
        Line.X := 'X1';
        Probe('ok', 10, 'C1', Line, Observer);
        Probe('missing', 10, 'NOPE', Line, Observer);
        Probe('excluded_by_second', 10, 'C2', Line, Observer);
        Probe('excluded_by_first', 10, 'C3', Line, Observer);
        Probe('blank', 10, '', Line, Observer);
        Line.X := 'NOX';
        Probe('no_host_match_existing', 10, 'C1', Line, Observer);
        Probe('no_host_match_missing', 10, 'NOPE', Line, Observer);
        Observer.Expect('ok', 'Yes||');
        Observer.Expect('missing', 'No|DB:RecordNotFound|The field TwoKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('excluded_by_second', 'No|DB:RecordNotFound|The field TwoKey of table LT RM Line contains a value (C2) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('excluded_by_first', 'No|DB:RecordNotFound|The field TwoKey of table LT RM Line contains a value (C3) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('blank', 'Yes||');
        Observer.Expect('no_host_match_existing', 'No|DB:RecordNotFound|The field TwoKey of table LT RM Line contains a value (C1) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('no_host_match_missing', 'No|DB:RecordNotFound|The field TwoKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Verify();
    end;

    [Test]
    procedure TwoNonKeyConditions_Validate()
    var
        Line: Record "LT RM Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Line.Id := 1;
        Line.X := 'X1';
        Probe('ok', 11, 'N1', Line, Observer);
        Probe('missing', 11, 'NOPE', Line, Observer);
        Probe('excluded_by_second', 11, 'N2', Line, Observer);
        Probe('excluded_by_first', 11, 'N3', Line, Observer);
        Probe('blank', 11, '', Line, Observer);
        Line.X := 'NOX';
        Probe('no_host_match_existing', 11, 'N1', Line, Observer);
        Probe('no_host_match_missing', 11, 'NOPE', Line, Observer);
        Observer.Expect('ok', 'Yes||');
        Observer.Expect('missing', 'No|DB:NothingInsideFilter|The field TwoNonKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM NonKey Rel).');
        Observer.Expect('excluded_by_second', 'No|DB:NothingInsideFilter|The field TwoNonKey of table LT RM Line contains a value (N2) that cannot be found in the related table (LT RM NonKey Rel).');
        Observer.Expect('excluded_by_first', 'No|DB:NothingInsideFilter|The field TwoNonKey of table LT RM Line contains a value (N3) that cannot be found in the related table (LT RM NonKey Rel).');
        Observer.Expect('blank', 'Yes||');
        Observer.Expect('no_host_match_existing', 'No|DB:NothingInsideFilter|The field TwoNonKey of table LT RM Line contains a value (N1) that cannot be found in the related table (LT RM NonKey Rel).');
        Observer.Expect('no_host_match_missing', 'No|DB:NothingInsideFilter|The field TwoNonKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM NonKey Rel).');
        Observer.Verify();
    end;

    [Test]
    procedure MixedKeyAndNonKey_Validate()
    var
        Line: Record "LT RM Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Line.Id := 1;
        Line.ItemNo := 'I1';
        Probe('ok', 12, 'V1', Line, Observer);
        Probe('missing', 12, 'NOPE', Line, Observer);
        Probe('excluded_by_nonkey', 12, 'V2', Line, Observer);
        Probe('excluded_by_key', 12, 'V3', Line, Observer);
        Probe('blank', 12, '', Line, Observer);
        Line.ItemNo := 'NOI';
        Probe('no_item_existing', 12, 'V1', Line, Observer);
        Probe('no_item_missing', 12, 'NOPE', Line, Observer);
        Observer.Expect('ok', 'Yes||');
        Observer.Expect('missing', 'No|DB:NothingInsideFilter|The field MixedKeyNonKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Mixed Rel).');
        Observer.Expect('excluded_by_nonkey', 'No|DB:NothingInsideFilter|The field MixedKeyNonKey of table LT RM Line contains a value (V2) that cannot be found in the related table (LT RM Mixed Rel).');
        Observer.Expect('excluded_by_key', 'No|DB:NothingInsideFilter|The field MixedKeyNonKey of table LT RM Line contains a value (V3) that cannot be found in the related table (LT RM Mixed Rel).');
        Observer.Expect('blank', 'Yes||');
        Observer.Expect('no_item_existing', 'No|DB:NothingInsideFilter|The field MixedKeyNonKey of table LT RM Line contains a value (V1) that cannot be found in the related table (LT RM Mixed Rel).');
        Observer.Expect('no_item_missing', 'No|DB:NothingInsideFilter|The field MixedKeyNonKey of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Mixed Rel).');
        Observer.Verify();
    end;

    [Test]
    procedure ThreeConditions_Validate()
    var
        Line: Record "LT RM Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Line.Id := 1;
        Line.ItemNo := 'I1';
        Line.X := 'X1';
        Probe('ok', 13, 'V1', Line, Observer);
        Probe('missing', 13, 'NOPE', Line, Observer);
        Probe('excluded_by_nonkey_kind', 13, 'V2', Line, Observer);
        Probe('excluded_by_nonkey_zone', 13, 'V3', Line, Observer);
        Probe('excluded_by_key_item', 13, 'V4', Line, Observer);
        Probe('blank', 13, '', Line, Observer);
        Observer.Expect('ok', 'Yes||');
        Observer.Expect('missing', 'No|DB:NothingInsideFilter|The field ThreeCond of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Three Rel).');
        Observer.Expect('excluded_by_nonkey_kind', 'No|DB:NothingInsideFilter|The field ThreeCond of table LT RM Line contains a value (V2) that cannot be found in the related table (LT RM Three Rel).');
        Observer.Expect('excluded_by_nonkey_zone', 'No|DB:NothingInsideFilter|The field ThreeCond of table LT RM Line contains a value (V3) that cannot be found in the related table (LT RM Three Rel).');
        Observer.Expect('excluded_by_key_item', 'No|DB:NothingInsideFilter|The field ThreeCond of table LT RM Line contains a value (V4) that cannot be found in the related table (LT RM Three Rel).');
        Observer.Expect('blank', 'Yes||');
        Observer.Verify();
    end;

    [Test]
    procedure ThreeKeyConditions_Validate()
    var
        Line: Record "LT RM Line";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Line.Id := 1;
        Line.X := 'X1';
        Line.Y := '1';
        Probe('ok', 14, 'C1', Line, Observer);
        Probe('missing', 14, 'NOPE', Line, Observer);
        Probe('excluded_by_c_filter', 14, 'ZZ', Line, Observer);
        Probe('excluded_by_b', 14, 'C2', Line, Observer);
        Probe('excluded_by_a', 14, 'C3', Line, Observer);
        Observer.Expect('ok', 'Yes||');
        Observer.Expect('missing', 'No|DB:RecordNotFound|The field ThreeKeyOnly of table LT RM Line contains a value (NOPE) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('excluded_by_c_filter', 'No|DB:RecordNotFound|The field ThreeKeyOnly of table LT RM Line contains a value (ZZ) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('excluded_by_b', 'No|DB:RecordNotFound|The field ThreeKeyOnly of table LT RM Line contains a value (C2) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Expect('excluded_by_a', 'No|DB:RecordNotFound|The field ThreeKeyOnly of table LT RM Line contains a value (C3) that cannot be found in the related table (LT RM Key Rel).');
        Observer.Verify();
    end;

    // ---- Added by writer bs (corpus issue #668, item 78): tables 83155 and 83156 in tableextension/lt-bs-tableext-leads/BsObjects.al ----
    // LT BS NK Source.RefName has TableRelation = "LT BS NK Target".Name, a field in no key of the target. It compiles; what does Validate do?

    [TryFunction]
    local procedure BsTryValidateName(var Src: Record "LT BS NK Source"; Value: Text[30])
    begin
        Src.Validate(RefName, Value);
    end;

    local procedure BsProbeName(Name: Text; Value: Text[30]; var Observer: Codeunit "Probe Observer")
    var
        Src: Record "LT BS NK Source";
        Ok: Boolean;
    begin
        Src.Init();
        Src.Id := 1;
        ClearLastError();
        Ok := BsTryValidateName(Src, Value);
        Observer.Observe(Name, Format(Ok) + '|' + GetLastErrorCode() + '|' + GetLastErrorText() + '|value=' + Src.RefName);
        ClearLastError();
    end;

    [Test]
    procedure RelationToNonKeyField_Validate()
    var
        Target: Record "LT BS NK Target";
        Observer: Codeunit "Probe Observer";
    begin
        Target.DeleteAll();
        Target.Code := 'C1';
        Target.Name := 'Alpha';
        Target.Insert();
        Target.Code := 'C2';
        Target.Name := 'Beta';
        Target.Insert();
        Target.Code := 'C3';
        Target.Name := 'Beta';
        Target.Insert();
        BsProbeName('one_match', 'Alpha', Observer);
        BsProbeName('other_case', 'ALPHA', Observer);
        BsProbeName('two_matches', 'Beta', Observer);
        BsProbeName('no_match', 'Gamma', Observer);
        BsProbeName('key_value_not_name', 'C1', Observer);
        BsProbeName('blank', '', Observer);
        Target.DeleteAll();
        Observer.Expect('one_match', 'Yes|||value=Alpha');
        Observer.Expect('other_case', 'No|DB:NothingInsideFilter|The field RefName of table LT BS NK Source contains a value (ALPHA) that cannot be found in the related table (LT BS NK Target).|value=');
        Observer.Expect('two_matches', 'Yes|||value=Beta');
        Observer.Expect('no_match', 'No|DB:NothingInsideFilter|The field RefName of table LT BS NK Source contains a value (Gamma) that cannot be found in the related table (LT BS NK Target).|value=');
        Observer.Expect('key_value_not_name', 'No|DB:NothingInsideFilter|The field RefName of table LT BS NK Source contains a value (C1) that cannot be found in the related table (LT BS NK Target).|value=');
        Observer.Expect('blank', 'Yes|||value=');
        Observer.Verify();
    end;
}
