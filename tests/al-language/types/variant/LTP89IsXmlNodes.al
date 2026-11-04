// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74635 "LT P89 Is Xml Nodes"
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
    procedure Node_FromEachKind()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XDoc: XmlDocument;
        XEl: XmlElement;
        XAttr: XmlAttribute;
        XCom: XmlComment;
        XTx: XmlText;
        XCd: XmlCData;
        XPi: XmlProcessingInstruction;
        XN: XmlNode;
    begin
        XDoc := XmlDocument.Create();
        XN := XDoc.AsXmlNode();
        V := XN; Observer.Observe('document_node', Flags(V));
        XEl := XmlElement.Create('root');
        XN := XEl.AsXmlNode();
        V := XN; Observer.Observe('element_node', Flags(V));
        XAttr := XmlAttribute.Create('n', 'v');
        XN := XAttr.AsXmlNode();
        V := XN; Observer.Observe('attribute_node', Flags(V));
        XCom := XmlComment.Create('c');
        XN := XCom.AsXmlNode();
        V := XN; Observer.Observe('comment_node', Flags(V));
        XTx := XmlText.Create('t');
        XN := XTx.AsXmlNode();
        V := XN; Observer.Observe('text_node', Flags(V));
        XCd := XmlCData.Create('d');
        XN := XCd.AsXmlNode();
        V := XN; Observer.Observe('cdata_node', Flags(V));
        XPi := XmlProcessingInstruction.Create('t', 'd');
        XN := XPi.AsXmlNode();
        V := XN; Observer.Observe('pi_node', Flags(V));
        V := XN; Observer.Observe('node_default', Flags(V));
        Observer.Expect('document_node', 'XmlDocument,');
        Observer.Expect('element_node', 'XmlElement,');
        Observer.Expect('attribute_node', 'XmlAttribute,');
        Observer.Expect('comment_node', 'XmlComment,');
        Observer.Expect('text_node', 'XmlText,');
        Observer.Expect('cdata_node', 'XmlCData,');
        Observer.Expect('pi_node', 'XmlProcessingInstruction,');
        Observer.Expect('node_default', 'XmlProcessingInstruction,');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_AttributeCollection()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XEl: XmlElement;
        XChild: XmlElement;
        XList: XmlNodeList;
        XAttrs: XmlAttributeCollection;
    begin
        XEl := XmlElement.Create('root');
        XChild := XmlElement.Create('child');
        XEl.Add(XChild);
        XEl.SetAttribute('a', '1');
        XList := XEl.GetChildNodes();
        V := XList; Observer.Observe('childnodes', Flags(V));
        Observer.Observe('childnodes_count', Format(XList.Count()));
        XAttrs := XEl.Attributes();
        V := XAttrs; Observer.Observe('attributes', Flags(V));
        Observer.Observe('attributes_count', Format(XAttrs.Count()));
        XList := XEl.GetDescendantElements();
        V := XList; Observer.Observe('descendants', Flags(V));
        XList := XEl.GetChildElements();
        V := XList; Observer.Observe('childelements', Flags(V));
        Observer.Expect('childnodes', 'XmlNodeList,');
        Observer.Expect('childnodes_count', '1');
        Observer.Expect('attributes', 'XmlAttributeCollection,');
        Observer.Expect('attributes_count', '1');
        Observer.Expect('descendants', 'XmlNodeList,');
        Observer.Expect('childelements', 'XmlNodeList,');
        Observer.Verify();
    end;

    [Test]
    procedure NameTable_NamespaceManager()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XDoc: XmlDocument;
        XNt: XmlNameTable;
        XNs: XmlNamespaceManager;
    begin
        XDoc := XmlDocument.Create();
        XNt := XDoc.NameTable();
        V := XNt; Observer.Observe('nametable', Flags(V));
        XNs.NameTable(XNt);
        V := XNs; Observer.Observe('nsmanager', Flags(V));
        Observer.Expect('nametable', 'XmlNameTable,');
        Observer.Expect('nsmanager', 'XmlNamespaceManager,');
        Observer.Verify();
    end;

    [Test]
    procedure NodeVsSpecific_Casting()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XEl: XmlElement;
        XN: XmlNode;
        XTx: XmlText;
    begin
        XEl := XmlElement.Create('root');
        XEl.Add(XmlText.Create('hello'));
        V := XEl.AsXmlNode();
        Observer.Observe('as_node', Flags(V));
        XN := XEl.AsXmlNode();
        Observer.Observe('node_is_element', Format(XN.IsXmlElement()));
        Observer.Observe('node_is_text', Format(XN.IsXmlText()));
        Observer.Observe('node_is_document', Format(XN.IsXmlDocument()));
        Observer.Observe('node_is_attribute', Format(XN.IsXmlAttribute()));
        Observer.Observe('node_is_comment', Format(XN.IsXmlComment()));
        Observer.Observe('node_is_cdata', Format(XN.IsXmlCData()));
        Observer.Observe('node_is_pi', Format(XN.IsXmlProcessingInstruction()));
        Observer.Observe('node_is_declaration', Format(XN.IsXmlDeclaration()));
        Observer.Observe('node_is_doctype', Format(XN.IsXmlDocumentType()));
        Observer.Expect('as_node', 'XmlElement,');
        Observer.Expect('node_is_element', 'Yes');
        Observer.Expect('node_is_text', 'No');
        Observer.Expect('node_is_document', 'No');
        Observer.Expect('node_is_attribute', 'No');
        Observer.Expect('node_is_comment', 'No');
        Observer.Expect('node_is_cdata', 'No');
        Observer.Expect('node_is_pi', 'No');
        Observer.Expect('node_is_declaration', 'No');
        Observer.Expect('node_is_doctype', 'No');
        Observer.Verify();
    end;

}
