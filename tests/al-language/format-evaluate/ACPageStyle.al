// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/pagestyle/pagestyle-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the PageStyle option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for PageStyle. Evaluate(PageStyle, Text) is not probed: a test that calls it ends the test session on BC 28 and 29 (see types/lt-page-style/PageStyle.al).
// BC versions: 27, 28, 29

codeunit 77518 "LT AC Page Style Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_PageStyle_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_None', Format(PageStyle::None));
        Observer.Observe('text_Standard', Format(PageStyle::Standard));
        Observer.Observe('text_StandardAccent', Format(PageStyle::StandardAccent));
        Observer.Observe('text_Strong', Format(PageStyle::Strong));
        Observer.Observe('text_StrongAccent', Format(PageStyle::StrongAccent));
        Observer.Observe('text_Attention', Format(PageStyle::Attention));
        Observer.Observe('text_AttentionAccent', Format(PageStyle::AttentionAccent));
        Observer.Observe('text_Favorable', Format(PageStyle::Favorable));
        Observer.Observe('text_Unfavorable', Format(PageStyle::Unfavorable));
        Observer.Observe('text_Ambiguous', Format(PageStyle::Ambiguous));
        Observer.Observe('text_Subordinate', Format(PageStyle::Subordinate));
        Observer.Observe('ordinal_None', Format(PageStyle::None, 0, 2));
        Observer.Observe('ordinal_Standard', Format(PageStyle::Standard, 0, 2));
        Observer.Observe('ordinal_StandardAccent', Format(PageStyle::StandardAccent, 0, 2));
        Observer.Observe('ordinal_Strong', Format(PageStyle::Strong, 0, 2));
        Observer.Observe('ordinal_StrongAccent', Format(PageStyle::StrongAccent, 0, 2));
        Observer.Observe('ordinal_Attention', Format(PageStyle::Attention, 0, 2));
        Observer.Observe('ordinal_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 2));
        Observer.Observe('ordinal_Favorable', Format(PageStyle::Favorable, 0, 2));
        Observer.Observe('ordinal_Unfavorable', Format(PageStyle::Unfavorable, 0, 2));
        Observer.Observe('ordinal_Ambiguous', Format(PageStyle::Ambiguous, 0, 2));
        Observer.Observe('ordinal_Subordinate', Format(PageStyle::Subordinate, 0, 2));
        Observer.Observe('number_None', Format(PageStyle::None, 0, 1));
        Observer.Observe('number_Standard', Format(PageStyle::Standard, 0, 1));
        Observer.Observe('number_StandardAccent', Format(PageStyle::StandardAccent, 0, 1));
        Observer.Observe('number_Strong', Format(PageStyle::Strong, 0, 1));
        Observer.Observe('number_StrongAccent', Format(PageStyle::StrongAccent, 0, 1));
        Observer.Observe('number_Attention', Format(PageStyle::Attention, 0, 1));
        Observer.Observe('number_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 1));
        Observer.Observe('number_Favorable', Format(PageStyle::Favorable, 0, 1));
        Observer.Observe('number_Unfavorable', Format(PageStyle::Unfavorable, 0, 1));
        Observer.Observe('number_Ambiguous', Format(PageStyle::Ambiguous, 0, 1));
        Observer.Observe('number_Subordinate', Format(PageStyle::Subordinate, 0, 1));
        Observer.Expect('text_None', 'None');
        Observer.Expect('text_Standard', 'Standard');
        Observer.Expect('text_StandardAccent', 'StandardAccent');
        Observer.Expect('text_Strong', 'Strong');
        Observer.Expect('text_StrongAccent', 'StrongAccent');
        Observer.Expect('text_Attention', 'Attention');
        Observer.Expect('text_AttentionAccent', 'AttentionAccent');
        Observer.Expect('text_Favorable', 'Favorable');
        Observer.Expect('text_Unfavorable', 'Unfavorable');
        Observer.Expect('text_Ambiguous', 'Ambiguous');
        Observer.Expect('text_Subordinate', 'Subordinate');
        Observer.Expect('ordinal_None', '1');
        Observer.Expect('ordinal_Standard', '2');
        Observer.Expect('ordinal_StandardAccent', '3');
        Observer.Expect('ordinal_Strong', '4');
        Observer.Expect('ordinal_StrongAccent', '5');
        Observer.Expect('ordinal_Attention', '6');
        Observer.Expect('ordinal_AttentionAccent', '7');
        Observer.Expect('ordinal_Favorable', '8');
        Observer.Expect('ordinal_Unfavorable', '9');
        Observer.Expect('ordinal_Ambiguous', '10');
        Observer.Expect('ordinal_Subordinate', '11');
        Observer.Expect('number_None', 'None');
        Observer.Expect('number_Standard', 'Standard');
        Observer.Expect('number_StandardAccent', 'StandardAccent');
        Observer.Expect('number_Strong', 'Strong');
        Observer.Expect('number_StrongAccent', 'StrongAccent');
        Observer.Expect('number_Attention', 'Attention');
        Observer.Expect('number_AttentionAccent', 'AttentionAccent');
        Observer.Expect('number_Favorable', 'Favorable');
        Observer.Expect('number_Unfavorable', 'Unfavorable');
        Observer.Expect('number_Ambiguous', 'Ambiguous');
        Observer.Expect('number_Subordinate', 'Subordinate');
        Observer.Verify();
    end;

    [Test]
    procedure AC_PageStyle_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: PageStyle;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := PageStyle::Subordinate;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = PageStyle::Subordinate));
        Observer.Observe('eq_first', Format(V = PageStyle::None));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Expect('default', '0');
        Observer.Expect('default_ordinal', '0');
        Observer.Expect('last', 'Subordinate');
        Observer.Expect('last_ordinal', '11');
        Observer.Expect('eq_last', 'Yes');
        Observer.Expect('eq_first', 'No');
        Observer.Expect('cleared', '0');
        Observer.Verify();
    end;

    [Test]
    procedure AC_PageStyle_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: PageStyle;
    begin
        V := PageStyle::None;
        Observer.Observe('case_None', CaseName(V));
        V := PageStyle::Standard;
        Observer.Observe('case_Standard', CaseName(V));
        V := PageStyle::StandardAccent;
        Observer.Observe('case_StandardAccent', CaseName(V));
        V := PageStyle::Strong;
        Observer.Observe('case_Strong', CaseName(V));
        V := PageStyle::StrongAccent;
        Observer.Observe('case_StrongAccent', CaseName(V));
        V := PageStyle::Attention;
        Observer.Observe('case_Attention', CaseName(V));
        V := PageStyle::AttentionAccent;
        Observer.Observe('case_AttentionAccent', CaseName(V));
        V := PageStyle::Favorable;
        Observer.Observe('case_Favorable', CaseName(V));
        V := PageStyle::Unfavorable;
        Observer.Observe('case_Unfavorable', CaseName(V));
        V := PageStyle::Ambiguous;
        Observer.Observe('case_Ambiguous', CaseName(V));
        V := PageStyle::Subordinate;
        Observer.Observe('case_Subordinate', CaseName(V));
        Observer.Expect('case_None', 'is_None');
        Observer.Expect('case_Standard', 'is_Standard');
        Observer.Expect('case_StandardAccent', 'is_StandardAccent');
        Observer.Expect('case_Strong', 'is_Strong');
        Observer.Expect('case_StrongAccent', 'is_StrongAccent');
        Observer.Expect('case_Attention', 'is_Attention');
        Observer.Expect('case_AttentionAccent', 'is_AttentionAccent');
        Observer.Expect('case_Favorable', 'is_Favorable');
        Observer.Expect('case_Unfavorable', 'is_Unfavorable');
        Observer.Expect('case_Ambiguous', 'is_Ambiguous');
        Observer.Expect('case_Subordinate', 'is_Subordinate');
        Observer.Verify();
    end;

    local procedure CaseName(V: PageStyle): Text
    begin
        case V of
            PageStyle::None:
                exit('is_None');
            PageStyle::Standard:
                exit('is_Standard');
            PageStyle::StandardAccent:
                exit('is_StandardAccent');
            PageStyle::Strong:
                exit('is_Strong');
            PageStyle::StrongAccent:
                exit('is_StrongAccent');
            PageStyle::Attention:
                exit('is_Attention');
            PageStyle::AttentionAccent:
                exit('is_AttentionAccent');
            PageStyle::Favorable:
                exit('is_Favorable');
            PageStyle::Unfavorable:
                exit('is_Unfavorable');
            PageStyle::Ambiguous:
                exit('is_Ambiguous');
            PageStyle::Subordinate:
                exit('is_Subordinate');
            else
                exit('other');
        end;
    end;
}
