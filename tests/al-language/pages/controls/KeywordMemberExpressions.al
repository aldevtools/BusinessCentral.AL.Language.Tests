// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75680, pages 75681 and 75683, test codeunit 75682
// Probe (al-runner issue 8650): property and source expressions of page controls that name members which are words of the
//   AL language.
// Facts:
//   - A control's Visible and Editable expressions and a control's source expression compile when they name a keyword member
//     quoted (Rec."If", Rec."Exit", Rec.Opt::"Do") or a member that is no keyword unquoted (Rec.Key, Rec.Local); a TestPage
//     reads the values the source expressions give and the Visible and Editable states the expressions give. The same page
//     gives Yes for true keyword-member expressions and No for expressions made false by a second row.
//   - On BC 27 and 28 a TestPage of a page whose control has `Visible = Rec."Exit" > 0;` raises "The identifier 'Exit'
//     could not be found." when the test reads that control's Visible state, and when it closes the page; BC 29 gives the
//     state. The page with the keyword Visible expressions (75683) and its test are BC 29 only.
//   - Not compiling (must-not-compile 3500 to 3556): one of 32 words unquoted after `.` or `::` in a page control's Visible,
//     Editable, Enabled, CaptionClass, HideValue, ShowMandatory or QuickEntry, a page action's Visible or Enabled, a group's
//     or part's Visible, a page's DataCaptionExpression, a control's or report column's source expression, and the same in
//     page and report extensions, an action-area group's Visible, and the Visible of a page extension's `modify` of any target
//     (a field, an action, a group, a part and eight others), with AL0107 at the name first.
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
            }
            field(KeyShown; Rec.Key + Rec.Local)
            {
                ApplicationArea = All;
            }
            field(LocalShown; Rec.Local)
            {
                ApplicationArea = All;
                Editable = Rec.Key > 0;
            }
        }
    }
}

#if BC29PLUS
// BC 29 only: on BC 27 and 28 a TestPage of this page raises "The identifier 'Exit' could not be found." (see Facts).
page 75683 "PGC Keyword Member Shown"
{
    PageType = CardPart;
    SourceTable = "PGC Keyword Member Row";

    layout
    {
        area(Content)
        {
            cuegroup(KeywordMembers)
            {
                field(IfShown; Rec."If")
                {
                    ApplicationArea = All;
                    Visible = Rec."Exit" > 0;
                }
                field(KeyShown; Rec.Key)
                {
                    ApplicationArea = All;
                    Visible = Rec.Opt = Rec.Opt::"Do";
                }
            }
        }
    }
}
#endif

codeunit 75682 "PGC Keyword Member Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordMemberExpressions_TestPage_ReadsSourceValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Member Row";
        Card: TestPage "PGC Keyword Member Card";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('IfShown', Card.IfShown.Value);
        Observer.Observe('KeyShown', Card.KeyShown.Value);
        Observer.Observe('LocalShown editable', Format(Card.LocalShown.Editable()));
        Card.Close();
        Observer.Expect('IfShown', '5');
        Observer.Expect('KeyShown', '5');
        Observer.Expect('LocalShown editable', 'Yes');
        Observer.Verify();
    end;

#if BC29PLUS
    // BC 29 only: on BC 27 and 28 this page raises "The identifier 'Exit' could not be found." (see Facts).
    [Test]
    procedure KeywordMemberExpressions_TestPage_ReadsVisibleStatesOfQuotedKeywordMembers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Member Row";
        Shown: TestPage "PGC Keyword Member Shown";
    begin
        Initialize();
        InsertRow(Row);
        Shown.OpenEdit();
        Shown.GoToRecord(Row);
        Observer.Observe('IfShown visible', Format(Shown.IfShown.Visible()));
        Observer.Observe('KeyShown visible', Format(Shown.KeyShown.Visible()));
        Shown.Close();
        Observer.Expect('IfShown visible', 'Yes');
        Observer.Expect('KeyShown visible', 'Yes');
        Observer.Verify();
    end;
#endif

    local procedure InsertRow(var Row: Record "PGC Keyword Member Row")
    begin
        Row.Id := 1;
        Row."If" := 4;
        Row."Exit" := 1;
        Row.Key := 2;
        Row.Local := 3;
        Row.Opt := Row.Opt::"Do";
        Row.Insert();
    end;

    local procedure InsertFalseRow(var Row: Record "PGC Keyword Member Row")
    begin
        Row.Id := 2;
        Row."If" := 4;
        Row."Exit" := 0;
        Row.Key := 0;
        Row.Local := 3;
        Row.Opt := Row.Opt::Zero;
        Row.Insert();
    end;

    local procedure Initialize()
    var
        Row: Record "PGC Keyword Member Row";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure KeywordMemberExpressions_TestPage_ReadsFalseEditableState()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Member Row";
        Card: TestPage "PGC Keyword Member Card";
    begin
        Initialize();
        InsertRow(Row);
        InsertFalseRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('IfShown', Card.IfShown.Value);
        Observer.Observe('KeyShown', Card.KeyShown.Value);
        Observer.Observe('LocalShown editable', Format(Card.LocalShown.Editable()));
        Card.Close();
        Observer.Expect('IfShown', '5');
        Observer.Expect('KeyShown', '3');
        Observer.Expect('LocalShown editable', 'No');
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure KeywordMemberExpressions_TestPage_ReadsFalseVisibleStatesOfQuotedKeywordMembers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Member Row";
        Shown: TestPage "PGC Keyword Member Shown";
    begin
        Initialize();
        InsertRow(Row);
        InsertFalseRow(Row);
        Shown.OpenEdit();
        Shown.GoToRecord(Row);
        Observer.Observe('IfShown value', Shown.IfShown.Value);
        Observer.Observe('KeyShown value', Shown.KeyShown.Value);
        Observer.Observe('IfShown visible', Format(Shown.IfShown.Visible()));
        Observer.Observe('KeyShown visible', Format(Shown.KeyShown.Visible()));
        Shown.Close();
        Observer.Expect('IfShown value', '4');
        Observer.Expect('KeyShown value', '0');
        Observer.Expect('IfShown visible', 'No');
        Observer.Expect('KeyShown visible', 'No');
        Observer.Verify();
    end;
#endif
}
