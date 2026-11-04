// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72032, codeunit 72033
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Temporary record and Variant - Probe wanted: what a Variant holds when a temporary record is assigned or passed
// Facts: rows visible through a Variant holding a temporary record: assigned, passed by value, passed by var, converted back with a record variable, with RecordRef.GetTable, and a non-temporary record for comparison
// BC versions: 29 (27 and 28 by CI)

table 72032 "LT PnD Tmp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72033 "LT PnD Temp Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CountThroughRecRef(V: Variant): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(Format(RecRef.Count()) + ' temp=' + Format(RecRef.IsTemporary()));
    end;

    local procedure CountThroughRecord(V: Variant): Text
    var
        Row: Record "LT PnD Tmp Row";
    begin
        Row := V;
        exit(Format(Row.Count()) + ' temp=' + Format(Row.IsTemporary()));
    end;

    local procedure AddThroughVar(var V: Variant)
    var
        Row: Record "LT PnD Tmp Row" temporary;
    begin
        Row := V;
        Row.Id := 99;
        Row.Insert();
        V := Row;
    end;

    local procedure ValueKind(V: Variant): Text
    begin
        exit('isRecord=' + Format(V.IsRecord) + ' isRecordRef=' + Format(V.IsRecordRef));
    end;

    local procedure Seed(var Tmp: Record "LT PnD Tmp Row" temporary)
    begin
        Tmp.DeleteAll();
        Tmp.Id := 1;
        Tmp.Name := 'a';
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Name := 'b';
        Tmp.Insert();
    end;

    [Test]
    procedure TempRecord_AssignedToVariant_AndRead()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
        Back: Record "LT PnD Tmp Row" temporary;
        V: Variant;
    begin
        Seed(Tmp);
        V := Tmp;
        Observer.Observe('kind', ValueKind(V));
        Observer.Observe('viaRecRef', CountThroughRecRef(V));
        Observer.Observe('viaRecord', CountThroughRecord(V));
        Back := V;
        Observer.Observe('backTemp', Format(Back.IsTemporary()));
        Observer.Observe('backCount', Format(Back.Count()));
        Observer.Observe('sourceCount', Format(Tmp.Count()));
        Observer.Expect('kind', 'isRecord=Yes isRecordRef=No');
        Observer.Expect('viaRecRef', '0 temp=Yes');
        Observer.Expect('viaRecord', '0 temp=No');
        Observer.Expect('backTemp', 'Yes');
        Observer.Expect('backCount', '0');
        Observer.Expect('sourceCount', '2');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_PassedToVariantParameter()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
    begin
        Seed(Tmp);
        Observer.Observe('viaRecRef', CountThroughRecRef(Tmp));
        Observer.Observe('viaRecord', CountThroughRecord(Tmp));
        Observer.Expect('viaRecRef', '2 temp=Yes');
        Observer.Expect('viaRecord', '0 temp=No');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_EmptyPassedToVariantParameter()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
    begin
        Observer.Observe('viaRecRef', CountThroughRecRef(Tmp));
        Observer.Observe('viaRecord', CountThroughRecord(Tmp));
        Observer.Expect('viaRecRef', '0 temp=Yes');
        Observer.Expect('viaRecord', '0 temp=No');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_VariantPassedByVar_ModifiedByCallee()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
        V: Variant;
    begin
        Seed(Tmp);
        V := Tmp;
        AddThroughVar(V);
        Observer.Observe('viaVariant', CountThroughRecord(V));
        Observer.Observe('sourceCount', Format(Tmp.Count()));
        Observer.Expect('viaVariant', '0 temp=No');
        Observer.Expect('sourceCount', '2');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ChangeSourceAfterAssignment()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
        V: Variant;
    begin
        Seed(Tmp);
        V := Tmp;
        Tmp.Id := 3;
        Tmp.Insert();
        Observer.Observe('sourceCount', Format(Tmp.Count()));
        Observer.Observe('variantCount', CountThroughRecord(V));
        Observer.Expect('sourceCount', '3');
        Observer.Expect('variantCount', '0 temp=No');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_FilterTravelsWithTheVariant()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
        Back: Record "LT PnD Tmp Row" temporary;
        V: Variant;
    begin
        Seed(Tmp);
        Tmp.SetRange(Id, 2);
        V := Tmp;
        Back := V;
        Observer.Observe('backFilters', Back.GetFilters());
        Observer.Observe('backCount', Format(Back.Count()));
        Observer.Observe('viaRecRef', CountThroughRecRef(V));
        Observer.Expect('backFilters', '');
        Observer.Expect('backCount', '0');
        Observer.Expect('viaRecRef', '0 temp=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RealRecord_ToVariantForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Real: Record "LT PnD Tmp Row";
        V: Variant;
    begin
        Real.DeleteAll();
        Real.Id := 1;
        Real.Insert();
        Real.Id := 2;
        Real.Insert();
        V := Real;
        Observer.Observe('kind', ValueKind(V));
        Observer.Observe('viaRecRef', CountThroughRecRef(V));
        Observer.Observe('viaRecord', CountThroughRecord(V));
        Observer.Observe('viaParam', CountThroughRecRef(Real));
        Observer.Expect('kind', 'isRecord=Yes isRecordRef=No');
        Observer.Expect('viaRecRef', '2 temp=No');
        Observer.Expect('viaRecord', '2 temp=No');
        Observer.Expect('viaParam', '2 temp=No');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_VariantToTempRecordRef_RowsVisibleToRecRefFind()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT PnD Tmp Row" temporary;
        RecRef: RecordRef;
        V: Variant;
    begin
        Seed(Tmp);
        V := Tmp;
        RecRef.GetTable(V);
        Observer.Observe('findFirst', Format(RecRef.FindFirst()));
        Observer.Observe('isEmpty', Format(RecRef.IsEmpty()));
        Observer.Expect('findFirst', 'No');
        Observer.Expect('isEmpty', 'Yes');
        Observer.Verify();
    end;
}
