// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74636 "LT P89 Is Xml Near"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsXmlAttribute() then
            R += 'XmlAttribute,';
        if V.IsXmlAttributeCollection() then
            R += 'XmlAttributeCollection,';
        if V.IsXmlCData() then
            R += 'XmlCData,';
        if V.IsXmlComment() then
            R += 'XmlComment,';
        if V.IsXmlDeclaration() then
            R += 'XmlDeclaration,';
        if V.IsXmlDocument() then
            R += 'XmlDocument,';
        if V.IsXmlDocumentType() then
            R += 'XmlDocumentType,';
        if V.IsXmlElement() then
            R += 'XmlElement,';
        if V.IsXmlNameTable() then
            R += 'XmlNameTable,';
        if V.IsXmlNamespaceManager() then
            R += 'XmlNamespaceManager,';
        if V.IsXmlNode() then
            R += 'XmlNode,';
        if V.IsXmlNodeList() then
            R += 'XmlNodeList,';
        if V.IsXmlProcessingInstruction() then
            R += 'XmlProcessingInstruction,';
        if V.IsXmlText() then
            R += 'XmlText,';
        if V.IsXmlWriteOptions() then
            R += 'XmlWriteOptions,';
        if V.IsXmlReadOptions() then
            R += 'XmlReadOptions,';
        exit(R);
    end;

    [Test]
    procedure Near_TextWithXml()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        T: Text;
        I: Integer;
        XDoc: XmlDocument;
        XEl: XmlElement;
        XTx: XmlText;
        XTxt: Text;
    begin
        T := '<root/>'; V := T; Observer.Observe('text_with_xml', Flags(V));
        I := 1; V := I; Observer.Observe('integer', Flags(V));
        Observer.Observe('empty', Flags(V));
        Clear(V); Observer.Observe('cleared', Flags(V));
        XDoc := XmlDocument.Create();
        XEl := XmlElement.Create('root');
        XDoc.Add(XEl);
        XDoc.WriteTo(XTxt);
        V := XTxt; Observer.Observe('doc_written_text', Flags(V));
        V := XEl.Name(); Observer.Observe('element_name', Flags(V));
        XTx := XmlText.Create('x');
        V := XTx.Value(); Observer.Observe('text_value', Flags(V));
        Observer.Expect('text_with_xml', '');
        Observer.Expect('integer', '');
        Observer.Expect('empty', '');
        Observer.Expect('cleared', '');
        Observer.Expect('doc_written_text', '');
        Observer.Expect('element_name', '');
        Observer.Expect('text_value', '');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentVsElement_RootAndParents()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XDoc: XmlDocument;
        XEl: XmlElement;
        XN: XmlNode;
    begin
        XDoc := XmlDocument.Create();
        XEl := XmlElement.Create('root');
        XDoc.Add(XEl);
        XDoc.GetRoot(XEl);
        V := XEl; Observer.Observe('root_element', Flags(V));
        XN := XEl.AsXmlNode();
        XN.GetDocument(XDoc);
        V := XDoc; Observer.Observe('document_of_node', Flags(V));
        Observer.Expect('root_element', 'XmlElement,');
        Observer.Expect('document_of_node', 'XmlDocument,');
        Observer.Verify();
    end;

}
