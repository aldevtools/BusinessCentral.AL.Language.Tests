// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocument Remove, GetParent, GetDocument and uninitialised variables
// BC versions: 29 (27 and 28 by CI)

codeunit 74806 "LT P97 Doc Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Build(var Doc: XmlDocument; Variant: Integer)
    begin
        Doc := XmlDocument.Create();
        case Variant of
            1:
                Doc.Add(XmlElement.Create('r'));
            3:
                begin
                    Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
                    Doc.Add(XmlComment.Create('lead'));
                    Doc.Add(XmlElement.Create('r', XmlElement.Create('c')));
                end;
        end;
    end;

    local procedure Ser(var Doc: XmlDocument): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    [TryFunction]
    local procedure TryRemove(var Doc: XmlDocument)
    begin
        Doc.Remove();
    end;

    [TryFunction]
    local procedure TryGetParent(var Doc: XmlDocument; var Found: Boolean)
    var
        P: XmlElement;
    begin
        Found := Doc.GetParent(P);
    end;

    [TryFunction]
    local procedure TryGetDocument(var Doc: XmlDocument; var Found: Boolean; var Same: Text)
    var
        D2: XmlDocument;
    begin
        Found := Doc.GetDocument(D2);
        Same := Ser(D2);
    end;

    [Test]
    procedure Remove_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        V: Integer;
    begin
        for V := 1 to 3 do begin
            Build(Doc, V);
            if TryRemove(Doc) then
                Observer.Observe('v' + Format(V), 'ok:' + Ser(Doc))
            else
                Observer.ObserveError('v' + Format(V));
        end;
        Observer.Expect('v1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v1|code', 'InvalidOperation');
        Observer.Expect('v2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v2|code', 'InvalidOperation');
        Observer.Expect('v3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v3|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        Build(Doc, 1);
        if TryRemove(Doc) then
            Observer.Observe('first', 'ok')
        else
            Observer.ObserveError('first');
        if TryRemove(Doc) then
            Observer.Observe('second', 'ok')
        else
            Observer.ObserveError('second');
        Observer.Expect('first|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('first|code', 'InvalidOperation');
        Observer.Expect('second|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('second|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Found: Boolean;
        V: Integer;
    begin
        for V := 1 to 3 do begin
            Build(Doc, V);
            if TryGetParent(Doc, Found) then
                Observer.Observe('v' + Format(V), Format(Found))
            else
                Observer.ObserveError('v' + Format(V));
        end;
        Observer.Expect('v1', 'No');
        Observer.Expect('v2', 'No');
        Observer.Expect('v3', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetDocument_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Found: Boolean;
        Same: Text;
        V: Integer;
    begin
        for V := 1 to 3 do begin
            Build(Doc, V);
            Same := '';
            if TryGetDocument(Doc, Found, Same) then
                Observer.Observe('v' + Format(V), Format(Found) + '|' + Same + '|' + Format(Same = Ser(Doc)))
            else
                Observer.ObserveError('v' + Format(V));
        end;
        Observer.Expect('v1', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<r />|Yes');
        Observer.Expect('v2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v2|code', 'InvalidOperation');
        Observer.Expect('v3', 'Yes|<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<!--lead-->\r\n<r>\r\n  <c />\r\n</r>|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetDocument_ReturnsTheSameInstance()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        D2: XmlDocument;
        Root: XmlElement;
    begin
        Build(Doc, 1);
        Doc.GetDocument(D2);
        D2.GetRoot(Root);
        Root.SetAttribute('touched', 'yes');
        Observer.Observe('original', Ser(Doc));
        Observer.Observe('copy', Ser(D2));
        Observer.Expect('original', '<?xml version="1.0" encoding="utf-16"?>\r\n<r touched="yes" />');
        Observer.Expect('copy', '<?xml version="1.0" encoding="utf-16"?>\r\n<r touched="yes" />');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetRoot(var Doc: XmlDocument; var Result: Text)
    var
        Root: XmlElement;
    begin
        Result := Format(Doc.GetRoot(Root));
    end;

    [TryFunction]
    local procedure TryEdit(var Doc: XmlDocument; Op: Integer)
    begin
        case Op of
            1:
                Doc.AddAfterSelf(XmlComment.Create('x'));
            2:
                Doc.AddBeforeSelf(XmlComment.Create('x'));
            3:
                Doc.ReplaceWith(XmlComment.Create('x'));
            4:
                Doc.Add(XmlComment.Create('x'));
            5:
                Doc.AddFirst(XmlComment.Create('x'));
            6:
                Doc.RemoveNodes();
        end;
    end;

    [Test]
    procedure Uninitialised_Document()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Found: Boolean;
        Same: Text;
        R: Text;
        S: Text;
    begin
        if TryRemove(Doc) then
            Observer.Observe('remove', 'ok')
        else
            Observer.ObserveError('remove');
        if TryGetParent(Doc, Found) then
            Observer.Observe('parent', Format(Found))
        else
            Observer.ObserveError('parent');
        if TryGetDocument(Doc, Found, Same) then
            Observer.Observe('document', Format(Found) + '|' + Same)
        else
            Observer.ObserveError('document');
        if TryGetRoot(Doc, R) then
            Observer.Observe('getroot', R)
        else
            Observer.ObserveError('getroot');
        if TryText(Doc, S) then
            Observer.Observe('writeto', S)
        else
            Observer.ObserveError('writeto');
        Observer.Expect('remove|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove|code', 'InvalidOperation');
        Observer.Expect('parent', 'No');
        Observer.Expect('document|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('document|code', 'InvalidOperation');
        Observer.Expect('getroot', 'No');
        Observer.Expect('writeto|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('writeto|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryText(var Doc: XmlDocument; var S: Text)
    begin
        Doc.WriteTo(S);
    end;

    [Test]
    procedure Uninitialised_Document_Edits()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        R: Text;
        Op: Integer;
    begin
        for Op := 1 to 6 do begin
            Clear(Doc);
            if TryEdit(Doc, Op) then begin
                if TryText(Doc, R) then
                    Observer.Observe('op' + Format(Op), R)
                else
                    Observer.ObserveError('op' + Format(Op) + '_ser');
            end else
                Observer.ObserveError('op' + Format(Op));
        end;
        Observer.Expect('op1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op1|code', 'InvalidOperation');
        Observer.Expect('op2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op2|code', 'InvalidOperation');
        Observer.Expect('op3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op3|code', 'InvalidOperation');
        Observer.Expect('op4_ser|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op4_ser|code', 'InvalidOperation');
        Observer.Expect('op5_ser|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op5_ser|code', 'InvalidOperation');
        Observer.Expect('op6_ser|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('op6_ser|code', 'InvalidOperation');
        Observer.Verify();
    end;
}
