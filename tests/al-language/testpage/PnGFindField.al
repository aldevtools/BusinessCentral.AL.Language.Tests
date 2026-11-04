// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-findfirstfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Card (70134), LT PnG Tree List (70149), LT PnG Item (70130)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 85 (TestPage: FindFirstField / FindNextField / FindPreviousField leave the cursor on a miss; a Text value matches a Code control) and 86 (TestPage: IsExpanded() / Expand on a page that is not a tree; HideValue / ShowMandatory read the literal property)
// BC versions: 29 (27 and 28 by CI)

codeunit 70186 "LT PnG Find Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to 6 do begin
            Item.Init();
            Item."No." := 'FF' + Format(i);
            Item.Name := 'Name ' + Format(i mod 3);
            Item.Qty := i * 10;
            Item.Amount := i / 2;
            Item.Flag := (i mod 2) = 0;
            Item.Insert();
        end;
    end;

    [Test]
    procedure FindFirstFieldHitsAndMisses()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('FF4');
        Observer.Observe('hit-name-1', Format(List.FindFirstField(List.NameCtl, 'Name 1')));
        Observer.Observe('hit-name-1-at', List.NoCtl.Value());
        List.GoToKey('FF5');
        Observer.Observe('miss', Format(List.FindFirstField(List.NameCtl, 'Name 9')));
        Observer.Observe('miss-at', List.NoCtl.Value());
        Observer.Observe('hit-qty-text', Format(List.FindFirstField(List.QtyCtl, '30')));
        Observer.Observe('hit-qty-text-at', List.NoCtl.Value());
        Observer.Observe('hit-qty-int', Format(List.FindFirstField(List.QtyCtl, 50)));
        Observer.Observe('hit-qty-int-at', List.NoCtl.Value());
        Observer.Observe('hit-flag-bool', Format(List.FindFirstField(List.FlagCtl, true)));
        Observer.Observe('hit-flag-at', List.NoCtl.Value());
        Observer.Observe('hit-amount', Format(List.FindFirstField(List.AmountCtl, 2.5)));
        Observer.Observe('hit-amount-at', List.NoCtl.Value());
        List.Close();
        Observer.Expect('hit-name-1', 'Yes');
        Observer.Expect('hit-name-1-at', 'FF1');
        Observer.Expect('miss', 'No');
        Observer.Expect('miss-at', 'FF5');
        Observer.Expect('hit-qty-text', 'No');
        Observer.Expect('hit-qty-text-at', 'FF5');
        Observer.Expect('hit-qty-int', 'Yes');
        Observer.Expect('hit-qty-int-at', 'FF5');
        Observer.Expect('hit-flag-bool', 'Yes');
        Observer.Expect('hit-flag-at', 'FF2');
        Observer.Expect('hit-amount', 'Yes');
        Observer.Expect('hit-amount-at', 'FF5');
        Observer.Verify();
    end;

    [Test]
    procedure FindFirstFieldTypeAndCaseBoundaries()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('code-control-text-exact', Format(List.FindFirstField(List.NoCtl, 'FF3')));
        Observer.Observe('code-control-text-exact-at', List.NoCtl.Value());
        Observer.Observe('code-control-text-lower', Format(List.FindFirstField(List.NoCtl, 'ff5')));
        Observer.Observe('code-control-lower-at', List.NoCtl.Value());
        Observer.Observe('text-control-lower', Format(List.FindFirstField(List.NameCtl, 'name 2')));
        Observer.Observe('text-control-lower-at', List.NoCtl.Value());
        Observer.Observe('code-control-integer', Format(List.FindFirstField(List.NoCtl, 3)));
        Observer.Observe('code-control-integer-at', List.NoCtl.Value());
        Observer.Observe('integer-control-text-nonnumeric', Format(List.FindFirstField(List.QtyCtl, 'abc')));
        Observer.Observe('integer-control-text-nonnumeric-at', List.NoCtl.Value());
        Observer.Observe('empty-text', Format(List.FindFirstField(List.NameCtl, '')));
        Observer.Observe('empty-text-at', List.NoCtl.Value());
        List.Close();
        Observer.Expect('code-control-text-exact', 'Yes');
        Observer.Expect('code-control-text-exact-at', 'FF3');
        Observer.Expect('code-control-text-lower', 'No');
        Observer.Expect('code-control-lower-at', 'FF3');
        Observer.Expect('text-control-lower', 'No');
        Observer.Expect('text-control-lower-at', 'FF3');
        Observer.Expect('code-control-integer', 'No');
        Observer.Expect('code-control-integer-at', 'FF3');
        Observer.Expect('integer-control-text-nonnumeric', 'No');
        Observer.Expect('integer-control-text-nonnumeric-at', 'FF3');
        Observer.Expect('empty-text', 'No');
        Observer.Expect('empty-text-at', 'FF3');
        Observer.Verify();
    end;

    [Test]
    procedure FindNextAndPreviousField()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('first', Format(List.FindFirstField(List.NameCtl, 'Name 0')));
        Observer.Observe('first-at', List.NoCtl.Value());
        Observer.Observe('next', Format(List.FindNextField(List.NameCtl, 'Name 0')));
        Observer.Observe('next-at', List.NoCtl.Value());
        Observer.Observe('next-miss', Format(List.FindNextField(List.NameCtl, 'Name 0')));
        Observer.Observe('next-miss-at', List.NoCtl.Value());
        Observer.Observe('previous', Format(List.FindPreviousField(List.NameCtl, 'Name 0')));
        Observer.Observe('previous-at', List.NoCtl.Value());
        Observer.Observe('previous-miss', Format(List.FindPreviousField(List.NameCtl, 'Name 0')));
        Observer.Observe('previous-miss-at', List.NoCtl.Value());
        Observer.Observe('next-other-value-miss', Format(List.FindNextField(List.NameCtl, 'Name 7')));
        Observer.Observe('next-other-value-at', List.NoCtl.Value());
        List.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-at', 'FF3');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next-at', 'FF6');
        Observer.Expect('next-miss', 'No');
        Observer.Expect('next-miss-at', 'FF6');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous-at', 'FF3');
        Observer.Expect('previous-miss', 'No');
        Observer.Expect('previous-miss-at', 'FF3');
        Observer.Expect('next-other-value-miss', 'No');
        Observer.Expect('next-other-value-at', 'FF3');
        Observer.Verify();
    end;

    [Test]
    procedure FindFieldOnAnUnpositionedPage()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        List.Last();
        Observer.Observe('next-from-last', Format(List.FindNextField(List.NameCtl, 'Name 1')));
        Observer.Observe('next-from-last-at', List.NoCtl.Value());
        Observer.Observe('previous-from-last', Format(List.FindPreviousField(List.NameCtl, 'Name 1')));
        Observer.Observe('previous-from-last-at', List.NoCtl.Value());
        List.First();
        Observer.Observe('previous-from-first', Format(List.FindPreviousField(List.NameCtl, 'Name 1')));
        Observer.Observe('previous-from-first-at', List.NoCtl.Value());
        List.Close();
        Observer.Expect('next-from-last', 'No');
        Observer.Expect('next-from-last-at', 'FF6');
        Observer.Expect('previous-from-last', 'Yes');
        Observer.Expect('previous-from-last-at', 'FF4');
        Observer.Expect('previous-from-first', 'No');
        Observer.Expect('previous-from-first-at', 'FF1');
        Observer.Verify();
    end;

    [Test]
    procedure IsExpandedAndExpandOnANonTreePage()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG Tree List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('is-expanded', Format(List.IsExpanded()));
        List.Expand(true);
        Observer.Observe('is-expanded-after-expand-true', Format(List.IsExpanded()));
        Observer.Observe('is-expanded-after-expand-false', Format(List.IsExpanded()));
        Observer.Observe('first-after', Format(List.First()));
        Observer.Observe('first-after-no', List.NoCtl.Value());
        List.Close();
        Observer.Expect('is-expanded', 'No');
        Observer.Expect('is-expanded-after-expand-true', 'No');
        Observer.Expect('is-expanded-after-expand-false', 'No');
        Observer.Expect('first-after', 'Yes');
        Observer.Expect('first-after-no', 'FF1');
        Observer.Verify();
    end;

    [Test]
    procedure HideValueAndShowMandatoryLiterals()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('mandatory-ctl-showmandatory', Format(Card.MandatoryCtl.ShowMandatory()));
        Observer.Observe('plain-ctl-showmandatory', Format(Card.PlainGrpCtl.ShowMandatory()));
        Observer.Observe('name-ctl-showmandatory', Format(Card.NameCtl.ShowMandatory()));
        Observer.Observe('hidevalue-ctl-hidevalue', Format(Card.HideValueCtl.HideValue()));
        Observer.Observe('plain-ctl-hidevalue', Format(Card.QtyCtl.HideValue()));
        Observer.Observe('hidevalue-ctl-value', Card.HideValueCtl.Value());
        Observer.Observe('qty-ctl-value', Card.QtyCtl.Value());
        Card.Close();
        Observer.Expect('mandatory-ctl-showmandatory', 'Yes');
        Observer.Expect('plain-ctl-showmandatory', 'Yes');
        Observer.Expect('name-ctl-showmandatory', 'No');
        Observer.Expect('hidevalue-ctl-hidevalue', 'Yes');
        Observer.Expect('plain-ctl-hidevalue', 'No');
        Observer.Expect('hidevalue-ctl-value', '');
        Observer.Expect('qty-ctl-value', '10');
        Observer.Verify();
    end;

    [Test]
    procedure HideValueAndShowMandatoryOnNewRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
    begin
        Card.OpenNew();
        Observer.Observe('new-mandatory-showmandatory', Format(Card.MandatoryCtl.ShowMandatory()));
        Observer.Observe('new-mandatory-value', Card.MandatoryCtl.Value());
        Observer.Observe('new-hidevalue', Format(Card.HideValueCtl.HideValue()));
        Observer.Observe('new-hidevalue-value', Card.HideValueCtl.Value());
        Card.Close();
        Observer.Expect('new-mandatory-showmandatory', 'Yes');
        Observer.Expect('new-mandatory-value', '');
        Observer.Expect('new-hidevalue', 'Yes');
        Observer.Expect('new-hidevalue-value', '');
        Observer.Verify();
    end;
}
