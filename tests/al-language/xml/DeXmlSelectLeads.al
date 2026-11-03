// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectsinglenode-string-xmlnode-method
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer"; self-contained codeunits 85903, 85904, 85905
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Leads (corpus issue 671):
//  - "SelectSingleNode sets the last error when the Boolean is used" (microsoft/AL#6159): what GetLastErrorText/GetLastErrorCode hold after
//    'if X.SelectSingleNode(...) then;' with no match, for the XmlDocument, XmlElement and XmlNode overloads, and after a match.
//  - "SelectSingleNode / SelectNodes with an empty XPath" (microsoft/AL#4602): '' for the three receivers, with and without the Boolean.
//  - "XmlNodeList.Get index base and error message" (microsoft/AL#5010): Get(0), Get(-1), Get(Count), Get(Count + 1) without the Boolean.

codeunit 85903 "LT DE Xml Select LastError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Load(var Doc: XmlDocument)
    begin
        XmlDocument.ReadFrom('<a><b>1</b></a>', Doc);
    end;

    local procedure LastError(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + ' text', GetLastErrorText());
        Observer.Observe(Name + ' code', GetLastErrorCode());
    end;

    [Test]
    procedure Missing_BooleanUsed_LastError()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        RootNode: XmlNode;
        N: XmlNode;
    begin
        Load(Doc);
        Doc.GetRoot(Root);
        RootNode := Root.AsXmlNode();

        ClearLastError();
        if Doc.SelectSingleNode('//missing', N) then;
        LastError(Observer, 'document');
        ClearLastError();
        if Root.SelectSingleNode('missing', N) then;
        LastError(Observer, 'element');
        ClearLastError();
        if RootNode.SelectSingleNode('missing', N) then;
        LastError(Observer, 'node');
        ClearLastError();
        Observer.Observe('document returned', Format(Doc.SelectSingleNode('//missing', N)));
        LastError(Observer, 'document format');
        Observer.Expect('document text', '');
        Observer.Expect('document code', '');
        Observer.Expect('element text', '');
        Observer.Expect('element code', '');
        Observer.Expect('node text', '');
        Observer.Expect('node code', '');
        Observer.Expect('document returned', 'No');
        Observer.Expect('document format text', '');
        Observer.Expect('document format code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Match_AfterEarlierError_LastError()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        N: XmlNode;
    begin
        Load(Doc);
        ClearLastError();
        if Doc.SelectSingleNode('//b', N) then;
        LastError(Observer, 'match clean');
        asserterror Error('earlier error');
        if Doc.SelectSingleNode('//b', N) then;
        LastError(Observer, 'match after error');
        asserterror Error('earlier error');
        if Doc.SelectSingleNode('//missing', N) then;
        LastError(Observer, 'missing after error');
        Observer.Expect('match clean text', '');
        Observer.Expect('match clean code', '');
        Observer.Expect('match after error text', 'earlier error');
        Observer.Expect('match after error code', 'Dialog');
        Observer.Expect('missing after error text', 'earlier error');
        Observer.Expect('missing after error code', 'Dialog');
        Observer.Verify();
    end;
}

