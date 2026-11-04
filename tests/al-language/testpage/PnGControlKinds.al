// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Controls (70142), LT PnG Cue Card (70143), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 11 (Pages): label is a field-like member (Value/Caption = its caption, not editable); cuegroup fields ignore SetValue; fixed and grid hold controls and are no members; systempart/usercontrol/customaction/fileuploadaction are no TestPage controls (compile-time, not observable at run time)
// Facts: Value, Caption, Editable, Enabled, Visible and SetValue behaviour of a label, of cue group fields and of fields inside a grid and a fixed group
// BC versions: 29 (27 and 28 by CI)

codeunit 70171 "LT PnG Control Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'K1';
        Item.Name := 'Kind One';
        Item.Qty := 4;
        Item.Amount := 2.5;
        Item.Insert();
    end;

    [Test]
    procedure LabelValueAndCaption()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Controls";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('label-value', Card.PlainLabel.Value());
        Observer.Observe('label-caption', Card.PlainLabel.Caption());
        Observer.Observe('label-editable', Format(Card.PlainLabel.Editable()));
        Observer.Observe('label-enabled', Format(Card.PlainLabel.Enabled()));
        Observer.Observe('label-visible', Format(Card.PlainLabel.Visible()));
        Observer.Observe('label-mandatory', Format(Card.PlainLabel.ShowMandatory()));
        Observer.Observe('name-value', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('label-value', 'A label caption');
        Observer.Expect('label-caption', 'A label caption');
        Observer.Expect('label-editable', 'No');
        Observer.Expect('label-enabled', 'Yes');
        Observer.Expect('label-visible', 'Yes');
        Observer.Expect('label-mandatory', 'No');
        Observer.Expect('name-value', 'Kind One');
        Observer.Verify();
    end;

    [Test]
    procedure LabelSetValueAndAssert()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Controls";
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Card.PlainLabel.SetValue('changed'); Error('LT-NOERROR'); end;
        Observer.ObserveError('label-setvalue');
        Observer.Observe('label-value-after-setvalue', Card.PlainLabel.Value());
        asserterror begin Card.PlainLabel.AssertEquals('A label caption'); Error('LT-NOERROR'); end;
        Observer.ObserveError('label-assertequals-caption');
        asserterror begin Card.PlainLabel.AssertEquals('other'); Error('LT-NOERROR'); end;
        Observer.ObserveError('label-assertequals-other');
        Card.Close();
        Observer.Expect('label-setvalue|text', 'LT-NOERROR');
        Observer.Expect('label-setvalue|code', 'Dialog');
        Observer.Expect('label-value-after-setvalue', 'changed');
        Observer.Expect('label-assertequals-caption|text', 'AssertEquals for Field: PlainLabel Expected = ''A label caption'', Actual = ''changed''');
        Observer.Expect('label-assertequals-caption|code', 'TestAssertEquals');
        Observer.Expect('label-assertequals-other|text', 'AssertEquals for Field: PlainLabel Expected = ''other'', Actual = ''changed''');
        Observer.Expect('label-assertequals-other|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure GridAndFixedFieldsAreReachable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Controls";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('grid-qty-value', Card.GridQty.Value());
        Observer.Observe('grid-qty-editable', Format(Card.GridQty.Editable()));
        Observer.Observe('fixed-amount-value', Card.FixedQty.Value());
        Observer.Observe('fixed-amount-editable', Format(Card.FixedQty.Editable()));
        Card.GridQty.SetValue(9);
        Observer.Observe('grid-qty-after-setvalue', Card.GridQty.Value());
        Card.FixedQty.SetValue(7.25);
        Observer.Observe('fixed-amount-after-setvalue', Card.FixedQty.Value());
        Card.Close();
        Observer.Expect('grid-qty-value', '4');
        Observer.Expect('grid-qty-editable', 'Yes');
        Observer.Expect('fixed-amount-value', '2.50');
        Observer.Expect('fixed-amount-editable', 'No');
        Observer.Expect('grid-qty-after-setvalue', '9');
        Observer.Expect('fixed-amount-after-setvalue', '7.25');
        Observer.Verify();
    end;

    [Test]
    procedure CueGroupFieldsAndSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Cues: TestPage "LT PnG Cue Card";
        Log: Codeunit "LT PnG Log";
        Stored: Record "LT PnG Item";
    begin
        Seed();
        Log.Reset();
        Cues.OpenEdit();
        Observer.Observe('cue-qty-value', Cues.CueQty.Value());
        Observer.Observe('cue-amount-value', Cues.CueAmount.Value());
        Observer.Observe('cue-qty-editable', Format(Cues.CueQty.Editable()));
        Observer.Observe('cue-qty-enabled', Format(Cues.CueQty.Enabled()));
        Observer.Observe('cue-qty-visible', Format(Cues.CueQty.Visible()));
        Observer.Observe('plain-name-editable', Format(Cues.PlainName.Editable()));
        Cues.CueQty.SetValue(11);
        Observer.Observe('cue-qty-after-setvalue', Cues.CueQty.Value());
        Cues.PlainName.SetValue('Plain Changed');
        Cues.Close();
        Stored.Get('K1');
        Observer.Observe('stored-qty-after-cue-setvalue', Format(Stored.Qty));
        Observer.Observe('stored-name-after-plain-setvalue', Stored.Name);
        Observer.Observe('log-after', Log.Dump());
        Observer.Expect('cue-qty-value', '4');
        Observer.Expect('cue-amount-value', '2.50');
        Observer.Expect('cue-qty-editable', 'Yes');
        Observer.Expect('cue-qty-enabled', 'Yes');
        Observer.Expect('cue-qty-visible', 'Yes');
        Observer.Expect('plain-name-editable', 'Yes');
        Observer.Expect('cue-qty-after-setvalue', '4');
        Observer.Expect('stored-qty-after-cue-setvalue', '4');
        Observer.Expect('stored-name-after-plain-setvalue', 'Plain Changed');
        Observer.Expect('log-after', 'TblVal(K1,Plain Changed)');
        Observer.Verify();
    end;

    [Test]
    procedure CueFieldAssertEquals()
    var
        Observer: Codeunit "Probe Observer";
        Cues: TestPage "LT PnG Cue Card";
    begin
        Seed();
        Cues.OpenView();
        Cues.CueQty.AssertEquals(4);
        asserterror begin Cues.CueQty.AssertEquals(5); Error('LT-NOERROR'); end;
        Observer.ObserveError('cue-assertequals-wrong');
        asserterror begin Cues.CueQty.SetValue(5); Error('LT-NOERROR'); end;
        Observer.ObserveError('cue-setvalue-in-view-mode');
        Observer.Observe('cue-qty-asinteger', Format(Cues.CueQty.AsInteger()));
        Observer.Observe('cue-amount-asdecimal', Format(Cues.CueAmount.AsDecimal()));
        Cues.Close();
        Observer.Expect('cue-assertequals-wrong|text', 'AssertEquals for Field: CueQty Expected = ''5'', Actual = ''4''');
        Observer.Expect('cue-assertequals-wrong|code', 'TestAssertEquals');
        Observer.Expect('cue-setvalue-in-view-mode|text', 'LT-NOERROR');
        Observer.Expect('cue-setvalue-in-view-mode|code', 'Dialog');
        Observer.Expect('cue-qty-asinteger', '4');
        Observer.Expect('cue-amount-asdecimal', '2.5');
        Observer.Verify();
    end;
}
