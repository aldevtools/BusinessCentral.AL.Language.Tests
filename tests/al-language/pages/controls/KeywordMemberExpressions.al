// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75680, page 75681, test codeunit 75682
// Probe (al-runner issue 8650): property and source expressions of page controls that name members which are words of the
//   AL language.
// Facts:
//   - A control's Visible and Editable expressions and a control's source expression compile when they name a keyword member
//     quoted (Rec."If", Rec."Exit", Rec.Opt::"Do") or a member that is no keyword unquoted (Rec.Key, Rec.Local); a TestPage
//     reads the values the source expressions give and the Visible and Editable states the expressions give.
//   - Not compiling (must-not-compile 3500 to 3551): one of 32 words unquoted after `.` or `::` in a page control's Visible,
//     Editable, Enabled, CaptionClass, HideValue, ShowMandatory or QuickEntry, a page action's Visible or Enabled, a group's
//     or part's Visible, a page's DataCaptionExpression, a control's or report column's source expression, and the same in
//     page and report extensions, with AL0107 at the name first.
// local object: the member names in the expressions are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75680 "PGC Keyword Member Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "If"; Integer) { }
        field(3; "Exit"; Integer) { }
        field(4; "Key"; Integer) { }
        field(5; Local; Integer) { }
        field(6; Opt; Option) { OptionMembers = Zero,"Do"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 75681 "PGC Keyword Member Card"
{
    PageType = Card;
    SourceTable = "PGC Keyword Member Row";

    layout
    {
        area(Content)
        {
            field(IfShown; Rec."If" + 1)
            {
                ApplicationArea = All;
                Visible = Rec."Exit" > 0;
            }
            field(KeyShown; Rec.Key + Rec.Local)
            {
                ApplicationArea = All;
                Visible = Rec.Opt = Rec.Opt::"Do";
            }
            field(LocalShown; Rec.Local)
            {
                ApplicationArea = All;
                Editable = Rec.Key > 0;
            }
        }
    }
}

codeunit 75682 "PGC Keyword Member Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordMemberExpressions_TestPage_ReadsValuesAndStates()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Member Row";
        Card: TestPage "PGC Keyword Member Card";
    begin
        Initialize();
        Row.Id := 1;
        Row."If" := 4;
        Row."Exit" := 1;
        Row.Key := 2;
        Row.Local := 3;
        Row.Opt := Row.Opt::"Do";
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('IfShown', Card.IfShown.Value);
        Observer.Observe('KeyShown', Card.KeyShown.Value);
        Observer.Observe('IfShown visible', Format(Card.IfShown.Visible()));
        Observer.Observe('KeyShown visible', Format(Card.KeyShown.Visible()));
        Observer.Observe('LocalShown editable', Format(Card.LocalShown.Editable()));
        Card.Close();
        Observer.Expect('IfShown', '5');
        Observer.Expect('KeyShown', '5');
        Observer.Expect('IfShown visible', 'Yes');
        Observer.Expect('KeyShown visible', 'Yes');
        Observer.Expect('LocalShown editable', 'Yes');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "PGC Keyword Member Row";
    begin
        Row.DeleteAll();
    end;
}
