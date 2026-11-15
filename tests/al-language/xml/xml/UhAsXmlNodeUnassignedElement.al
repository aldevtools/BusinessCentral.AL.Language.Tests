// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-asxmlnode-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observe form, written for aldevtools/BusinessCentral.AL.Runner#8157; the values come from this pull request's CI run.
// Facts: what XmlElement.AsXmlNode() does on an XmlElement variable that nothing assigned (and on one that was cleared), and what the
//   XmlNode it returns does: IsXmlElement, AsXmlElement and WriteTo(Text). UhUnassignedXmlElement.al (codeunit 66992) measures
//   AsXmlNode and WriteTo in one step, so it does not show which of the two calls raises; this file measures them one by one.
// BC versions: 27.5, 28.5, 29.0

codeunit 66997 "LT UH AsXmlNode Unassigned"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try(Step: Text; var Result: Text)
    var
        E: XmlElement;
        E2: XmlElement;
        N: XmlNode;
        T: Text;
    begin
        case Step of
            'asxmlnode':
                begin
                    N := E.AsXmlNode();
                    Result := 'done';
                end;
            'isxmlelement':
                begin
                    N := E.AsXmlNode();
                    Result := Format(N.IsXmlElement());
                end;
            'asxmlelement':
                begin
                    N := E.AsXmlNode();
                    E2 := N.AsXmlElement();
                    Result := 'done';
                end;
            'writeto':
                begin
                    N := E.AsXmlNode();
                    N.WriteTo(T);
                    Result := T;
                end;
            'cleared':
                begin
                    E := XmlElement.Create('a');
                    Clear(E);
                    N := E.AsXmlNode();
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
    procedure AsXmlNode_Unassigned_Direct()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        N: XmlNode;
    begin
        N := E.AsXmlNode();
        Observer.Observe('returned', 'yes');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Unassigned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'asxmlnode');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Unassigned_IsXmlElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'isxmlelement');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Unassigned_AsXmlElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'asxmlelement');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Unassigned_WriteTo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'writeto');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Cleared()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'cleared');
        Observer.Finish();
    end;
}
