// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Card (70134), LT PnG Doc (70137), LT PnG Item (70130), LT PnG Head (70131), LT PnG Line (70132)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 57 (TestPage: the error of a control that is not on the runtime page, its field id) and 69 (TestPart: GetField(Id) answers)
// Facts: error text and code of every member of a Visible = false field and of a field in a Visible = false group; GetField(Id) on a TestPart and its error for ids 0, 1, 2, -1, 100000
// BC versions: 29 (27 and 28 by CI)

codeunit 70174 "LT PnG Hidden Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'H1';
        Item.Name := 'Hidden One';
        Item.Qty := 3;
        Item.Grp := 'GRP';
        Item.Insert();
    end;

    [Test]
    procedure InvisibleFieldMembers()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
        Got: Text;
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Got := Card.HiddenCtl.Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-value');
        asserterror begin Card.HiddenCtl.SetValue('x'); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-setvalue');
        asserterror begin Card.HiddenCtl.AssertEquals('GRP'); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-assertequals');
        asserterror begin Observer.Observe('hidden-visible', Format(Card.HiddenCtl.Visible())); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-visible-call');
        asserterror begin Observer.Observe('hidden-editable', Format(Card.HiddenCtl.Editable())); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-editable-call');
        asserterror begin Observer.Observe('hidden-enabled', Format(Card.HiddenCtl.Enabled())); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-enabled-call');
        asserterror begin Got := Card.HiddenCtl.Caption(); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-caption');
        Card.Close();
        Observer.Expect('hidden-value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-value|code', 'TestFieldNotFound');
        Observer.Expect('hidden-setvalue|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-setvalue|code', 'TestFieldNotFound');
        Observer.Expect('hidden-assertequals|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-assertequals|code', 'TestFieldNotFound');
        Observer.Expect('hidden-visible-call|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-visible-call|code', 'TestFieldNotFound');
        Observer.Expect('hidden-editable-call|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-editable-call|code', 'TestFieldNotFound');
        Observer.Expect('hidden-enabled-call|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-enabled-call|code', 'TestFieldNotFound');
        Observer.Expect('hidden-caption|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('hidden-caption|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure FieldInInvisibleGroup()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
        Got: Text;
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Got := Card.InHiddenGroupCtl.Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('group-field-value');
        asserterror begin Card.InHiddenGroupCtl.SetValue('x'); Error('LT-NOERROR'); end;
        Observer.ObserveError('group-field-setvalue');
        asserterror begin Observer.Observe('group-field-visible', Format(Card.InHiddenGroupCtl.Visible())); Error('LT-NOERROR'); end;
        Observer.ObserveError('group-field-visible-call');
        Card.Close();
        Observer.Expect('group-field-value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('group-field-value|code', 'TestFieldNotFound');
        Observer.Expect('group-field-setvalue|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('group-field-setvalue|code', 'TestFieldNotFound');
        Observer.Expect('group-field-visible-call|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('group-field-visible-call|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure InvisibleFieldInViewAndNewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
        Got: Text;
    begin
        Seed();
        Card.OpenView();
        asserterror begin Got := Card.HiddenCtl.Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('view-hidden-value');
        Card.Close();
        Card.OpenNew();
        asserterror begin Got := Card.HiddenCtl.Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('new-hidden-value');
        Observer.Observe('new-plain-grp-value', Card.PlainGrpCtl.Value());
        Card.Close();
        Observer.Expect('view-hidden-value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('view-hidden-value|code', 'TestFieldNotFound');
        Observer.Expect('new-hidden-value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('new-hidden-value|code', 'TestFieldNotFound');
        Observer.Expect('new-plain-grp-value', '');
        Observer.Verify();
    end;

    [Test]
    procedure PartGetFieldById()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc";
        Head: Record "LT PnG Head";
        Line: Record "LT PnG Line";
        Got: Text;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."Code" := 'D1';
        Head.Insert();
        Line."Head Code" := 'D1';
        Line."Line No." := 10000;
        Line.Descr := 'Line ten';
        Line.Insert();
        Doc.OpenEdit();
        Doc.Lines.First();
        asserterror begin Got := Doc.Lines.GetField(1).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-1');
        asserterror begin Got := Doc.Lines.GetField(2).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-2');
        asserterror begin Got := Doc.Lines.GetField(3).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-3');
        asserterror begin Got := Doc.Lines.GetField(0).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-0');
        asserterror begin Got := Doc.Lines.GetField(-1).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-minus-1');
        asserterror begin Got := Doc.Lines.GetField(100000).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-100000');
        asserterror begin Got := Doc.Lines.GetField(2147483647).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('getfield-maxint');
        Doc.Close();
        Observer.Expect('getfield-1|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-1|code', 'TestFieldNotFound');
        Observer.Expect('getfield-2|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-2|code', 'TestFieldNotFound');
        Observer.Expect('getfield-3|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-3|code', 'TestFieldNotFound');
        Observer.Expect('getfield-0|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-0|code', 'TestFieldNotFound');
        Observer.Expect('getfield-minus-1|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-minus-1|code', 'TestFieldNotFound');
        Observer.Expect('getfield-100000|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-100000|code', 'TestFieldNotFound');
        Observer.Expect('getfield-maxint|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield-maxint|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PageGetFieldById()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
        Got: Text;
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Got := Card.GetField(1).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('page-getfield-1');
        asserterror begin Got := Card.GetField(2).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('page-getfield-2');
        asserterror begin Got := Card.GetField(0).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('page-getfield-0');
        asserterror begin Got := Card.GetField(-5).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('page-getfield-minus-5');
        asserterror begin Got := Card.GetField(100000).Value(); Error('LT-NOERROR'); end;
        Observer.ObserveError('page-getfield-100000');
        Card.Close();
        Observer.Expect('page-getfield-1|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('page-getfield-1|code', 'TestFieldNotFound');
        Observer.Expect('page-getfield-2|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('page-getfield-2|code', 'TestFieldNotFound');
        Observer.Expect('page-getfield-0|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('page-getfield-0|code', 'TestFieldNotFound');
        Observer.Expect('page-getfield-minus-5|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('page-getfield-minus-5|code', 'TestFieldNotFound');
        Observer.Expect('page-getfield-100000|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('page-getfield-100000|code', 'TestFieldNotFound');
        Observer.Verify();
    end;
}
