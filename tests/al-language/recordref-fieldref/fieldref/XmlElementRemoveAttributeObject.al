// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-removeattribute-method
// Scope: in-scope
// Fixtures used: Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlElement.RemoveAttribute(Attribute: XmlAttribute) for an attribute of the element, an attribute of another element and an attribute already removed; element text and result
// BC versions: 29 (27 and 28 by CI)

codeunit 71730 "LT XML RemoveAttr Obj"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(E: XmlElement): Text
    var
        Txt: Text;
    begin
        E.WriteTo(Txt);
        exit(Txt);
    end;

    [Test]
    procedure RemoveAttribute_ByObject()
    var
        Observer: Codeunit "Probe Observer";
        E1: XmlElement;
        E2: XmlElement;
        A1: XmlAttribute;
        A2: XmlAttribute;
        Free: XmlAttribute;
    begin
        E1 := XmlElement.Create('a');
        E1.SetAttribute('k1', 'v1');
        E1.SetAttribute('k2', 'v2');
        E2 := XmlElement.Create('b');
        E2.SetAttribute('k1', 'w1');
        E1.Attributes().Get('k1', A1);
        E2.Attributes().Get('k1', A2);
        E1.RemoveAttribute(A1);
        Observer.Observe('after_remove_own', Show(E1));
        Observer.Observe('other_untouched', Show(E2));
        E1.RemoveAttribute(A1);
        Observer.Observe('after_remove_again', Show(E1));
        E1.RemoveAttribute(A2);
        Observer.Observe('after_remove_foreign', Show(E1));
        Observer.Observe('other_after_foreign', Show(E2));
        Free := XmlAttribute.Create('k2', 'v2');
        E1.RemoveAttribute(Free);
        Observer.Observe('after_remove_detached_same_name', Show(E1));
        Observer.Observe('has_k1', Format(E1.Attributes().Count()));
        Observer.Expect('after_remove_own', '<a k2="v2" />');
        Observer.Expect('other_untouched', '<b k1="w1" />');
        Observer.Expect('after_remove_again', '<a k2="v2" />');
        Observer.Expect('after_remove_foreign', '<a k2="v2" />');
        Observer.Expect('other_after_foreign', '<b k1="w1" />');
        Observer.Expect('after_remove_detached_same_name', '<a />');
        Observer.Expect('has_k1', '0');
        Observer.Verify();
    end;
}
