// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), shared table 50001 "ALT Shape 01", self-contained codeunits 96470 and 96471
// Probe: written against the CI run of its pull request on BC 27.5, 28.5 and 29.0 (the Expect lines are generated from what BC did).
// Settles docs/probes-needed.md row: variant-from-variant-temp-record-keeps-rows (al-runner issue 8070)
// Facts: a Variant assigned from another Variant that holds a temporary record (a Variant result, a by-value and a var
//   Variant parameter, a local and a global Variant): the rows visible through it, whether a write through one side shows
//   through the other, whether filters travel, a record that is not temporary, a target Variant that already holds a value.
//   Measured: a copy of a Variant that holds a temporary record keeps the 2 rows, IsTemporary = Yes and a filter (Id: 2); a row inserted
//   through either Variant shows through the other (one table, not a copy); a stored record stays not temporary. Same on 27, 28 and 29.
// BC versions: 27 - 29

codeunit 96470 "LT VFV Source"
{
    procedure BuildTemp(): Variant
    var
        Tmp: Record "ALT Shape 01" temporary;
    begin
        Tmp.Id := 1;
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Insert();
        exit(Tmp);
    end;

    procedure BuildFiltered(): Variant
    var
        Tmp: Record "ALT Shape 01" temporary;
    begin
        Tmp.Id := 1;
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Insert();
        Tmp.SetRange(Id, 2);
        exit(Tmp);
    end;

    procedure BuildStored(): Variant
    var
        Real: Record "ALT Shape 01";
    begin
        Real.DeleteAll();
        Real.Id := 1;
        Real.Insert();
        Real.Id := 2;
        Real.Insert();
        exit(Real);
    end;
}

codeunit 96471 "LT VFV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Source: Codeunit "LT VFV Source";
        GlobalV: Variant;

    local procedure CountOf(V: Variant): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(Format(RecRef.Count()) + ' temp=' + Format(RecRef.IsTemporary()) + ' filters=' + RecRef.GetFilters());
    end;

    local procedure CountThroughTempRecord(V: Variant): Text
    var
        Row: Record "ALT Shape 01" temporary;
    begin
        Row.Copy(V, true);
        exit(Format(Row.Count()));
    end;

    local procedure InsertThrough(V: Variant; NewId: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        RecRef.Field(1).Value := NewId;
        RecRef.Insert();
    end;

    local procedure Seed(var Tmp: Record "ALT Shape 01" temporary)
    begin
        Tmp.Id := 1;
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Insert();
    end;

    // ---- C1: the reporter's shape, a Variant result stored in a local Variant ----
    [Test]
    procedure C1_ResultIntoLocalVariant()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := Source.BuildTemp();
        Observer.Observe('recref', CountOf(V));
        Observer.Observe('copyshared', CountThroughTempRecord(V));
        Observer.Expect('recref', '2 temp=Yes filters=');
        Observer.Expect('copyshared', '2');
        Observer.Verify();
    end;

    // ---- C2: the reporter's shape, a by-value Variant parameter copied to a local Variant ----
    [Test]
    procedure C2_ByValueParameterIntoLocalVariant()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "ALT Shape 01" temporary;
    begin
        Seed(Tmp);
        Observer.Observe('param_copy', CopyByValue(Tmp));
        Observer.Expect('param_copy', '2 temp=Yes filters=|2 temp=Yes filters=');
        Observer.Verify();
    end;

    local procedure CopyByValue(P: Variant): Text
    var
        V: Variant;
    begin
        V := P;
        exit(CountOf(P) + '|' + CountOf(V));
    end;

    // ---- C3: a var Variant parameter copied to a local Variant ----
    [Test]
    procedure C3_VarParameterIntoLocalVariant()
    var
        Observer: Codeunit "Probe Observer";
        W: Variant;
    begin
        W := Source.BuildTemp();
        Observer.Observe('var_copy', CopyByVar(W));
        Observer.Expect('var_copy', '2 temp=Yes filters=');
        Observer.Verify();
    end;

    local procedure CopyByVar(var P: Variant): Text
    var
        V: Variant;
    begin
        V := P;
        exit(CountOf(V));
    end;

    // ---- C4: a local Variant copied to another local Variant ----
    [Test]
    procedure C4_LocalVariantIntoLocalVariant()
    var
        Observer: Codeunit "Probe Observer";
        W: Variant;
        V: Variant;
    begin
        W := Source.BuildTemp();
        V := W;
        Observer.Observe('local_copy', CountOf(V));
        Observer.Observe('local_source', CountOf(W));
        Observer.Expect('local_copy', '2 temp=Yes filters=');
        Observer.Expect('local_source', '2 temp=Yes filters=');
        Observer.Verify();
    end;

    // ---- C5: a Variant result stored in a global Variant ----
    [Test]
    procedure C5_ResultIntoGlobalVariant()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalV := Source.BuildTemp();
        Observer.Observe('global', CountOf(GlobalV));
        Observer.Expect('global', '2 temp=Yes filters=');
        Observer.Verify();
    end;

    // ---- C6: one table or a copy: a row inserted through the new Variant, read through the old one, and back ----
    [Test]
    procedure C6_WriteThroughEitherSide()
    var
        Observer: Codeunit "Probe Observer";
        W: Variant;
        V: Variant;
    begin
        W := Source.BuildTemp();
        V := W;
        InsertThrough(V, 3);
        Observer.Observe('after_insert_via_new_old', CountOf(W));
        Observer.Observe('after_insert_via_new_new', CountOf(V));
        InsertThrough(W, 4);
        Observer.Observe('after_insert_via_old_new', CountOf(V));
        Observer.Expect('after_insert_via_new_old', '3 temp=Yes filters=');
        Observer.Expect('after_insert_via_new_new', '3 temp=Yes filters=');
        Observer.Expect('after_insert_via_old_new', '4 temp=Yes filters=');
        Observer.Verify();
    end;

    // ---- C7: a filtered temporary record: filters kept by the copy ----
    [Test]
    procedure C7_FilteredTemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := Source.BuildFiltered();
        Observer.Observe('filtered', CountOf(V));
        Observer.Expect('filtered', '1 temp=Yes filters=Id: 2');
        Observer.Verify();
    end;

    // ---- C8: a record that is not temporary ----
    [Test]
    procedure C8_StoredRecord()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := Source.BuildStored();
        Observer.Observe('stored', CountOf(V));
        Observer.Expect('stored', '2 temp=No filters=');
        Observer.Verify();
    end;

    // ---- C9: a target Variant that already holds a value ----
    [Test]
    procedure C9_TargetAlreadyHoldsAValue()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        I: Integer;
    begin
        I := 7;
        V := I;
        V := Source.BuildTemp();
        Observer.Observe('reassigned', CountOf(V));
        Observer.Expect('reassigned', '2 temp=Yes filters=');
        Observer.Verify();
    end;
}
