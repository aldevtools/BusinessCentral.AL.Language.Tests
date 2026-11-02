// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-modifyallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables "LT Y80 Row" and "LT Y80 Log" (pages/lt-y80-gone-rows/Y80GoneRows.al); own objects 94236 - 94241
// Probe (writer Y80, from the runtime lane rt-pages-1102c): a changed row saved on a page whose ModifyAllowed is false, other than at Close.
//   pages/lt-y61-page-probes/Y61ModifyDeniedSave.al pins a List and a Card for: an action that assigns, Rec.Modify in an action, SetValue then Next,
//   SetValue then an action with CurrPage.SaveRecord, a Card with CurrPage.Update(true) (the step that saves gives 'Page cannot be saved.', code
//   SaveAbort, and the page keeps the changed value). Here the other steps after a SetValue: Previous, First, Last, GoToKey, New, an action with
//   CurrPage.Update(true) and Update(false), a second SetValue on another control; on a List, a Worksheet, a Card and a Document with a ListPart
//   (a SetValue in the header and in the part, then a move of the part and of the host). Each step runs in a TryFunction and reports ok, the
//   error text and code and the log of the page's OnModifyRecord (P:) and the table's OnModify (M:).
// BC versions: 27, 28, 29

page 94237 "LT Y80 MD List"
{
    PageType = List;
    SourceTable = "LT Y80 Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                end;
            }
            action(UpdateTrueAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(UpdateFalseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('P:' + Format(Rec.Id));
        exit(true);
    end;
}

page 94238 "LT Y80 MD Card"
{
    PageType = Card;
    SourceTable = "LT Y80 Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                end;
            }
            action(UpdateTrueAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(UpdateFalseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('P:' + Format(Rec.Id));
        exit(true);
    end;
}

page 94239 "LT Y80 MD Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y80 Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                end;
            }
            action(UpdateTrueAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(UpdateFalseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('P:' + Format(Rec.Id));
        exit(true);
    end;
}

page 94241 "LT Y80 MD Line Part"
{
    PageType = ListPart;
    SourceTable = "LT Y80 Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('P:' + Format(Rec.Id));
        exit(true);
    end;
}

page 94240 "LT Y80 MD Doc"
{
    PageType = Document;
    SourceTable = "LT Y80 Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            part(Lines; "LT Y80 MD Line Part") { ApplicationArea = All; }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('P:' + Format(Rec.Id));
        exit(true);
    end;
}

codeunit 94236 "LT Y80 Modify Denied Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y80 Row";
        Log: Record "LT Y80 Log";
        I: Integer;
    begin
        ClearLastError();
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I * 10;
            Row.Txt := 'r' + Format(I * 10);
            Row.Num := I;
            Row.Insert();
        end;
        Log.DeleteAll();
    end;

    local procedure Stored(Id: Integer): Text
    var
        Row: Record "LT Y80 Row";
    begin
        Row.Get(Id);
        exit(Row.Txt + '/' + Format(Row.Num));
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [TryFunction]
    local procedure TryList(var P: TestPage "LT Y80 MD List"; Which: Text)
    begin
        case Which of
            'set':
                P.TxtCtl.SetValue('x');
            'set2':
                P.NumCtl.SetValue(77);
            'next':
                P.Next();
            'previous':
                P.Previous();
            'first':
                P.First();
            'last':
                P.Last();
            'goto':
                P.GoToKey(30);
            'new':
                P.New();
            'save':
                P.SaveAct.Invoke();
            'updatetrue':
                P.UpdateTrueAct.Invoke();
            'updatefalse':
                P.UpdateFalseAct.Invoke();
            'close':
                P.Close();
        end;
    end;

    [TryFunction]
    local procedure TryCard(var P: TestPage "LT Y80 MD Card"; Which: Text)
    begin
        case Which of
            'set':
                P.TxtCtl.SetValue('x');
            'set2':
                P.NumCtl.SetValue(77);
            'next':
                P.Next();
            'previous':
                P.Previous();
            'first':
                P.First();
            'last':
                P.Last();
            'goto':
                P.GoToKey(30);
            'new':
                P.New();
            'save':
                P.SaveAct.Invoke();
            'updatetrue':
                P.UpdateTrueAct.Invoke();
            'updatefalse':
                P.UpdateFalseAct.Invoke();
            'close':
                P.Close();
        end;
    end;

    [TryFunction]
    local procedure TryWorksheet(var P: TestPage "LT Y80 MD Worksheet"; Which: Text)
    begin
        case Which of
            'set':
                P.TxtCtl.SetValue('x');
            'set2':
                P.NumCtl.SetValue(77);
            'next':
                P.Next();
            'previous':
                P.Previous();
            'first':
                P.First();
            'last':
                P.Last();
            'goto':
                P.GoToKey(30);
            'new':
                P.New();
            'save':
                P.SaveAct.Invoke();
            'updatetrue':
                P.UpdateTrueAct.Invoke();
            'updatefalse':
                P.UpdateFalseAct.Invoke();
            'close':
                P.Close();
        end;
    end;

    [TryFunction]
    local procedure TryDoc(var P: TestPage "LT Y80 MD Doc"; Which: Text)
    begin
        case Which of
            'set':
                P.TxtCtl.SetValue('x');
            'next':
                P.Next();
            'last':
                P.Last();
            'first':
                P.First();
            'partset':
                P.Lines.TxtCtl.SetValue('p');
            'partnext':
                P.Lines.Next();
            'partfirst':
                P.Lines.First();
            'partlast':
                P.Lines.Last();
            'close':
                P.Close();
        end;
    end;

    [Test]
    procedure Y80_MD_List_Set_previous()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('previous', TryList(P, 'previous'));
        Observer.Observe('shown after previous', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('previous ok', 'Yes');
        Observer.Expect('previous|text', 'Page cannot be saved.');
        Observer.Expect('previous|code', 'SaveAbort');
        Observer.Expect('previous log', '');
        Observer.Expect('shown after previous', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_first()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('first', TryList(P, 'first'));
        Observer.Observe('shown after first', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', 'Page cannot be saved.');
        Observer.Expect('first|code', 'SaveAbort');
        Observer.Expect('first log', '');
        Observer.Expect('shown after first', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_last()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('last', TryList(P, 'last'));
        Observer.Observe('shown after last', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('last ok', 'Yes');
        Observer.Expect('last|text', 'Page cannot be saved.');
        Observer.Expect('last|code', 'SaveAbort');
        Observer.Expect('last log', '');
        Observer.Expect('shown after last', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_goto()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('goto', TryList(P, 'goto'));
        Observer.Observe('shown after goto', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('goto ok', 'No');
        Observer.Expect('goto|text', 'The row does not exist on the TestPage.');
        Observer.Expect('goto|code', 'TestRowNotFound');
        Observer.Expect('goto log', '');
        Observer.Expect('shown after goto', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_new()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('new', TryList(P, 'new'));
        Observer.Observe('shown after new', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', 'Page cannot be saved.');
        Observer.Expect('new|code', 'SaveAbort');
        Observer.Expect('new log', '');
        Observer.Expect('shown after new', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_updatetrue()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('updatetrue', TryList(P, 'updatetrue'));
        Observer.Observe('shown after updatetrue', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatetrue ok', 'Yes');
        Observer.Expect('updatetrue|text', 'Page cannot be saved.');
        Observer.Expect('updatetrue|code', 'SaveAbort');
        Observer.Expect('updatetrue log', '');
        Observer.Expect('shown after updatetrue', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_updatefalse()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('updatefalse', TryList(P, 'updatefalse'));
        Observer.Observe('shown after updatefalse', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatefalse ok', 'Yes');
        Observer.Expect('updatefalse|text', 'Page cannot be saved.');
        Observer.Expect('updatefalse|code', 'SaveAbort');
        Observer.Expect('updatefalse log', '');
        Observer.Expect('shown after updatefalse', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_Set2_Next()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('set2', TryList(P, 'set2'));
        Observer.Observe('shown after set2', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('next', TryList(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('set2 ok', 'Yes');
        Observer.Expect('set2|text', '');
        Observer.Expect('set2|code', '');
        Observer.Expect('set2 log', '');
        Observer.Expect('shown after set2', '10/x/77');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/77');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_List_Set_Next_Next()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryList(P, 'set'));
        Step('next', TryList(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('next', TryList(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryList(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/1');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_previous()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('previous', TryCard(P, 'previous'));
        Observer.Observe('shown after previous', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('previous ok', 'Yes');
        Observer.Expect('previous|text', 'Page cannot be saved.');
        Observer.Expect('previous|code', 'SaveAbort');
        Observer.Expect('previous log', '');
        Observer.Expect('shown after previous', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_first()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('first', TryCard(P, 'first'));
        Observer.Observe('shown after first', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', 'Page cannot be saved.');
        Observer.Expect('first|code', 'SaveAbort');
        Observer.Expect('first log', '');
        Observer.Expect('shown after first', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_last()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('last', TryCard(P, 'last'));
        Observer.Observe('shown after last', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('last ok', 'Yes');
        Observer.Expect('last|text', 'Page cannot be saved.');
        Observer.Expect('last|code', 'SaveAbort');
        Observer.Expect('last log', '');
        Observer.Expect('shown after last', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_goto()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('goto', TryCard(P, 'goto'));
        Observer.Observe('shown after goto', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('goto ok', 'No');
        Observer.Expect('goto|text', 'The row does not exist on the TestPage.');
        Observer.Expect('goto|code', 'TestRowNotFound');
        Observer.Expect('goto log', '');
        Observer.Expect('shown after goto', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_new()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('new', TryCard(P, 'new'));
        Observer.Observe('shown after new', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', 'Page cannot be saved.');
        Observer.Expect('new|code', 'SaveAbort');
        Observer.Expect('new log', '');
        Observer.Expect('shown after new', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_updatetrue()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('updatetrue', TryCard(P, 'updatetrue'));
        Observer.Observe('shown after updatetrue', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatetrue ok', 'Yes');
        Observer.Expect('updatetrue|text', 'Page cannot be saved.');
        Observer.Expect('updatetrue|code', 'SaveAbort');
        Observer.Expect('updatetrue log', '');
        Observer.Expect('shown after updatetrue', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_updatefalse()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('updatefalse', TryCard(P, 'updatefalse'));
        Observer.Observe('shown after updatefalse', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatefalse ok', 'Yes');
        Observer.Expect('updatefalse|text', 'Page cannot be saved.');
        Observer.Expect('updatefalse|code', 'SaveAbort');
        Observer.Expect('updatefalse log', '');
        Observer.Expect('shown after updatefalse', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Card_Set_Set2_Next()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryCard(P, 'set'));
        Step('set2', TryCard(P, 'set2'));
        Observer.Observe('shown after set2', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('next', TryCard(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryCard(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('set2 ok', 'Yes');
        Observer.Expect('set2|text', '');
        Observer.Expect('set2|code', '');
        Observer.Expect('set2 log', '');
        Observer.Expect('shown after set2', '10/x/77');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/77');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_previous()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('previous', TryWorksheet(P, 'previous'));
        Observer.Observe('shown after previous', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('previous ok', 'Yes');
        Observer.Expect('previous|text', 'Page cannot be saved.');
        Observer.Expect('previous|code', 'SaveAbort');
        Observer.Expect('previous log', '');
        Observer.Expect('shown after previous', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_first()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.Last();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('first', TryWorksheet(P, 'first'));
        Observer.Observe('shown after first', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '30/r30/3');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', 'Page cannot be saved.');
        Observer.Expect('first|code', 'SaveAbort');
        Observer.Expect('first log', '');
        Observer.Expect('shown after first', '30/x/3');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_last()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('last', TryWorksheet(P, 'last'));
        Observer.Observe('shown after last', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('last ok', 'Yes');
        Observer.Expect('last|text', 'Page cannot be saved.');
        Observer.Expect('last|code', 'SaveAbort');
        Observer.Expect('last log', '');
        Observer.Expect('shown after last', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_goto()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('goto', TryWorksheet(P, 'goto'));
        Observer.Observe('shown after goto', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('goto ok', 'No');
        Observer.Expect('goto|text', 'The row does not exist on the TestPage.');
        Observer.Expect('goto|code', 'TestRowNotFound');
        Observer.Expect('goto log', '');
        Observer.Expect('shown after goto', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_new()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('new', TryWorksheet(P, 'new'));
        Observer.Observe('shown after new', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', 'Page cannot be saved.');
        Observer.Expect('new|code', 'SaveAbort');
        Observer.Expect('new log', '');
        Observer.Expect('shown after new', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_updatetrue()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('updatetrue', TryWorksheet(P, 'updatetrue'));
        Observer.Observe('shown after updatetrue', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatetrue ok', 'Yes');
        Observer.Expect('updatetrue|text', 'Page cannot be saved.');
        Observer.Expect('updatetrue|code', 'SaveAbort');
        Observer.Expect('updatetrue log', '');
        Observer.Expect('shown after updatetrue', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_updatefalse()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('updatefalse', TryWorksheet(P, 'updatefalse'));
        Observer.Observe('shown after updatefalse', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('updatefalse ok', 'Yes');
        Observer.Expect('updatefalse|text', 'Page cannot be saved.');
        Observer.Expect('updatefalse|code', 'SaveAbort');
        Observer.Expect('updatefalse log', '');
        Observer.Expect('shown after updatefalse', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_Set2_Next()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('set2', TryWorksheet(P, 'set2'));
        Observer.Observe('shown after set2', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('next', TryWorksheet(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('set2 ok', 'Yes');
        Observer.Expect('set2|text', '');
        Observer.Expect('set2|code', '');
        Observer.Expect('set2 log', '');
        Observer.Expect('shown after set2', '10/x/77');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/77');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Worksheet_Set_Next_Next()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('set', TryWorksheet(P, 'set'));
        Step('next', TryWorksheet(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Step('next', TryWorksheet(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + '/' + P.NumCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryWorksheet(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10/1');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/1');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x/1');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Doc_HeaderSet_Next()
    var
        P: TestPage "LT Y80 MD Doc";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('set', TryDoc(P, 'set'));
        Observer.Observe('shown after set', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('next', TryDoc(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryDoc(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10 part 10/r10');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('shown after set', '10/x part 10/r10');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '10/x part 10/r10');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Doc_HeaderSet_PartFirst()
    var
        P: TestPage "LT Y80 MD Doc";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('set', TryDoc(P, 'set'));
        Observer.Observe('shown after set', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partfirst', TryDoc(P, 'partfirst'));
        Observer.Observe('shown after partfirst', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryDoc(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10 part 10/r10');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('set log', '');
        Observer.Expect('shown after set', '10/x part 10/r10');
        Observer.Expect('partfirst ok', 'Yes');
        Observer.Expect('partfirst|text', '');
        Observer.Expect('partfirst|code', '');
        Observer.Expect('partfirst log', '');
        Observer.Expect('shown after partfirst', '10/x part 10/r10');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Doc_PartSet_PartNext()
    var
        P: TestPage "LT Y80 MD Doc";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partset', TryDoc(P, 'partset'));
        Observer.Observe('shown after partset', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partnext', TryDoc(P, 'partnext'));
        Observer.Observe('shown after partnext', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryDoc(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10 part 10/r10');
        Observer.Expect('partset ok', 'Yes');
        Observer.Expect('partset|text', '');
        Observer.Expect('partset|code', '');
        Observer.Expect('partset log', '');
        Observer.Expect('shown after partset', '10/r10 part 10/p');
        Observer.Expect('partnext ok', 'Yes');
        Observer.Expect('partnext|text', 'Page cannot be saved.');
        Observer.Expect('partnext|code', 'SaveAbort');
        Observer.Expect('partnext log', '');
        Observer.Expect('shown after partnext', '10/r10 part 10/p');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Doc_PartSet_HostNext()
    var
        P: TestPage "LT Y80 MD Doc";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partset', TryDoc(P, 'partset'));
        Observer.Observe('shown after partset', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('next', TryDoc(P, 'next'));
        Observer.Observe('shown after next', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryDoc(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10 part 10/r10');
        Observer.Expect('partset ok', 'Yes');
        Observer.Expect('partset|text', '');
        Observer.Expect('partset|code', '');
        Observer.Expect('partset log', '');
        Observer.Expect('shown after partset', '10/r10 part 10/p');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('shown after next', '20/r20 part 10/p');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_MD_Doc_PartSet_PartLast()
    var
        P: TestPage "LT Y80 MD Doc";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('start', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partset', TryDoc(P, 'partset'));
        Observer.Observe('shown after partset', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Step('partlast', TryDoc(P, 'partlast'));
        Observer.Observe('shown after partlast', P.IdCtl.Value() + '/' + P.TxtCtl.Value() + ' part ' + P.Lines.IdCtl.Value() + '/' + P.Lines.TxtCtl.Value());
        Observer.Observe('stored 10', Stored(10));
        Step('close', TryDoc(P, 'close'));
        Observer.Observe('stored 10 after close', Stored(10));
        Observer.Expect('start', '10/r10 part 10/r10');
        Observer.Expect('partset ok', 'Yes');
        Observer.Expect('partset|text', '');
        Observer.Expect('partset|code', '');
        Observer.Expect('partset log', '');
        Observer.Expect('shown after partset', '10/r10 part 10/p');
        Observer.Expect('partlast ok', 'Yes');
        Observer.Expect('partlast|text', 'Page cannot be saved.');
        Observer.Expect('partlast|code', 'SaveAbort');
        Observer.Expect('partlast log', '');
        Observer.Expect('shown after partlast', '10/r10 part 10/p');
        Observer.Expect('stored 10', 'r10/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored 10 after close', 'r10/1');
        Observer.Verify();
    end;
}
