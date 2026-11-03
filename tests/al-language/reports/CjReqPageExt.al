// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own log 84660, report 84651, report extension 84652, test codeunit 84653
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts (corpus issue 667, item 152): a report extension request page field whose Visible is an expression over a variable of the report extension
//   (Visible = not HideExt): it compiles, and the field is visible or hidden on the request page by the value the variable has when the page opens.
// BC versions: 27-29

// SingleInstance log used only by test codeunit 84653.
codeunit 84660 "LT CJ ReqPage Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 84651 "LT CJ ReqPage Base Rep"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(BaseCtl; BaseVal)
                {
                    ApplicationArea = All;
                    Caption = 'Base';
                }
            }
        }
    }

    var
        BaseVal: Boolean;
}

reportextension 84652 "LT CJ ReqPage Ext" extends "LT CJ ReqPage Base Rep"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(ExtCtl; ExtVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext';
                    Visible = not HideExt;
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('open hide=' + Format(HideExt));
        end;
    }

    procedure SetHideExt(NewHide: Boolean)
    begin
        HideExt := NewHide;
    end;

    var
        ExtVal: Boolean;
        HideExt: Boolean;
        Log: Codeunit "LT CJ ReqPage Log";
}

codeunit 84653 "LT CJ ReqPage Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CJ ReqPage Log";

    [RequestPageHandler]
    procedure Capture(var RP: TestRequestPage "LT CJ ReqPage Base Rep")
    begin
        Log.Add('base visible=' + Format(RP.BaseCtl.Visible()) + ' ext visible=' + Format(RP.ExtCtl.Visible()));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('Capture')]
    procedure ExtVariable_Default_FieldVisible()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CJ ReqPage Base Rep";
    begin
        Log.Take();
        Observer.Observe('parameters empty', Format(Rpt.RunRequestPage() = ''));
        Observer.Observe('log', Log.Take());
        Observer.Expect('parameters empty', 'Yes');
        Observer.Expect('log', 'open hide=No;base visible=Yes ext visible=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Capture')]
    procedure ExtVariable_SetTrue_FieldHidden()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CJ ReqPage Base Rep";
    begin
        Log.Take();
        Rpt.SetHideExt(true);
        Observer.Observe('parameters empty', Format(Rpt.RunRequestPage() = ''));
        Observer.Observe('log', Log.Take());
        Observer.Expect('parameters empty', 'Yes');
        Observer.Expect('log', 'open hide=Yes;base visible=Yes ext visible=No;');
        Observer.Verify();
    end;
}
