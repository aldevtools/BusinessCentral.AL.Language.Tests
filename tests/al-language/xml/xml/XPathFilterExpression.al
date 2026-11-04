// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectnodes-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 70911
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a predicate after a closing parenthesis (document-order positions over the whole node set), last(), steps after it, and the conjunction form Pageworks writes
// BC versions: 29 (27 and 28 by CI)

codeunit 70911 "LT P170 XPath Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Doc(var D: XmlDocument)
    begin
        XmlDocument.ReadFrom('<r><a><i n="1"><c>c1</c></i></a><i n="2"><c>c2</c></i><b><d><i n="3"><c>c3</c></i></d><i n="4"/></b><DataItem name="X"><c>dx1</c></DataItem><DataItem name="Y"><c>dy</c></DataItem><DataItem name="X"><c>dx2</c></DataItem></r>', D);
    end;

    [TryFunction]
    local procedure TryQuery(D: XmlDocument; XPath: Text; var R: Text)
    var
        L: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
    begin
        Ok := D.SelectNodes(XPath, L);
        R := Format(Ok) + ' ' + Format(L.Count());
        if L.Count() > 0 then begin
            L.Get(1, N);
            R += ' first=' + N.AsXmlElement().Name() + ':' + N.AsXmlElement().InnerText();
        end;
    end;

    local procedure Q(D: XmlDocument; XPath: Text): Text
    var
        R: Text;
    begin
        if TryQuery(D, XPath, R) then
            exit(R);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P170_Filter_PositionAfterParenthesis()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('second', Q(D, '(//i)[2]'));
        Observer.Observe('first', Q(D, '(//i)[1]'));
        Observer.Observe('fourth', Q(D, '(//i)[4]'));
        Observer.Observe('beyond', Q(D, '(//i)[9]'));
        Observer.Observe('zero', Q(D, '(//i)[0]'));
        Observer.Observe('last', Q(D, '(//i)[last()]'));
        Observer.Observe('last_minus_one', Q(D, '(//i)[last()-1]'));
        Observer.Observe('position_lt', Q(D, '(//i)[position()<3]'));
        Observer.Observe('no_parens_second', Q(D, '//i[2]'));
        Observer.Expect('second', 'Yes 1 first=i:c2');
        Observer.Expect('first', 'Yes 1 first=i:c1');
        Observer.Expect('fourth', 'Yes 1 first=i:');
        Observer.Expect('beyond', 'Yes 0');
        Observer.Expect('zero', 'Yes 0');
        Observer.Expect('last', 'Yes 1 first=i:');
        Observer.Expect('last_minus_one', 'Yes 1 first=i:c3');
        Observer.Expect('position_lt', 'Yes 2 first=i:c1');
        Observer.Expect('no_parens_second', 'Yes 0');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Filter_StepsAfterThePredicate()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('second_c', Q(D, '(//i)[2]/c'));
        Observer.Observe('last_c', Q(D, '(//i)[last()]/c'));
        Observer.Observe('third_c', Q(D, '(//i)[3]/c'));
        Observer.Observe('attr_after', Q(D, '(//i)[2]/@n'));
        Observer.Observe('then_predicate', Q(D, '(//i)[2][@n=''2'']'));
        Observer.Observe('then_predicate_mismatch', Q(D, '(//i)[2][@n=''1'']'));
        Observer.Observe('descendant_after', Q(D, '(//b)[1]//c'));
        Observer.Expect('second_c', 'Yes 1 first=c:c2');
        Observer.Expect('last_c', 'Yes 0');
        Observer.Expect('third_c', 'Yes 1 first=c:c3');
        Observer.Expect('attr_after', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute to Microsoft.Dynamics.Nav.Runtime.NavXmlElement.|Conversion');
        Observer.Expect('then_predicate', 'Yes 1 first=i:c2');
        Observer.Expect('then_predicate_mismatch', 'Yes 0');
        Observer.Expect('descendant_after', 'Yes 1 first=c:c3');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Filter_RelativeToTheRootElement()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        Root: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
    begin
        Doc(D);
        D.GetRoot(Root);
        Ok := Root.SelectNodes('(.//i)[2]', L);
        Observer.Observe('second', Format(Ok) + ' ' + Format(L.Count()));
        if L.Count() > 0 then begin
            L.Get(1, N);
            Observer.Observe('second_text', N.AsXmlElement().InnerText());
        end;
        Ok := Root.SelectNodes('(.//i)[last()]/c', L);
        Observer.Observe('last_c', Format(Ok) + ' ' + Format(L.Count()));
        Ok := Root.SelectNodes('(./b//i)[1]', L);
        Observer.Observe('b_first', Format(Ok) + ' ' + Format(L.Count()));
        Observer.Expect('second', 'Yes 1');
        Observer.Expect('second_text', 'c2');
        Observer.Expect('last_c', 'Yes 0');
        Observer.Expect('b_first', 'Yes 1');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Filter_PageworksConjunctionForm()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Doc(D);
        Observer.Observe('first_x', Q(D, '(.//*[local-name()="DataItem" and @name="X"])[1]/c'));
        Observer.Observe('second_x', Q(D, '(.//*[local-name()="DataItem" and @name="X"])[2]/c'));
        Observer.Observe('third_x', Q(D, '(.//*[local-name()="DataItem" and @name="X"])[3]/c'));
        Observer.Observe('y', Q(D, '(//*[local-name()="DataItem" and @name="Y"])[1]/c'));
        Observer.Observe('last_x', Q(D, '(//*[local-name()="DataItem" and @name="X"])[last()]/c'));
        Observer.Expect('first_x', 'Yes 1 first=c:dx1');
        Observer.Expect('second_x', 'Yes 1 first=c:dx2');
        Observer.Expect('third_x', 'Yes 0');
        Observer.Expect('y', 'Yes 1 first=c:dy');
        Observer.Expect('last_x', 'Yes 1 first=c:dx2');
        Observer.Verify();
    end;
}
