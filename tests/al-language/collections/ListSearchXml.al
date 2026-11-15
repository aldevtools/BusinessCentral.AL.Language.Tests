// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-contains-method
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer"
// Probe: observe form. Each test ends with Observer.Finish(); its failure message carries what BC did. The assert form replaces it.
// BC versions: 27.5, 28.5, 29.0
// Lead: al-runner issue 8165 (List.Contains, IndexOf, LastIndexOf and Remove on a list of XML handles).
//
// The area: List.Contains, IndexOf, LastIndexOf and Remove on a List of [XmlNode], [XmlElement], [XmlDocument] and
// [XmlAttribute]. Each list holds another handle of the same type with other content, then the target twice, so IndexOf and
// LastIndexOf tell the positions apart. The searched value is one of:
// - Same: the variable that was added.
// - Copy: another variable assigned from it (V2 := V).
// - Refetched: a new handle of the same node, read again from the tree (AsXmlNode, GetRoot, GetDocument, Attributes().Get).
// - SameContent: a new node with the same name and content.
// - Unassigned: a variable never assigned, added twice and searched (XmlNode, XmlElement, XmlDocument).
// Each call runs in a TryFunction: a call that raises records the error text and code instead of the answer.
// Remove runs last; the count after it is recorded.

codeunit 76810 "COL List Search Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryNode(var L: List of [XmlNode]; var V: XmlNode; Member: Integer; var R: Text)
    begin
        case Member of
            1:
                R := Format(L.Contains(V));
            2:
                R := Format(L.IndexOf(V));
            3:
                R := Format(L.LastIndexOf(V));
            4:
                R := Format(L.Remove(V));
        end;
    end;

    local procedure ObserveNode(var Observer: Codeunit "Probe Observer"; var L: List of [XmlNode]; var V: XmlNode)
    var
        Names: List of [Text];
        Member: Integer;
        R: Text;
    begin
        Names.Add('contains');
        Names.Add('indexof');
        Names.Add('lastindexof');
        Names.Add('remove');
        for Member := 1 to 4 do
            if TryNode(L, V, Member, R) then
                Observer.Observe(Names.Get(Member), R)
            else
                Observer.ObserveError(Names.Get(Member));
        Observer.Observe('count_after', Format(L.Count()));
    end;

    [TryFunction]
    local procedure TryAddNode(var L: List of [XmlNode]; var V: XmlNode)
    begin
        L.Add(V);
    end;

    [TryFunction]
    local procedure TryElement(var L: List of [XmlElement]; var V: XmlElement; Member: Integer; var R: Text)
    begin
        case Member of
            1:
                R := Format(L.Contains(V));
            2:
                R := Format(L.IndexOf(V));
            3:
                R := Format(L.LastIndexOf(V));
            4:
                R := Format(L.Remove(V));
        end;
    end;

    local procedure ObserveElement(var Observer: Codeunit "Probe Observer"; var L: List of [XmlElement]; var V: XmlElement)
    var
        Names: List of [Text];
        Member: Integer;
        R: Text;
    begin
        Names.Add('contains');
        Names.Add('indexof');
        Names.Add('lastindexof');
        Names.Add('remove');
        for Member := 1 to 4 do
            if TryElement(L, V, Member, R) then
                Observer.Observe(Names.Get(Member), R)
            else
                Observer.ObserveError(Names.Get(Member));
        Observer.Observe('count_after', Format(L.Count()));
    end;

    [TryFunction]
    local procedure TryAddElement(var L: List of [XmlElement]; var V: XmlElement)
    begin
        L.Add(V);
    end;

    [TryFunction]
    local procedure TryDocument(var L: List of [XmlDocument]; var V: XmlDocument; Member: Integer; var R: Text)
    begin
        case Member of
            1:
                R := Format(L.Contains(V));
            2:
                R := Format(L.IndexOf(V));
            3:
                R := Format(L.LastIndexOf(V));
            4:
                R := Format(L.Remove(V));
        end;
    end;

    local procedure ObserveDocument(var Observer: Codeunit "Probe Observer"; var L: List of [XmlDocument]; var V: XmlDocument)
    var
        Names: List of [Text];
        Member: Integer;
        R: Text;
    begin
        Names.Add('contains');
        Names.Add('indexof');
        Names.Add('lastindexof');
        Names.Add('remove');
        for Member := 1 to 4 do
            if TryDocument(L, V, Member, R) then
                Observer.Observe(Names.Get(Member), R)
            else
                Observer.ObserveError(Names.Get(Member));
        Observer.Observe('count_after', Format(L.Count()));
    end;

    [TryFunction]
    local procedure TryAddDocument(var L: List of [XmlDocument]; var V: XmlDocument)
    begin
        L.Add(V);
    end;

    [TryFunction]
    local procedure TryAttribute(var L: List of [XmlAttribute]; var V: XmlAttribute; Member: Integer; var R: Text)
    begin
        case Member of
            1:
                R := Format(L.Contains(V));
            2:
                R := Format(L.IndexOf(V));
            3:
                R := Format(L.LastIndexOf(V));
            4:
                R := Format(L.Remove(V));
        end;
    end;

    local procedure ObserveAttribute(var Observer: Codeunit "Probe Observer"; var L: List of [XmlAttribute]; var V: XmlAttribute)
    var
        Names: List of [Text];
        Member: Integer;
        R: Text;
    begin
        Names.Add('contains');
        Names.Add('indexof');
        Names.Add('lastindexof');
        Names.Add('remove');
        for Member := 1 to 4 do
            if TryAttribute(L, V, Member, R) then
                Observer.Observe(Names.Get(Member), R)
            else
                Observer.ObserveError(Names.Get(Member));
        Observer.Observe('count_after', Format(L.Count()));
    end;

    [TryFunction]
    local procedure TryAddAttribute(var L: List of [XmlAttribute]; var V: XmlAttribute)
    begin
        L.Add(V);
    end;

    [Test]
    procedure XmlNodeList_Search_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlNode];
        E: XmlElement;
        OtherE: XmlElement;
        N: XmlNode;
        S: XmlNode;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        N := E.AsXmlNode();
        L.Add(OtherE.AsXmlNode());
        L.Add(N);
        L.Add(N);
        ObserveNode(Observer, L, N);
        Observer.Finish();
    end;

    [Test]
    procedure XmlNodeList_Search_CopiedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlNode];
        E: XmlElement;
        OtherE: XmlElement;
        N: XmlNode;
        S: XmlNode;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        N := E.AsXmlNode();
        L.Add(OtherE.AsXmlNode());
        L.Add(N);
        L.Add(N);
        S := N;
        ObserveNode(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlNodeList_Search_RefetchedHandle()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlNode];
        E: XmlElement;
        OtherE: XmlElement;
        N: XmlNode;
        S: XmlNode;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        N := E.AsXmlNode();
        L.Add(OtherE.AsXmlNode());
        L.Add(N);
        L.Add(N);
        S := E.AsXmlNode();
        ObserveNode(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlNodeList_Search_SameContentOtherNode()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlNode];
        E: XmlElement;
        OtherE: XmlElement;
        N: XmlNode;
        S: XmlNode;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        N := E.AsXmlNode();
        L.Add(OtherE.AsXmlNode());
        L.Add(N);
        L.Add(N);
        S := XmlElement.Create('a', '', 'x').AsXmlNode();
        ObserveNode(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlElementList_Search_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlElement];
        D: XmlDocument;
        E: XmlElement;
        OtherE: XmlElement;
        S: XmlElement;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        D := XmlDocument.Create();
        D.Add(E);
        L.Add(OtherE);
        L.Add(E);
        L.Add(E);
        ObserveElement(Observer, L, E);
        Observer.Finish();
    end;

    [Test]
    procedure XmlElementList_Search_CopiedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlElement];
        D: XmlDocument;
        E: XmlElement;
        OtherE: XmlElement;
        S: XmlElement;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        D := XmlDocument.Create();
        D.Add(E);
        L.Add(OtherE);
        L.Add(E);
        L.Add(E);
        S := E;
        ObserveElement(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlElementList_Search_RefetchedHandle()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlElement];
        D: XmlDocument;
        E: XmlElement;
        OtherE: XmlElement;
        S: XmlElement;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        D := XmlDocument.Create();
        D.Add(E);
        L.Add(OtherE);
        L.Add(E);
        L.Add(E);
        D.GetRoot(S);
        ObserveElement(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlElementList_Search_SameContentOtherNode()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlElement];
        D: XmlDocument;
        E: XmlElement;
        OtherE: XmlElement;
        S: XmlElement;
    begin
        E := XmlElement.Create('a', '', 'x');
        OtherE := XmlElement.Create('b', '', 'y');
        D := XmlDocument.Create();
        D.Add(E);
        L.Add(OtherE);
        L.Add(E);
        L.Add(E);
        S := XmlElement.Create('a', '', 'x');
        ObserveElement(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlDocumentList_Search_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlDocument];
        D: XmlDocument;
        OtherD: XmlDocument;
        E: XmlElement;
        S: XmlDocument;
    begin
        D := XmlDocument.Create();
        E := XmlElement.Create('a', '', 'x');
        D.Add(E);
        OtherD := XmlDocument.Create();
        OtherD.Add(XmlElement.Create('b', '', 'y'));
        L.Add(OtherD);
        L.Add(D);
        L.Add(D);
        ObserveDocument(Observer, L, D);
        Observer.Finish();
    end;

    [Test]
    procedure XmlDocumentList_Search_CopiedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlDocument];
        D: XmlDocument;
        OtherD: XmlDocument;
        E: XmlElement;
        S: XmlDocument;
    begin
        D := XmlDocument.Create();
        E := XmlElement.Create('a', '', 'x');
        D.Add(E);
        OtherD := XmlDocument.Create();
        OtherD.Add(XmlElement.Create('b', '', 'y'));
        L.Add(OtherD);
        L.Add(D);
        L.Add(D);
        S := D;
        ObserveDocument(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlDocumentList_Search_RefetchedHandle()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlDocument];
        D: XmlDocument;
        OtherD: XmlDocument;
        E: XmlElement;
        S: XmlDocument;
    begin
        D := XmlDocument.Create();
        E := XmlElement.Create('a', '', 'x');
        D.Add(E);
        OtherD := XmlDocument.Create();
        OtherD.Add(XmlElement.Create('b', '', 'y'));
        L.Add(OtherD);
        L.Add(D);
        L.Add(D);
        E.GetDocument(S);
        ObserveDocument(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlDocumentList_Search_SameContentOtherDocument()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlDocument];
        D: XmlDocument;
        OtherD: XmlDocument;
        E: XmlElement;
        S: XmlDocument;
    begin
        D := XmlDocument.Create();
        E := XmlElement.Create('a', '', 'x');
        D.Add(E);
        OtherD := XmlDocument.Create();
        OtherD.Add(XmlElement.Create('b', '', 'y'));
        L.Add(OtherD);
        L.Add(D);
        L.Add(D);
        S := XmlDocument.Create();
        S.Add(XmlElement.Create('a', '', 'x'));
        ObserveDocument(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlAttributeList_Search_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlAttribute];
        E: XmlElement;
        A: XmlAttribute;
        S: XmlAttribute;
        Found: Boolean;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.Create('x', '1'));
        Found := E.Attributes().Get('x', A);
        Observer.Observe('found', Format(Found));
        L.Add(XmlAttribute.Create('y', '2'));
        L.Add(A);
        L.Add(A);
        ObserveAttribute(Observer, L, A);
        Observer.Finish();
    end;

    [Test]
    procedure XmlAttributeList_Search_CopiedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlAttribute];
        E: XmlElement;
        A: XmlAttribute;
        S: XmlAttribute;
        Found: Boolean;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.Create('x', '1'));
        Found := E.Attributes().Get('x', A);
        Observer.Observe('found', Format(Found));
        L.Add(XmlAttribute.Create('y', '2'));
        L.Add(A);
        L.Add(A);
        S := A;
        ObserveAttribute(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlAttributeList_Search_RefetchedHandle()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlAttribute];
        E: XmlElement;
        A: XmlAttribute;
        S: XmlAttribute;
        Found: Boolean;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.Create('x', '1'));
        Found := E.Attributes().Get('x', A);
        Observer.Observe('found', Format(Found));
        L.Add(XmlAttribute.Create('y', '2'));
        L.Add(A);
        L.Add(A);
        Found := E.Attributes().Get('x', S);
        Observer.Observe('found_again', Format(Found));
        ObserveAttribute(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlAttributeList_Search_SameContentOtherAttribute()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlAttribute];
        E: XmlElement;
        A: XmlAttribute;
        S: XmlAttribute;
        Found: Boolean;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.Create('x', '1'));
        Found := E.Attributes().Get('x', A);
        Observer.Observe('found', Format(Found));
        L.Add(XmlAttribute.Create('y', '2'));
        L.Add(A);
        L.Add(A);
        S := XmlAttribute.Create('x', '1');
        ObserveAttribute(Observer, L, S);
        Observer.Finish();
    end;

    [Test]
    procedure XmlNodeList_Search_UnassignedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlNode];
        U: XmlNode;
    begin
        if not TryAddNode(L, U) then
            Observer.ObserveError('add')
        else begin
            Observer.Observe('add', 'ok');
            if not TryAddNode(L, U) then
                Observer.ObserveError('add_again')
            else
                ObserveNode(Observer, L, U);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure XmlElementList_Search_UnassignedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlElement];
        U: XmlElement;
    begin
        if not TryAddElement(L, U) then
            Observer.ObserveError('add')
        else begin
            Observer.Observe('add', 'ok');
            if not TryAddElement(L, U) then
                Observer.ObserveError('add_again')
            else
                ObserveElement(Observer, L, U);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure XmlDocumentList_Search_UnassignedVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [XmlDocument];
        U: XmlDocument;
    begin
        if not TryAddDocument(L, U) then
            Observer.ObserveError('add')
        else begin
            Observer.Observe('add', 'ok');
            if not TryAddDocument(L, U) then
                Observer.ObserveError('add_again')
            else
                ObserveDocument(Observer, L, U);
        end;
        Observer.Finish();
    end;
}
