// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattribute/xmlattribute-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlAttribute Remove, GetParent, GetDocument, ReplaceWith and uninitialised variables, attached, detached and removed
// BC versions: 29 (27 and 28 by CI)

codeunit 74803 "LT P97 Attr Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ser(E: XmlElement): Text
    var
        S: Text;
    begin
        E.WriteTo(S);
        exit(S);
    end;

    local procedure Build(var Doc: XmlDocument; var Root: XmlElement; var X: XmlAttribute)
    begin
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('r');
        Root.SetAttribute('p', '1');
        Root.SetAttribute('x', '2');
        Root.SetAttribute('q', '3');
        Doc.Add(Root);
        Doc.GetRoot(Root);
        Root.Attributes().Get('x', X);
    end;

    [TryFunction]
    local procedure TryRemove(var X: XmlAttribute)
    begin
        X.Remove();
    end;

    [TryFunction]
    local procedure TryGetParent(var X: XmlAttribute; var P: XmlElement; var Found: Boolean)
    begin
        Found := X.GetParent(P);
    end;

    [TryFunction]
    local procedure TryGetDocument(var X: XmlAttribute; var D: XmlDocument; var Found: Boolean)
    begin
        Found := X.GetDocument(D);
    end;

    local procedure ParentText(var Observer: Codeunit "Probe Observer"; Name: Text; var X: XmlAttribute)
    var
        P: XmlElement;
        Found: Boolean;
    begin
        if TryGetParent(X, P, Found) then begin
            Observer.Observe(Name + '_found', Format(Found));
            if Found then
                Observer.Observe(Name + '_name', P.Name());
        end else
            Observer.ObserveError(Name + '_err');
    end;

    local procedure DocText(var Observer: Codeunit "Probe Observer"; Name: Text; var X: XmlAttribute)
    var
        D: XmlDocument;
        Found: Boolean;
        S: Text;
    begin
        if TryGetDocument(X, D, Found) then begin
            Observer.Observe(Name + '_found', Format(Found));
            if Found then begin
                D.WriteTo(S);
                Observer.Observe(Name + '_doc', S);
            end;
        end else
            Observer.ObserveError(Name + '_err');
    end;

    [Test]
    procedure Remove_Attached()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlAttribute;
        Q: XmlAttribute;
    begin
        Build(Doc, Root, X);
        Observer.Observe('before', Ser(Root));
        if TryRemove(X) then
            Observer.Observe('removed', Ser(Root))
        else
            Observer.ObserveError('remove');
        Observer.Observe('value_after', X.Value());
        Observer.Observe('name_after', X.Name());
        ParentText(Observer, 'parent_after', X);
        if TryRemove(X) then
            Observer.Observe('removed_twice', Ser(Root))
        else
            Observer.ObserveError('remove_twice');
        Observer.Observe('has_x', Format(Root.Attributes().Get('x', Q)));
        Root.Add(X);
        Observer.Observe('readded', Ser(Root));
        Observer.Expect('before', '<r p="1" x="2" q="3" />');
        Observer.Expect('removed', '<r p="1" q="3" />');
        Observer.Expect('value_after', '2');
        Observer.Expect('name_after', 'x');
        Observer.Expect('parent_after_found', 'No');
        Observer.Expect('remove_twice|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove_twice|code', 'InvalidOperation');
        Observer.Expect('has_x', 'No');
        Observer.Expect('readded', '<r p="1" q="3" x="2" />');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Detached()
    var
        Observer: Codeunit "Probe Observer";
        X: XmlAttribute;
        S: Text;
    begin
        X := XmlAttribute.Create('x', '2');
        if TryRemove(X) then
            Observer.Observe('removed', 'ok')
        else
            Observer.ObserveError('remove');
        X.WriteTo(S);
        Observer.Observe('after', S);
        Observer.Expect('remove|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove|code', 'InvalidOperation');
        Observer.Expect('after', 'x="2"');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_FirstMiddleLast()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlAttribute;
    begin
        Build(Doc, Root, X);
        Root.Attributes().Get('p', X);
        X.Remove();
        Observer.Observe('first', Ser(Root));
        Root.Attributes().Get('q', X);
        X.Remove();
        Observer.Observe('last', Ser(Root));
        Root.Attributes().Get('x', X);
        X.Remove();
        Observer.Observe('only', Ser(Root));
        Observer.Observe('count', Format(Root.Attributes().Count()));
        Observer.Expect('first', '<r x="2" q="3" />');
        Observer.Expect('last', '<r x="2" />');
        Observer.Expect('only', '<r />');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_GetDocument_States()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlAttribute;
        Loose: XmlElement;
    begin
        Build(Doc, Root, X);
        ParentText(Observer, 'attached', X);
        DocText(Observer, 'attached', X);
        X.Remove();
        ParentText(Observer, 'removed', X);
        DocText(Observer, 'removed', X);
        X := XmlAttribute.Create('y', '1');
        ParentText(Observer, 'detached', X);
        DocText(Observer, 'detached', X);
        Loose := XmlElement.Create('loose');
        Loose.Add(X);
        ParentText(Observer, 'loose', X);
        DocText(Observer, 'loose', X);
        Observer.Expect('attached_found', 'Yes');
        Observer.Expect('attached_name', 'r');
        Observer.Expect('attached_found', 'Yes');
        Observer.Expect('attached_doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r p="1" x="2" q="3" />');
        Observer.Expect('removed_found', 'No');
        Observer.Expect('removed_found', 'No');
        Observer.Expect('detached_found', 'No');
        Observer.Expect('detached_found', 'No');
        Observer.Expect('loose_found', 'Yes');
        Observer.Expect('loose_name', 'loose');
        Observer.Expect('loose_found', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_AfterReplaceAndMove()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlAttribute;
        Y: XmlAttribute;
        Other: XmlElement;
    begin
        Build(Doc, Root, X);
        Y := XmlAttribute.Create('y', '9');
        X.ReplaceWith(Y);
        Observer.Observe('replaced', Ser(Root));
        ParentText(Observer, 'old', X);
        ParentText(Observer, 'new', Y);
        Other := XmlElement.Create('other');
        Y.Remove();
        Other.Add(Y);
        ParentText(Observer, 'moved', Y);
        Observer.Observe('other', Ser(Other));
        Observer.Observe('root', Ser(Root));
        Observer.Expect('replaced', '<r p="1" y="9" q="3" />');
        Observer.Expect('old_found', 'No');
        Observer.Expect('new_found', 'Yes');
        Observer.Expect('new_name', 'r');
        Observer.Expect('moved_found', 'Yes');
        Observer.Expect('moved_name', 'other');
        Observer.Expect('other', '<other y="9" />');
        Observer.Expect('root', '<r p="1" q="3" />');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryProp(var X: XmlAttribute; Prop: Integer; var R: Text)
    var
        S: Text;
        Root: XmlElement;
    begin
        case Prop of
            1:
                R := X.Name();
            2:
                R := X.Value();
            3:
                R := X.LocalName();
            4:
                R := X.NamespaceUri();
            5:
                R := X.NamespacePrefix();
            6:
                begin
                    R := Format(X.WriteTo(S));
                    R += '|' + S;
                end;
            7:
                R := Format(X.AsXmlNode().IsXmlAttribute());
            8:
                begin
                    X.Value('changed');
                    R := 'set';
                end;
            9:
                begin
                    X.AddAfterSelf(XmlAttribute.Create('n', '1'));
                    R := 'after';
                end;
            10:
                begin
                    X.AddBeforeSelf(XmlAttribute.Create('n', '1'));
                    R := 'before';
                end;
            11:
                begin
                    X.ReplaceWith(XmlAttribute.Create('n', '1'));
                    R := 'replace';
                end;
            12:
                begin
                    Root := XmlElement.Create('r');
                    Root.Add(X);
                    Root.WriteTo(R);
                end;
        end;
    end;

    [Test]
    procedure Uninitialised_Attribute()
    var
        Observer: Codeunit "Probe Observer";
        X: XmlAttribute;
        P: XmlElement;
        Found: Boolean;
        R: Text;
        Prop: Integer;
    begin
        if TryRemove(X) then
            Observer.Observe('remove', 'ok')
        else
            Observer.ObserveError('remove');
        if TryGetParent(X, P, Found) then
            Observer.Observe('parent', Format(Found))
        else
            Observer.ObserveError('parent');
        DocText(Observer, 'd', X);
        for Prop := 1 to 12 do begin
            Clear(X);
            R := '';
            if TryProp(X, Prop, R) then
                Observer.Observe('prop' + Format(Prop), R)
            else
                Observer.ObserveError('prop' + Format(Prop));
        end;
        Observer.Expect('remove|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('remove|code', 'NotInitialized');
        Observer.Expect('parent|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('parent|code', 'NotInitialized');
        Observer.Expect('d_err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('d_err|code', 'NotInitialized');
        Observer.Expect('prop1|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop1|code', 'NotInitialized');
        Observer.Expect('prop2|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop2|code', 'NotInitialized');
        Observer.Expect('prop3|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop3|code', 'NotInitialized');
        Observer.Expect('prop4|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop4|code', 'NotInitialized');
        Observer.Expect('prop5|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop5|code', 'NotInitialized');
        Observer.Expect('prop6|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('prop6|code', 'NotInitialized');
        Observer.Expect('prop7', 'Yes');
        Observer.Expect('prop8|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop8|code', 'NotInitialized');
        Observer.Expect('prop9|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('prop9|code', 'NotInitialized');
        Observer.Expect('prop10|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('prop10|code', 'NotInitialized');
        Observer.Expect('prop11|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('prop11|code', 'NotInitialized');
        Observer.Expect('prop12|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('prop12|code', 'NotInitialized');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): AsXmlNode() of an unassigned variable of each node kind (prop7 above pins IsXmlAttribute for XmlAttribute):
    // which Is* flags the node gives, and what reading it does.
    local procedure Flags(N: XmlNode): Text
    begin
        exit(Format(N.IsXmlAttribute()) + ',' + Format(N.IsXmlCData()) + ',' + Format(N.IsXmlComment()) + ',' + Format(N.IsXmlDeclaration()) + ',' +
            Format(N.IsXmlDocument()) + ',' + Format(N.IsXmlDocumentType()) + ',' + Format(N.IsXmlElement()) + ',' +
            Format(N.IsXmlProcessingInstruction()) + ',' + Format(N.IsXmlText()));
    end;

    [TryFunction]
    local procedure TryAsNode(Kind: Integer; var N: XmlNode)
    var
        A: XmlAttribute;
        T: XmlText;
        C: XmlCData;
        Cm: XmlComment;
        E: XmlElement;
        Pi: XmlProcessingInstruction;
        Dt: XmlDocumentType;
        D: XmlDocument;
    begin
        case Kind of
            1:
                N := A.AsXmlNode();
            2:
                N := T.AsXmlNode();
            3:
                N := C.AsXmlNode();
            4:
                N := Cm.AsXmlNode();
            5:
                N := E.AsXmlNode();
            6:
                N := Pi.AsXmlNode();
            7:
                N := Dt.AsXmlNode();
            8:
                N := D.AsXmlNode();
        end;
    end;

    [TryFunction]
    local procedure TryUse(var N: XmlNode; Use: Integer; var R: Text)
    var
        S: Text;
        P: XmlElement;
    begin
        case Use of
            1:
                begin
                    N.WriteTo(S);
                    R := S;
                end;
            2:
                R := Format(N.GetParent(P));
            3:
                R := N.AsXmlAttribute().Name();
            4:
                R := N.AsXmlText().Value();
            5:
                R := N.AsXmlElement().Name();
            6:
                R := Format(Flags(N.AsXmlAttribute().AsXmlNode()));
        end;
    end;

    local procedure RunAsNodeKinds(var Observer: Codeunit "Probe Observer"; FromKind: Integer; ToKind: Integer)
    var
        N: XmlNode;
        Kind: Integer;
        Use: Integer;
        R: Text;
    begin
        for Kind := FromKind to ToKind do begin
            Clear(N);
            if TryAsNode(Kind, N) then begin
                Observer.Observe('k' + Format(Kind), Flags(N));
                for Use := 1 to 6 do begin
                    R := '';
                    if TryUse(N, Use, R) then
                        Observer.Observe('k' + Format(Kind) + 'u' + Format(Use), R)
                    else
                        Observer.ObserveError('k' + Format(Kind) + 'u' + Format(Use));
                end;
            end else
                Observer.ObserveError('k' + Format(Kind));
        end;
    end;

    [Test]
    procedure Uninitialised_AsXmlNode_Attribute_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAsNodeKinds(Observer, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Uninitialised_AsXmlNode_CData_Comment()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAsNodeKinds(Observer, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Uninitialised_AsXmlNode_Element_ProcessingInstruction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAsNodeKinds(Observer, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Uninitialised_AsXmlNode_DocumentType_Document()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAsNodeKinds(Observer, 7, 8);
        Observer.Finish();
    end;
}
