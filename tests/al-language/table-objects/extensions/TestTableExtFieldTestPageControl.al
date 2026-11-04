// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-first-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Universal Validated Ext (60025) —
//   ALTUniversalValidated.TableExt.al, adding "Ext Validated" (60250) with its own
//   OnValidate — and ALT Universal Ext Card Page (60018), a page fixture whose ONLY field
//   control besides the primary key is bound to that extension field.
//
// CLAIM: a TestPage field control bound to a field a tableextension adds to the page's
// source table reads and writes through exactly like a control bound to the table's own
// field — the write is a Validate, not a raw assignment, so it runs the extension field's
// OnValidate trigger. Distinct from TestTableExtFieldValidate (which proves Rec.Validate
// runs the trigger; this proves a PAGE control does too) and from TestTableExtCrossApp
// (which proves plain Insert/Get/SetRange on a cross-app extension field; this is a
// same-app extension exercised through a TestPage, not Rec directly).

codeunit 60022 "TableExt Field TestPage Ctl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TestPageControl_BoundToExtField_Get_ReturnsRecValue()
    var
        Universal: Record "ALT Universal";
        CardPage: TestPage "ALT Universal Ext Card Page";
    begin
        Initialize();
        Universal."Entry No." := 401;
        Universal."Ext Validated" := 'Seeded';
        Universal.Insert(false);

        CardPage.OpenEdit();
        CardPage.GoToRecord(Universal);
        Assert.AreEqual('Seeded', CardPage."Ext Validated".Value(), 'a control bound to a tableextension field must read the field''s current value');
        CardPage.Close();
    end;

    [Test]
    procedure TestPageControl_BoundToExtField_SetValue_WritesThroughAndRunsOnValidate()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
        CardPage: TestPage "ALT Universal Ext Card Page";
    begin
        Initialize();
        Universal."Entry No." := 402;
        Universal.Insert(false);

        CardPage.OpenEdit();
        CardPage.GoToRecord(Universal);
        CardPage."Ext Validated".SetValue('Via Page');
        CardPage.Close();

        Universal.Get(402);
        Assert.AreEqual('Via Page', Universal."Ext Validated", 'SetValue on a tableextension field control must persist through Rec');

        TrigLog.SetRange(TriggerName, 'UNIVERSALEXTONVALIDATE');
        TrigLog.SetRange(SourceEntryNo, 402);
        Assert.AreEqual(1, TrigLog.Count(),
            'SetValue on a tableextension field control is a Validate, so it must run the field''s own OnValidate exactly once');
        TrigLog.FindFirst();
        Assert.AreEqual('Via Page', TrigLog.NewValue, 'the OnValidate trigger must observe the value the page control wrote');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
