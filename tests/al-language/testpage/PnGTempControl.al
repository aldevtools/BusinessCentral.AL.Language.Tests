// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Temp Ctl (70141), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 16 (Pages): a control bound to a field of a page-global temporary record: read, SetValue, whether the field's table OnValidate runs
// Facts: reads and SetValue through controls bound to TempBuf.Name/Qty/Flag/Amount, shared binding of two controls, table OnValidate logging, SetValue errors
// BC versions: 29 (27 and 28 by CI)

codeunit 70172 "LT PnG Temp Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReadsThroughTheControls()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PnG Temp Ctl";
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Pg.OpenEdit();
        Observer.Observe('name-a', Pg.TmpNameA.Value());
        Observer.Observe('name-b', Pg.TmpNameB.Value());
        Observer.Observe('qty', Pg.TmpQty.Value());
        Observer.Observe('flag', Pg.TmpFlag.Value());
        Observer.Observe('amount', Pg.TmpAmount.Value());
        Observer.Observe('name-a-editable', Format(Pg.TmpNameA.Editable()));
        Observer.Observe('name-a-enabled', Format(Pg.TmpNameA.Enabled()));
        Pg.Close();
        Observer.Expect('name-a', 'Start');
        Observer.Expect('name-b', 'Start');
        Observer.Expect('qty', '5');
        Observer.Expect('flag', 'No');
        Observer.Expect('amount', '0.00');
        Observer.Expect('name-a-editable', 'Yes');
        Observer.Expect('name-a-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueThroughTheControls()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PnG Temp Ctl";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Log.Reset();
        Pg.OpenEdit();
        asserterror begin Pg.TmpNameA.SetValue('Changed'); Error('LT-NOERROR'); end;
        Observer.ObserveError('setvalue-name');
        Observer.Observe('name-a-after', Pg.TmpNameA.Value());
        Observer.Observe('name-b-after', Pg.TmpNameB.Value());
        asserterror begin Pg.TmpQty.SetValue(8); Error('LT-NOERROR'); end;
        Observer.ObserveError('setvalue-qty');
        Observer.Observe('qty-after', Pg.TmpQty.Value());
        asserterror begin Pg.TmpFlag.SetValue(true); Error('LT-NOERROR'); end;
        Observer.ObserveError('setvalue-flag');
        Observer.Observe('flag-after', Pg.TmpFlag.Value());
        asserterror begin Pg.TmpAmount.SetValue(1.5); Error('LT-NOERROR'); end;
        Observer.ObserveError('setvalue-amount');
        Observer.Observe('amount-after', Pg.TmpAmount.Value());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('stored-rows', Format(Item.Count()));
        Pg.Close();
        Observer.Expect('setvalue-name|text', 'LT-NOERROR');
        Observer.Expect('setvalue-name|code', 'Dialog');
        Observer.Expect('name-a-after', 'Changed');
        Observer.Expect('name-b-after', 'Changed');
        Observer.Expect('setvalue-qty|text', 'LT-NOERROR');
        Observer.Expect('setvalue-qty|code', 'Dialog');
        Observer.Expect('qty-after', '8');
        Observer.Expect('setvalue-flag|text', 'LT-NOERROR');
        Observer.Expect('setvalue-flag|code', 'Dialog');
        Observer.Expect('flag-after', 'Yes');
        Observer.Expect('setvalue-amount|text', 'LT-NOERROR');
        Observer.Expect('setvalue-amount|code', 'Dialog');
        Observer.Expect('amount-after', '1.50');
        Observer.Expect('log', '');
        Observer.Expect('stored-rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueTooLongAndInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PnG Temp Ctl";
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Pg.OpenEdit();
        asserterror begin Pg.TmpNameA.SetValue(PadStr('', 51, 'x')); Error('LT-NOERROR'); end;
        Observer.ObserveError('name-51-chars');
        asserterror begin Pg.TmpQty.SetValue('abc'); Error('LT-NOERROR'); end;
        Observer.ObserveError('qty-text');
        asserterror begin Pg.TmpFlag.SetValue('maybe'); Error('LT-NOERROR'); end;
        Observer.ObserveError('flag-text');
        asserterror begin Pg.TmpAmount.SetValue('1.2.3'); Error('LT-NOERROR'); end;
        Observer.ObserveError('amount-text');
        Pg.Close();
        Observer.Expect('name-51-chars|text', 'Validation error for Field: TmpNameA,  Message = ''The length of the string is 51, but it must be less than or equal to 50 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx''');
        Observer.Expect('name-51-chars|code', 'TestValidation');
        Observer.Expect('qty-text|text', 'Validation error for Field: TmpQty,  Message = ''Your entry of ''abc'' is not an acceptable value for ''TmpQty''. The value "abc" can''t be evaluated into type Integer.''');
        Observer.Expect('qty-text|code', 'TestValidation');
        Observer.Expect('flag-text|text', 'Validation error for Field: TmpFlag,  Message = ''Your entry of ''maybe'' is not an acceptable value for ''TmpFlag''.''');
        Observer.Expect('flag-text|code', 'TestValidation');
        Observer.Expect('amount-text|text', 'Validation error for Field: TmpAmount,  Message = ''Your entry of ''1.2.3'' is not an acceptable value for ''TmpAmount''. ''1.2.3'' is not a part of a valid decimal expression.''');
        Observer.Expect('amount-text|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure AssertEqualsThroughTheControls()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PnG Temp Ctl";
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Pg.OpenEdit();
        Pg.TmpNameA.AssertEquals('Start');
        asserterror begin Pg.TmpNameA.AssertEquals('Other'); Error('LT-NOERROR'); end;
        Observer.ObserveError('assertequals-name-wrong');
        Pg.TmpQty.AssertEquals(5);
        asserterror begin Pg.TmpQty.AssertEquals(6); Error('LT-NOERROR'); end;
        Observer.ObserveError('assertequals-qty-wrong');
        Observer.Observe('qty-asinteger', Format(Pg.TmpQty.AsInteger()));
        Observer.Observe('flag-asboolean', Format(Pg.TmpFlag.AsBoolean()));
        Pg.Close();
        Observer.Expect('assertequals-name-wrong|text', 'AssertEquals for Field: TmpNameA Expected = ''Other'', Actual = ''Start''');
        Observer.Expect('assertequals-name-wrong|code', 'TestAssertEquals');
        Observer.Expect('assertequals-qty-wrong|text', 'AssertEquals for Field: TmpQty Expected = ''6'', Actual = ''5''');
        Observer.Expect('assertequals-qty-wrong|code', 'TestAssertEquals');
        Observer.Expect('qty-asinteger', '5');
        Observer.Expect('flag-asboolean', 'No');
        Observer.Verify();
    end;
}
