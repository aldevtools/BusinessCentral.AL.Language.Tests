// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6284 (reporter's repro): the system table Page Control Field read for an API page that has a control bound to a built-in call (field(companyName; CompanyName)): FieldNo is 0 for that control, so two of the three controls are table-bound.

table 90563 "LT WB PX Entry"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 90563 "LT WB PX Entries API"
{
    PageType = API;
    APIPublisher = 'repro';
    APIGroup = 'repro';
    APIVersion = 'v1.0';
    EntityName = 'entry';
    EntitySetName = 'entries';
    SourceTable = "LT WB PX Entry";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(number; Rec."No.") { }
                field(amount; Rec.Amount) { }
                field(companyName; CompanyName) { }
            }
        }
    }
}

codeunit 90564 "LT WB PX Tests"
{
    Subtype = Test;

    [Test]
    procedure FieldNumbersOfAnApiPageWithABuiltInControl()
    var
        PageControlField: Record "Page Control Field";
        Bound: Integer;
    begin
        PageControlField.SetRange(PageNo, Page::"LT WB PX Entries API");
        PageControlField.FindSet();
        repeat
            if PageControlField.FieldNo <> 0 then
                Bound += 1;
        until PageControlField.Next() = 0;
        if Bound <> 2 then
            Error('got %1', Bound);
    end;

    [Test]
    procedure FilterToTableBoundControlsOnly()
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT WB PX Entries API");
        PageControlField.SetFilter(FieldNo, '<>0');
        if PageControlField.Count() <> 2 then
            Error('got %1', PageControlField.Count());
    end;
}
