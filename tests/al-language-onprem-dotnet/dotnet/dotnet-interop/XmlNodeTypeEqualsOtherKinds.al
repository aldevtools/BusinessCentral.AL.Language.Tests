// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlnodetype
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61448
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): NodeType.Equals(AL value): the argument is System.Object, an AL Integer/Text/Option argument may not compile
//
// XmlNodeType.Equals with an AL Integer, Text and a CLR object (issue 154 item 4).
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlNodeType"; XnEo) { }
    }
    assembly("mscorlib")
    {
        type("System.Object"; XnEoObj) { }
    }
}

codeunit 61448 "LT XmlNodeType EqualsOther"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryIntegerOne(var Result: Text)
    var
        NodeType: DotNet XnEo;
        Other: DotNet XnEo;
        Same: DotNet XnEo;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(1));
    end;

    local procedure OutIntegerOne(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryIntegerOne(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryIntegerVariable(var Result: Text)
    var
        NodeType: DotNet XnEo;
        Other: DotNet XnEo;
        Same: DotNet XnEo;
        I: Integer;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        I := 1;
        Result := Format(NodeType.Equals(I));
    end;

    local procedure OutIntegerVariable(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryIntegerVariable(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryTextElement(var Result: Text)
    var
        NodeType: DotNet XnEo;
        Other: DotNet XnEo;
        Same: DotNet XnEo;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals('Element'));
    end;

    local procedure OutTextElement(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryTextElement(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryTextVariable(var Result: Text)
    var
        NodeType: DotNet XnEo;
        Other: DotNet XnEo;
        Same: DotNet XnEo;
        T: Text;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        T := 'Element';
        Result := Format(NodeType.Equals(T));
    end;

    local procedure OutTextVariable(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryTextVariable(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryUnassigned(var Result: Text)
    var
        NodeType: DotNet XnEo;
        Other: DotNet XnEo;
        Same: DotNet XnEo;
        Nothing: DotNet XnEoObj;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(Nothing));
    end;

    local procedure OutUnassigned(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryUnassigned(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlNodeType_Equals_AlValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('IntegerOne', OutIntegerOne());
        Observer.Observe('IntegerVariable', OutIntegerVariable());
        Observer.Observe('TextElement', OutTextElement());
        Observer.Observe('TextVariable', OutTextVariable());
        Observer.Observe('Unassigned', OutUnassigned());
        Observer.Expect('IntegerOne', 'ok:No');
        Observer.Expect('IntegerVariable', 'ok:No');
        Observer.Expect('TextElement', 'ok:No');
        Observer.Expect('TextVariable', 'ok:No');
        Observer.Expect('Unassigned', 'ok:No');
        Observer.Verify();
    end;
}
