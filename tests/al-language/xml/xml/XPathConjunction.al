// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectnodes-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 70910
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SelectNodes / SelectSingleNode with predicates joined by and (either order, three terms), and combined with or, not(), contains(), text()='x'; position() and last() inside a conjunction; quotes inside literals
// BC versions: 29 (27 and 28 by CI)

codeunit 70910 "LT P170 XPath And"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var D: XmlDocument)
    begin
        XmlDocument.ReadFrom('<r><Column name="A">one</Column><Column name="B">two</Column><Other name="A">three</Other><Column name="A" kind="k">four</Column></r>', D);
    end;

    [TryFunction]
    local procedure TryCount(D: XmlDocument; XPath: Text; var R: Text)
    var
        L: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
    begin
        Ok := D.SelectNodes(XPath, L);
        R := Format(Ok) + ' ' + Format(L.Count());
        if L.Count() > 0 then begin
            L.Get(1, N);
            R += ' first=' + N.AsXmlElement().InnerText();
        end;
    end;

    local procedure Q(D: XmlDocument; XPath: Text): Text
    var
        R: Text;
    begin
        if TryCount(D, XPath, R) then
            exit(R);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P170_And_LocalNameAndAttribute()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('column_a', Q(D, '//*[local-name()=''Column'' and @name=''A'']'));
        Observer.Observe('other_a_swapped', Q(D, '//*[@name=''A'' and local-name()=''Other'']'));
        Observer.Observe('column_z', Q(D, '//*[local-name()=''Column'' and @name=''Z'']'));
        Observer.Observe('column_b', Q(D, '//*[local-name()=''Column'' and @name=''B'']'));
        Observer.Observe('double_quotes', Q(D, '//*[local-name()="Column" and @name="A"]'));
        Observer.Observe('no_spaces', Q(D, '//*[local-name()=''Column''and @name=''A'']'));
        Observer.Observe('three_terms', Q(D, '//*[local-name()=''Column'' and @name=''A'' and @kind=''k'']'));
        Observer.Observe('three_terms_no_match', Q(D, '//*[local-name()=''Column'' and @name=''B'' and @kind=''k'']'));
        Observer.Observe('name_then_name', Q(D, '//*[@name=''A'' and @name=''B'']'));
        Observer.Observe('element_name_form', Q(D, '//Column[@name=''A'' and @kind]'));
        Observer.Expect('column_a', 'Yes 2 first=one');
        Observer.Expect('other_a_swapped', 'Yes 1 first=three');
        Observer.Expect('column_z', 'Yes 0');
        Observer.Expect('column_b', 'Yes 1 first=two');
        Observer.Expect('double_quotes', 'Yes 2 first=one');
        Observer.Expect('no_spaces', 'Yes 2 first=one');
        Observer.Expect('three_terms', 'Yes 1 first=four');
        Observer.Expect('three_terms_no_match', 'Yes 0');
        Observer.Expect('name_then_name', 'Yes 0');
        Observer.Expect('element_name_form', 'Yes 1 first=four');
        Observer.Verify();
    end;

    [Test]
    procedure P170_And_WithOrNotContainsText()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('or_and', Q(D, '//*[@name=''A'' and (local-name()=''Other'' or @kind)]'));
        Observer.Observe('and_or_precedence', Q(D, '//*[@name=''B'' or @name=''A'' and local-name()=''Other'']'));
        Observer.Observe('not_and', Q(D, '//*[local-name()=''Column'' and not(@name=''A'')]'));
        Observer.Observe('contains_and', Q(D, '//*[contains(@name,''A'') and local-name()=''Column'']'));
        Observer.Observe('text_eq', Q(D, '//*[text()=''two'']'));
        Observer.Observe('text_and_name', Q(D, '//*[text()=''one'' and @name=''A'']'));
        Observer.Observe('text_and_name_mismatch', Q(D, '//*[text()=''one'' and @name=''B'']'));
        Observer.Observe('text_contains', Q(D, '//*[contains(text(),''o'') and @name]'));
        Observer.Observe('starts_with', Q(D, '//*[starts-with(local-name(),''Col'') and @name=''A'']'));
        Observer.Observe('count_attr', Q(D, '//*[count(@*)=2 and local-name()=''Column'']'));
        Observer.Expect('or_and', 'Yes 2 first=three');
        Observer.Expect('and_or_precedence', 'Yes 2 first=two');
        Observer.Expect('not_and', 'Yes 1 first=two');
        Observer.Expect('contains_and', 'Yes 2 first=one');
        Observer.Expect('text_eq', 'Yes 1 first=two');
        Observer.Expect('text_and_name', 'Yes 1 first=one');
        Observer.Expect('text_and_name_mismatch', 'Yes 0');
        Observer.Expect('text_contains', 'Yes 3 first=one');
        Observer.Expect('starts_with', 'Yes 2 first=one');
        Observer.Expect('count_attr', 'Yes 1 first=four');
        Observer.Verify();
    end;

    [Test]
    procedure P170_And_PositionAndLastInsideConjunction()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('position', Q(D, '//Column[@name=''A'' and position()=2]'));
        Observer.Observe('last', Q(D, '//Column[@name=''A'' and last()]'));
        Observer.Observe('position_first', Q(D, '//Column[position()=1 and @name=''A'']'));
        Observer.Observe('position_filter_chain', Q(D, '//Column[@name=''A''][2]'));
        Observer.Expect('position', 'Yes 0');
        Observer.Expect('last', 'Yes 2 first=one');
        Observer.Expect('position_first', 'Yes 1 first=one');
        Observer.Expect('position_filter_chain', 'Yes 1 first=four');
        Observer.Verify();
    end;

    [Test]
    procedure P170_And_QuotesInsideLiterals()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        XmlDocument.ReadFrom('<r><c n="it''s" m="x"/><c n="say &quot;hi&quot;" m="y"/><c n="plain" m="z"/></r>', D);
        Observer.Observe('apostrophe_in_double', Q(D, '//c[@n="it''s" and @m="x"]'));
        Observer.Observe('quote_in_single', Q(D, '//c[@n=''say "hi"'' and @m=''y'']'));
        Observer.Observe('apostrophe_ends_literal', Q(D, '//c[@n=''it''s'' and @m=''x'']'));
        Observer.Observe('unterminated', Q(D, '//c[@n=''plain and @m=''z'']'));
        Observer.Observe('empty_literal', Q(D, '//c[@n='''' and @m=''z'']'));
        Observer.Observe('and_inside_literal', Q(D, '//c[@n=''a and b'']'));
        Observer.Expect('apostrophe_in_double', 'Yes 1 first=');
        Observer.Expect('quote_in_single', 'Yes 1 first=');
        Observer.Expect('apostrophe_ends_literal', 'No 0');
        Observer.Expect('unterminated', 'No 0');
        Observer.Expect('empty_literal', 'Yes 0');
        Observer.Expect('and_inside_literal', 'Yes 0');
        Observer.Verify();
    end;

    [Test]
    procedure P170_And_SelectSingleNode_AndElementContext()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        Root: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
        Ok: Boolean;
    begin
        Doc(D);
        Ok := D.SelectSingleNode('//*[local-name()=''Column'' and @name=''B'']', N);
        Observer.Observe('single_found', Format(Ok));
        if Ok then
            Observer.Observe('single_text', N.AsXmlElement().InnerText());
        Ok := D.SelectSingleNode('//*[local-name()=''Column'' and @name=''Z'']', N);
        Observer.Observe('single_missing', Format(Ok));
        Ok := D.SelectSingleNode('//*[local-name()=''Column'' and @name=''A'']', N);
        Observer.Observe('single_first_of_two', Format(Ok));
        if Ok then
            Observer.Observe('single_first_text', N.AsXmlElement().InnerText());
        D.GetRoot(Root);
        Ok := Root.SelectNodes('.//*[local-name()=''Column'' and @name=''A'']', L);
        Observer.Observe('element_context', Format(Ok) + ' ' + Format(L.Count()));
        Observer.Expect('single_found', 'Yes');
        Observer.Expect('single_text', 'two');
        Observer.Expect('single_missing', 'No');
        Observer.Expect('single_first_of_two', 'Yes');
        Observer.Expect('single_first_text', 'one');
        Observer.Expect('element_context', 'Yes 2');
        Observer.Verify();
    end;
}
