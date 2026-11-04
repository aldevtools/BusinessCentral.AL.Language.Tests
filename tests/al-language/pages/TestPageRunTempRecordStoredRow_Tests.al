// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: TPRTR Row (67362), TPRTR Child (67363), TPRTR Probe (67362), TPRTR Card (67362),
//                Assert (60021)
//
// The database holds row B with Grp 'DB' and two child rows pointing at B. The caller's
// TEMPORARY record holds its own row B with Grp 'TMP', inserted into the temporary table, and in
// one arm the caller then sets Grp to 'MEM' without saving it. Page.Run(Card, TempRow) opens the
// card; the handler records "No.:Grp:Cnt" as the page shows them. The three possible Grp values
// tell apart: the caller's unsaved value (MEM), the temporary table's row (TMP), and the
// database's row (DB).
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4762.

codeunit 67363 "TPRTR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Probe: Codeunit "TPRTR Probe";
        Row: Record "TPRTR Row";
        Child: Record "TPRTR Child";
    begin
        Probe.Reset();
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Init();
        Row."No." := 'B';
        Row.Grp := 'DB';
        Row.Insert();
        AddChild(1, 'B');
        AddChild(2, 'B');
        AddChild(3, 'A');
        Commit();
    end;

    local procedure AddChild(EntryNo: Integer; Parent: Code[20])
    var
        Child: Record "TPRTR Child";
    begin
        Child.Init();
        Child."Entry No." := EntryNo;
        Child.Parent := Parent;
        Child.Insert();
    end;

    local procedure InsertTempB(var TempRow: Record "TPRTR Row" temporary)
    begin
        TempRow.Init();
        TempRow."No." := 'B';
        TempRow.Grp := 'TMP';
        TempRow.Insert();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure TempRecordOnOpenPageSeesCallersValues()
    var
        TempRow: Record "TPRTR Row" temporary;
        Probe: Codeunit "TPRTR Probe";
    begin
        Initialize();
        InsertTempB(TempRow);
        TempRow.Grp := 'MEM';
        Page.Run(Page::"TPRTR Card", TempRow);
        Assert.AreEqual('B:MEM:Yes', Probe.GetOpenSeen(), 'what the card''s Rec holds in OnOpenPage after Page.Run(Id, TempRec)');
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure TempRecordShowsTheTemporaryTablesRow()
    var
        TempRow: Record "TPRTR Row" temporary;
        Probe: Codeunit "TPRTR Probe";
    begin
        Initialize();
        InsertTempB(TempRow);
        TempRow.Grp := 'MEM';
        Page.Run(Page::"TPRTR Card", TempRow);
        Assert.AreEqual('B:TMP:2', Probe.GetShown(), 'No.:Grp:Cnt the card shows after Page.Run(Id, TempRec) with an unsaved Grp');
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure TempRecordFlowFieldIsCalculatedFromTheDatabase()
    var
        TempRow: Record "TPRTR Row" temporary;
        Probe: Codeunit "TPRTR Probe";
    begin
        Initialize();
        InsertTempB(TempRow);
        Page.Run(Page::"TPRTR Card", TempRow);
        Assert.AreEqual('B:TMP:2', Probe.GetShown(), 'No.:Grp:Cnt the card shows after Page.Run(Id, TempRec) on an unchanged temporary row');
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "TPRTR Card")
    var
        Probe: Codeunit "TPRTR Probe";
    begin
        Probe.RecordShown(Card."No.".Value() + ':' + Card.Grp.Value() + ':' + Card.Cnt.Value());
        Card.Close();
    end;
}
