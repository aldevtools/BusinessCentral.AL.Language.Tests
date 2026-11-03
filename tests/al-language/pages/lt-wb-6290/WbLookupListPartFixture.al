// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6290 (follow-up to 6032, reporter's repro, passed on real BC): objects for WbLookupListPartTests.al. TestField.Lookup on a page whose ListPart has a two-field SubPageLink shows the picked value.

table 90590 "LT WB Lookup Setting"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Resource No."; Code[20]) { }
    }
    keys
    {
        key(PK; "Primary Key") { }
    }
}

table 90591 "LT WB Lookup Resource"
{
    LookupPageId = "LT WB Lookup Resource List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Group Code"; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { }
    }
}

page 90592 "LT WB Lookup Resource List"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }
}

page 90593 "LT WB Lookup Resource Part"
{
    PageType = ListPart;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Scope; Scope)
            {
                ApplicationArea = All;
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }

    procedure ShowScope(NewScope: Code[20])
    begin
        Scope := NewScope;
        CurrPage.Update(false);
    end;

    var
        Scope: Code[20];
}

page 90594 "LT WB Single Link Schedule"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupResource(Text, false));
                    end;

                    trigger OnValidate()
                    begin
                        SaveAndUpdate();
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Resources; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        OpenSetting();
    end;

    var
        Setting: Record "LT WB Lookup Setting";

    local procedure LookupResource(var Text: Text; AskFirst: Boolean): Boolean
    var
        Resource: Record "LT WB Lookup Resource";
    begin
        if AskFirst then
            if StrMenu('Work Center,Machine Center', 1) = 0 then
                exit(false);
        if Page.RunModal(Page::"LT WB Lookup Resource List", Resource) <> Action::LookupOK then
            exit(false);
        Text := Resource."No.";
        exit(true);
    end;

    local procedure OpenSetting()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    local procedure SaveAndUpdate()
    begin
        Setting.Modify();
        CurrPage.Update(false);
    end;
}

page 90595 "LT WB Multi Link Schedule"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT WB Lookup Resource";
                    begin
                        if Page.RunModal(Page::"LT WB Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Resources; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    var
        Setting: Record "LT WB Lookup Setting";
}

page 90596 "LT WB Two Parts Schedule"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT WB Lookup Resource";
                    begin
                        if Page.RunModal(Page::"LT WB Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(ResourcesOne; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
            part(ResourcesTwo; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    var
        Setting: Record "LT WB Lookup Setting";
}

page 90597 "LT WB Multi Link Part Update"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT WB Lookup Resource";
                    begin
                        if Page.RunModal(Page::"LT WB Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Resources.Page.ShowScope(Setting."Resource No.");
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Resources; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    var
        Setting: Record "LT WB Lookup Setting";
}

page 90598 "LT WB Multi Link Menu"
{
    PageType = List;
    SourceTable = "LT WB Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT WB Lookup Resource";
                    begin
                        if StrMenu('Work Center,Machine Center', 1) = 0 then
                            exit(false);
                        if Page.RunModal(Page::"LT WB Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Resources; "LT WB Lookup Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    var
        Setting: Record "LT WB Lookup Setting";
}
