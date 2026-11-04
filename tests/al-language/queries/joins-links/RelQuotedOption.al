// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own tables 70774 and 70775, test codeunit 70777 (risky: Option member with a space and the quoted member inside filter())
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation where(F = filter(A | "B C")) with a quoted identifier inside filter(): Validate of a value whose F is each member, outside the filter, unknown and blank; error text start and code via TryFunction
// BC versions: 29 (27 and 28 by CI)

table 70774 "LT P100 Item Op"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; F; Option) { OptionMembers = A,"B C",D; }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 70775 "LT P100 Rel Op"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[10])
        {
            TableRelation = "LT P100 Item Op".Code where(F = filter(A | "B C"));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70777 "LT P100 Rel Quoted Op"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P100 Item Op";
    begin
        Item.DeleteAll();
        Item.Init();
        Item.Code := 'IA';
        Item.F := Item.F::A;
        Item.Insert();
        Item.Init();
        Item.Code := 'IBC';
        Item.F := Item.F::"B C";
        Item.Insert();
        Item.Init();
        Item.Code := 'ID';
        Item.F := Item.F::D;
        Item.Insert();
    end;

    [TryFunction]
    local procedure TryRef(var R: Record "LT P100 Rel Op"; V: Code[10])
    begin
        R.Validate(Ref, V);
    end;

    local procedure Outcome(V: Code[10]): Text
    var
        R: Record "LT P100 Rel Op";
    begin
        R.Init();
        if TryRef(R, V) then
            exit('ok:' + R.Ref);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 90) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P100_Validate_EachKind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('v_ia', Outcome('IA'));
        Observer.Observe('v_ibc', Outcome('IBC'));
        Observer.Observe('v_id', Outcome('ID'));
        Observer.Observe('v_nope', Outcome('NOPE'));
        Observer.Observe('v_blank', Outcome(''));
        Observer.Expect('v_ia', 'ok:IA');
        Observer.Expect('v_ibc', 'ok:IBC');
        Observer.Expect('v_id', 'error:The field Ref of table LT P100 Rel Op contains a value (ID) that cannot be found in the re|DB:NothingInsideFilter');
        Observer.Expect('v_nope', 'error:The field Ref of table LT P100 Rel Op contains a value (NOPE) that cannot be found in the |DB:NothingInsideFilter');
        Observer.Expect('v_blank', 'ok:');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Validate_ErrorAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Rel Op";
    begin
        Seed();
        R.Validate(Ref, 'IA');
        Observer.Observe('e_ia', 'no error');
        R.Validate(Ref, 'IBC');
        Observer.Observe('e_ibc', 'no error');
        asserterror R.Validate(Ref, 'ID');
        Observer.ObserveError('e_id');
        asserterror R.Validate(Ref, 'NOPE');
        Observer.ObserveError('e_nope');
        Observer.Expect('e_ia', 'no error');
        Observer.Expect('e_ibc', 'no error');
        Observer.Expect('e_id|text', 'The field Ref of table LT P100 Rel Op contains a value (ID) that cannot be found in the related table (LT P100 Item Op).');
        Observer.Expect('e_id|code', 'DB:NothingInsideFilter');
        Observer.Expect('e_nope|text', 'The field Ref of table LT P100 Rel Op contains a value (NOPE) that cannot be found in the related table (LT P100 Item Op).');
        Observer.Expect('e_nope|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Assign_Then_Validate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P100 Rel Op";
    begin
        Seed();
        R.Init();
        R.Ref := 'NOPE';
        Observer.Observe('assigned', R.Ref);
        R.Validate(Ref, '');
        Observer.Observe('blank_ok', R.Ref);
        R.Validate(Ref, 'IA');
        Observer.Observe('first_ok', R.Ref);
        asserterror R.Validate(Ref, 'NOPE');
        Observer.ObserveError('then_nope');
        Observer.Observe('kept', R.Ref);
        Observer.Expect('assigned', 'NOPE');
        Observer.Expect('blank_ok', '');
        Observer.Expect('first_ok', 'IA');
        Observer.Expect('then_nope|text', 'The field Ref of table LT P100 Rel Op contains a value (NOPE) that cannot be found in the related table (LT P100 Item Op).');
        Observer.Expect('then_nope|code', 'DB:NothingInsideFilter');
        Observer.Expect('kept', 'IA');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Item_FilterByHand()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P100 Item Op";
    begin
        Seed();
        Observer.Observe('count', Format(Item.Count()));
        Item.SetFilter(F, 'A|B C');
        Observer.Observe('hand_filter_count', Format(Item.Count()));
        Observer.Observe('hand_filter_text', Item.GetFilter(F));
        Observer.Expect('count', '3');
        Observer.Expect('hand_filter_count', '2');
        Observer.Expect('hand_filter_text', 'A|B C');
        Observer.Verify();
    end;
}
