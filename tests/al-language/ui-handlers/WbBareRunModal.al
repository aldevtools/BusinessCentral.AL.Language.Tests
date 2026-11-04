// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6283 (reporter's repro, passed on real BC): a page procedure that calls the bare RunModal() (no Page variable) runs the page instance it belongs to modally; Caption and LookupMode before it; the ModalPageHandler picks the first row and OK returns Action::LookupOK.

table 90560 "LT WB PS Template"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

page 90560 "LT WB PS Templates"
{
    PageType = List;
    SourceTable = "LT WB PS Template";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    procedure Lookup(var SelectedCode: Code[20]): Boolean
    begin
        Caption('Select a template');
        LookupMode(true);
        if RunModal() = Action::LookupOK then begin
            SelectedCode := Rec."Code";
            exit(true);
        end;
    end;
}

codeunit 90561 "LT WB PS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('PickFirstHandler')]
    procedure PageProcedureRunsItselfModal()
    var
        Template: Record "LT WB PS Template";
        Templates: Page "LT WB PS Templates";
        SelectedCode: Code[20];
    begin
        Template.DeleteAll();
        Template."Code" := 'A';
        Template.Insert();
        if not Templates.Lookup(SelectedCode) then
            Error('lookup cancelled');
        if SelectedCode <> 'A' then
            Error('got %1', SelectedCode);
    end;

    [ModalPageHandler]
    procedure PickFirstHandler(var Templates: TestPage "LT WB PS Templates")
    begin
        Templates.First();
        Templates.OK().Invoke();
    end;
}
