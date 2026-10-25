// Probe: pages with OnFindRecord / OnNextRecord. CurrPage.Update on such a page (what the client asks next, what a control reads before the next move), and a row deleted by an action when the page serves only one row at a time while the table holds more.
// Settles: md:276 (CurrPage.Update on a page with OnFindRecord / OnNextRecord; trace and control values afterwards), md:277 (one-row window over a view with more rows).
// Writer SF (al-runtime-rs assumption update-refresh-list-onfindrecord): SF_ tests, pages 89060-89062 (a list with OnFindRecord only, a list part and its host card).

codeunit 68733 "W2 Update Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 68734 "W2 Find Update List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    CurrPage.Update(false);
                    Log.Add('ActionEnd');
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    CurrPage.Update(true);
                    Log.Add('ActionEnd');
                end;
            }
            // The stored row changes behind the page's back, then the page is told to refresh.
            action(ChangeStoredRowAndUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                    Other: Record "W2 Below Row";
                begin
                    Log.Add('ActionBegin');
                    Other.Get(Rec.Id);
                    Other.Name := 'stored';
                    Other.Modify();
                    CurrPage.Update(false);
                    Log.Add('ActionEnd');
                end;
            }
            // Rec changes in memory, then Update(true) saves it.
            action(ChangeRecAndUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    Rec.Name := 'memory';
                    CurrPage.Update(true);
                    Log.Add('ActionEnd');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('Find(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "W2 Update Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('Next(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
    end;
}

// Serves one row per window: OnNextRecord never moves.
page 68736 "W2 One Row List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrent)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    Rec.Delete();
                    Log.Add('ActionEnd');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('Find(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('Next(' + Format(Steps) + ')=0');
        exit(0);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
    end;
}

codeunit 68735 "W2 Update Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W2 Below Row";
        Log: Codeunit "W2 Update Log";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Name := 'ten';
        Row.Insert();
        Row.Id := 20;
        Row.Name := 'twenty';
        Row.Insert();
        Row.Id := 30;
        Row.Name := 'thirty';
        Row.Insert();
        Log.Take();
    end;

    local procedure AfterActionEnd(Trace: Text): Text
    var
        Position: Integer;
    begin
        Position := StrPos(Trace, 'ActionEnd;');
        if Position = 0 then
            exit('<no ActionEnd>');
        exit(CopyStr(Trace, Position + StrLen('ActionEnd;')));
    end;

    // ---- md:276 ----

    [Test]
    procedure Update_False_OnOpenedPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 Find Update List";
        Trace: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(20);
        Log.Take();
        Pg.UpdateFalse.Invoke();
        Trace := Log.Take();
        Observer.Observe('during_action', CopyStr(Trace, 1, StrPos(Trace, 'ActionEnd;') + 9));
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('name_after', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('during_action', 'AGR(20);ActionBegin;ActionEnd;');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('id_after', '20');
        Observer.Expect('name_after', 'twenty');
        Observer.Verify();
    end;

    [Test]
    procedure Update_True_OnOpenedPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 Find Update List";
        Trace: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(20);
        Log.Take();
        Pg.UpdateTrue.Invoke();
        Trace := Log.Take();
        Observer.Observe('during_action', CopyStr(Trace, 1, StrPos(Trace, 'ActionEnd;') + 9));
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('during_action', 'AGR(20);ActionBegin;ActionEnd;');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('id_after', '20');
        Observer.Verify();
    end;

    [Test]
    procedure Update_StoredRowChangedBehindThePage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 Find Update List";
        Trace: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(20);
        Log.Take();
        Pg.ChangeStoredRowAndUpdate.Invoke();
        Trace := Log.Take();
        Observer.Observe('during_action', CopyStr(Trace, 1, StrPos(Trace, 'ActionEnd;') + 9));
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('name_read_directly_after', Pg.Name.Value());
        Observer.Observe('id_after', Pg.Id.Value());
        Pg.Next();
        Observer.Observe('after_next', Log.Take());
        Pg.Previous();
        Observer.Observe('name_after_moving_back', Pg.Name.Value());
        Pg.Close();
        Observer.Expect('during_action', 'AGR(20);ActionBegin;ActionEnd;');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('name_read_directly_after', 'stored');
        Observer.Expect('id_after', '20');
        Observer.Expect('after_next', 'AGR(30);Find(=);AGR(30);AGCR(30);');
        Observer.Expect('name_after_moving_back', 'stored');
        Observer.Verify();
    end;

    [Test]
    procedure Update_True_AfterRecChangedInMemory()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Row: Record "W2 Below Row";
        Pg: TestPage "W2 Find Update List";
        Trace: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(20);
        Log.Take();
        Pg.ChangeRecAndUpdateTrue.Invoke();
        Trace := Log.Take();
        Observer.Observe('during_action', CopyStr(Trace, 1, StrPos(Trace, 'ActionEnd;') + 9));
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('name_read_directly_after', Pg.Name.Value());
        Pg.Close();
        Row.Get(20);
        Observer.Observe('name_stored', Row.Name);
        Observer.Expect('during_action', 'AGR(20);ActionBegin;ActionEnd;');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('name_read_directly_after', 'memory');
        Observer.Expect('name_stored', 'memory');
        Observer.Verify();
    end;

    // ---- md:277 ----

    [Test]
    procedure OneRowWindow_DeleteFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 One Row List";
        Trace: Text;
    begin
        Seed();
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('id_at_open', Pg.Id.Value());
        Pg.DeleteCurrent.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('open', 'Find(=><);AGR(10);Next(1)=0;Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_at_open', '10');
        Observer.Expect('after_action', 'Next(1)=0;Next(-1)=0;AGCR(0);AGR(10);Find(=>);AGR(20);Next(1)=0;Next(-1)=0;Find(=);AGR(20);AGCR(20);AGCR(0);');
        Observer.Expect('id_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OneRowWindow_DeleteAfterGoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 One Row List";
        Trace: Text;
        Ok: Boolean;
        Found: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Found := false;
        Ok := TryGoTo(Pg, Found);
        Observer.Observe('goto|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('goto');
        Observer.Observe('goto|found', Format(Found));
        Observer.Observe('id_at_goto', Pg.Id.Value());
        Log.Take();
        Pg.DeleteCurrent.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('goto|ok', 'Yes');
        Observer.Expect('goto|found', 'No');
        Observer.Expect('id_at_goto', '10');
        Observer.Expect('after_action', 'Next(1)=0;Next(-1)=0;AGCR(0);AGR(10);Find(=>);AGR(20);Next(1)=0;Next(-1)=0;Find(=);AGR(20);AGCR(20);AGCR(0);');
        Observer.Expect('id_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OneRowWindow_DeleteLastRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 One Row List";
        Trace: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Last();
        Observer.Observe('id_at_last', Pg.Id.Value());
        Log.Take();
        Pg.DeleteCurrent.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Pg.Close();
        Observer.Expect('id_at_last', '10');
        Observer.Expect('after_action', 'Next(1)=0;Next(-1)=0;AGCR(0);AGR(10);Find(=>);AGR(20);Next(1)=0;Next(-1)=0;Find(=);AGR(20);AGCR(20);AGCR(0);');
        Observer.Expect('id_after', '0');
        Observer.Verify();
    end;

    // ---- writer SF (al-runtime-rs assumption update-refresh-list-onfindrecord): CurrPage.Update(false) on lists with 1, 2, 5 and 25 rows,
    //      the cursor on the first, a middle and the last row; a list with OnFindRecord only; a list part of a card. ----

    local procedure SfSeed(Count: Integer)
    var
        Row: Record "W2 Below Row";
        Log: Codeunit "W2 Update Log";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to Count do begin
            Row.Init();
            Row.Id := Index * 10;
            Row.Name := 'r' + Format(Index * 10);
            Row.Insert();
        end;
        Log.Take();
    end;

    // Opens the list on Count rows, moves the cursor to the row with Id CursorId, runs the action that calls CurrPage.Update(false).
    local procedure SfListUpdate(var Observer: Codeunit "Probe Observer"; Count: Integer; CursorId: Integer)
    var
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "W2 Find Update List";
        Trace: Text;
    begin
        SfSeed(Count);
        Pg.OpenEdit();
        Observer.Observe('goto', Format(Pg.GoToKey(CursorId)));
        Log.Take();
        Pg.UpdateFalse.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('next', Format(Pg.Next()));
        Observer.Observe('id_next', Pg.Id.Value());
        Observer.Observe('next_trace', Log.Take());
        Pg.Close();
    end;

    [Test]
    procedure SF_Update_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 1, 10);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(10);Find(=>);AGR(10);Next(1)=0;Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_after', '10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_TwoRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 2, 10);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(10);Find(=>);AGR(10);Next(1)=1;AGR(20);Next(1)=0;AGR(10);Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_after', '10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '20');
        Observer.Expect('next_trace', 'AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_TwoRows_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 2, 20);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=0;Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('id_after', '20');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_FiveRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 5, 10);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(10);Find(=>);AGR(10);Next(1)=1;AGR(20);Next(1)=1;AGR(30);Next(1)=1;AGR(40);Next(1)=1;AGR(50);Next(1)=0;AGR(10);Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_after', '10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '20');
        Observer.Expect('next_trace', 'AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_FiveRows_Middle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 5, 30);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(30);Find(=>);AGR(30);Next(1)=1;AGR(40);Next(1)=1;AGR(50);Next(1)=0;AGR(30);Next(-1)=-1;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(30);Find(=);AGR(30);AGCR(30);');
        Observer.Expect('id_after', '30');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '40');
        Observer.Expect('next_trace', 'AGR(40);Find(=);AGR(40);AGCR(40);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_FiveRows_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 5, 50);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(50);Find(=>);AGR(50);Next(1)=0;Next(-1)=-1;AGR(40);Next(-1)=-1;AGR(30);Next(-1)=-1;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(50);Find(=);AGR(50);AGCR(50);');
        Observer.Expect('id_after', '50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_TwentyFiveRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 25, 10);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(10);Find(=>);AGR(10);Next(1)=1;AGR(20);Next(1)=1;AGR(30);Next(1)=1;AGR(40);Next(1)=1;AGR(50);Next(1)=1;AGR(60);Next(1)=1;AGR(70);Next(1)=1;AGR(80);Next(1)=1;AGR(90);Next(1)=1;AGR(100);Next(1)=1;AGR(110);Next(1)=1;AGR(120);Next(1)=1;AGR(130);Next(1)=1;AGR(140);Next(1)=1;AGR(150);Next(1)=1;AGR(160);Next(1)=1;AGR(170);Next(1)=1;AGR(180);Next(1)=1;AGR(190);Next(1)=1;AGR(200);AGR(10);Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_after', '10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '20');
        Observer.Expect('next_trace', 'AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_TwentyFiveRows_Middle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 25, 130);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(130);Find(=>);AGR(130);Next(1)=1;AGR(140);Next(1)=1;AGR(150);Next(1)=1;AGR(160);Next(1)=1;AGR(170);Next(1)=1;AGR(180);Next(1)=1;AGR(190);Next(1)=1;AGR(200);Next(1)=1;AGR(210);Next(1)=1;AGR(220);Next(1)=1;AGR(230);Next(1)=1;AGR(240);Next(1)=1;AGR(250);Next(1)=0;AGR(130);Next(-1)=-1;AGR(120);Next(-1)=-1;AGR(110);Next(-1)=-1;AGR(100);Next(-1)=-1;AGR(90);Next(-1)=-1;AGR(80);Next(-1)=-1;AGR(70);Next(-1)=-1;AGR(60);Next(-1)=-1;AGR(50);Next(-1)=-1;AGR(40);Next(-1)=-1;AGR(30);Next(-1)=-1;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(130);Find(=);AGR(130);AGCR(130);');
        Observer.Expect('id_after', '130');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '140');
        Observer.Expect('next_trace', 'AGR(140);Find(=);AGR(140);AGCR(140);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Update_TwentyFiveRows_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfListUpdate(Observer, 25, 250);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(250);Find(=>);AGR(250);Next(1)=0;Next(-1)=-1;AGR(240);Next(-1)=-1;AGR(230);Next(-1)=-1;AGR(220);Next(-1)=-1;AGR(210);Next(-1)=-1;AGR(200);Next(-1)=-1;AGR(190);Next(-1)=-1;AGR(180);Next(-1)=-1;AGR(170);Next(-1)=-1;AGR(160);Next(-1)=-1;AGR(150);Next(-1)=-1;AGR(140);Next(-1)=-1;AGR(130);Next(-1)=-1;AGR(120);Next(-1)=-1;AGR(110);Next(-1)=-1;AGR(100);Next(-1)=-1;AGR(90);Next(-1)=-1;AGR(80);Next(-1)=-1;AGR(70);Next(-1)=-1;AGR(60);Next(-1)=-1;AGR(50);AGR(250);AGR(50);Next(-1)=-1;AGR(40);Next(-1)=-1;AGR(30);Next(-1)=-1;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(250);Find(=);AGR(250);AGCR(250);');
        Observer.Expect('id_after', '250');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    // The list with OnFindRecord and no OnNextRecord.
    local procedure SfFindOnlyUpdate(var Observer: Codeunit "Probe Observer"; Count: Integer; CursorId: Integer)
    var
        Log: Codeunit "W2 Update Log";
        Pg: TestPage "LT SF Find Only List";
        Trace: Text;
    begin
        SfSeed(Count);
        Pg.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('goto', Format(Pg.GoToKey(CursorId)));
        Log.Take();
        Pg.UpdateFalse.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Pg.Id.Value());
        Observer.Observe('next', Format(Pg.Next()));
        Observer.Observe('id_next', Pg.Id.Value());
        Observer.Observe('next_trace', Log.Take());
        Pg.Close();
    end;

    [Test]
    procedure SF_FindOnly_ThreeRows_Middle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfFindOnlyUpdate(Observer, 3, 20);
        Observer.Expect('open', 'Find(=><);AGR(10);AGR(20);AGR(30);AGR(10);Find(=);AGR(10);AGCR(10);');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);AGR(30);AGR(20);AGR(10);AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('id_after', '20');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '30');
        Observer.Expect('next_trace', 'AGR(30);Find(=);AGR(30);AGCR(30);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_FindOnly_FiveRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfFindOnlyUpdate(Observer, 5, 10);
        Observer.Expect('open', 'Find(=><);AGR(10);AGR(20);AGR(30);AGR(40);AGR(50);AGR(10);Find(=);AGR(10);AGCR(10);');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(10);Find(=>);AGR(10);AGR(20);AGR(30);AGR(40);AGR(50);AGR(10);Find(=);AGR(10);AGCR(10);');
        Observer.Expect('id_after', '10');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '20');
        Observer.Expect('next_trace', 'AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_FindOnly_TwentyFiveRows_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfFindOnlyUpdate(Observer, 25, 250);
        Observer.Expect('open', 'Find(=><);AGR(10);AGR(20);AGR(30);AGR(40);AGR(50);AGR(60);AGR(70);AGR(80);AGR(90);AGR(100);AGR(110);AGR(120);AGR(130);AGR(140);AGR(150);AGR(160);AGR(170);AGR(180);AGR(190);AGR(200);AGR(10);Find(=);AGR(10);AGCR(10);');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(250);Find(=>);AGR(250);AGR(240);AGR(230);AGR(220);AGR(210);AGR(200);AGR(190);AGR(180);AGR(170);AGR(160);AGR(150);AGR(140);AGR(130);AGR(120);AGR(110);AGR(100);AGR(90);AGR(80);AGR(70);AGR(60);AGR(50);AGR(250);AGR(50);AGR(40);AGR(30);AGR(20);AGR(10);AGR(250);Find(=);AGR(250);AGCR(250);');
        Observer.Expect('id_after', '250');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    // A list part (OnFindRecord and OnNextRecord) on a card: the part's own action calls CurrPage.Update(false).
    local procedure SfPartUpdate(var Observer: Codeunit "Probe Observer"; Count: Integer; CursorId: Integer)
    var
        Log: Codeunit "W2 Update Log";
        Host: TestPage "LT SF Find Host";
        Trace: Text;
    begin
        SfSeed(Count);
        Host.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('goto', Format(Host.Rows.GoToKey(CursorId)));
        Log.Take();
        Host.Rows.UpdateFalse.Invoke();
        Trace := Log.Take();
        Observer.Observe('after_action', AfterActionEnd(Trace));
        Observer.Observe('id_after', Host.Rows.Id.Value());
        Observer.Observe('next', Format(Host.Rows.Next()));
        Observer.Observe('id_next', Host.Rows.Id.Value());
        Observer.Observe('next_trace', Log.Take());
        Host.Close();
    end;

    [Test]
    procedure SF_Part_ThreeRows_Middle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfPartUpdate(Observer, 3, 20);
        Observer.Expect('open', 'Find(=><);AGR(10);Next(1)=1;AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(10);Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(20);Find(=>);AGR(20);Next(1)=1;AGR(30);Next(1)=0;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(20);Find(=);AGR(20);AGCR(20);');
        Observer.Expect('id_after', '20');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '30');
        Observer.Expect('next_trace', 'AGR(30);Find(=);AGR(30);AGCR(30);');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Part_FiveRows_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfPartUpdate(Observer, 5, 50);
        Observer.Expect('open', 'Find(=><);AGR(10);Next(1)=1;AGR(20);Next(1)=1;AGR(30);Next(1)=1;AGR(40);Next(1)=1;AGR(50);Next(1)=0;AGR(10);Next(-1)=0;Find(=);AGR(10);AGCR(10);');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('after_action', 'AGR(50);Find(=>);AGR(50);Next(1)=0;Next(-1)=-1;AGR(40);Next(-1)=-1;AGR(30);Next(-1)=-1;AGR(20);Next(-1)=-1;AGR(10);Next(-1)=0;AGR(50);Find(=);AGR(50);AGCR(50);');
        Observer.Expect('id_after', '50');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id_next', '0');
        Observer.Expect('next_trace', 'AGCR(0);');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGoTo(var Pg: TestPage "W2 One Row List"; var Found: Boolean)
    begin
        Found := Pg.GoToKey(20);
    end;
}

// Writer SF: a list with OnFindRecord only (no OnNextRecord).
page 89060 "LT SF Find Only List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    CurrPage.Update(false);
                    Log.Add('ActionEnd');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('Find(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
    end;
}

// Writer SF: a list part with OnFindRecord and OnNextRecord, hosted by the card below.
page 89061 "LT SF Find Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "W2 Update Log";
                begin
                    Log.Add('ActionBegin');
                    CurrPage.Update(false);
                    Log.Add('ActionEnd');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('Find(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "W2 Update Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('Next(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGR(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "W2 Update Log";
    begin
        Log.Add('AGCR(' + Format(Rec.Id) + ')');
    end;
}

// Writer SF: a card (no triggers of its own) whose part is the list part above, without a link.
page 89062 "LT SF Find Host"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Below Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(HostId; Rec.Id) { ApplicationArea = All; }
            part(Rows; "LT SF Find Part")
            {
                ApplicationArea = All;
            }
        }
    }
}
