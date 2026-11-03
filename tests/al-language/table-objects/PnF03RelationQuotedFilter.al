// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73938, tables 73857 and 73858, codeunit 73859
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "TableRelation ... where(F = filter(A | "B C"))" (GetLastErrorText flag, SaveValues with page extensions, ... issue 35)
// Facts: Validate of a field whose relation is T where(Kind = filter(A | "B C")) with a row of kind 'B C', of kind 'A', of another kind and with no row
// BC versions: 29 (27 and 28 by CI)

enum 73938 "LT PnF Rel Kind"
{
    Extensible = false;

    value(0; A) { }
    value(1; "B C") { }
    value(2; Z) { }
}

table 73857 "LT PnF Rel Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Kind; Enum "LT PnF Rel Kind") { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73858 "LT PnF Rel Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[20])
        {
            TableRelation = "LT PnF Rel Target"."Code" where(Kind = filter(A | "B C"));
        }
        field(3; RefSingle; Code[20])
        {
            TableRelation = "LT PnF Rel Target"."Code" where(Kind = filter("B C"));
        }
        field(4; RefNot; Code[20])
        {
            TableRelation = "LT PnF Rel Target"."Code" where(Kind = filter(<> "B C"));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73859 "LT PnF Rel Quoted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Src: Record "LT PnF Rel Source"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            2:
                Src.Validate(Ref, Value);
            3:
                Src.Validate(RefSingle, Value);
            4:
                Src.Validate(RefNot, Value);
        end;
    end;

    local procedure Probe(Name: Text; FieldNo: Integer; Value: Code[20]; var Observer: Codeunit "Probe Observer")
    var
        Src: Record "LT PnF Rel Source";
    begin
        if TryValidate(Src, FieldNo, Value) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Seed()
    var
        T: Record "LT PnF Rel Target";
    begin
        T.DeleteAll();
        T.Code := 'R1';
        T.Kind := T.Kind::A;
        T.Insert();
        T.Code := 'R2';
        T.Kind := T.Kind::"B C";
        T.Insert();
        T.Code := 'R3';
        T.Kind := T.Kind::Z;
        T.Insert();
    end;

    [Test]
    procedure Relation_QuotedFilter_Alternatives()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('kind_A', 2, 'R1', Observer);
        Probe('kind_BC', 2, 'R2', Observer);
        Probe('kind_Z', 2, 'R3', Observer);
        Probe('missing', 2, 'NOPE', Observer);
        Probe('blank', 2, '', Observer);
        Observer.Expect('kind_A', 'ok');
        Observer.Expect('kind_BC', 'ok');
        Observer.Expect('kind_Z|text', 'The field Ref of table LT PnF Rel Source contains a value (R3) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('kind_Z|code', 'DB:NothingInsideFilter');
        Observer.Expect('missing|text', 'The field Ref of table LT PnF Rel Source contains a value (NOPE) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('missing|code', 'DB:NothingInsideFilter');
        Observer.Expect('blank', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_QuotedFilter_Single()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('kind_A', 3, 'R1', Observer);
        Probe('kind_BC', 3, 'R2', Observer);
        Probe('kind_Z', 3, 'R3', Observer);
        Probe('missing', 3, 'NOPE', Observer);
        Observer.Expect('kind_A|text', 'The field RefSingle of table LT PnF Rel Source contains a value (R1) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('kind_A|code', 'DB:NothingInsideFilter');
        Observer.Expect('kind_BC', 'ok');
        Observer.Expect('kind_Z|text', 'The field RefSingle of table LT PnF Rel Source contains a value (R3) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('kind_Z|code', 'DB:NothingInsideFilter');
        Observer.Expect('missing|text', 'The field RefSingle of table LT PnF Rel Source contains a value (NOPE) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('missing|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_QuotedFilter_Negated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('kind_A', 4, 'R1', Observer);
        Probe('kind_BC', 4, 'R2', Observer);
        Probe('kind_Z', 4, 'R3', Observer);
        Observer.Expect('kind_A', 'ok');
        Observer.Expect('kind_BC|text', 'The field RefNot of table LT PnF Rel Source contains a value (R2) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('kind_BC|code', 'DB:NothingInsideFilter');
        Observer.Expect('kind_Z', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_QuotedFilter_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnF Rel Target";
    begin
        T.DeleteAll();
        Probe('empty_2', 2, 'R2', Observer);
        Probe('empty_3', 3, 'R2', Observer);
        Probe('empty_4', 4, 'R2', Observer);
        Observer.Expect('empty_2|text', 'The field Ref of table LT PnF Rel Source contains a value (R2) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('empty_2|code', 'DB:NothingInsideFilter');
        Observer.Expect('empty_3|text', 'The field RefSingle of table LT PnF Rel Source contains a value (R2) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('empty_3|code', 'DB:NothingInsideFilter');
        Observer.Expect('empty_4|text', 'The field RefNot of table LT PnF Rel Source contains a value (R2) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('empty_4|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_QuotedFilter_OnlyOtherKind()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnF Rel Target";
    begin
        T.DeleteAll();
        T.Code := 'Z1';
        T.Kind := T.Kind::Z;
        T.Insert();
        Probe('only_Z_2', 2, 'Z1', Observer);
        Probe('only_Z_3', 3, 'Z1', Observer);
        Probe('only_Z_4', 4, 'Z1', Observer);
        Observer.Expect('only_Z_2|text', 'The field Ref of table LT PnF Rel Source contains a value (Z1) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('only_Z_2|code', 'DB:NothingInsideFilter');
        Observer.Expect('only_Z_3|text', 'The field RefSingle of table LT PnF Rel Source contains a value (Z1) that cannot be found in the related table (LT PnF Rel Target).');
        Observer.Expect('only_Z_3|code', 'DB:NothingInsideFilter');
        Observer.Expect('only_Z_4', 'ok');
        Observer.Verify();
    end;
}
