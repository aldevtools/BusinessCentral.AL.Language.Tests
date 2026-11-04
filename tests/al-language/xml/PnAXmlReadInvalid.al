// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: ReadFrom of invalid XML returns false when the result is used
// Facts: XmlDocument.ReadFrom of invalid text: result used, statement form (error text, code, line and position)
// BC versions: 29 (27 and 28 by CI)

codeunit 70085 "LT PnA Xml ReadInvalid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        XmlDocument.ReadFrom(Src, Doc);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    begin
        Observer.Observe(Name + '-used', Format(XmlDocument.ReadFrom(Src, Doc)));
        Observer.Observe(Name + '-stmt', Format(TryRead(Src)));
        Observer.ObserveError(Name + '-stmt');
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure Invalid_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'unclosed', '<a>');
        Probe(Observer, 'mismatch', '<a></b>');
        Probe(Observer, 'empty', '');
        Probe(Observer, 'plain-text', 'x');
        Probe(Observer, 'unquoted-attribute', '<a b=1/>');
        Probe(Observer, 'two-roots', '<a/><b/>');
        Probe(Observer, 'unknown-entity', '<a>&bogus;</a>');
        Probe(Observer, 'bare-ampersand', '<a>a & b</a>');
        Probe(Observer, 'lt-in-text', '<a>a < b</a>');
        Probe(Observer, 'duplicate-attribute', '<a b="1" b="2"/>');
        Probe(Observer, 'unbound-prefix', '<p:a/>');
        Probe(Observer, 'only-declaration', '<?xml version="1.0"?>');
        Probe(Observer, 'declaration-not-first', ' <?xml version="1.0"?><a/>');
        Probe(Observer, 'bad-version', '<?xml version="9.9"?><a/>');
        Probe(Observer, 'unknown-encoding', '<?xml version="1.0" encoding="bogus"?><a/>');
        Probe(Observer, 'text-before-root', 'x<a/>');
        Probe(Observer, 'text-after-root', '<a/>x');
        Observer.Expect('unclosed-used', 'No');
        Observer.Expect('unclosed-stmt', 'No');
        Observer.Expect('unclosed-stmt|text', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Expect('unclosed-stmt|code', 'Xml:Xml');
        Observer.Expect('mismatch-used', 'No');
        Observer.Expect('mismatch-stmt', 'No');
        Observer.Expect('mismatch-stmt|text', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('mismatch-stmt|code', 'Xml:Xml');
        Observer.Expect('empty-used', 'No');
        Observer.Expect('empty-stmt', 'No');
        Observer.Expect('empty-stmt|text', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0.');
        Observer.Expect('empty-stmt|code', 'Xml:Xml');
        Observer.Expect('plain-text-used', 'No');
        Observer.Expect('plain-text-stmt', 'No');
        Observer.Expect('plain-text-stmt|text', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Expect('plain-text-stmt|code', 'Xml:Xml');
        Observer.Expect('unquoted-attribute-used', 'No');
        Observer.Expect('unquoted-attribute-stmt', 'No');
        Observer.Expect('unquoted-attribute-stmt|text', 'The following exception was encountered when processing XML data: ''''1'' is an unexpected token. The expected token is ''"'' or ''''''. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('unquoted-attribute-stmt|code', 'Xml:Xml');
        Observer.Expect('two-roots-used', 'No');
        Observer.Expect('two-roots-stmt', 'No');
        Observer.Expect('two-roots-stmt|text', 'The following exception was encountered when processing XML data: ''There are multiple root elements. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('two-roots-stmt|code', 'Xml:Xml');
        Observer.Expect('unknown-entity-used', 'No');
        Observer.Expect('unknown-entity-stmt', 'No');
        Observer.Expect('unknown-entity-stmt|text', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''bogus''. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Expect('unknown-entity-stmt|code', 'Xml:Xml');
        Observer.Expect('bare-ampersand-used', 'No');
        Observer.Expect('bare-ampersand-stmt', 'No');
        Observer.Expect('bare-ampersand-stmt|text', 'The following exception was encountered when processing XML data: ''An error occurred while parsing EntityName. Line 1, position 7.'' at line 1 and position 7.');
        Observer.Expect('bare-ampersand-stmt|code', 'Xml:Xml');
        Observer.Expect('lt-in-text-used', 'No');
        Observer.Expect('lt-in-text-stmt', 'No');
        Observer.Expect('lt-in-text-stmt|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the '' '' character, hexadecimal value 0x20. Line 1, position 7.'' at line 1 and position 7.');
        Observer.Expect('lt-in-text-stmt|code', 'Xml:Xml');
        Observer.Expect('duplicate-attribute-used', 'No');
        Observer.Expect('duplicate-attribute-stmt', 'No');
        Observer.Expect('duplicate-attribute-stmt|text', 'The following exception was encountered when processing XML data: ''''b'' is a duplicate attribute name. Line 1, position 10.'' at line 1 and position 10.');
        Observer.Expect('duplicate-attribute-stmt|code', 'Xml:Xml');
        Observer.Expect('unbound-prefix-used', 'No');
        Observer.Expect('unbound-prefix-stmt', 'No');
        Observer.Expect('unbound-prefix-stmt|text', 'The following exception was encountered when processing XML data: ''''p'' is an undeclared prefix. Line 1, position 2.'' at line 1 and position 2.');
        Observer.Expect('unbound-prefix-stmt|code', 'Xml:Xml');
        Observer.Expect('only-declaration-used', 'No');
        Observer.Expect('only-declaration-stmt', 'No');
        Observer.Expect('only-declaration-stmt|text', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0.');
        Observer.Expect('only-declaration-stmt|code', 'Xml:Xml');
        Observer.Expect('declaration-not-first-used', 'No');
        Observer.Expect('declaration-not-first-stmt', 'No');
        Observer.Expect('declaration-not-first-stmt|text', 'The following exception was encountered when processing XML data: ''Unexpected XML declaration. The XML declaration must be the first node in the document, and no whitespace characters are allowed to appear before it. Line 1, position 4.'' at line 1 and position 4.');
        Observer.Expect('declaration-not-first-stmt|code', 'Xml:Xml');
        Observer.Expect('bad-version-used', 'No');
        Observer.Expect('bad-version-stmt', 'No');
        Observer.Expect('bad-version-stmt|text', 'The following exception was encountered when processing XML data: ''Version number ''9.9'' is invalid. Line 1, position 16.'' at line 1 and position 16.');
        Observer.Expect('bad-version-stmt|code', 'Xml:Xml');
        Observer.Expect('unknown-encoding-used', 'Yes');
        Observer.Expect('unknown-encoding-stmt', 'Yes');
        Observer.Expect('unknown-encoding-stmt|text', '');
        Observer.Expect('unknown-encoding-stmt|code', '');
        Observer.Expect('text-before-root-used', 'No');
        Observer.Expect('text-before-root-stmt', 'No');
        Observer.Expect('text-before-root-stmt|text', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Expect('text-before-root-stmt|code', 'Xml:Xml');
        Observer.Expect('text-after-root-used', 'No');
        Observer.Expect('text-after-root-stmt', 'No');
        Observer.Expect('text-after-root-stmt|text', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Expect('text-after-root-stmt|code', 'Xml:Xml');
        Observer.Verify();
    end;





    [Test]
    procedure Invalid_LineAndPosition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'line1', '<a></b>');
        Probe(Observer, 'line2', '<a>' + Lf() + '</b>');
        Probe(Observer, 'line3-indented', '<a>' + Lf() + '<b>' + Lf() + '   </c></b></a>');
        Probe(Observer, 'crlf-counting', '<a>' + Lf() + Lf() + '</b>');
        Probe(Observer, 'long-line', '<a>' + PadStr('', 50, 'x') + '</b>');
        Observer.Expect('line1-used', 'No');
        Observer.Expect('line1-stmt', 'No');
        Observer.Expect('line1-stmt|text', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('line1-stmt|code', 'Xml:Xml');
        Observer.Expect('line2-used', 'No');
        Observer.Expect('line2-stmt', 'No');
        Observer.Expect('line2-stmt|text', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 2, position 3.'' at line 2 and position 3.');
        Observer.Expect('line2-stmt|code', 'Xml:Xml');
        Observer.Expect('line3-indented-used', 'No');
        Observer.Expect('line3-indented-stmt', 'No');
        Observer.Expect('line3-indented-stmt|text', 'The following exception was encountered when processing XML data: ''The ''b'' start tag on line 2 position 2 does not match the end tag of ''c''. Line 3, position 6.'' at line 3 and position 6.');
        Observer.Expect('line3-indented-stmt|code', 'Xml:Xml');
        Observer.Expect('crlf-counting-used', 'No');
        Observer.Expect('crlf-counting-stmt', 'No');
        Observer.Expect('crlf-counting-stmt|text', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 3, position 3.'' at line 3 and position 3.');
        Observer.Expect('crlf-counting-stmt|code', 'Xml:Xml');
        Observer.Expect('long-line-used', 'No');
        Observer.Expect('long-line-stmt', 'No');
        Observer.Expect('long-line-stmt|text', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 1, position 56.'' at line 1 and position 56.');
        Observer.Expect('long-line-stmt|code', 'Xml:Xml');
        Observer.Verify();
    end;
}
