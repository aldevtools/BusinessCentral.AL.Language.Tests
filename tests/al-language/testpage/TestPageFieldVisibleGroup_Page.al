// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TP Field Visible Row (60964)
//
// Five controls, five combinations of "does the ENCLOSING group's Visible affect this field":
//
//   RecValue                   - not inside any group at all (baseline, always visible).
//   FieldInStaticHiddenGroup   - inside a group whose Visible is the literal `false`. On real BC
//                                 this whole subtree is dead-code-eliminated at compile time: the
//                                 control never exists on the runtime page, so a TestPage access
//                                 raises "field ... is not found on the page" rather than reporting
//                                 Visible() = false.
//   FieldInDynamicGroup        - inside a group whose Visible is a page-variable expression
//                                 (ShowDynamic), no Visible of its own. A non-literal Visible is
//                                 never compile-time-eliminated: the control stays on the page and
//                                 Visible() reflects the expression's current value, live.
//   OwnHiddenFieldInVisibleGroup - same dynamic (visible) group, but this control ALSO declares
//                                 its own literal `Visible = false`, which eliminates it from the
//                                 runtime page the same way FieldInStaticHiddenGroup is eliminated,
//                                 regardless of the enclosing group's (variable-driven) visibility.
//   FieldInNestedGroup          - two groups deep (OuterGroup > InnerGroup > field). InnerGroup
//                                 declares no Visible of its own; only OuterGroup's variable
//                                 expression (ShowOuter) governs it, so nothing here is compile-time
//                                 eliminated. This is the case that tells apart a fix that only
//                                 checks the immediate parent from one that walks the whole
//                                 ancestor chain.
//
// ToggleDynamic and ToggleOuter are plain page-variable-bound controls (not Rec fields) the
// tests flip with TestPage.<field>.SetValue() to move ShowDynamic / ShowOuter between false and
// true, then re-read Visible() on the controls above.

page 60959 "TP Field Visible Card"
{
    PageType = Card;
    SourceTable = "TP Field Visible Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP Field Visible Card';

    layout
    {
        area(Content)
        {
            field(RecValue; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Rec Value';
            }

            group(StaticHiddenGroup)
            {
                ShowCaption = false;
                Visible = false;

                field(FieldInStaticHiddenGroup; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Field In Static Hidden Group';
                }
            }

            group(DynamicGroup)
            {
                ShowCaption = false;
                Visible = ShowDynamic;

                field(FieldInDynamicGroup; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Field In Dynamic Group';
                }

                field(OwnHiddenFieldInVisibleGroup; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Own Hidden Field In Visible Group';
                    Visible = false;
                }
            }

            group(OuterGroup)
            {
                ShowCaption = false;
                Visible = ShowOuter;

                group(InnerGroup)
                {
                    ShowCaption = false;

                    field(FieldInNestedGroup; Rec.Value)
                    {
                        ApplicationArea = All;
                        Caption = 'Field In Nested Group';
                    }
                }
            }

            field(ToggleDynamic; ShowDynamic)
            {
                ApplicationArea = All;
                Caption = 'Toggle Dynamic';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }

            field(ToggleOuter; ShowOuter)
            {
                ApplicationArea = All;
                Caption = 'Toggle Outer';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ShowDynamic: Boolean;
        ShowOuter: Boolean;
}
