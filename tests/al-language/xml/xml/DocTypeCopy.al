// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType and XmlDeclaration copy semantics: assignment, parameters, document clone and reuse
// BC versions: 29 (27 and 28 by CI)

codeunit 72085 "LT P83 DocType Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Dt: XmlDocumentType): Text
    begin
        exit('[' + GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt) + ']');
    end;

    local procedure RenameByValue(Dt: XmlDocumentType)
    begin
        Dt.SetName('byvalue');
    end;

    local procedure RenameByVar(var Dt: XmlDocumentType)
    begin
        Dt.SetName('byvar');
    end;

    local procedure ReplaceByVar(var Dt: XmlDocumentType)
    begin
        Dt := XmlDocumentType.Create('replaced', '', '', '');
    end;

    local procedure GName(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetName(R);
        exit(R);
    end;

    local procedure GPub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetPublicId(R);
        exit(R);
    end;

    local procedure GSys(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetSystemId(R);
        exit(R);
    end;

    local procedure GSub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetInternalSubset(R);
        exit(R);
    end;

    [Test]
    procedure Assignment_SharesTheNode()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlDocumentType;
        B: XmlDocumentType;
    begin
        A := XmlDocumentType.Create('a', 'p', 's', 'i');
        B := A;
        B.SetName('changed');
        B.SetPublicId('pp');
        B.SetSystemId('ss');
        B.SetInternalSubset('ii');
        Observer.Observe('a', Describe(A));
        Observer.Observe('b', Describe(B));
        A := XmlDocumentType.Create('fresh', '', '', '');
        Observer.Observe('a-reassigned', Describe(A));
        Observer.Observe('b-kept', Describe(B));
        Observer.Expect('a', '[changed|pp|ss|ii]');
        Observer.Expect('b', '[changed|pp|ss|ii]');
        Observer.Expect('a-reassigned', '[fresh|||]');
        Observer.Expect('b-kept', '[changed|pp|ss|ii]');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_ByValueAndByVar()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlDocumentType;
    begin
        A := XmlDocumentType.Create('a', '', '', '');
        RenameByValue(A);
        Observer.Observe('by-value', Describe(A));
        RenameByVar(A);
        Observer.Observe('by-var', Describe(A));
        ReplaceByVar(A);
        Observer.Observe('replaced-by-var', Describe(A));
        Observer.Expect('by-value', '[byvalue|||]');
        Observer.Expect('by-var', '[byvar|||]');
        Observer.Expect('replaced-by-var', '[replaced|||]');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentHoldsTheSameNode()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        A: XmlDocumentType;
        Got: XmlDocumentType;
        T: Text;
    begin
        A := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(A);
        Doc.Add(XmlElement.Create('a'));
        A.SetSystemId('later.dtd');
        Doc.WriteTo(T);
        Observer.Observe('after-set', T);
        Doc.GetDocumentType(Got);
        Got.SetName('b');
        Observer.Observe('original-name', GName(A));
        Doc.WriteTo(T);
        Observer.Observe('after-rename', T);
        Observer.Expect('after-set', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE a PUBLIC "" "later.dtd"[]>\r\n<a />');
        Observer.Expect('original-name', 'b');
        Observer.Expect('after-rename', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE b PUBLIC "" "later.dtd"[]>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentAssignment_AndClone()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Doc2: XmlDocument;
        Got: XmlDocumentType;
        T: Text;
    begin
        Doc := XmlDocument.Create(XmlDocumentType.Create('a', '', '', ''));
        Doc.Add(XmlElement.Create('a'));
        Doc2 := Doc;
        Doc2.GetDocumentType(Got);
        Got.SetName('shared');
        Doc.WriteTo(T);
        Observer.Observe('assigned-copy', T);
        Doc2 := Doc.AsXmlNode().AsXmlDocument();
        Doc2.GetDocumentType(Got);
        Got.SetName('viaNode');
        Doc.WriteTo(T);
        Observer.Observe('via-node', T);
        Observer.Expect('assigned-copy', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE shared PUBLIC "" ""[]>\r\n<a />');
        Observer.Expect('via-node', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE viaNode PUBLIC "" ""[]>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentReadTwice_TypeIsReplaced()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Got: XmlDocumentType;
    begin
        XmlDocument.ReadFrom('<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>', Doc);
        Observer.Observe('first', Format(Doc.GetDocumentType(Got)));
        XmlDocument.ReadFrom('<a/>', Doc);
        Observer.Observe('second', Format(Doc.GetDocumentType(Got)));
        asserterror Observer.Observe('kept-name', GName(Got));
        Observer.ObserveError('af160');
        Observer.Expect('first', 'No');
        Observer.Expect('second', 'No');
        Observer.Expect('af160|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType variable not initialized.');
        Observer.Expect('af160|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure TypeOutlivesItsDocument()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        A: XmlDocumentType;
        T: Text;
    begin
        A := XmlDocumentType.Create('a', 'p', 's', 'i');
        Doc := XmlDocument.Create(A);
        Doc.Add(XmlElement.Create('a'));
        Clear(Doc);
        Observer.Observe('after-clear', Describe(A));
        A.WriteTo(T);
        Observer.Observe('written', T);
        Doc := XmlDocument.Create();
        Observer.Observe('add-again', Format(TryAdd(Doc, A)));
        Observer.ObserveError('add-again');
        Observer.Expect('after-clear', '[a|p|s|i]');
        Observer.Expect('written', '<!DOCTYPE a PUBLIC "p" "s"[i]>');
        Observer.Expect('add-again', 'Yes');
        Observer.Expect('add-again|text', '');
        Observer.Expect('add-again|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAdd(D: XmlDocument; A: XmlDocumentType)
    begin
        D.Add(A);
    end;

    [Test]
    procedure Declaration_CopySemantics()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlDeclaration;
        B: XmlDeclaration;
        Doc: XmlDocument;
        Got: XmlDeclaration;
        T: Text;
    begin
        A := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        B := A;
        B.Standalone('no');
        Observer.Observe('assigned', A.Standalone());
        Doc := XmlDocument.Create(A);
        Doc.Add(XmlElement.Create('a'));
        A.Encoding('utf-16');
        Doc.WriteTo(T);
        Observer.Observe('doc-after-change', T);
        Doc.GetDeclaration(Got);
        Got.Version('1.1');
        Observer.Observe('original-version', A.Version());
        Observer.Expect('assigned', 'no');
        Observer.Expect('doc-after-change', '<?xml version="1.0" encoding="utf-16" standalone="no"?>\r\n<a />');
        Observer.Expect('original-version', '1.1');
        Observer.Verify();
    end;
}
