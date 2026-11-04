// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 79 (TestFilter: CurrentKey() text, SetCurrentKey with no matching key, every change saves the current row and moves to the first match) and 80 (TestFilter: a page left without a row by a filter shows a blank row with a single-valued filter copied onto it, OnValidate)
// Facts: CurrentKey() before and after SetCurrentKey for single, composite, unknown and partial keys; the row, stored rows and log after SetFilter / SetCurrentKey / Ascending with a pending row; the blank row after a filter that matches nothing
// BC versions: 29 (27 and 28 by CI)

codeunit 70183 "LT PnG Test Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'F1';
        Item.Name := 'Cc';
        Item.Qty := 30;
        Item.Insert();
        Item."No." := 'F2';
        Item.Name := 'Aa';
        Item.Qty := 20;
        Item.Insert();
        Item."No." := 'F3';
        Item.Name := 'Bb';
        Item.Qty := 10;
        Item.Insert();
    end;

    [Test]
    procedure CurrentKeyText()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('initial', List.Filter.CurrentKey());
        List.Filter.SetCurrentKey(Qty);
        Observer.Observe('qty', List.Filter.CurrentKey());
        Observer.Observe('qty-first', Format(List.First()));
        Observer.Observe('qty-first-no', List.NoCtl.Value());
        List.Filter.SetCurrentKey(Name, Qty);
        Observer.Observe('name-qty', List.Filter.CurrentKey());
        Observer.Observe('name-qty-first-no', List.NoCtl.Value());
        List.Filter.SetCurrentKey("No.");
        Observer.Observe('no', List.Filter.CurrentKey());
        List.Filter.SetCurrentKey(Name);
        Observer.Observe('name-prefix-of-composite', List.Filter.CurrentKey());
        Observer.Observe('ascending', Format(List.Filter.Ascending()));
        List.Close();
        Observer.Expect('initial', 'No.');
        Observer.Expect('qty', 'Qty');
        Observer.Expect('qty-first', 'Yes');
        Observer.Expect('qty-first-no', 'F3');
        Observer.Expect('name-qty', 'Name,Qty');
        Observer.Expect('name-qty-first-no', 'F2');
        Observer.Expect('no', 'No.');
        Observer.Expect('name-prefix-of-composite', 'Name,Qty');
        Observer.Expect('ascending', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKeyWithoutMatchingKey()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        asserterror begin List.Filter.SetCurrentKey(Amount); Error('LT-NOERROR'); end;
        Observer.ObserveError('amount');
        Observer.Observe('after-amount', List.Filter.CurrentKey());
        asserterror begin List.Filter.SetCurrentKey(Qty, Name); Error('LT-NOERROR'); end;
        Observer.ObserveError('qty-name');
        Observer.Observe('after-qty-name', List.Filter.CurrentKey());
        asserterror begin List.Filter.SetCurrentKey(Flag, Grp); Error('LT-NOERROR'); end;
        Observer.ObserveError('flag-grp');
        asserterror begin List.Filter.SetCurrentKey(Name, Qty, Amount); Error('LT-NOERROR'); end;
        Observer.ObserveError('name-qty-amount');
        Observer.Observe('after-all', List.Filter.CurrentKey());
        List.Close();
        Observer.Expect('amount|text', 'LT-NOERROR');
        Observer.Expect('amount|code', 'Dialog');
        Observer.Expect('after-amount', 'Amount');
        Observer.Expect('qty-name|text', 'LT-NOERROR');
        Observer.Expect('qty-name|code', 'Dialog');
        Observer.Expect('after-qty-name', 'Qty,Name');
        Observer.Expect('flag-grp|text', 'LT-NOERROR');
        Observer.Expect('flag-grp|code', 'Dialog');
        Observer.Expect('name-qty-amount|text', 'LT-NOERROR');
        Observer.Expect('name-qty-amount|code', 'Dialog');
        Observer.Expect('after-all', 'Name,Qty,Amount');
        Observer.Verify();
    end;

    [Test]
    procedure AscendingReversesTheWalk()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        List.Filter.SetCurrentKey(Qty);
        List.Filter.Ascending(false);
        Observer.Observe('ascending-after-false', Format(List.Filter.Ascending()));
        Observer.Observe('first-descending', Format(List.First()));
        Observer.Observe('first-descending-no', List.NoCtl.Value());
        List.Next();
        Observer.Observe('second-descending-no', List.NoCtl.Value());
        List.Filter.Ascending(true);
        Observer.Observe('first-ascending-no', List.NoCtl.Value());
        List.Close();
        Observer.Expect('ascending-after-false', 'No');
        Observer.Expect('first-descending', 'Yes');
        Observer.Expect('first-descending-no', 'F1');
        Observer.Expect('second-descending-no', 'F2');
        Observer.Expect('first-ascending-no', 'F3');
        Observer.Verify();
    end;

    [Test]
    procedure FilterChangeMovesToFirstMatch()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('F3');
        Observer.Observe('before', List.NoCtl.Value());
        Log.Reset();
        List.Filter.SetFilter(Qty, '>=20');
        Observer.Observe('after-filter', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        List.Filter.SetFilter(Qty, '');
        Observer.Observe('after-clear', List.NoCtl.Value());
        List.Filter.SetCurrentKey(Qty);
        Observer.Observe('after-key', List.NoCtl.Value());
        List.GoToKey('F1');
        List.Filter.Ascending(false);
        Observer.Observe('after-descending', List.NoCtl.Value());
        List.Close();
        Observer.Expect('before', 'F3');
        Observer.Expect('after-filter', 'F1');
        Observer.Expect('log', 'List.AGR(F1,Cc);List.AGR(F2,Aa);List.AGR(F1,Cc);List.AGR(F1,Cc);List.AGCR(F1,F3)');
        Observer.Expect('after-clear', 'F1');
        Observer.Expect('after-key', 'F3');
        Observer.Expect('after-descending', 'F1');
        Observer.Verify();
    end;

    [Test]
    procedure FilterChangeSavesThePendingRow()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenEdit();
        List.New();
        List.NoCtl.SetValue('F9');
        List.NameCtl.SetValue('Pending');
        Observer.Observe('stored-before', Format(Item.Get('F9')));
        List.Filter.SetFilter(Qty, '>=20');
        Observer.Observe('stored-after-filter', Format(Item.Get('F9')));
        Observer.Observe('current-after-filter', List.NoCtl.Value());
        List.New();
        List.NoCtl.SetValue('F8');
        List.Filter.SetCurrentKey(Qty);
        Observer.Observe('stored-after-key', Format(Item.Get('F8')));
        List.New();
        List.NoCtl.SetValue('F7');
        List.Filter.Ascending(false);
        Observer.Observe('stored-after-ascending', Format(Item.Get('F7')));
        List.Close();
        Observer.Expect('stored-before', 'Yes');
        Observer.Expect('stored-after-filter', 'Yes');
        Observer.Expect('current-after-filter', 'F1');
        Observer.Expect('stored-after-key', 'Yes');
        Observer.Expect('stored-after-ascending', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FilterMatchingNothingShowsBlankRowSingleValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenEdit();
        Log.Reset();
        List.Filter.SetFilter(Name, 'Zed');
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('no', List.NoCtl.Value());
        Observer.Observe('name', List.NameCtl.Value());
        Observer.Observe('qty', List.QtyCtl.Value());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('filter-text', List.Filter.GetFilter(Name));
        List.Close();
        Observer.Expect('first', 'No');
        Observer.Expect('no', '');
        Observer.Expect('name', '');
        Observer.Expect('qty', '0');
        Observer.Expect('log', 'List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Expect('filter-text', 'Zed');
        Observer.Verify();
    end;

    [Test]
    procedure FilterMatchingNothingOtherShapes()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenEdit();
        Log.Reset();
        List.Filter.SetFilter(Qty, '99');
        Observer.Observe('qty99-first', Format(List.First()));
        Observer.Observe('qty99-qty', List.QtyCtl.Value());
        Observer.Observe('qty99-log', Log.Dump());
        Log.Reset();
        List.Filter.SetFilter(Qty, '90..99');
        Observer.Observe('range-qty', List.QtyCtl.Value());
        Observer.Observe('range-log', Log.Dump());
        Log.Reset();
        List.Filter.SetFilter(Qty, '');
        List.Filter.SetFilter("No.", 'ZZ1');
        Observer.Observe('key-no', List.NoCtl.Value());
        Observer.Observe('key-log', Log.Dump());
        List.Close();
        Observer.Expect('qty99-first', 'No');
        Observer.Expect('qty99-qty', '0');
        Observer.Expect('qty99-log', 'List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Expect('range-qty', '0');
        Observer.Expect('range-log', 'List.OnNewRecord;List.AGCR(,);List.OnNewRecord;List.AGCR(,)');
        Observer.Expect('key-no', 'ZZ1');
        Observer.Expect('key-log', 'List.AGR(F1,Cc);List.AGR(F2,Aa);List.AGR(F3,Bb);List.AGR(F1,Cc);List.AGR(F1,Cc);List.AGCR(F1,F1);List.OnNewRecord;List.AGCR(ZZ1,ZZ1);List.OnNewRecord;List.AGCR(ZZ1,ZZ1)');
        Observer.Verify();
    end;

    [Test]
    procedure FilterMatchingNothingInViewMode()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Name, 'Zed');
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('name', List.NameCtl.Value());
        Observer.Observe('no', List.NoCtl.Value());
        List.Close();
        Observer.Expect('first', 'No');
        Observer.Expect('name', '');
        Observer.Expect('no', '');
        Observer.Verify();
    end;
}
