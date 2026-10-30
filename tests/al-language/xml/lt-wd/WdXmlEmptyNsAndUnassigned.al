// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattributecollection/xmlattributecollection-set-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90720
// Probe: written against al-runner issue 6303; every value asserted below is what the BC service tier produced.
// Facts: (1) XmlAttributeCollection.Set(Name, '', Value) and XmlElement.SetAttribute(Name, '', Value) compared with the two-argument forms: the serialized element,
//        replacing an existing attribute, and the attribute's namespace URI.
//        (2) an XmlNode / XmlElement variable that was never assigned, passed as content to Add, AddFirst, AddAfterSelf and AddBeforeSelf: whether an error is raised, its text and code.
// BC versions: 27, 28, 29

codeunit 90720 "LT WD Xml Empty Ns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_XmlAttrCollection_Set_EmptyNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Attrs: XmlAttributeCollection;
        Attr: XmlAttribute;
        Xml: Text;
    begin
        Root := XmlElement.Create('root');
        Doc := XmlDocument.Create();
        Doc.Add(Root);
        Attrs := Root.Attributes();
        Attrs.Set('kind', '', 'a');
        Root.WriteTo(Xml);
        Observer.Observe('after Set with empty namespace', Xml);
        Observer.Observe('count', Format(Attrs.Count()));
        Attrs.Set('kind', '', 'b');
        Root.WriteTo(Xml);
        Observer.Observe('after Set again', Xml);
        Observer.Observe('count again', Format(Attrs.Count()));
        Attrs.Set('kind', 'c');
        Root.WriteTo(Xml);
        Observer.Observe('after two-argument Set', Xml);
        Attrs.Get('kind', Attr);
        Observer.Observe('namespace uri', Attr.NamespaceUri());
        Observer.Observe('value', Attr.Value());
        Observer.Observe('Get with empty namespace', Format(Attrs.Get('kind', '', Attr)));
        Observer.Observe('Contains with empty namespace', Format(Attrs.Contains('kind', '')));
        Observer.Finish();
    end;

    [Test]
    procedure WD_XmlElement_SetAttribute_EmptyNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        Xml: Text;
    begin
        Root := XmlElement.Create('root');
        Root.SetAttribute('kind', '', 'a');
        Root.WriteTo(Xml);
        Observer.Observe('SetAttribute with empty namespace', Xml);
        Root.SetAttribute('kind', 'b');
        Root.WriteTo(Xml);
        Observer.Observe('then two-argument SetAttribute', Xml);
        Observer.Finish();
    end;

    [Test]
    procedure WD_XmlNode_Unassigned_AsContent()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        NewNode: XmlNode;
        Xml: Text;
    begin
        Root := XmlElement.Create('root');
        Child := XmlElement.Create('child');
        Root.Add(Child);
        Doc := XmlDocument.Create();
        Doc.Add(Root);
        asserterror Child.AddAfterSelf(NewNode);
        Observer.ObserveError('AddAfterSelf');
        asserterror Child.AddBeforeSelf(NewNode);
        Observer.ObserveError('AddBeforeSelf');
        asserterror Root.Add(NewNode);
        Observer.ObserveError('Add');
        asserterror Root.AddFirst(NewNode);
        Observer.ObserveError('AddFirst');
        Doc.WriteTo(Xml);
        Observer.Observe('document after the failed calls', Xml);
        Observer.Finish();
    end;

    [Test]
    procedure WD_XmlElement_Unassigned_AsContent()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        Child: XmlElement;
        Unassigned: XmlElement;
        Xml: Text;
    begin
        Root := XmlElement.Create('root');
        Child := XmlElement.Create('child');
        Root.Add(Child);
        asserterror Child.AddAfterSelf(Unassigned);
        Observer.ObserveError('AddAfterSelf');
        asserterror Root.Add(Unassigned);
        Observer.ObserveError('Add');
        Root.WriteTo(Xml);
        Observer.Observe('root after the failed calls', Xml);
        Observer.Finish();
    end;
}
