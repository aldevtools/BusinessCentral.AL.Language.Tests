// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-data-type
// Scope: in-scope
// Fixtures used: Assert (60021), and the table/page/pageextension below
//
// The subject is a control DECLARED BY A PAGEEXTENSION on a page that AL opens itself -- with
// Page.Run, or through a Page variable -- and a TestPage reaches by TRAPPING it, rather than
// opening it. TestPageExtensionControlBinding_Page.al covers the same controls on a TestPage
// that opens the page itself.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4738: Base Application's
// pageextension 705 adds `field(Context; Format(Rec."Context Record ID"))` to page 700
// "Error Messages", and a trapped "Error Messages" page reported that control as not found.
//
// Two extension controls, one per way a pageextension control gets a binding the page itself
// does not have: an EXPRESSION over Rec, and a GLOBAL the extension declares and assigns in its
// own OnOpenPage. The base page's own Rec-bound control is the baseline.

table 67470 "PXR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Rec Text"; Text[20]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

page 67970 "PXR List"
{
    PageType = List;
    SourceTable = "PXR Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'PXT List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Rec Text"; Rec."Rec Text") { ApplicationArea = All; }
            }
        }
    }
}

pageextension 67470 "PXR List Ext" extends "PXR List"
{
    layout
    {
        addafter("Rec Text")
        {
            // Bound to an EXPRESSION over Rec -- the shape of "Error Messages".Context.
            field(ExtExpression; Format(Rec."Entry No.") + ':' + Rec."Rec Text") { ApplicationArea = All; }

            // Bound to a variable the PAGEEXTENSION declares, assigned in its own OnOpenPage.
            // Its OnValidate rewrites the same global, so a TestPage write reads back the
            // trigger's result only if the trigger ran on the extension instance whose global
            // the control is bound to.
            field(ExtGlobalField; ExtGlobal)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    ExtGlobal := UpperCase(ExtGlobal) + '!';
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExtGlobal := 'EXTOPENED';
    end;

    var
        ExtGlobal: Text[20];
}
