// Writer TI (al-runner issue 6043): a page extension in ANOTHER app declares local procedures with the name and signature of the protected, public,
// local and internal procedures of its base page (LtTiBasePage.al in the AL Internals Test Fixture app). alc accepts all four. Which procedure
// runs for a bare call inside the extension, and which for the base page's own calls, is recorded in a log.
pageextension 89915 "LT TI Same Name Ext" extends "LT TI Same Name Base"
{
    trigger OnOpenPage()
    begin
        Log.Add('ext-open');
        Prot();
        Pub();
        Loc();
        Int();
    end;

    local procedure Prot()
    begin
        Log.Add('ext.Prot');
    end;

    local procedure Pub()
    begin
        Log.Add('ext.Pub');
    end;

    local procedure Loc()
    begin
        Log.Add('ext.Loc');
    end;

    local procedure Int()
    begin
        Log.Add('ext.Int');
    end;

    var
        Log: Codeunit "LT TI Same Name Log";
}

codeunit 89916 "LT TI Same Name Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "LT TI Same Name Log";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure TI_PageExt_LocalSameName_OpenPage()
    var
        Page: TestPage "LT TI Same Name Base";
    begin
        Log.Take();
        Page.OpenView();
        Observer.Observe('open', Log.Take());
        Page.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TI_PageExt_LocalSameName_BaseOwnCalls()
    var
        BasePage: Page "LT TI Same Name Base";
    begin
        Log.Take();
        BasePage.Pub();
        Observer.Observe('public call from outside', Log.Take());
        BasePage.CallAll();
        Observer.Observe('CallAll', Log.Take());
        Observer.Finish();
    end;
}
