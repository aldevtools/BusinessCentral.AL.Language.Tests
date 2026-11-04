// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-styleexpr-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71886, page 71887 and test codeunits 71888, 71892 to 71895
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the PageStyle type: Format(PageStyle::X), Format(PageStyle::X, 0, 2) and Format(PageStyle::X, 0, 1) for every member (PageStyle is an option-like type: AsInteger does not exist); a PageStyle variable after assignment and after Clear (Format gives 0).
//   Evaluate(PageStyle, Text) is not pinned: a test that calls it ends the test session ("hub connection closed") on BC 28 and 29, so no result can be recorded.
//   A style cannot be read back from a TestPage control (the TestPage field has no style member), so only the text a page puts into its StyleExpr variable is covered.
// BC versions: 27, 28, 29
table 71886 "LT PS Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71887 "LT PS List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT PS Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleText;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleText;
                }
            }
        }
    }

    var
        StyleText: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Id of
            1:
                StyleText := Format(PageStyle::Strong);
            2:
                StyleText := Format(PageStyle::Unfavorable);
            else
                StyleText := Format(PageStyle::None);
        end;
    end;

    procedure StyleOf(): Text
    begin
        exit(StyleText);
    end;
}

codeunit 71888 "LT PageStyle Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_Format_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format_None', Format(PageStyle::None));
        Observer.Observe('format_Standard', Format(PageStyle::Standard));
        Observer.Observe('format_StandardAccent', Format(PageStyle::StandardAccent));
        Observer.Observe('format_Strong', Format(PageStyle::Strong));
        Observer.Observe('format_StrongAccent', Format(PageStyle::StrongAccent));
        Observer.Observe('format_Attention', Format(PageStyle::Attention));
        Observer.Observe('format_AttentionAccent', Format(PageStyle::AttentionAccent));
        Observer.Observe('format_Favorable', Format(PageStyle::Favorable));
        Observer.Observe('format_Unfavorable', Format(PageStyle::Unfavorable));
        Observer.Observe('format_Ambiguous', Format(PageStyle::Ambiguous));
        Observer.Observe('format_Subordinate', Format(PageStyle::Subordinate));
        Observer.Expect('format_None', 'None');
        Observer.Expect('format_Standard', 'Standard');
        Observer.Expect('format_StandardAccent', 'StandardAccent');
        Observer.Expect('format_Strong', 'Strong');
        Observer.Expect('format_StrongAccent', 'StrongAccent');
        Observer.Expect('format_Attention', 'Attention');
        Observer.Expect('format_AttentionAccent', 'AttentionAccent');
        Observer.Expect('format_Favorable', 'Favorable');
        Observer.Expect('format_Unfavorable', 'Unfavorable');
        Observer.Expect('format_Ambiguous', 'Ambiguous');
        Observer.Expect('format_Subordinate', 'Subordinate');
        Observer.Verify();
    end;
}

codeunit 71892 "LT PageStyle FormatNumber2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_FormatNumber2_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format2_None', Format(PageStyle::None, 0, 2));
        Observer.Observe('format2_Standard', Format(PageStyle::Standard, 0, 2));
        Observer.Observe('format2_StandardAccent', Format(PageStyle::StandardAccent, 0, 2));
        Observer.Observe('format2_Strong', Format(PageStyle::Strong, 0, 2));
        Observer.Observe('format2_StrongAccent', Format(PageStyle::StrongAccent, 0, 2));
        Observer.Observe('format2_Attention', Format(PageStyle::Attention, 0, 2));
        Observer.Observe('format2_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 2));
        Observer.Observe('format2_Favorable', Format(PageStyle::Favorable, 0, 2));
        Observer.Observe('format2_Unfavorable', Format(PageStyle::Unfavorable, 0, 2));
        Observer.Observe('format2_Ambiguous', Format(PageStyle::Ambiguous, 0, 2));
        Observer.Observe('format2_Subordinate', Format(PageStyle::Subordinate, 0, 2));
        Observer.Expect('format2_None', '1');
        Observer.Expect('format2_Standard', '2');
        Observer.Expect('format2_StandardAccent', '3');
        Observer.Expect('format2_Strong', '4');
        Observer.Expect('format2_StrongAccent', '5');
        Observer.Expect('format2_Attention', '6');
        Observer.Expect('format2_AttentionAccent', '7');
        Observer.Expect('format2_Favorable', '8');
        Observer.Expect('format2_Unfavorable', '9');
        Observer.Expect('format2_Ambiguous', '10');
        Observer.Expect('format2_Subordinate', '11');
        Observer.Verify();
    end;
}

codeunit 71893 "LT PageStyle FormatNumber1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_FormatNumber1_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format1_None', Format(PageStyle::None, 0, 1));
        Observer.Observe('format1_Standard', Format(PageStyle::Standard, 0, 1));
        Observer.Observe('format1_StandardAccent', Format(PageStyle::StandardAccent, 0, 1));
        Observer.Observe('format1_Strong', Format(PageStyle::Strong, 0, 1));
        Observer.Observe('format1_StrongAccent', Format(PageStyle::StrongAccent, 0, 1));
        Observer.Observe('format1_Attention', Format(PageStyle::Attention, 0, 1));
        Observer.Observe('format1_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 1));
        Observer.Observe('format1_Favorable', Format(PageStyle::Favorable, 0, 1));
        Observer.Observe('format1_Unfavorable', Format(PageStyle::Unfavorable, 0, 1));
        Observer.Observe('format1_Ambiguous', Format(PageStyle::Ambiguous, 0, 1));
        Observer.Observe('format1_Subordinate', Format(PageStyle::Subordinate, 0, 1));
        Observer.Expect('format1_None', 'None');
        Observer.Expect('format1_Standard', 'Standard');
        Observer.Expect('format1_StandardAccent', 'StandardAccent');
        Observer.Expect('format1_Strong', 'Strong');
        Observer.Expect('format1_StrongAccent', 'StrongAccent');
        Observer.Expect('format1_Attention', 'Attention');
        Observer.Expect('format1_AttentionAccent', 'AttentionAccent');
        Observer.Expect('format1_Favorable', 'Favorable');
        Observer.Expect('format1_Unfavorable', 'Unfavorable');
        Observer.Expect('format1_Ambiguous', 'Ambiguous');
        Observer.Expect('format1_Subordinate', 'Subordinate');
        Observer.Verify();
    end;
}

codeunit 71894 "LT PageStyle Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_Variable_Assign()
    var
        Observer: Codeunit "Probe Observer";
        Style: PageStyle;
        Txt: Text;
        Ok: Boolean;
    begin
        Style := PageStyle::Favorable;
        Observer.Observe('assigned', Format(Style));
        Observer.Observe('assigned_format2', Format(Style, 0, 2));
        Txt := Format(PageStyle::AttentionAccent);
        Observer.Observe('text', Txt);
        Observer.Expect('assigned', 'Favorable');
        Observer.Expect('assigned_format2', '8');
        Observer.Expect('text', 'AttentionAccent');
        Observer.Verify();
    end;
}

codeunit 71895 "LT PageStyle Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_Variable_Clear()
    var
        Observer: Codeunit "Probe Observer";
        Style: PageStyle;
        Txt: Text;
        Ok: Boolean;
    begin
        Style := PageStyle::Favorable;
        Clear(Style);
        Observer.Observe('cleared', Format(Style));
        Observer.Observe('cleared_format2', Format(Style, 0, 2));
        Observer.Expect('cleared', '0');
        Observer.Expect('cleared_format2', '0');
        Observer.Verify();
    end;
}
