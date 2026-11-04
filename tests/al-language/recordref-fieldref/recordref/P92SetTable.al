// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.SetTable into the same and a different table, filters and temporary state carried over, GetTable
// BC versions: 29 (27 and 28 by CI)

codeunit 72213 "LT P92 SetTable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetTableItem(var RecRef: RecordRef; var Item: Record "LT P92 Item")
    begin
        RecRef.SetTable(Item);
    end;

    [TryFunction]
    local procedure TrySetTablePair(var RecRef: RecordRef; var Pair: Record "LT P92 Pair")
    begin
        RecRef.SetTable(Pair);
    end;

    [Test]
    procedure SetTable_SameTable_CarriesRowAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(3).SetFilter('>=%1', 20);
        RecRef.FindFirst();
        RecRef.SetTable(Item);
        Observer.Observe('code', Item.Code);
        Observer.Observe('name', Item.Name);
        Observer.Observe('qty', Format(Item.Qty));
        Observer.Observe('hasfilter', Format(Item.HasFilter()));
        Observer.Observe('count_filtered', Format(Item.Count()));
        Observer.Observe('filter_qty', Item.GetFilter(Qty));
        Observer.Observe('istemp', Format(Item.IsTemporary()));
        RecRef.Close();
        Observer.Expect('code', 'A2');
        Observer.Expect('name', 'Beta');
        Observer.Expect('qty', '20');
        Observer.Expect('hasfilter', 'Yes');
        Observer.Expect('count_filtered', '2');
        Observer.Expect('filter_qty', '>=20');
        Observer.Expect('istemp', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_ReplacesPreviousRecordState()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.SetRange(Code, 'B1');
        Item.Code := 'ZZZ';
        Item.Name := 'stale';
        RecRef.Open(72200);
        RecRef.FindFirst();
        RecRef.SetTable(Item);
        Observer.Observe('code', Item.Code);
        Observer.Observe('name', Item.Name);
        Observer.Observe('old_filter_kept', Format(Item.HasFilter()));
        Observer.Observe('old_filter_text', Item.GetFilter(Code));
        RecRef.Close();
        Observer.Expect('code', 'A1');
        Observer.Expect('name', 'Alpha');
        Observer.Expect('old_filter_kept', 'No');
        Observer.Expect('old_filter_text', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_Unopened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        asserterror RecRef.SetTable(Item);
        Observer.ObserveError('unopened');
        RecRef.Open(72200);
        RecRef.Close();
        asserterror RecRef.SetTable(Item);
        Observer.ObserveError('closed');
        Observer.Expect('unopened|text', 'The record is not open.');
        Observer.Expect('unopened|code', 'RecordNotOpened');
        Observer.Expect('closed|text', 'The record is not open.');
        Observer.Expect('closed|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure SetTable_TemporaryVariants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Real: Record "LT P92 Item";
        TempRec: Record "LT P92 Item" temporary;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.FindFirst();
        RecRef.SetTable(TempRec);
        Observer.Observe('real_into_temp_istemp', Format(TempRec.IsTemporary()));
        Observer.Observe('real_into_temp_code', TempRec.Code);
        Observer.Observe('real_into_temp_count', Format(TempRec.Count()));
        RecRef.Close();
        RecRef.Open(72200, true);
        RecRef.Field(1).Value := 'TT';
        RecRef.Insert();
        RecRef.SetTable(Real);
        Observer.Observe('temp_into_real_istemp', Format(Real.IsTemporary()));
        Observer.Observe('temp_into_real_code', Real.Code);
        Observer.Observe('temp_into_real_count', Format(Real.Count()));
        RecRef.Close();
        Observer.Expect('real_into_temp_istemp', 'Yes');
        Observer.Expect('real_into_temp_code', 'A1');
        Observer.Expect('real_into_temp_count', '0');
        Observer.Expect('temp_into_real_istemp', 'No');
        Observer.Expect('temp_into_real_code', 'TT');
        Observer.Expect('temp_into_real_count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_SetTable_RoundTripWrites()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
        Check: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.Get('A1');
        RecRef.GetTable(Item);
        RecRef.Field(2).Value := 'ViaRef';
        Observer.Observe('item_before_settable', Item.Name);
        RecRef.SetTable(Item);
        Observer.Observe('item_after_settable', Item.Name);
        Item.Modify();
        Check.Get('A1');
        Observer.Observe('stored', Check.Name);
        RecRef.GetTable(Item);
        Observer.Observe('recref_number', Format(RecRef.Number()));
        RecRef.Close();
        Observer.Expect('item_before_settable', 'Alpha');
        Observer.Expect('item_after_settable', 'ViaRef');
        Observer.Expect('stored', 'ViaRef');
        Observer.Expect('recref_number', '72200');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_SecondCallSwitchesTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
        Pair: Record "LT P92 Pair";
    begin
        Helper.SeedItems();
        Helper.SeedPairs();
        Item.FindFirst();
        Pair.FindFirst();
        RecRef.GetTable(Item);
        Observer.Observe('first_name', RecRef.Name());
        RecRef.GetTable(Pair);
        Observer.Observe('second_name', RecRef.Name());
        Observer.Observe('second_pos', RecRef.GetPosition());
        Item.SetRange(Code, 'A2');
        RecRef.GetTable(Item);
        Observer.Observe('filter_carried', Format(RecRef.HasFilter()));
        Observer.Observe('filter_count', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Expect('first_name', 'LT P92 Item');
        Observer.Expect('second_name', 'LT P92 Pair');
        Observer.Expect('second_pos', 'Grp=CONST(A,B),Seq=CONST(3)');
        Observer.Expect('filter_carried', 'Yes');
        Observer.Expect('filter_count', '1');
        Observer.Verify();
    end;
}
