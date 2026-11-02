// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnodelist/xmlnodelist-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained objects 92862-92864 and interface "LT Y44 I Nodes"
// Probe: gap cycle 4, spec G4-17. foreach over an XmlNodeList that was never assigned: a local, the named return value of a procedure
//        with an empty body (called directly and through an interface), and Count/Get on such a list.
//        Already pinned nearby: xml/XmlNodes.al TP_NodeList_Clear (fresh Count 0, foreach over a cleared list).
//        Every value asserted is what BC 27.5, 28.5, 29.0 (CI containers) and a SaaS sandbox BC 29 produced, all the same.
// BC versions: 27, 28, 29

interface "LT Y44 I Nodes"
{
    procedure GetNodes() Nodes: XmlNodeList;
}

codeunit 92863 "LT Y44 Empty Nodes" implements "LT Y44 I Nodes"
{
    procedure GetNodes() Nodes: XmlNodeList
    begin
    end;
}

codeunit 92864 "LT Y44 Two Nodes" implements "LT Y44 I Nodes"
{
    procedure GetNodes() Nodes: XmlNodeList
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<a><b>1</b><b>2</b></a>', Doc);
        Doc.SelectNodes('//b', Nodes);
    end;
}

codeunit 92862 "LT Y44 Foreach Fresh NodeList"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure EmptyReturn() Nodes: XmlNodeList
    begin
    end;

    [TryFunction]
    local procedure TryForeach(L: XmlNodeList; var Visits: Integer; var Texts: Text)
    var
        N: XmlNode;
    begin
        foreach N in L do begin
            Visits += 1;
            Texts += N.AsXmlElement().InnerText() + ',';
        end;
    end;

    local procedure Run(Name: Text; L: XmlNodeList)
    var
        Visits: Integer;
        Texts: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryForeach(L, Visits, Texts);
        Observer.Observe('ok_' + Name, Format(Ok));
        Observer.Observe('visits_' + Name, Format(Visits) + ' ' + Texts);
        if not Ok then
            Observer.ObserveError('err_' + Name);
    end;

    [Test]
    procedure ForeachNodeList_NeverAssigned()
    var
        L: XmlNodeList;
    begin
        Run('never', L);
        Observer.Expect('ok_never', 'Yes');
        Observer.Expect('visits_never', '0 ');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachNodeList_InterfaceEmptyReturn()
    var
        EmptyNodes: Codeunit "LT Y44 Empty Nodes";
        TwoNodes: Codeunit "LT Y44 Two Nodes";
        I: Interface "LT Y44 I Nodes";
        L: XmlNodeList;
    begin
        I := EmptyNodes;
        L := I.GetNodes();
        Run('iface_empty', L);
        I := TwoNodes;
        L := I.GetNodes();
        Run('iface_two', L);
        Observer.Expect('ok_iface_empty', 'Yes');
        Observer.Expect('visits_iface_empty', '0 ');
        Observer.Expect('ok_iface_two', 'Yes');
        Observer.Expect('visits_iface_two', '2 1,2,');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryForeachDirect(var Visits: Integer)
    var
        N: XmlNode;
    begin
        foreach N in EmptyReturn() do
            Visits += 1;
    end;

    [Test]
    procedure ForeachNodeList_LocalEmptyReturn()
    var
        L: XmlNodeList;
        Visits: Integer;
        Ok: Boolean;
    begin
        L := EmptyReturn();
        Run('local', L);
        ClearLastError();
        Ok := TryForeachDirect(Visits);
        Observer.Observe('ok_direct', Format(Ok));
        Observer.Observe('visits_direct', Format(Visits));
        if not Ok then
            Observer.ObserveError('err_direct');
        Observer.Expect('ok_local', 'Yes');
        Observer.Expect('visits_local', '0 ');
        Observer.Expect('ok_direct', 'Yes');
        Observer.Expect('visits_direct', '0');
        Observer.Verify();
    end;

    // Get as a statement: the Boolean answer is not used, so a missing node raises
    [TryFunction]
    local procedure TryGetNoBool(L: XmlNodeList; var N: XmlNode)
    begin
        L.Get(1, N);
    end;

    [Test]
    procedure NodeList_NeverAssigned_Members()
    var
        L: XmlNodeList;
        N: XmlNode;
    begin
        Observer.Observe('count', Format(L.Count()));
        ClearLastError();
        Observer.Observe('get_bool', Format(L.Get(1, N)));
        ClearLastError();
        if TryGetNoBool(L, N) then
            Observer.Observe('get_nobool', 'ok ' + Format(N.IsXmlElement()))
        else
            Observer.ObserveError('get_nobool');
        Observer.Expect('count', '0');
        Observer.Expect('get_bool', 'No');
        Observer.Expect('get_nobool|text', 'Index out of bounds.');
        Observer.Expect('get_nobool|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;
}
