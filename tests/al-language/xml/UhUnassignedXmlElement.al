// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43643688944); the values are the same on all three.
// Facts: what each member of an XmlElement variable that nothing assigned does (a value, or the error text and code). Every member has its own
//   test. Repro of aldevtools/BusinessCentral.AL.Runner#7760 (comment of 2026-11-14, the XmlElement cells).
// Result: every member of an unassigned XmlElement fails with "<Nav type> variable not initialized." (code NotInitialized); the type in the
//   text is the handle the member goes through: NavXmlElement, NavXmlAttributeCollection (SetAttribute, Attributes, HasAttributes) or NavXmlNode
//   (AsXmlNode, WriteTo, Remove).
// BC versions: 27.5, 28.5, 29.0

codeunit 66992 "LT UH Unassigned XmlElement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try(Step: Text; var Result: Text)
    var
        E: XmlElement;
        N: XmlNode;
        T: Text;
        Attr: XmlAttributeCollection;
        Nodes: XmlNodeList;
        B: Boolean;
    begin
        case Step of
            'innerxml':
                Result := E.InnerXml();
            'setattribute':
                begin
                    E.SetAttribute('a', 'b');
                    Result := 'done';
                end;
            'getchildelements':
                begin
                    Nodes := E.GetChildElements();
                    Result := Format(Nodes.Count());
                end;
            'attributes':
                begin
                    Attr := E.Attributes();
                    Result := Format(Attr.Count());
                end;
            'asxmlnode':
                begin
                    N := E.AsXmlNode();
                    N.WriteTo(T);
                    Result := T;
                end;
            'name':
                Result := E.Name();
            'innertext':
                Result := E.InnerText();
            'add':
                begin
                    E.Add(XmlText.Create('x'));
                    Result := 'done';
                end;
            'writeto':
                begin
                    E.WriteTo(T);
                    Result := T;
                end;
            'getchildnodes':
                begin
                    Nodes := E.GetChildNodes();
                    Result := Format(Nodes.Count());
                end;
            'hasattributes':
                Result := Format(E.Attributes().Count() > 0);
            'isempty':
                Result := Format(E.IsEmpty());
            'remove':
                begin
                    E.Remove();
                    Result := 'done';
                end;
        end;
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Step: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if Try(Step, Result) then
            Observer.Observe('result', 'ok:' + Result)
        else
            Observer.Observe('result', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Unassigned_InnerXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'innerxml');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_SetAttribute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'setattribute');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlAttributeCollection variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_GetChildElements()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'getchildelements');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_Attributes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'attributes');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlAttributeCollection variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_AsXmlNode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'asxmlnode');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'name');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_InnerText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'innertext');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_Add()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'add');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_WriteTo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'writeto');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_GetChildNodes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'getchildnodes');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_HasAttributes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'hasattributes');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlAttributeCollection variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_IsEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'isempty');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_Remove()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'remove');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.|NotInitialized');
        Observer.Verify();
    end;
}
