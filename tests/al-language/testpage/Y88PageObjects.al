// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-updatepropagation-property
// Scope: in-scope
// Fixtures used: own objects 94707 - 94729 (writer Y88); Probe Observer (69160); tests in Y88PageProbes.al (codeunits 94723, 94724)
// Probe: (a) a part whose OnValidate modifies the host's source row and calls CurrPage.Update(false) (the shape of
//   pages/lt-qj-part-propagation/QjPartPropagation.al), on hosts with UpdatePropagation = Both, SubPart and not set, each once as the base page and once as a
//   page that a page extension extends with a field; a page extension that adds a second part (UpdatePropagation = Both) to a host whose base part has none;
//   a page extension that modifies the base part. (b) the Enabled property of profiles and profile extensions as it shows in the All Profile table.

table 94720 "LT Y88 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Total; Decimal) { }
        field(3; Descr; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94721 "LT Y88 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Decimal) { }
    }
    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

page 94722 "LT Y88 Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y88 Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(QtyF; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Head: Record "LT Y88 Head";
                    begin
                        if Head.Get(Rec."Doc No.") then begin
                            Head.Total := Rec.Qty;
                            Head.Modify();
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
}

page 94707 "LT Y88 Host Both"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

page 94708 "LT Y88 Host Both X"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

pageextension 94715 "LT Y88 Host Both X Ext" extends "LT Y88 Host Both X"
{
    layout
    {
        addlast(Content)
        {
            field(DescrF; Rec.Descr) { ApplicationArea = All; }
        }
    }
}

page 94709 "LT Y88 Host Sub"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = SubPart;
            }
        }
    }
}

page 94710 "LT Y88 Host Sub X"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = SubPart;
            }
        }
    }
}

pageextension 94716 "LT Y88 Host Sub X Ext" extends "LT Y88 Host Sub X"
{
    layout
    {
        addlast(Content)
        {
            field(DescrF; Rec.Descr) { ApplicationArea = All; }
        }
    }
}

page 94711 "LT Y88 Host Default"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 94712 "LT Y88 Host Default X"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

pageextension 94717 "LT Y88 Host Default X Ext" extends "LT Y88 Host Default X"
{
    layout
    {
        addlast(Content)
        {
            field(DescrF; Rec.Descr) { ApplicationArea = All; }
        }
    }
}

// The extension adds a second part with UpdatePropagation = Both to a host whose own part has none.
page 94713 "LT Y88 Host Ext Part"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

pageextension 94718 "LT Y88 Host Ext Part Ext" extends "LT Y88 Host Ext Part"
{
    layout
    {
        addlast(Content)
        {
            part(LinesBoth; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

// The extension modifies the base part (a property that may be customized) and leaves UpdatePropagation to the base page.
page 94714 "LT Y88 Host Modify Part"
{
    PageType = Card;
    SourceTable = "LT Y88 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoF; Rec."No.") { ApplicationArea = All; }
            field(TotalF; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT Y88 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

pageextension 94719 "LT Y88 Host Modify Part Ext" extends "LT Y88 Host Modify Part"
{
    layout
    {
        modify(Lines)
        {
            Caption = 'Ext lines';
        }
    }
}

page 94725 "LT Y88 RC"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;
}

profile "LT Y88 Prof Off"
{
    Caption = 'LT Y88 Prof Off';
    RoleCenter = "LT Y88 RC";
    Enabled = false;
}

profile "LT Y88 Prof Default"
{
    Caption = 'LT Y88 Prof Default';
    RoleCenter = "LT Y88 RC";
}

profile "LT Y88 Prof Base Off"
{
    Caption = 'LT Y88 Prof Base Off';
    RoleCenter = "LT Y88 RC";
    Enabled = false;
}

profileextension "LT Y88 Prof Base Off Ext" extends "LT Y88 Prof Base Off"
{
    Enabled = true;
}

profile "LT Y88 Prof Base On"
{
    Caption = 'LT Y88 Prof Base On';
    RoleCenter = "LT Y88 RC";
    Enabled = true;
}

profileextension "LT Y88 Prof Base On Ext" extends "LT Y88 Prof Base On"
{
    Caption = 'LT Y88 Prof Base On Ext Caption';
}
