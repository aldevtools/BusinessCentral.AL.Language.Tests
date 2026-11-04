// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 70116
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: RecordRef: Duplicate is a fully independent ref (its own buffer and filters); a temporary ref
// Facts: RecordRef.Duplicate: filters, position and buffer independent of the source; Duplicate of a temporary and a closed ref
// BC versions: 29 (27 and 28 by CI)

table 70116 "LT PnA Gen"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Amt; Decimal) { }
        field(5; DateF; Date) { }
        field(6; Flag; Boolean) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 70117 "LT PnA RecRef Duplicate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        G: Record "LT PnA Gen";
    begin
        G.DeleteAll();
        Ins('A', 'alpha', 1);
        Ins('B', 'beta', 2);
        Ins('C', 'gamma', 2);
        Ins('D', 'delta', 3);
    end;

    local procedure Ins(C: Code[20]; N: Text[30]; Q: Integer)
    var
        G: Record "LT PnA Gen";
    begin
        G.Code := C;
        G.Name := N;
        G.Qty := Q;
        G.Insert();
    end;

    [Test]
    procedure Duplicate_FiltersAndPositionAreIndependent()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
        Dup: RecordRef;
    begin
        Seed();
        R.Open(Database::"LT PnA Gen");
        R.Field(3).SetRange(2);
        Dup := R.Duplicate();
        Observer.Observe('count-source', Format(R.Count()));
        Observer.Observe('count-duplicate', Format(Dup.Count()));
        Observer.Observe('filters-duplicate', Dup.GetFilters());
        Dup.Field(3).SetRange(3);
        Observer.Observe('count-source-after-dup-filter', Format(R.Count()));
        Observer.Observe('count-duplicate-after-dup-filter', Format(Dup.Count()));
        Observer.Observe('filters-source-after-dup-filter', R.GetFilters());
        R.Field(3).SetRange(1);
        Observer.Observe('count-duplicate-after-source-filter', Format(Dup.Count()));
        R.Reset();
        Observer.Observe('count-source-after-reset', Format(R.Count()));
        Observer.Observe('count-duplicate-after-source-reset', Format(Dup.Count()));
        R.FindFirst();
        Dup.FindFirst();
        Observer.Observe('first-source', Format(R.Field(1).Value));
        Observer.Observe('first-duplicate', Format(Dup.Field(1).Value));
        R.Next();
        Observer.Observe('source-after-next', Format(R.Field(1).Value));
        Observer.Observe('duplicate-after-source-next', Format(Dup.Field(1).Value));
        R.Close();
        Observer.Observe('duplicate-open-after-source-close', Format(Dup.IsEmpty()));
        Observer.Expect('count-source', '2');
        Observer.Expect('count-duplicate', '2');
        Observer.Expect('filters-duplicate', 'Qty: 2');
        Observer.Expect('count-source-after-dup-filter', '2');
        Observer.Expect('count-duplicate-after-dup-filter', '1');
        Observer.Expect('filters-source-after-dup-filter', 'Qty: 2');
        Observer.Expect('count-duplicate-after-source-filter', '1');
        Observer.Expect('count-source-after-reset', '4');
        Observer.Expect('count-duplicate-after-source-reset', '1');
        Observer.Expect('first-source', 'A');
        Observer.Expect('first-duplicate', 'D');
        Observer.Expect('source-after-next', 'B');
        Observer.Expect('duplicate-after-source-next', 'D');
        Observer.Expect('duplicate-open-after-source-close', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_BufferIsIndependent()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
        Dup: RecordRef;
    begin
        Seed();
        R.Open(Database::"LT PnA Gen");
        R.FindFirst();
        Dup := R.Duplicate();
        Observer.Observe('duplicate-current-after-copy', Format(Dup.Field(1).Value));
        R.Field(2).Value := 'changed';
        Observer.Observe('duplicate-name-after-source-edit', Format(Dup.Field(2).Value));
        Dup.Field(2).Value := 'other';
        Observer.Observe('source-name-after-duplicate-edit', Format(R.Field(2).Value));
        R.Modify();
        Observer.Observe('duplicate-name-after-source-modify', Format(Dup.Field(2).Value));
        Dup.Get(R.RecordId);
        Observer.Observe('duplicate-after-get-of-source-id', Format(Dup.Field(2).Value));
        Observer.Observe('same-table-number', Format(R.Number() = Dup.Number()));
        Observer.Observe('same-name', Format(R.Name() = Dup.Name()));
        Observer.Observe('is-temporary-source', Format(R.IsTemporary()));
        Observer.Observe('is-temporary-duplicate', Format(Dup.IsTemporary()));
        Observer.Expect('duplicate-current-after-copy', 'A');
        Observer.Expect('duplicate-name-after-source-edit', 'alpha');
        Observer.Expect('source-name-after-duplicate-edit', 'changed');
        Observer.Expect('duplicate-name-after-source-modify', 'other');
        Observer.Expect('duplicate-after-get-of-source-id', 'changed');
        Observer.Expect('same-table-number', 'Yes');
        Observer.Expect('same-name', 'Yes');
        Observer.Expect('is-temporary-source', 'No');
        Observer.Expect('is-temporary-duplicate', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDup(var Src: RecordRef; var Dst: RecordRef)
    begin
        Dst := Src.Duplicate();
    end;

    [Test]
    procedure Duplicate_TemporaryAndClosed()
    var
        Observer: Codeunit "Probe Observer";
        R: RecordRef;
        Dup: RecordRef;
        T: RecordRef;
        TDup: RecordRef;
        Closed: RecordRef;
        ClosedDup: RecordRef;
    begin
        Seed();
        T.Open(Database::"LT PnA Gen", true);
        T.Field(1).Value := 'T1';
        T.Insert();
        Observer.Observe('temporary-duplicate', Format(TryDup(T, TDup)));
        Observer.ObserveError('temporary-duplicate');
        Observer.Observe('temporary-duplicate-is-temporary', Format(TDup.IsTemporary()));
        Observer.Observe('temporary-duplicate-count', Format(TDup.Count()));
        T.Field(1).Value := 'T2';
        T.Insert();
        Observer.Observe('temporary-duplicate-count-after-insert-in-source', Format(TDup.Count()));
        Observer.Observe('closed-duplicate', Format(TryDup(Closed, ClosedDup)));
        Observer.ObserveError('closed-duplicate');
        Observer.Expect('temporary-duplicate', 'Yes');
        Observer.Expect('temporary-duplicate|text', '');
        Observer.Expect('temporary-duplicate|code', '');
        Observer.Expect('temporary-duplicate-is-temporary', 'Yes');
        Observer.Expect('temporary-duplicate-count', '1');
        Observer.Expect('temporary-duplicate-count-after-insert-in-source', '2');
        Observer.Expect('closed-duplicate', 'No');
        Observer.Expect('closed-duplicate|text', 'The record is not open.');
        Observer.Expect('closed-duplicate|code', 'RecordNotOpened');
        Observer.Verify();
    end;
}
