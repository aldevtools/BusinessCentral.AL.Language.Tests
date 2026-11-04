// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72479 "LT P194 Rel Src"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Ref; Code[20]) { }
        field(3; Ref2; Code[20])
        {
            TableRelation = "LT P194 Gen"."Code";
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

tableextension 72480 "LT P194 Rel Src Ext" extends "LT P194 Rel Src"
{
    fields
    {
        modify(Ref)
        {
            TableRelation = "LT P194 Gen"."Code";
        }
    }
}

codeunit 72481 "LT P194 Rel Src Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P194_ModifyRelation_Validate()
    var
        Gen: Record "LT P194 Gen";
        Src: Record "LT P194 Rel Src";
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Src.DeleteAll();
        Gen."Code" := 'G1';
        Gen.Insert();
        Src."Code" := 'S1';
        Src.Insert();
        Src.Validate(Ref, 'G1');
        Observer.Observe('ref_existing', Src.Ref);
        asserterror begin
            Src.Validate(Ref, 'NOPE');
            Error('NoError');
        end;
        Observer.ObserveError('ref_missing');
        Observer.Observe('ref_after_missing', Src.Ref);
        Src.Validate(Ref, '');
        Observer.Observe('ref_blank', Format(Src.Ref = ''));
        asserterror Src.Validate(Ref2, 'G1');
        Observer.ObserveError('af66');
        Observer.Observe('ref2_existing', Src.Ref2);
        asserterror begin
            Src.Validate(Ref2, 'NOPE');
            Error('NoError');
        end;
        Observer.ObserveError('ref2_missing');
        Src.Ref := 'NOPE';
        asserterror Src.Modify();
        Observer.ObserveError('af75');
        Observer.Observe('direct_assign_kept', Src.Ref);
        Observer.Expect('ref_existing', 'G1');
        Observer.Expect('ref_missing|text', 'The field Ref of table LT P194 Rel Src contains a value (NOPE) that cannot be found in the related table (LT P194 Gen).');
        Observer.Expect('ref_missing|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ref_after_missing', 'G1');
        Observer.Expect('ref_blank', 'Yes');
        Observer.Expect('af66|text', 'The field Ref2 of table LT P194 Rel Src contains a value (G1) that cannot be found in the related table (LT P194 Gen).');
        Observer.Expect('af66|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ref2_existing', '');
        Observer.Expect('ref2_missing|text', 'The field Ref2 of table LT P194 Rel Src contains a value (NOPE) that cannot be found in the related table (LT P194 Gen).');
        Observer.Expect('ref2_missing|code', 'DB:PrimRecordNotFound');
        Observer.Expect('af75|text', 'The LT P194 Rel Src does not exist. Identification fields and values: Code=''S1''');
        Observer.Expect('af75|code', 'DB:RecordNotFound');
        Observer.Expect('direct_assign_kept', 'NOPE');
        Observer.Verify();
    end;

    [Test]
    procedure P194_ModifyRelation_FieldRefMeta()
    var
        Src: Record "LT P194 Rel Src";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT P194 Rel Src");
        FldRef := RecRef.Field(2);
        Observer.Observe('ref_relation_table', Format(FldRef.Relation()));
        FldRef := RecRef.Field(3);
        Observer.Observe('ref2_relation_table', Format(FldRef.Relation()));
        Observer.Observe('src_is_used', Format(Src.TableCaption() <> ''));
        Observer.Expect('ref_relation_table', '72463');
        Observer.Expect('ref2_relation_table', '72463');
        Observer.Expect('src_is_used', 'Yes');
        Observer.Verify();
    end;
}
