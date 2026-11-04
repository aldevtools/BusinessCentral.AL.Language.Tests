// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A TableRelation with a blank enum member in its filter: where(Kind = filter(" ")) (assumption blank-enum-in-relation-filter); record/TestCalcFormulaQuotedFilterTests.Codeunit.al:158 pins the same filter in a CalcFormula only.
// BC versions: 29 (27 and 28 by CI)

enum 70827 "LT BERel Kind"
{
    Extensible = true;
    value(0; " ") { }
    value(1; Alpha) { }
    value(2; Beta) { }
}

table 70397 "LT BERel Target"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Kind; Enum "LT BERel Kind") { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 70398 "LT BERel Source"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Blank Ref"; Code[10])
        {
            TableRelation = "LT BERel Target"."Code" where(Kind = filter(" "));
        }
        field(3; "Alpha Ref"; Code[10])
        {
            TableRelation = "LT BERel Target"."Code" where(Kind = filter(Alpha));
        }
        field(4; "Not Blank Ref"; Code[10])
        {
            TableRelation = "LT BERel Target"."Code" where(Kind = filter(<> " "));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70399 "LT BERel Blank Member"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Target: Record "LT BERel Target";
        Source: Record "LT BERel Source";
    begin
        Target.DeleteAll();
        Source.DeleteAll();
        AddTarget('T-BLANK', Target.Kind::" ");
        AddTarget('T-ALPHA', Target.Kind::Alpha);
        AddTarget('T-BETA', Target.Kind::Beta);
    end;

    local procedure AddTarget(C: Code[10]; K: Enum "LT BERel Kind")
    var
        Target: Record "LT BERel Target";
    begin
        Target.Code := C;
        Target.Kind := K;
        Target.Insert();
    end;

    [Test]
    procedure Validate_BlankKindFilter_Result()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT BERel Source";
    begin
        Seed();
        Source.Init();
        Source.Validate("Blank Ref", 'T-BLANK');
        Observer.Observe('blank_ref_blank_row', Source."Blank Ref");
        asserterror Source.Validate("Blank Ref", 'T-ALPHA');
        Observer.ObserveError('blank_ref_alpha_row');
        asserterror Source.Validate("Blank Ref", 'T-BETA');
        Observer.ObserveError('blank_ref_beta_row');
        asserterror Source.Validate("Blank Ref", 'T-NONE');
        Observer.ObserveError('blank_ref_unknown');
        Observer.Expect('blank_ref_blank_row', 'T-BLANK');
        Observer.Expect('blank_ref_alpha_row|text', 'The field Blank Ref of table LT BERel Source contains a value (T-ALPHA) that cannot be found in the related table (LT BERel Target).');
        Observer.Expect('blank_ref_alpha_row|code', 'DB:NothingInsideFilter');
        Observer.Expect('blank_ref_beta_row|text', 'The field Blank Ref of table LT BERel Source contains a value (T-BETA) that cannot be found in the related table (LT BERel Target).');
        Observer.Expect('blank_ref_beta_row|code', 'DB:NothingInsideFilter');
        Observer.Expect('blank_ref_unknown|text', 'The field Blank Ref of table LT BERel Source contains a value (T-NONE) that cannot be found in the related table (LT BERel Target).');
        Observer.Expect('blank_ref_unknown|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;
}