codeunit 85904 "LT DE Xml Empty XPath"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySingle(Kind: Integer; UseBoolean: Boolean; var Found: Boolean)
    var
        Doc: XmlDocument;
        Root: XmlElement;
        N: XmlNode;
    begin
        XmlDocument.ReadFrom('<a><b>1</b></a>', Doc);
        Doc.GetRoot(Root);
        case Kind of
            1:
                if UseBoolean then
                    Found := Doc.SelectSingleNode('', N)
                else
                    Doc.SelectSingleNode('', N);
            2:
                if UseBoolean then
                    Found := Root.SelectSingleNode('', N)
                else
                    Root.SelectSingleNode('', N);
            3:
                if UseBoolean then
                    Found := Root.AsXmlNode().SelectSingleNode('', N)
                else
                    Root.AsXmlNode().SelectSingleNode('', N);
        end;
    end;

    [TryFunction]
    local procedure TryNodes(Kind: Integer; UseBoolean: Boolean; var Found: Boolean; var Count: Integer)
    var
        Doc: XmlDocument;
        Root: XmlElement;
        L: XmlNodeList;
    begin
        XmlDocument.ReadFrom('<a><b>1</b></a>', Doc);
        Doc.GetRoot(Root);
        case Kind of
            1:
                if UseBoolean then
                    Found := Doc.SelectNodes('', L)
                else
                    Doc.SelectNodes('', L);
            2:
                if UseBoolean then
                    Found := Root.SelectNodes('', L)
                else
                    Root.SelectNodes('', L);
            3:
                if UseBoolean then
                    Found := Root.AsXmlNode().SelectNodes('', L)
                else
                    Root.AsXmlNode().SelectNodes('', L);
        end;
        Count := L.Count();
    end;

    local procedure KindName(Kind: Integer): Text
    begin
        case Kind of
            1:
                exit('document');
            2:
                exit('element');
        end;
        exit('node');
    end;

    [Test]
    procedure SelectSingleNode_EmptyXPath()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Integer;
        Found: Boolean;
    begin
        for Kind := 1 to 3 do begin
            Found := false;
            ClearLastError();
            if TrySingle(Kind, true, Found) then
                Observer.Observe(KindName(Kind) + ' with boolean', 'ok ' + Format(Found))
            else
                Observer.Observe(KindName(Kind) + ' with boolean', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
            if TrySingle(Kind, false, Found) then
                Observer.Observe(KindName(Kind) + ' without boolean', 'ok')
            else
                Observer.Observe(KindName(Kind) + ' without boolean', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('document with boolean', 'ok No');
        Observer.Expect('document without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Expect('element with boolean', 'ok No');
        Observer.Expect('element without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Expect('node with boolean', 'ok No');
        Observer.Expect('node without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_EmptyXPath()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Integer;
        Found: Boolean;
        Count: Integer;
    begin
        for Kind := 1 to 3 do begin
            Found := false;
            Count := -1;
            ClearLastError();
            if TryNodes(Kind, true, Found, Count) then
                Observer.Observe(KindName(Kind) + ' with boolean', 'ok ' + Format(Found) + ' count ' + Format(Count))
            else
                Observer.Observe(KindName(Kind) + ' with boolean', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
            if TryNodes(Kind, false, Found, Count) then
                Observer.Observe(KindName(Kind) + ' without boolean', 'ok count ' + Format(Count))
            else
                Observer.Observe(KindName(Kind) + ' without boolean', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('document with boolean', 'ok No count 0');
        Observer.Expect('document without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Expect('element with boolean', 'ok No count 0');
        Observer.Expect('element without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Expect('node with boolean', 'ok No count 0');
        Observer.Expect('node without boolean', 'error Expression must evaluate to a node-set.|Xml:XPath');
        Observer.Verify();
    end;
}

codeunit 85905 "LT DE XmlNodeList Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGet(L: XmlNodeList; Index: Integer; var Name: Text)
    var
        N: XmlNode;
    begin
        L.Get(Index, N);
        Name := N.AsXmlElement().InnerText();
    end;

    [Test]
    procedure Get_WithoutBoolean_Indexes()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        L: XmlNodeList;
        Index: Integer;
        Indexes: List of [Integer];
        Name: Text;
    begin
        Indexes.AddRange(-1, 0, 1, 3, 4);
        XmlDocument.ReadFrom('<a><b>1</b><b>2</b><b>3</b></a>', Doc);
        Doc.GetRoot(Root);
        L := Root.GetChildElements('b');
        Observer.Observe('count', Format(L.Count()));
        foreach Index in Indexes do begin
            Name := '';
            ClearLastError();
            if TryGet(L, Index, Name) then
                Observer.Observe('get ' + Format(Index), 'ok ' + Name)
            else
                Observer.Observe('get ' + Format(Index), 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('count', '3');
        Observer.Expect('get -1', 'error Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('get 0', 'error The parameter index must have a value greater than zero.|IndexOutOfBounds');
        Observer.Expect('get 1', 'ok 1');
        Observer.Expect('get 3', 'ok 3');
        Observer.Expect('get 4', 'error Index out of bounds.|IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure Get_WithoutBoolean_EmptyList()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        L: XmlNodeList;
        Name: Text;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.GetRoot(Root);
        L := Root.GetChildNodes();
        ClearLastError();
        if TryGet(L, 1, Name) then
            Observer.Observe('get 1 of empty', 'ok ' + Name)
        else
            Observer.Observe('get 1 of empty', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('get 1 of empty', 'error Index out of bounds.|IndexOutOfBounds');
        Observer.Verify();
    end;
}
