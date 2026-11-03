// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setloadfields-method
// Scope: in-scope
// Fixtures used: table 72200, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.SetLoadFields / AddLoadFields / AreFieldsLoaded and Record.LoadFields (partial records)
// BC versions: 29 (27 and 28 by CI)

codeunit 72218 "LT P92 LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecRef_SetLoadFields_ReadsOnlyThose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.SetLoadFields(2);
        RecRef.Field(1).SetRange('A2');
        Observer.Observe('find', Format(RecRef.FindFirst()));
        Observer.Observe('name_loaded', Format(RecRef.Field(2).Value));
        Observer.Observe('pk_loaded', Format(RecRef.Field(1).Value));
        Observer.Observe('qty', Format(RecRef.Field(3).Value));
        Observer.Observe('amt', Format(RecRef.Field(4).Value));
        RecRef.Close();
        Observer.Expect('find', 'Yes');
        Observer.Expect('name_loaded', 'Beta');
        Observer.Expect('pk_loaded', 'A2');
        Observer.Expect('qty', '20');
        Observer.Expect('amt', '2.5');
        Observer.Verify();
    end;

    [Test]
    procedure RecRef_AreFieldsLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        Observer.Observe('default_all', Format(RecRef.AreFieldsLoaded(1, 2, 3)));
        RecRef.SetLoadFields(2, 3);
        RecRef.FindFirst();
        Observer.Observe('2', Format(RecRef.AreFieldsLoaded(2)));
        Observer.Observe('3', Format(RecRef.AreFieldsLoaded(3)));
        Observer.Observe('2_3', Format(RecRef.AreFieldsLoaded(2, 3)));
        Observer.Observe('4', Format(RecRef.AreFieldsLoaded(4)));
        Observer.Observe('2_4', Format(RecRef.AreFieldsLoaded(2, 4)));
        Observer.Observe('pk', Format(RecRef.AreFieldsLoaded(1)));
        RecRef.AddLoadFields(4);
        RecRef.FindFirst();
        Observer.Observe('4_after_add', Format(RecRef.AreFieldsLoaded(4)));
        Observer.Observe('2_after_add', Format(RecRef.AreFieldsLoaded(2)));
        RecRef.SetLoadFields();
        RecRef.FindFirst();
        Observer.Observe('5_after_clear', Format(RecRef.AreFieldsLoaded(5)));
        RecRef.Close();
        Observer.Expect('default_all', 'No');
        Observer.Expect('2', 'Yes');
        Observer.Expect('3', 'Yes');
        Observer.Expect('2_3', 'Yes');
        Observer.Expect('4', 'No');
        Observer.Expect('2_4', 'No');
        Observer.Expect('pk', 'Yes');
        Observer.Expect('4_after_add', 'Yes');
        Observer.Expect('2_after_add', 'Yes');
        Observer.Expect('5_after_clear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecRef_AddLoadFields_Accumulates()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.AddLoadFields(2);
        RecRef.AddLoadFields(3);
        RecRef.FindFirst();
        Observer.Observe('2', Format(RecRef.AreFieldsLoaded(2)));
        Observer.Observe('3', Format(RecRef.AreFieldsLoaded(3)));
        Observer.Observe('4', Format(RecRef.AreFieldsLoaded(4)));
        RecRef.Close();
        Observer.Expect('2', 'Yes');
        Observer.Expect('3', 'Yes');
        Observer.Expect('4', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecRef_LoadFields_ModifyKeepsUnloaded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.SetLoadFields(2);
        RecRef.Field(1).SetRange('A3');
        RecRef.FindFirst();
        RecRef.Field(2).Value := 'Partial';
        RecRef.Modify();
        RecRef.Close();
        Item.Get('A3');
        Observer.Observe('name', Item.Name);
        Observer.Observe('qty_kept', Format(Item.Qty));
        Observer.Observe('amt_kept', Format(Item.Amt));
        Observer.Expect('name', 'Partial');
        Observer.Expect('qty_kept', '30');
        Observer.Expect('amt_kept', '3.5');
        Observer.Verify();
    end;

    [Test]
    procedure Record_LoadFields_ThenAreFieldsLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.LoadFields(Name, Qty);
        Item.FindFirst();
        Observer.Observe('name', Format(Item.AreFieldsLoaded(Name)));
        Observer.Observe('qty', Format(Item.AreFieldsLoaded(Qty)));
        Observer.Observe('amt', Format(Item.AreFieldsLoaded(Amt)));
        Observer.Observe('name_qty', Format(Item.AreFieldsLoaded(Name, Qty)));
        Observer.Observe('name_amt', Format(Item.AreFieldsLoaded(Name, Amt)));
        Item.SetLoadFields(Amt);
        Item.FindFirst();
        Observer.Observe('amt_after_set', Format(Item.AreFieldsLoaded(Amt)));
        Observer.Observe('name_after_set', Format(Item.AreFieldsLoaded(Name)));
        Observer.Expect('name', 'Yes');
        Observer.Expect('qty', 'Yes');
        Observer.Expect('amt', 'Yes');
        Observer.Expect('name_qty', 'Yes');
        Observer.Expect('name_amt', 'Yes');
        Observer.Expect('amt_after_set', 'Yes');
        Observer.Expect('name_after_set', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_GetTableCarriesToRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        Item: Record "LT P92 Item";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        Item.SetLoadFields(Name);
        RecRef.GetTable(Item);
        RecRef.FindFirst();
        Observer.Observe('name', Format(RecRef.AreFieldsLoaded(2)));
        Observer.Observe('qty', Format(RecRef.AreFieldsLoaded(3)));
        RecRef.Close();
        Observer.Expect('name', 'Yes');
        Observer.Expect('qty', 'No');
        Observer.Verify();
    end;
}
