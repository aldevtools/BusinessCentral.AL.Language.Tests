// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmlnodetype
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61449
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): NodeType = NodeType.Element and NodeType <> Other between .NET enum members
//
// The operators = and <> on XmlNodeType members, and + as a number (issue 154 item 4; the enum operators are pinned for NumberStyles in TestDotNetValueKindsContracts.al).
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlNodeType"; XnOp) { }
    }
    assembly("mscorlib")
    {
        type("System.Object"; XnOpObj) { }
    }
}

codeunit 61449 "LT XmlNodeType Operators"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEqElement(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType = NodeType.Element);
    end;

    local procedure OutEqElement(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryEqElement(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEqOtherVariable(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType = Same);
    end;

    local procedure OutEqOtherVariable(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryEqOtherVariable(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEqDifferent(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType = Other);
    end;

    local procedure OutEqDifferent(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryEqDifferent(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNeDifferent(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType <> Other);
    end;

    local procedure OutNeDifferent(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryNeDifferent(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNeSame(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType <> NodeType.Element);
    end;

    local procedure OutNeSame(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryNeSame(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEqReversed(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType.Element = NodeType);
    end;

    local procedure OutEqReversed(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryEqReversed(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryPlusZero(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType + 0);
    end;

    local procedure OutPlusZero(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryPlusZero(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryPlusOther(var Result: Text)
    var
        NodeType: DotNet XnOp;
        Other: DotNet XnOp;
        Same: DotNet XnOp;
    begin
        NodeType := NodeType.Element;
        Other := Other.Attribute;
        Same := Same.Element;
        Result := Format(NodeType + Other);
    end;

    local procedure OutPlusOther(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryPlusOther(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlNodeType_Operators_EnumMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('EqElement', OutEqElement());
        Observer.Observe('EqOtherVariable', OutEqOtherVariable());
        Observer.Observe('EqDifferent', OutEqDifferent());
        Observer.Observe('NeDifferent', OutNeDifferent());
        Observer.Observe('NeSame', OutNeSame());
        Observer.Observe('EqReversed', OutEqReversed());
        Observer.Observe('PlusZero', OutPlusZero());
        Observer.Observe('PlusOther', OutPlusOther());
        Observer.Expect('EqElement', 'ok:Yes');
        Observer.Expect('EqOtherVariable', 'ok:Yes');
        Observer.Expect('EqDifferent', 'ok:No');
        Observer.Expect('NeDifferent', 'ok:Yes');
        Observer.Expect('NeSame', 'ok:No');
        Observer.Expect('EqReversed', 'ok:Yes');
        Observer.Expect('PlusZero', 'ok:1');
        Observer.Expect('PlusOther', 'ok:3');
        Observer.Verify();
    end;
}
