// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: XPath: location paths with names, *, ., .., @a, //, text(), [n], [last()]
// Facts: XmlDocument.SelectNodes with plain paths, predicates, namespaces via XmlNamespaceManager, malformed paths
// BC versions: 29 (27 and 28 by CI)

codeunit 70084 "LT PnA Xml XPath"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
        Mgr: XmlNamespaceManager;
        Cnt: Integer;
        UseMgr: Boolean;

    local procedure Setup()
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:x"><a id="1"><b>t1</b></a><a id="2"><b>t2</b></a><p:c>pc</p:c><d xmlns="urn:def">dd</d><e/></r>', Doc);
        Mgr.AddNamespace('p', 'urn:x');
        Mgr.AddNamespace('q', 'urn:def');
    end;

    [TryFunction]
    local procedure TrySelect(Path: Text)
    begin
        Cnt := -1;
        if UseMgr then begin
            if Doc.SelectNodes(Path, Mgr, Nodes) then
                Cnt := Nodes.Count();
        end else
            if Doc.SelectNodes(Path, Nodes) then
                Cnt := Nodes.Count();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text; WithMgr: Boolean)
    begin
        UseMgr := WithMgr;
        Observer.Observe(Name, Format(TrySelect(Path)) + '|' + Format(Cnt));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure PlainPaths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Probe(Observer, 'children', '/r/a', false);
        Probe(Observer, 'star', '/r/*', false);
        Probe(Observer, 'first', '/r/a[1]', false);
        Probe(Observer, 'last', '/r/a[last()]', false);
        Probe(Observer, 'position', '/r/a[position()=2]', false);
        Probe(Observer, 'index-zero', '/r/a[0]', false);
        Probe(Observer, 'index-beyond', '/r/a[3]', false);
        Probe(Observer, 'descendant', '//b', false);
        Probe(Observer, 'parent', '/r/a/b/..', false);
        Probe(Observer, 'self', '/r/.', false);
        Probe(Observer, 'dot-alone', '.', false);
        Probe(Observer, 'attribute', '/r/a/@id', false);
        Probe(Observer, 'attribute-star', '/r/a/@*', false);
        Probe(Observer, 'text', '//text()', false);
        Probe(Observer, 'attr-predicate', '/r/a[@id=''2'']', false);
        Probe(Observer, 'attr-exists', '/r/a[@id]', false);
        Probe(Observer, 'local-name', '/r/*[local-name()=''c'']', false);
        Probe(Observer, 'no-ns-d', '/r/d', false);
        Probe(Observer, 'empty-element', '/r/e', false);
        Probe(Observer, 'root-only', '/', false);
        Probe(Observer, 'count-function', 'count(/r/a)', false);
        Observer.Expect('children', 'Yes|2');
        Observer.Expect('children|text', '');
        Observer.Expect('children|code', '');
        Observer.Expect('star', 'Yes|5');
        Observer.Expect('star|text', '');
        Observer.Expect('star|code', '');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first|text', '');
        Observer.Expect('first|code', '');
        Observer.Expect('last', 'Yes|1');
        Observer.Expect('last|text', '');
        Observer.Expect('last|code', '');
        Observer.Expect('position', 'Yes|1');
        Observer.Expect('position|text', '');
        Observer.Expect('position|code', '');
        Observer.Expect('index-zero', 'Yes|0');
        Observer.Expect('index-zero|text', '');
        Observer.Expect('index-zero|code', '');
        Observer.Expect('index-beyond', 'Yes|0');
        Observer.Expect('index-beyond|text', '');
        Observer.Expect('index-beyond|code', '');
        Observer.Expect('descendant', 'Yes|2');
        Observer.Expect('descendant|text', '');
        Observer.Expect('descendant|code', '');
        Observer.Expect('parent', 'Yes|2');
        Observer.Expect('parent|text', '');
        Observer.Expect('parent|code', '');
        Observer.Expect('self', 'Yes|1');
        Observer.Expect('self|text', '');
        Observer.Expect('self|code', '');
        Observer.Expect('dot-alone', 'Yes|1');
        Observer.Expect('dot-alone|text', '');
        Observer.Expect('dot-alone|code', '');
        Observer.Expect('attribute', 'Yes|2');
        Observer.Expect('attribute|text', '');
        Observer.Expect('attribute|code', '');
        Observer.Expect('attribute-star', 'Yes|2');
        Observer.Expect('attribute-star|text', '');
        Observer.Expect('attribute-star|code', '');
        Observer.Expect('text', 'Yes|4');
        Observer.Expect('text|text', '');
        Observer.Expect('text|code', '');
        Observer.Expect('attr-predicate', 'Yes|1');
        Observer.Expect('attr-predicate|text', '');
        Observer.Expect('attr-predicate|code', '');
        Observer.Expect('attr-exists', 'Yes|2');
        Observer.Expect('attr-exists|text', '');
        Observer.Expect('attr-exists|code', '');
        Observer.Expect('local-name', 'Yes|1');
        Observer.Expect('local-name|text', '');
        Observer.Expect('local-name|code', '');
        Observer.Expect('no-ns-d', 'Yes|0');
        Observer.Expect('no-ns-d|text', '');
        Observer.Expect('no-ns-d|code', '');
        Observer.Expect('empty-element', 'Yes|1');
        Observer.Expect('empty-element|text', '');
        Observer.Expect('empty-element|code', '');
        Observer.Expect('root-only', 'Yes|1');
        Observer.Expect('root-only|text', '');
        Observer.Expect('root-only|code', '');
        Observer.Expect('count-function', 'Yes|0');
        Observer.Expect('count-function|text', '');
        Observer.Expect('count-function|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure NamespacePaths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Probe(Observer, 'prefixed-no-manager', '/r/p:c', false);
        Probe(Observer, 'prefixed-with-manager', '/r/p:c', true);
        Probe(Observer, 'unknown-prefix-with-manager', '/r/z:c', true);
        Probe(Observer, 'default-ns-with-manager', '/r/q:d', true);
        Probe(Observer, 'default-ns-unprefixed', '/r/d', true);
        Probe(Observer, 'plain-with-manager', '/r/a', true);
        Probe(Observer, 'star-with-manager', '/r/*', true);
        Observer.Expect('prefixed-no-manager', 'Yes|-1');
        Observer.Expect('prefixed-no-manager|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('prefixed-no-manager|code', 'Xml:XPath');
        Observer.Expect('prefixed-with-manager', 'Yes|1');
        Observer.Expect('prefixed-with-manager|text', '');
        Observer.Expect('prefixed-with-manager|code', '');
        Observer.Expect('unknown-prefix-with-manager', 'Yes|-1');
        Observer.Expect('unknown-prefix-with-manager|text', 'Namespace prefix ''z'' is not defined.');
        Observer.Expect('unknown-prefix-with-manager|code', 'Xml:XPath');
        Observer.Expect('default-ns-with-manager', 'Yes|1');
        Observer.Expect('default-ns-with-manager|text', '');
        Observer.Expect('default-ns-with-manager|code', '');
        Observer.Expect('default-ns-unprefixed', 'Yes|0');
        Observer.Expect('default-ns-unprefixed|text', '');
        Observer.Expect('default-ns-unprefixed|code', '');
        Observer.Expect('plain-with-manager', 'Yes|2');
        Observer.Expect('plain-with-manager|text', '');
        Observer.Expect('plain-with-manager|code', '');
        Observer.Expect('star-with-manager', 'Yes|5');
        Observer.Expect('star-with-manager|text', '');
        Observer.Expect('star-with-manager|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure MalformedPaths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Probe(Observer, 'at-at-at', '/r/@@@', false);
        Probe(Observer, 'trailing-slash', '/r/', false);
        Probe(Observer, 'unclosed-bracket', '/r/a[', false);
        Probe(Observer, 'empty-path', '', false);
        Probe(Observer, 'only-spaces', '   ', false);
        Probe(Observer, 'triple-slash', '///a', false);
        Probe(Observer, 'bad-function', '/r/a[nofn()]', false);
        Probe(Observer, 'number-result', '1+1', false);
        Probe(Observer, 'string-result', 'concat(''a'',''b'')', false);
        Probe(Observer, 'unclosed-quote', '/r/a[@id=''1]', false);
        Observer.Expect('at-at-at', 'Yes|-1');
        Observer.Expect('at-at-at|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('at-at-at|code', 'Xml:XPath');
        Observer.Expect('trailing-slash', 'Yes|-1');
        Observer.Expect('trailing-slash|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('trailing-slash|code', 'Xml:XPath');
        Observer.Expect('unclosed-bracket', 'Yes|-1');
        Observer.Expect('unclosed-bracket|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('unclosed-bracket|code', 'Xml:XPath');
        Observer.Expect('empty-path', 'Yes|-1');
        Observer.Expect('empty-path|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('empty-path|code', 'Xml:XPath');
        Observer.Expect('only-spaces', 'Yes|-1');
        Observer.Expect('only-spaces|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('only-spaces|code', 'Xml:XPath');
        Observer.Expect('triple-slash', 'Yes|-1');
        Observer.Expect('triple-slash|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('triple-slash|code', 'Xml:XPath');
        Observer.Expect('bad-function', 'Yes|-1');
        Observer.Expect('bad-function|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('bad-function|code', 'Xml:XPath');
        Observer.Expect('number-result', 'Yes|0');
        Observer.Expect('number-result|text', '');
        Observer.Expect('number-result|code', '');
        Observer.Expect('string-result', 'Yes|0');
        Observer.Expect('string-result|text', '');
        Observer.Expect('string-result|code', '');
        Observer.Expect('unclosed-quote', 'Yes|-1');
        Observer.Expect('unclosed-quote|text', 'This is an unclosed string.');
        Observer.Expect('unclosed-quote|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingleNode_And_Elements()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        R: XmlElement;
    begin
        Setup();
        Observer.Observe('single-hit', Format(Doc.SelectSingleNode('/r/a[2]', N)));
        Observer.Observe('single-hit-text', N.AsXmlElement().InnerText());
        Observer.Observe('single-miss', Format(Doc.SelectSingleNode('/r/zz', N)));
        Observer.Observe('single-first-of-many', Format(Doc.SelectSingleNode('/r/a', N)));
        Observer.Observe('single-first-of-many-text', N.AsXmlElement().InnerText());
        Doc.GetRoot(R);
        Observer.Observe('element-select', Format(R.SelectNodes('a', Nodes)));
        Observer.Observe('element-select-count', Format(Nodes.Count()));
        Observer.Observe('element-select-dotslash', Format(R.SelectNodes('./a/b', Nodes)));
        Observer.Observe('element-select-dotslash-count', Format(Nodes.Count()));
        Observer.Observe('element-select-absolute', Format(R.SelectNodes('/r/a', Nodes)));
        Observer.Observe('element-select-absolute-count', Format(Nodes.Count()));
        Observer.Expect('single-hit', 'Yes');
        Observer.Expect('single-hit-text', 't2');
        Observer.Expect('single-miss', 'No');
        Observer.Expect('single-first-of-many', 'Yes');
        Observer.Expect('single-first-of-many-text', 't1');
        Observer.Expect('element-select', 'Yes');
        Observer.Expect('element-select-count', '2');
        Observer.Expect('element-select-dotslash', 'Yes');
        Observer.Expect('element-select-dotslash-count', '2');
        Observer.Expect('element-select-absolute', 'Yes');
        Observer.Expect('element-select-absolute-count', '2');
        Observer.Verify();
    end;
}
