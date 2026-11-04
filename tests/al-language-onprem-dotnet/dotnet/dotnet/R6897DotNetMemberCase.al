// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99460
// Probe: al-runtime-rs issue 6897: a DotNet member written in another letter case than its .NET name (Base Application codeunit 1203
//   "Import XML File to Data Exch.", ParseParentChildLine, writes XmlElement.OuterXML for the .NET OuterXml). Method (LoadXml as loadxml and LOADXML),
//   property get (OuterXml as OuterXML), property set (InnerText as innertext) and a static method (Convert.ToInt32
//   as TOINT32), each next to its exact spelling. A public .NET field (String.Empty) does not compile in AL under any spelling (AL0132), so no field case.
// RISKY (compile): the AL member names written in another case than the .NET name.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtR6Doc) { }
        type("System.Xml.XmlElement"; LtR6Elem) { }
    }
    assembly("mscorlib")
    {
        type("System.Convert"; LtR6Convert) { }
    }
}

codeunit 99460 "LT R6897 DotNet Member Case"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Method_WrittenInAnotherCase_BindsToTheDotNetMethod()
    var
        Doc: DotNet LtR6Doc;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<a><b>x</b></a>');
        Observer.Observe('exact', Doc.OuterXml());
        Doc.loadxml('<a><b>lower</b></a>');
        Observer.Observe('lower', Doc.OuterXml());
        Doc.LOADXML('<a><b>upper</b></a>');
        Observer.Observe('upper', Doc.OuterXml());
        Observer.Expect('exact', '<a><b>x</b></a>');
        Observer.Expect('lower', '<a><b>lower</b></a>');
        Observer.Expect('upper', '<a><b>upper</b></a>');
        Observer.Verify();
    end;

    [Test]
    procedure PropertyGet_WrittenInAnotherCase_BindsToTheDotNetProperty()
    var
        Doc: DotNet LtR6Doc;
        Elem: DotNet LtR6Elem;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<a><b>x</b></a>');
        Elem := Doc.DocumentElement();
        Observer.Observe('exact', Elem.OuterXml);
        Observer.Observe('as OuterXML', Elem.OuterXML);
        Observer.Observe('as outerxml', Elem.outerxml);
        Observer.Observe('as OuterXML call', Elem.OuterXML());
        Observer.Expect('exact', '<a><b>x</b></a>');
        Observer.Expect('as OuterXML', '<a><b>x</b></a>');
        Observer.Expect('as outerxml', '<a><b>x</b></a>');
        Observer.Expect('as OuterXML call', '<a><b>x</b></a>');
        Observer.Verify();
    end;

    [Test]
    procedure PropertySet_WrittenInAnotherCase_BindsToTheDotNetProperty()
    var
        Doc: DotNet LtR6Doc;
        Elem: DotNet LtR6Elem;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<a>x</a>');
        Elem := Doc.DocumentElement();
        Elem.innertext := 'set lower';
        Observer.Observe('after innertext :=', Elem.InnerText);
        Elem.INNERTEXT := 'set upper';
        Observer.Observe('after INNERTEXT :=', Elem.InnerText);
        Elem.innertext('as call');
        Observer.Observe('after innertext(...)', Elem.InnerText);
        Observer.Expect('after innertext :=', 'set lower');
        Observer.Expect('after INNERTEXT :=', 'set upper');
        Observer.Expect('after innertext(...)', 'as call');
        Observer.Verify();
    end;

    [Test]
    procedure StaticMethod_WrittenInAnotherCase_BindsToTheDotNetMethod()
    var
        Conv: DotNet LtR6Convert;
    begin
        Observer.Observe('exact', Format(Conv.ToInt32('7')));
        Observer.Observe('as TOINT32', Format(Conv.TOINT32('8')));
        Observer.Observe('as toint32', Format(Conv.toint32('9')));
        Observer.Expect('exact', '7');
        Observer.Expect('as TOINT32', '8');
        Observer.Expect('as toint32', '9');
        Observer.Verify();
    end;
}
