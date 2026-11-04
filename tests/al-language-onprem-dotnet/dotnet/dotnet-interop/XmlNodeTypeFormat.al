// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlnodetype
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61451
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): XmlNodeType members read through a DotNet variable (NodeType := NodeType.Element)
//
// Format, Format(x, 0, 9), ToString() and numeric value of XmlNodeType members (issue 154 item 4).
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlNodeType"; XnFm) { }
    }
    assembly("mscorlib")
    {
        type("System.Object"; XnFmObj) { }
    }
}

codeunit 61451 "LT XmlNodeType Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryNone(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.None;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryElement(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Element;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryAttribute(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Attribute;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryText(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Text;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryCDATA(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.CDATA;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryComment(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Comment;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryDocument(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Document;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryWhitespace(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.Whitespace;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryEndElement(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.EndElement;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    [TryFunction]
    local procedure TryXmlDeclaration(var Result: Text)
    var
        NodeType: DotNet XnFm;
    begin
        NodeType := NodeType.XmlDeclaration;
        Result := Format(NodeType) + '|' + Format(NodeType, 0, 9) + '|' + NodeType.ToString() + '|' + Format(NodeType + 0);
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, Result)
        else
            Observer.Observe(Name + '_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlNodeType_Members_FormatToStringAndNumber()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        Report(Observer, 'None', TryNone(Result), Result);
        ClearLastError();
        Report(Observer, 'Element', TryElement(Result), Result);
        ClearLastError();
        Report(Observer, 'Attribute', TryAttribute(Result), Result);
        ClearLastError();
        Report(Observer, 'Text', TryText(Result), Result);
        ClearLastError();
        Report(Observer, 'CDATA', TryCDATA(Result), Result);
        ClearLastError();
        Report(Observer, 'Comment', TryComment(Result), Result);
        ClearLastError();
        Report(Observer, 'Document', TryDocument(Result), Result);
        ClearLastError();
        Report(Observer, 'Whitespace', TryWhitespace(Result), Result);
        ClearLastError();
        Report(Observer, 'EndElement', TryEndElement(Result), Result);
        ClearLastError();
        Report(Observer, 'XmlDeclaration', TryXmlDeclaration(Result), Result);
        Observer.Expect('None', 'None|None|None|0');
        Observer.Expect('Element', 'Element|Element|Element|1');
        Observer.Expect('Attribute', 'Attribute|Attribute|Attribute|2');
        Observer.Expect('Text', 'Text|Text|Text|3');
        Observer.Expect('CDATA', 'CDATA|CDATA|CDATA|4');
        Observer.Expect('Comment', 'Comment|Comment|Comment|8');
        Observer.Expect('Document', 'Document|Document|Document|9');
        Observer.Expect('Whitespace', 'Whitespace|Whitespace|Whitespace|13');
        Observer.Expect('EndElement', 'EndElement|EndElement|EndElement|15');
        Observer.Expect('XmlDeclaration', 'XmlDeclaration|XmlDeclaration|XmlDeclaration|17');
        Observer.Verify();
    end;
}
