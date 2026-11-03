// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlnodetype
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61450
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): NodeType < Other (order operators on a .NET enum; AL0175-like candidate)
//
// The order operators on XmlNodeType members (issue 154 item 4, extra).
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlNodeType"; XnOr) { }
    }
    assembly("mscorlib")
    {
        type("System.Object"; XnOrObj) { }
    }
}

codeunit 61450 "LT XmlNodeType Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLess(var Result: Text)
    var
        NodeType: DotNet XnOr;
        Other: DotNet XnOr;
        Same: DotNet XnOr;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType < Other);
    end;

    local procedure OutLess(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryLess(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGreater(var Result: Text)
    var
        NodeType: DotNet XnOr;
        Other: DotNet XnOr;
        Same: DotNet XnOr;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(Other > NodeType);
    end;

    local procedure OutGreater(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryGreater(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLessEqualSame(var Result: Text)
    var
        NodeType: DotNet XnOr;
        Other: DotNet XnOr;
        Same: DotNet XnOr;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType <= Same);
    end;

    local procedure OutLessEqualSame(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryLessEqualSame(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryInSet(var Result: Text)
    var
        NodeType: DotNet XnOr;
        Other: DotNet XnOr;
        Same: DotNet XnOr;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType in [NodeType.Element, NodeType.Text]);
    end;

    local procedure OutInSet(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryInSet(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlNodeType_Order_EnumMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Less', OutLess());
        Observer.Observe('Greater', OutGreater());
        Observer.Observe('LessEqualSame', OutLessEqualSame());
        Observer.Observe('InSet', OutInSet());
        Observer.Expect('Less', 'ok:Yes');
        Observer.Expect('Greater', 'ok:Yes');
        Observer.Expect('LessEqualSame', 'ok:Yes');
        Observer.Expect('InSet', 'ok:Yes');
        Observer.Verify();
    end;
}
