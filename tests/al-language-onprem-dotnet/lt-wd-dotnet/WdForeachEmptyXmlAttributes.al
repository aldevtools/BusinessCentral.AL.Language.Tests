// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlattributecollection
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99345
// Probe: written against al-runner issue 6316. foreach over the DotNet System.Xml.XmlAttributeCollection of an element with no attributes, with one attribute and with three;
//        the same through XmlNodeList of an element without children (XML DOM Management.AddNamespaces loops over DocumentElement.Attributes).
//        Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtWdXDoc) { }
        type("System.Xml.XmlAttributeCollection"; LtWdXAttrs) { }
        type("System.Xml.XmlAttribute"; LtWdXAttr) { }
        type("System.Xml.XmlNodeList"; LtWdXNodes) { }
        type("System.Xml.XmlNode"; LtWdXNode) { }
    }
}

codeunit 99345 "LT WD Foreach Empty Xml Attrs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CountAttributes(Xml: Text; var Names: Text): Integer
    var
        XmlDoc: DotNet LtWdXDoc;
        Attributes: DotNet LtWdXAttrs;
        Attribute: DotNet LtWdXAttr;
        Counter: Integer;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.LoadXml(Xml);
        Attributes := XmlDoc.DocumentElement.Attributes;
        Names := '';
        foreach Attribute in Attributes do begin
            Counter += 1;
            Names += Attribute.Name + ';';
        end;
        exit(Counter);
    end;

    [Test]
    procedure WD_Foreach_XmlAttributeCollection()
    var
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        Observer.Observe('no attributes: count', Format(CountAttributes('<root/>', Names)));
        Observer.Observe('no attributes: names', Names);
        Observer.Observe('one attribute: count', Format(CountAttributes('<root a="1"/>', Names)));
        Observer.Observe('one attribute: names', Names);
        Observer.Observe('three attributes: count', Format(CountAttributes('<root a="1" b="2" xmlns:p="urn:p"/>', Names)));
        Observer.Observe('three attributes: names', Names);
        Observer.Finish();
    end;

    [Test]
    procedure WD_Foreach_XmlNodeList_NoChildren()
    var
        Observer: Codeunit "Probe Observer";
        XmlDoc: DotNet LtWdXDoc;
        Nodes: DotNet LtWdXNodes;
        Node: DotNet LtWdXNode;
        Counter: Integer;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.LoadXml('<root/>');
        Nodes := XmlDoc.DocumentElement.ChildNodes;
        foreach Node in Nodes do
            Counter += 1;
        Observer.Observe('empty element: child count', Format(Counter));
        Observer.Finish();
    end;
}
