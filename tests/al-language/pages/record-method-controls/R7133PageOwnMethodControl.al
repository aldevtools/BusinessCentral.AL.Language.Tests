// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: Cloud-compatible. Fixtures used: Probe Observer (69160); own table 95984, pages 95985 and 95986, page extension 95987,
// test codeunit 95988.
// Probe: (al-runner issue 7133) a field control whose source is a public procedure of the source table without parentheses
// (`Rec.CalculatedTotal`): on the page's own control and on a control a page extension adds, neither with an Editable property.
// What the TestPage reads as the control's value, and whether the control is editable on a page opened for edit and for view.
// The pageextension form with Editable = false is pinned in TestRecordMethodControls.al.
// BC versions: 27.5+

table 95984 "LT R7133 Method Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; Amount; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure CalculatedTotal(): Decimal
    begin
        exit(Amount + 1);
    end;
}

page 95985 "LT R7133 Own Method Card"
{
    PageType = Card;
    SourceTable = "LT R7133 Method Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Data)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Total; Rec.CalculatedTotal) { ApplicationArea = All; }
            }
        }
    }
}

page 95986 "LT R7133 Ext Method Card"
{
    PageType = Card;
    SourceTable = "LT R7133 Method Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Data)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 95987 "LT R7133 Ext Method" extends "LT R7133 Ext Method Card"
{
    layout
    {
        addlast(Data)
        {
            field(Total; Rec.CalculatedTotal) { ApplicationArea = All; }
        }
    }
}

codeunit 95988 "LT R7133 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT R7133 Method Row";
    begin
        Row.DeleteAll(false);
        Row.Id := 7;
        Row.Amount := 41.5;
        Row.Insert(false);
    end;

    [Test]
    procedure PageOwnControl_RecordMethodNoParentheses()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7133 Own Method Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('view_value', Card.Total.Value());
        Observer.Observe('view_editable', Format(Card.Total.Editable()));
        Card.Close();
        Card.OpenEdit();
        Observer.Observe('edit_value', Card.Total.Value());
        Observer.Observe('edit_editable', Format(Card.Total.Editable()));
        Observer.Observe('edit_id_editable', Format(Card.Id.Editable()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageExtensionControl_RecordMethodNoParentheses_NoEditableProperty()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7133 Ext Method Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('view_value', Card.Total.Value());
        Observer.Observe('view_editable', Format(Card.Total.Editable()));
        Card.Close();
        Card.OpenEdit();
        Observer.Observe('edit_value', Card.Total.Value());
        Observer.Observe('edit_editable', Format(Card.Total.Editable()));
        Card.Close();
        Observer.Finish();
    end;
}
