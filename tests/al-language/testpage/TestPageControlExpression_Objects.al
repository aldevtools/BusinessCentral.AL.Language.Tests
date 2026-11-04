// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: (none)
//
// Backing objects for the control-property-expression suite.
//
// Visible, Editable and Enabled on a page control accept an AL client expression, not only a
// variable name. The AL compiler limits what may appear in one: a procedure call is rejected with
//
//     AL0322: Procedure calls is not valid for client expressions.
//             Client expressions can only use simple data types and field references.
//
// so the grammar is literals, page globals, source-table field references, `not`, `and` / `or`,
// the comparison operators, and parentheses. Each control below is one shape from that grammar.
// None is a compile-time literal, so none is dead-code-eliminated: every control exists on the
// runtime page.
//
// Two design decisions, both forced by measurement rather than taste:
//
//   1. Every control binds to its OWN source field. Controls that share one field are the subject
//      of a separate question, and mixing the two makes a failure ambiguous about which one it is
//      about.
//   2. The page globals are seeded in OnOpenPage from a SingleInstance codeunit the test sets
//      BEFORE opening, not from the record and not by a TestPage.SetValue after opening. An
//      earlier version of this suite set them after opening and asserted the controls followed;
//      real BC disagreed on all 8 versions, including for a bare `Visible = HideIt`. Seeding
//      before the page exists asks what the expression evaluates to without also asking whether a
//      later change is observable, which is a different question.
//
// Every expression here is over PAGE GLOBALS. An expression referencing a source-table FIELD is
// deliberately not covered: measured on all 8 BC versions, such an expression evaluates as if the
// field held its type default whatever row the page is on, which is its own question with its own
// test.

codeunit 60260 "TPCE State"
{
    SingleInstance = true;

    var
        HideValue: Boolean;
        SecondValue: Boolean;

    procedure SetHide(NewValue: Boolean)
    begin
        HideValue := NewValue;
    end;

    procedure GetHide(): Boolean
    begin
        exit(HideValue);
    end;

    procedure SetSecond(NewValue: Boolean)
    begin
        SecondValue := NewValue;
    end;

    procedure GetSecond(): Boolean
    begin
        exit(SecondValue);
    end;
}

table 60257 "TPCE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(10; F1; Text[30]) { }
        field(11; F2; Text[30]) { }
        field(12; F3; Text[30]) { }
        field(13; F4; Text[30]) { }
        field(14; F5; Text[30]) { }
        field(17; F8; Text[30]) { }
        field(18; F9; Text[30]) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 60258 "TPCE Card"
{
    PageType = Card;
    SourceTable = "TPCE Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPCE Card';

    layout
    {
        area(Content)
        {
            // The baseline: a bare page global. The only shape whose property text is a single
            // identifier, and the one every other test here is read against.
            field(PlainGlobal; Rec.F1) { ApplicationArea = All; Visible = HideIt; }

            field(NotGlobal; Rec.F2) { ApplicationArea = All; Visible = not HideIt; }

            field(AndGlobals; Rec.F3) { ApplicationArea = All; Visible = HideIt and SecondFlag; }

            field(OrGlobals; Rec.F4) { ApplicationArea = All; Visible = HideIt or SecondFlag; }

            field(NotParenthesized; Rec.F5) { ApplicationArea = All; Visible = not (HideIt or SecondFlag); }

            // The same grammar governs Editable and Enabled, not only Visible.
            field(NotEditable; Rec.F8) { ApplicationArea = All; Editable = not HideIt; }

            field(NotEnabled; Rec.F9) { ApplicationArea = All; Enabled = not HideIt; }
        }
    }

    trigger OnOpenPage()
    var
        State: Codeunit "TPCE State";
    begin
        HideIt := State.GetHide();
        SecondFlag := State.GetSecond();
    end;

    var
        HideIt: Boolean;
        SecondFlag: Boolean;
}
