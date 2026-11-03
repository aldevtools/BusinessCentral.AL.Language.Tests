// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-pages
// Scope: in-scope
// Fixtures used: Assert (60021), and the table/page/pageextension below
//
// The subject is a control DECLARED BY A PAGEEXTENSION, read through a TestPage. The existing
// pageextensiontrigger suite covers a pageextension's page TRIGGERS on a TestPage; its
// pageextension adds no layout control at all, so nothing upstream measures this.
//
// TWO CONTROLS ON PURPOSE, and the pair is the whole design. AL Runner issue
// StefanMaron/BusinessCentral.AL.Runner#4145 reports NavTestFieldNotFoundException for an
// extension control bound to an extension GLOBAL, and names two candidate causes it could not
// separate: the page metadata not carrying the extension's control at all, or the extension's
// InitializeComponent (where source expressions are registered) being skipped.
//
// A control bound to Rec discriminates them. If BOTH controls are found, the metadata carries
// extension controls and the global-bound one is a source-expression problem. If NEITHER is
// found, it is the metadata. One control alone cannot tell those apart -- which is exactly why
// the issue asked for this shape rather than a single reproducer.

table 60987 "PXC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Rec Text"; Text[20]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

page 60991 "PXC Card"
{
    PageType = Card;
    SourceTable = "PXC Row";
    ApplicationArea = All;
    Caption = 'PXC Card';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }
}

pageextension 60997 "PXC Card Ext" extends "PXC Card"
{
    layout
    {
        addlast(Content)
        {
            // Bound to a variable the PAGEEXTENSION declares.
            field(ExtGlobalField; ExtGlobal) { ApplicationArea = All; }

            // Bound to a field of the page's own SourceTable, from the same pageextension.
            // Same declaration site, different binding -- that is what separates the two causes.
            field(ExtRecField; Rec."Rec Text") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        ExtGlobal := 'EXTGLOBAL';
    end;

    var
        ExtGlobal: Text[20];
}

// ---------------------------------------------------------------------------------------------
// THE SAME SUBJECT ONE LEVEL DOWN: a pageextension control on a page used as a SUBPAGE PART.
//
// Added for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4181, which reports that the
// fix for the top-level shape above does not reach a part. The two are not the same measurement:
// for a part, BC builds and caches the subpage form itself inside NavForm.GetPart, so a runner
// that binds extensions "before the metadata load" has no such point left to act at. Whether BC
// finds the control there was an EXPECTATION carried over from the top-level result, never a
// service-tier verdict -- these arms are what turn it into one.
//
// The same two-control design as above, for the same reason: a global-bound control and a
// Rec-bound one from the one pageextension, so a failure separates "the part's metadata does not
// carry extension controls" from "it does, and the source expression is missing".

table 60985 "PXC Sub Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Sub Text"; Text[20]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

page 60989 "PXC Sub Part"
{
    PageType = ListPart;
    SourceTable = "PXC Sub Row";
    ApplicationArea = All;
    Caption = 'PXC Sub Part';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            }
        }
    }
}

pageextension 60996 "PXC Sub Part Ext" extends "PXC Sub Part"
{
    layout
    {
        addlast(Content)
        {
            // Bound to a variable the PAGEEXTENSION declares -- the shape #4181 reports.
            field(SubExtGlobalField; SubExtGlobal) { ApplicationArea = All; }

            // Bound to a field of the part's own SourceTable, from the same pageextension.
            field(SubExtRecField; Rec."Sub Text") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        SubExtGlobal := 'SUBEXTGLOBAL';
    end;

    var
        SubExtGlobal: Text[20];
}

page 60990 "PXC Host Card"
{
    PageType = Card;
    SourceTable = "PXC Row";
    ApplicationArea = All;
    Caption = 'PXC Host Card';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }

            // The part is the whole point: its form is built and cached by BC's own GetPart,
            // which is what makes this a different measurement from the top-level card above.
            part(SubPart; "PXC Sub Part")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
