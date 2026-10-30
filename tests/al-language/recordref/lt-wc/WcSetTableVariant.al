// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90642, table 90640
// Probe: written against al-runner issue 6308 (RecordRef.SetTable into a Variant that holds a RecordRef); every value asserted below is what the BC service tier produced.
// Facts: RecordRef.SetTable(V) with a RecordRef in V: the same RecordRef as the receiver, another open RecordRef of the same table, a RecordRef of
//        another table, a RecordRef that is not open, and an empty Variant. Buffer, filters and current row afterwards, and whether the two stay shared.
// BC versions: 27, 28, 29

table 90640 "LT WC Set Doc"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 90641 "LT WC Set Other"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90642 "LT WC Set Table Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Doc: Record "LT WC Set Doc";
        Other: Record "LT WC Set Other";
    begin
        Doc.DeleteAll();
        Other.DeleteAll();
        Doc."No." := 'A';
        Doc.Amount := 1;
        Doc.Insert();
        Doc."No." := 'B';
        Doc.Amount := 2;
        Doc.Insert();
        Doc."No." := 'C';
        Doc.Amount := 3;
        Doc.Insert();
        Other.Id := 7;
        Other.Insert();
    end;

    local procedure Info(var RR: RecordRef): Text
    begin
        if RR.Number() = 0 then
            exit('closed');
        exit(Format(RR.Number()) + '|filters=' + RR.GetFilters() + '|count=' + Format(RR.Count()) + '|current=' + Format(RR.Field(1).Value));
    end;

    local procedure VariantInfo(var V: Variant): Text
    var
        RR: RecordRef;
    begin
        if not V.IsRecordRef() then
            exit('not a RecordRef');
        RR := V;
        exit(Info(RR));
    end;

    [Test]
    procedure WC_SetTable_VariantHoldsSameRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Seed();
        RecRef.Open(Database::"LT WC Set Doc");
        V := RecRef;
        RecRef.FindLast();
        RecRef.SetRecFilter();
        Observer.Observe('receiver before', Info(RecRef));
        Observer.Observe('variant before', VariantInfo(V));
        RecRef.SetTable(V);
        Observer.Observe('variant kind', Format(V.IsRecordRef()) + '|' + Format(V.IsRecord()));
        Observer.Observe('receiver after', Info(RecRef));
        Observer.Observe('variant after', VariantInfo(V));
        RecRef.Reset();
        Observer.Observe('receiver reset', Info(RecRef));
        Observer.Observe('variant after reset', VariantInfo(V));
        RecRef := V;
        Observer.Observe('receiver from variant', Info(RecRef));
        Observer.Finish();
    end;

    [Test]
    procedure WC_SetTable_VariantHoldsOtherRecordRefOfSameTable()
    var
        Observer: Codeunit "Probe Observer";
        Source: RecordRef;
        Target: RecordRef;
        V: Variant;
    begin
        Seed();
        Source.Open(Database::"LT WC Set Doc");
        Source.SetFilter("No.", 'B..C');
        Source.FindFirst();
        Target.Open(Database::"LT WC Set Doc");
        Target.FindFirst();
        V := Target;
        Observer.Observe('source', Info(Source));
        Observer.Observe('target before', Info(Target));
        Source.SetTable(V);
        Observer.Observe('target after', Info(Target));
        Observer.Observe('variant after', VariantInfo(V));
        Source.Next();
        Observer.Observe('source moved', Info(Source));
        Observer.Observe('target after source moved', Info(Target));
        Observer.Observe('variant after source moved', VariantInfo(V));
        Target.Reset();
        Observer.Observe('variant after target reset', VariantInfo(V));
        Observer.Observe('source after target reset', Info(Source));
        Observer.Finish();
    end;

    [Test]
    procedure WC_SetTable_VariantHoldsRecordRefOfOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Source: RecordRef;
        Target: RecordRef;
        V: Variant;
    begin
        Seed();
        Source.Open(Database::"LT WC Set Doc");
        Source.FindFirst();
        Target.Open(Database::"LT WC Set Other");
        Target.FindFirst();
        V := Target;
        asserterror Source.SetTable(V);
        Observer.ObserveError('other table');
        Observer.Observe('variant after', VariantInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure WC_SetTable_VariantHoldsClosedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Source: RecordRef;
        Target: RecordRef;
        V: Variant;
    begin
        Seed();
        Source.Open(Database::"LT WC Set Doc");
        Source.SetFilter("No.", 'B..C');
        Source.FindFirst();
        V := Target;
        Observer.Observe('variant before', VariantInfo(V));
        asserterror Source.SetTable(V);
        Observer.ObserveError('closed target');
        Observer.Observe('variant after', VariantInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure WC_SetTable_EmptyVariant()
    var
        Observer: Codeunit "Probe Observer";
        Source: RecordRef;
        V: Variant;
    begin
        Seed();
        Source.Open(Database::"LT WC Set Doc");
        Source.FindFirst();
        asserterror Source.SetTable(V);
        Observer.ObserveError('empty variant');
        Observer.Observe('kind after', Format(V.IsRecordRef()) + '|' + Format(V.IsRecord()) + '|' + Format(V.IsRecordId()));
        Observer.Finish();
    end;
}
