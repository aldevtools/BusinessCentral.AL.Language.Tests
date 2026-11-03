// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72477 "LT P194 ReqGroup Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(Row; "LT P194 Gen")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(OpenGrp)
                {
                    field(OpenFld; OpenVar)
                    {
                        ApplicationArea = All;
                    }
                }
                group(LockedGrp)
                {
                    Editable = false;

                    field(LockedFld; LockedVar)
                    {
                        ApplicationArea = All;
                    }
                }
                group(DisabledGrp)
                {
                    Enabled = false;

                    field(DisabledFld; DisabledVar)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    var
        OpenVar: Text[30];
        LockedVar: Text[30];
        DisabledVar: Text[30];
}

codeunit 72478 "LT P194 ReqGroup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure P194_ReportGroup_EditableEnabled()
    begin
        Commit();
        Report.Run(Report::"LT P194 ReqGroup Rpt");
        Observer.Expect('open_editable', 'Yes');
        Observer.Expect('open_enabled', 'Yes');
        Observer.Expect('open_value', 'v');
        Observer.Expect('locked_editable', 'No');
        Observer.Expect('locked_enabled', 'Yes');
        Observer.Expect('locked_setvalue|text', 'NoError');
        Observer.Expect('locked_setvalue|code', 'Dialog');
        Observer.Expect('disabled_editable', 'Yes');
        Observer.Expect('disabled_enabled', 'No');
        Observer.Expect('disabled_setvalue|text', 'NoError');
        Observer.Expect('disabled_setvalue|code', 'Dialog');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure GroupHandler(var RP: TestRequestPage "LT P194 ReqGroup Rpt")
    begin
        Observer.Observe('open_editable', Format(RP.OpenFld.Editable()));
        Observer.Observe('open_enabled', Format(RP.OpenFld.Enabled()));
        RP.OpenFld.SetValue('v');
        Observer.Observe('open_value', RP.OpenFld.Value());
        Observer.Observe('locked_editable', Format(RP.LockedFld.Editable()));
        Observer.Observe('locked_enabled', Format(RP.LockedFld.Enabled()));
        asserterror begin
            RP.LockedFld.SetValue('x');
            Error('NoError');
        end;
        Observer.ObserveError('locked_setvalue');
        Observer.Observe('disabled_editable', Format(RP.DisabledFld.Editable()));
        Observer.Observe('disabled_enabled', Format(RP.DisabledFld.Enabled()));
        asserterror begin
            RP.DisabledFld.SetValue('x');
            Error('NoError');
        end;
        Observer.ObserveError('disabled_setvalue');
        RP.Cancel().Invoke();
    end;
}
