// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlnodetype
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61447
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): NodeType.Equals(NodeType.Element) on a .NET enum member (System.Xml assembly alias; the assembly name System.Xml may need to be System.Xml.ReaderWriter or similar)
//
// XmlNodeType.Equals with a member of the same enum (issue 154 item 4).
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlNodeType"; XnEq) { }
    }
    assembly("mscorlib")
    {
        type("System.Object"; XnEqObj) { }
    }
}

codeunit 61447 "LT XmlNodeType Equals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySameMember(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(NodeType.Element));
    end;

    local procedure OutSameMember(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TrySameMember(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySameValueOtherVariable(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(Same));
    end;

    local procedure OutSameValueOtherVariable(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TrySameValueOtherVariable(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOtherMember(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(Other));
    end;

    local procedure OutOtherMember(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOtherMember(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOtherMemberReversed(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(Other.Equals(NodeType));
    end;

    local procedure OutOtherMemberReversed(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOtherMemberReversed(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySelfVariable(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(NodeType));
    end;

    local procedure OutSelfVariable(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TrySelfVariable(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryElementVsText(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Equals(NodeType.Text));
    end;

    local procedure OutElementVsText(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryElementVsText(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNotEquals(var Result: Text)
    var
        NodeType: DotNet XnEq;
        Other: DotNet XnEq;
        Same: DotNet XnEq;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(not NodeType.Equals(NodeType.Attribute));
    end;

    local procedure OutNotEquals(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryNotEquals(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlNodeType_Equals_EnumMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('SameMember', OutSameMember());
        Observer.Observe('SameValueOtherVariable', OutSameValueOtherVariable());
        Observer.Observe('OtherMember', OutOtherMember());
        Observer.Observe('OtherMemberReversed', OutOtherMemberReversed());
        Observer.Observe('SelfVariable', OutSelfVariable());
        Observer.Observe('ElementVsText', OutElementVsText());
        Observer.Observe('NotEquals', OutNotEquals());
        Observer.Expect('SameMember', 'ok:Yes');
        Observer.Expect('SameValueOtherVariable', 'ok:Yes');
        Observer.Expect('OtherMember', 'ok:No');
        Observer.Expect('OtherMemberReversed', 'ok:No');
        Observer.Expect('SelfVariable', 'ok:Yes');
        Observer.Expect('ElementVsText', 'ok:No');
        Observer.Expect('NotEquals', 'ok:Yes');
        Observer.Verify();
    end;
}
