// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: Cloud-compatible. Fixtures: own method-source row and pages below. BC versions: 27.5+.
// local object: the table method and the extension control's source-expression syntax are under test.
table 69028 "PAG Method Source Row"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } field(2; Amount; Decimal) { } }
    keys { key(PK; Id) { Clustered = true; } }
    procedure CalculatedTotal(): Decimal
    begin
        exit(Amount + 1);
    end;
}
page 69038 "PAG Method Bare Host"
{
    PageType = Card;
    SourceTable = "PAG Method Source Row";
    layout { area(Content) { group(Data) { field(Id; Rec.Id) { ApplicationArea = All; } } } }
}
pageextension 69054 "PAG Method Bare Extension" extends "PAG Method Bare Host"
{
    layout { addlast(Data) { field(Total; Rec.CalculatedTotal) { ApplicationArea = All; Editable = false; } } }
}
page 69053 "PAG Method Call Host"
{
    PageType = Card;
    SourceTable = "PAG Method Source Row";
    layout { area(Content) { group(Data) { field(Id; Rec.Id) { ApplicationArea = All; } } } }
}
pageextension 69055 "PAG Method Call Extension" extends "PAG Method Call Host"
{
    layout { addlast(Data) { field(Total; Rec.CalculatedTotal()) { ApplicationArea = All; Editable = false; } } }
}
codeunit 69056 "PAG Record Method Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    [Test]
    procedure PageExtension_RecordMethod_NoParentheses_ReadsCalculatedValue()
    var
        View: TestPage "PAG Method Bare Host";
    begin
        Initialize();
        View.OpenView();
        View.Total.AssertEquals(42.5);
        View.Close();
    end;
    [Test]
    procedure PageExtension_RecordMethod_Parentheses_ReadsCalculatedValue()
    var
        View: TestPage "PAG Method Call Host";
    begin
        Initialize();
        View.OpenView();
        View.Total.AssertEquals(42.5);
        View.Close();
    end;
    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Row: Record "PAG Method Source Row";
    begin
        Cleanup.Initialize();
        Row.DeleteAll(false);
        Row.Id := 77;
        Row.Amount := 41.5;
        Row.Insert(false);
    end;
}
