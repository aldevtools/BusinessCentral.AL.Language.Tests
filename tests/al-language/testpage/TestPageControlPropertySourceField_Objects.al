// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: (none — the table below is the card page's SourceTable)
//
// Backing objects for the source-table-field half of the control-property-expression grammar
// (codeunit 60259's TPCE suite covers the page-global half and deliberately excludes this one —
// see its own header). Visible, Editable and Enabled accept a client expression that may
// reference a field on the page's SourceTable, and an informal measurement (issue #2596 on
// StefanMaron/BusinessCentral.AL.Runner) found such an expression reads as if the field held its
// type default, whatever row the page is on — but that measurement never varied WHEN the record
// was bound (always GoToRecord after a plain OpenView) or WHETHER anything ever refreshes it.
// This suite settles both:
//
//   1. Is "blank record" the rule, or an artifact of evaluating before the record loads?
//      TestPageControlPropertySourceField_Tests's DirectOpenOnTheOnlyRow test opens with NO
//      GoToRecord call at all — the table holds exactly the one row under test, so OpenView
//      lands on it directly. (TestPage has no SetRecord — that method exists only on the
//      untestable Page type — so this is the closest ordering variation the testability layer
//      actually exposes.) The earlier measurement always navigated with GoToRecord after
//      OpenView; this rules out GoToRecord itself as the explanation.
//   2. Does anything ever unfreeze it? EditingTheFieldThroughThePage tests an in-page edit (not
//      an external Rec.Modify) to the exact field the expression reads, and
//      ReopeningThePage_StillReadsBlank tests a genuinely fresh page instance against a row whose
//      field was already changed and saved.
//
// Every visibility-under-test control binds to its OWN field, distinct from the field its
// property expression reads and distinct from the other test control's field — the same
// discipline codeunit 60265's header uses, for the same reason: a control sharing a field with
// something else makes a failure ambiguous about which one it is about.

table 60753 "TPCF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Flag; Boolean) { }
        field(3; Value; Text[30]) { }
        field(4; Spare; Text[30]) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 60754 "TPCF Card"
{
    PageType = Card;
    SourceTable = "TPCF Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPCF Card';

    layout
    {
        area(Content)
        {
            // Plain, no property override — lets a test read back which row it is on, and edit
            // Flag / Value THROUGH the page (as a user would) rather than only through Rec.

            field(FlagCtl; Rec.Flag) { ApplicationArea = All; }

            field(ValueCtl; Rec.Value) { ApplicationArea = All; }

            // The two shapes under test. Each binds to a field NEITHER other test control nor
            // its own property expression touches, so a read from it is unambiguous.

            field(BoolVisible; Rec.Spare) { ApplicationArea = All; Visible = Rec.Flag; }

            field(CmpVisible; Rec.PK) { ApplicationArea = All; Visible = (Rec.Value <> ''); }
        }
    }
}
