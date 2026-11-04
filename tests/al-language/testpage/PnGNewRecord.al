// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Card (70134), LT PnG Doc (70137), LT PnG Part (70136), LT PnG Item (70130), LT PnG Head (70131), LT PnG Line (70132), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 77 (NewRecord: filters of a record handed to Page.Run copied onto a new row, primary-key gate, validation of the stamped fields) and 78 (NewRecord: an action saves the current row first, on a part and on a plain page)
// Facts: control values and trigger log after New() on a page that was handed a filtered record, and whether an action sees a pending new row in the table
// BC versions: 29 (27 and 28 by CI)

codeunit 70182 "LT PnG New Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'N1';
        Item.Name := 'Alpha';
        Item.Qty := 7;
        Item.Flag := true;
        Item.Insert();
        Item."No." := 'N2';
        Item.Name := 'Beta';
        Item.Qty := 8;
        Item.Flag := false;
        Item.Insert();
    end;

    [Test]
    [HandlerFunctions('ListNewHandler')]
    procedure HandedRecordNonKeyFilters()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Mode := 1;
        Log.Reset();
        Item.SetRange(Name, 'Alpha');
        Item.SetRange(Qty, 7);
        Item.SetRange(Flag, true);
        Page.Run(Page::"LT PnG List", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(N1,Alpha);List.AGR(N1,Alpha);List.AGCR(N1,);opened;List.OnNewRecord;List.AGCR(,);new(||0|No);after-key(|0|No)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListNewHandler')]
    procedure HandedRecordKeyFieldFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Mode := 1;
        Log.Reset();
        Item.SetRange("No.", 'FILTERED');
        Page.Run(Page::"LT PnG List", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.OnNewRecord;List.AGCR(FILTERED,FILTERED);List.OnNewRecord;List.AGCR(FILTERED,FILTERED);opened;List.OnNewRecord;List.AGCR(FILTERED,FILTERED);new(FILTERED||0|No);after-key(|0|No)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListNewHandler')]
    procedure HandedRecordRangeAndMultiValueFilters()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Mode := 1;
        Log.Reset();
        Item.SetFilter(Name, 'Alpha|Beta');
        Item.SetRange(Qty, 1, 10);
        Item.SetFilter("No.", '<>X');
        Page.Run(Page::"LT PnG List", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(N1,Alpha);List.AGR(N2,Beta);List.AGR(N1,Alpha);List.AGR(N1,Alpha);List.AGCR(N1,);opened;List.OnNewRecord;List.AGCR(,);new(||0|No);after-key(|0|No)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListNewHandler')]
    procedure HandedRecordNoFilters()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Mode := 1;
        Log.Reset();
        Page.Run(Page::"LT PnG List", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(N1,Alpha);List.AGR(N2,Beta);List.AGR(N1,Alpha);List.AGR(N1,Alpha);List.AGCR(N1,);opened;List.OnNewRecord;List.AGCR(,);new(||0|No);after-key(|0|No)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListNewHandler')]
    procedure HandedRecordWithOnlyPrimaryKeyValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Mode := 2;
        Log.Reset();
        Item.SetRange(Name, 'Alpha');
        Page.Run(Page::"LT PnG List", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'List.OnInit;List.OnOpenPage;List.AGR(N1,Alpha);List.AGR(N1,Alpha);List.AGCR(N1,);opened;List.OnNewRecord;List.AGCR(,);new(||0|No)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardNewHandler')]
    procedure HandedRecordToACard()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Log.Reset();
        Item.SetRange(Name, 'Alpha');
        Item.SetRange(Qty, 7);
        Page.Run(Page::"LT PnG Card", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(N1,Alpha);Card.AGCR(N1,Alpha);opened(N1);Card.OnNewRecord;Card.AGCR(,);new(||0);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure ListPendingNewRowSavedBeforeAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
        Item: Record "LT PnG Item";
    begin
        Seed();
        List.OpenEdit();
        List.New();
        List.NoCtl.SetValue('P1');
        List.NameCtl.SetValue('Pending');
        Log.Reset();
        List.ReadTableRow.Invoke();
        Observer.Observe('action-log', Log.Dump());
        Observer.Observe('stored-p1', Format(Item.Get('P1')));
        List.Close();
        Observer.Expect('action-log', 'List.AGR(P1,Pending);ReadTable(P1,Yes);List.AGR(P1,Pending);List.AGR(P1,Pending);List.AGR(N2,Beta);List.AGR(N1,Alpha);List.AGR(P1,Pending);List.AGR(P1,Pending);List.AGCR(P1,P1)');
        Observer.Expect('stored-p1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CardPendingNewRowSavedBeforeAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Card: TestPage "LT PnG Card";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Card.OpenNew();
        Card.NoCtl.SetValue('P2');
        Card.NameCtl.SetValue('Pending card');
        Log.Reset();
        Card.ReadTableRow.Invoke();
        Observer.Observe('action-log', Log.Dump());
        Observer.Observe('stored-p2', Format(Item.Get('P2')));
        Card.Close();
        Observer.Expect('action-log', 'Card.AGR(P2,Pending card);ReadTable(Yes);Card.AGR(P2,Pending card);Card.AGR(P2,Pending card);Card.AGCR(P2,Pending card)');
        Observer.Expect('stored-p2', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PartPendingNewRowSavedBeforeAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc";
        Head: Record "LT PnG Head";
        Line: Record "LT PnG Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."Code" := 'D1';
        Head.Insert();
        Doc.OpenEdit();
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('Pending part');
        Log.Reset();
        Doc.Lines.ReadTableRow.Invoke();
        Observer.Observe('action-log', Log.Dump());
        Observer.Observe('stored-lines', Format(Line.Count()));
        Doc.Close();
        Observer.Expect('action-log', 'Part.AGR(D1/20000);PartReadTable(D1/20000,Yes);Part.AGR(D1/20000);Part.AGR(D1/20000)');
        Observer.Expect('stored-lines', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ListPendingEditSavedBeforeAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
        Item: Record "LT PnG Item";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        List.NameCtl.SetValue('Edited before action');
        Log.Reset();
        List.ReadTableRow.Invoke();
        Item.Get('N1');
        Observer.Observe('stored-name-after-action', Item.Name);
        Observer.Observe('action-log', Log.Dump());
        List.Close();
        Observer.Expect('stored-name-after-action', 'Edited before action');
        Observer.Expect('action-log', 'List.AGR(N1,Edited before action);ReadTable(N1,Yes);List.AGR(N1,Edited before action);List.AGR(N1,Edited before action);List.AGR(N2,Beta);List.AGR(N1,Edited before action);List.AGR(N1,Edited before action);List.AGCR(N1,N1)');
        Observer.Verify();
    end;

    [PageHandler]
    procedure ListNewHandler(var List: TestPage "LT PnG List")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('opened');
        if Mode = 2 then begin
            List.New();
            Log.Add('new(' + List.NoCtl.Value() + '|' + List.NameCtl.Value() + '|' + List.QtyCtl.Value() + '|' + List.FlagCtl.Value() + ')');
            exit;
        end;
        List.New();
        Log.Add('new(' + List.NoCtl.Value() + '|' + List.NameCtl.Value() + '|' + List.QtyCtl.Value() + '|' + List.FlagCtl.Value() + ')');
        List.NoCtl.SetValue('NEWROW');
        Log.Add('after-key(' + List.NameCtl.Value() + '|' + List.QtyCtl.Value() + '|' + List.FlagCtl.Value() + ')');
    end;

    [PageHandler]
    procedure CardNewHandler(var Card: TestPage "LT PnG Card")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('opened(' + Card.NoCtl.Value() + ')');
        Card.New();
        Log.Add('new(' + Card.NoCtl.Value() + '|' + Card.NameCtl.Value() + '|' + Card.QtyCtl.Value() + ')');
    end;
}
