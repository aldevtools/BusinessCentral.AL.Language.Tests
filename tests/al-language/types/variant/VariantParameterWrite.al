// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74561 "LT P167 Var Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74562 "LT P167 Variant Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertThroughValue(V: Variant; Id: Integer)
    var
        R: Record "LT P167 Var Rec";
    begin
        if V.IsRecord() then begin
            R := V;
            R.Id := Id;
            R.Txt := 'in callee';
            R.Insert();
        end;
    end;

    local procedure InsertThroughVar(var V: Variant; Id: Integer)
    var
        R: Record "LT P167 Var Rec";
    begin
        R := V;
        R.Id := Id;
        R.Txt := 'in callee';
        R.Insert();
        V := R;
    end;

    local procedure InsertViaRecordRef(V: Variant; Id: Integer)
    var
        RR: RecordRef;
    begin
        RR.GetTable(V);
        RR.Field(1).Value := Id;
        RR.Field(2).Value := 'via ref';
        RR.Insert();
    end;

    [TryFunction]
    local procedure TryInsertViaRecordRef(V: Variant; Id: Integer)
    begin
        InsertViaRecordRef(V, Id);
    end;

    [Test]
    procedure TempRecord_InsertInCalleeThroughValueVariant()
    var
        Tmp: Record "LT P167 Var Rec" temporary;
        Perm: Record "LT P167 Var Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Perm.DeleteAll();
        InsertThroughValue(Tmp, 1);
        Observer.Observe('caller_temp_count', Format(Tmp.Count()));
        Observer.Observe('permanent_count', Format(Perm.Count()));
        Observer.Expect('caller_temp_count', '0');
        Observer.Expect('permanent_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure PermanentRecord_InsertInCalleeThroughValueVariant()
    var
        Rec: Record "LT P167 Var Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        InsertThroughValue(Rec, 1);
        Observer.Observe('caller_count', Format(Rec.Count()));
        Observer.Expect('caller_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_InsertInCalleeThroughVarVariant()
    var
        Tmp: Record "LT P167 Var Rec" temporary;
        V: Variant;
        Perm: Record "LT P167 Var Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Perm.DeleteAll();
        V := Tmp;
        InsertThroughVar(V, 1);
        Observer.Observe('caller_temp_count', Format(Tmp.Count()));
        Observer.Observe('permanent_count', Format(Perm.Count()));
        Observer.Observe('variant_is_record', Format(V.IsRecord()));
        Observer.Expect('caller_temp_count', '0');
        Observer.Expect('permanent_count', '1');
        Observer.Expect('variant_is_record', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_InsertThroughRecordRefOfVariantParameter()
    var
        Tmp: Record "LT P167 Var Rec" temporary;
        Perm: Record "LT P167 Var Rec";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Perm.DeleteAll();
        Ok := TryInsertViaRecordRef(Tmp, 1);
        Observer.Observe('call_ok', Format(Ok));
        if not Ok then
            Observer.Observe('error_start', CopyStr(GetLastErrorText(), 1, 120));
        Observer.Observe('caller_temp_count', Format(Tmp.Count()));
        Observer.Observe('permanent_count', Format(Perm.Count()));
        Observer.Expect('call_ok', 'Yes');
        Observer.Expect('caller_temp_count', '1');
        Observer.Expect('permanent_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PermanentRecord_AssignedToVariant_CallerSeesLaterInsert()
    var
        Rec: Record "LT P167 Var Rec";
        V: Variant;
        Copy: Record "LT P167 Var Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := Rec;
        Rec.Id := 5;
        Rec.Insert();
        Copy := V;
        Observer.Observe('caller_count', Format(Rec.Count()));
        Observer.Observe('copy_id', Format(Copy.Id));
        Observer.Observe('copy_is_temporary', Format(Copy.IsTemporary()));
        Observer.Expect('caller_count', '1');
        Observer.Expect('copy_id', '0');
        Observer.Expect('copy_is_temporary', 'No');
        Observer.Verify();
    end;
}
