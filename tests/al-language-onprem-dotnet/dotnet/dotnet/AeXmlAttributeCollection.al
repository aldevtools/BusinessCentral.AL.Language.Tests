// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlattributecollection
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99002
// Probe: al-runtime-rs corpus topic 203 item 5 (corpus issue 632): the legacy DotNet System.Xml.XmlAttributeCollection of a node loaded from <a x="1"/>:
//   ItemOf by name, by index, by a missing name and a missing index, Count, Value and InnerText of the attribute, Item(index), and the exception text for each miss.
// RISKY (compile): the AL member names ItemOf / Item / Count of the collection.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtAeXDoc) { }
        type("System.Xml.XmlAttributeCollection"; LtAeXAttrs) { }
        type("System.Xml.XmlAttribute"; LtAeXAttr) { }
        type("System.Xml.XmlElement"; LtAeXElem) { }
    }
}

codeunit 99002 "LT AE XmlAttributeCollection"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(var Doc: DotNet LtAeXDoc; var Attrs: DotNet LtAeXAttrs; Xml: Text)
    var
        Elem: DotNet LtAeXElem;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml(Xml);
        Elem := Doc.DocumentElement();
        Attrs := Elem.Attributes();
    end;

    [Test]
    procedure Attributes_Count_ItemOfName()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
    begin
        Load(Doc, Attrs, '<a x="1"/>');
        Observer.Observe('count', Format(Attrs.Count()));
        Attr := Attrs.ItemOf('x');
        Observer.Observe('name null', Format(IsNull(Attr)));
        Observer.Observe('name', Attr.Name());
        Observer.Observe('value', Attr.Value());
        Observer.Observe('innertext', Attr.InnerText());
        Observer.Expect('count', '1');
        Observer.Expect('name null', 'No');
        Observer.Expect('name', 'x');
        Observer.Expect('value', '1');
        Observer.Expect('innertext', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Attributes_ItemOfIndex_And_ItemIndex()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
    begin
        Load(Doc, Attrs, '<a x="1" y="two"/>');
        Observer.Observe('count', Format(Attrs.Count()));
        Attr := Attrs.ItemOf(0);
        Observer.Observe('index 0', Attr.Name() + '=' + Attr.Value());
        Attr := Attrs.ItemOf(1);
        Observer.Observe('index 1', Attr.Name() + '=' + Attr.Value());
        Attr := Attrs.Item(1);
        Observer.Observe('Item(1)', Attr.Name() + '=' + Attr.Value());
        Observer.Expect('count', '2');
        Observer.Expect('index 0', 'x=1');
        Observer.Expect('index 1', 'y=two');
        Observer.Expect('Item(1)', 'y=two');
        Observer.Verify();
    end;

    [Test]
    procedure Attributes_MissingName()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
    begin
        Load(Doc, Attrs, '<a x="1"/>');
        Attr := Attrs.ItemOf('nope');
        Observer.Observe('missing name null', Format(IsNull(Attr)));
        Attr := Attrs.ItemOf('X');
        Observer.Observe('wrong case null', Format(IsNull(Attr)));
        Observer.Expect('missing name null', 'Yes');
        Observer.Expect('wrong case null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Attributes_MissingIndex_Error()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
    begin
        Load(Doc, Attrs, '<a x="1"/>');
        asserterror Attr := Attrs.ItemOf(5);
        Observer.ObserveError('index 5');
        asserterror Attr := Attrs.ItemOf(-1);
        Observer.ObserveError('index -1');
        Attr := Attrs.Item(5);
        Observer.Observe('Item(5) null', Format(IsNull(Attr)));
        Observer.Expect('index 5|text', 'A call to System.Xml.XmlAttributeCollection.ItemOf failed with this message: The index being passed in is out of range.');
        Observer.Expect('index 5|code', 'DotNetInvoke:IndexOutOfRange');
        Observer.Expect('index -1|text', 'A call to System.Xml.XmlAttributeCollection.ItemOf failed with this message: The index being passed in is out of range.');
        Observer.Expect('index -1|code', 'DotNetInvoke:IndexOutOfRange');
        Observer.Expect('Item(5) null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Attributes_NoAttributes()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
    begin
        Load(Doc, Attrs, '<a/>');
        Observer.Observe('count', Format(Attrs.Count()));
        Attr := Attrs.ItemOf('x');
        Observer.Observe('null', Format(IsNull(Attr)));
        Observer.Expect('count', '0');
        Observer.Expect('null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Null_MemberAccess_Error()
    var
        Doc: DotNet LtAeXDoc;
        Attrs: DotNet LtAeXAttrs;
        Attr: DotNet LtAeXAttr;
        Value: Text;
    begin
        Load(Doc, Attrs, '<a x="1"/>');
        Attr := Attrs.ItemOf('nope');
        asserterror Value := Attr.Value();
        Observer.ObserveError('value of null');
        Observer.Expect('value of null|text', 'A DotNet variable has not been instantiated. Attempting to call System.Xml.XmlAttribute.Value in CodeUnit LT AE XmlAttributeCollection: Attribute_Null_MemberAccess_Error');
        Observer.Expect('value of null|code', 'DotNetVariableNotCreated');
        Observer.Verify();
    end;
}
