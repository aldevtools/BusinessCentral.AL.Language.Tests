// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.Update(false/true) on a list and on a card that have OnFindRecord, OnAfterGetRecord and OnAfterGetCurrRecord: the Which string asked of OnFindRecord and the order of the triggers that follow; after an edit that is saved already.
// BC versions: 29 (27 and 28 by CI)

table 74816 "LT P168 Upd Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74817 "LT P168 Upd Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Wipe()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ';';
            Result += Line;
        end;
        exit(Result);
    end;
}

page 74818 "LT P168 Upd List"
{
    PageType = List;
    SourceTable = "LT P168 Upd Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshPlain)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('act:Update(false)');
                    CurrPage.Update(false);
                    Log.Add('act:after');
                end;
            }
            action(RefreshSave)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('act:Update(true)');
                    CurrPage.Update(true);
                    Log.Add('act:after');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P168 Upd Log";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('Find:' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        Log.Add('Next:' + Format(Steps));
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGC:' + Format(Rec.Id));
    end;
}

page 74819 "LT P168 Upd Card"
{
    PageType = Card;
    SourceTable = "LT P168 Upd Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdF; Rec.Id) { ApplicationArea = All; }
            field(NameF; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshPlain)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('act:Update(false)');
                    CurrPage.Update(false);
                    Log.Add('act:after');
                end;
            }
            action(RefreshSave)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('act:Update(true)');
                    CurrPage.Update(true);
                    Log.Add('act:after');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P168 Upd Log";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('Find:' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGC:' + Format(Rec.Id));
    end;
}

codeunit 74820 "LT P168 Update Find Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P168 Upd Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'N' + Format(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure P168_List_UpdateFalse_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd List";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('open', Log.Joined());
        TP.GoToKey(2);
        Log.Wipe();
        TP.RefreshPlain.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('current', Format(TP.IdF.AsInteger()));
        TP.Close();
        Observer.Expect('open', 'Find:=><;AGR:1;Next:1;AGR:2;Next:1;AGR:3;Next:1;AGR:1;Next:-1;Find:=;AGR:1;AGC:1');
        Observer.Expect('update', 'AGR:2;act:Update(false);act:after;AGR:2;Find:=>;AGR:2;Next:1;AGR:3;Next:1;AGR:2;Next:-1;AGR:1;Next:-1;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Expect('current', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P168_List_UpdateTrue_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd List";
    begin
        Seed();
        TP.OpenView();
        TP.GoToKey(2);
        Log.Wipe();
        TP.RefreshSave.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('current', Format(TP.IdF.AsInteger()));
        TP.Close();
        Observer.Expect('update', 'AGR:2;act:Update(true);act:after;AGR:2;Find:=>;AGR:2;Next:1;AGR:3;Next:1;AGR:2;Next:-1;AGR:1;Next:-1;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Expect('current', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P168_List_UpdateOnLastRow_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd List";
    begin
        Seed();
        TP.OpenView();
        TP.Last();
        Log.Wipe();
        TP.RefreshPlain.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('current', Format(TP.IdF.AsInteger()));
        TP.Close();
        Observer.Expect('update', 'AGR:3;act:Update(false);act:after;AGR:3;Find:=>;AGR:3;Next:1;Next:-1;AGR:2;Next:-1;AGR:1;Next:-1;AGR:3;Find:=;AGR:3;AGC:3');
        Observer.Expect('current', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P168_List_UpdateAfterSavedEdit_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd List";
        Row: Record "LT P168 Upd Row";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey(2);
        TP.NameF.SetValue('Edited');
        Log.Wipe();
        TP.RefreshPlain.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('name', TP.NameF.Value());
        Row.Get(2);
        Observer.Observe('stored', Row.Name);
        TP.Close();
        Observer.Expect('update', 'AGR:2;act:Update(false);act:after;AGR:2;Find:=>;AGR:2;Next:1;AGR:3;Next:1;AGR:2;Next:-1;AGR:1;Next:-1;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Expect('name', 'Edited');
        Observer.Expect('stored', 'Edited');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Card_UpdateFalse_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd Card";
    begin
        Seed();
        TP.OpenView();
        TP.GoToKey(2);
        Log.Wipe();
        TP.RefreshPlain.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('current', Format(TP.IdF.AsInteger()));
        TP.Close();
        Observer.Expect('update', 'AGR:2;act:Update(false);act:after;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Expect('current', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Card_UpdateTrue_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd Card";
    begin
        Seed();
        TP.OpenView();
        TP.GoToKey(2);
        Log.Wipe();
        TP.RefreshSave.Invoke();
        Observer.Observe('update', Log.Joined());
        TP.Close();
        Observer.Expect('update', 'AGR:2;act:Update(true);act:after;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Card_UpdateAfterSavedEdit_LogsWhichAndTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P168 Upd Log";
        TP: TestPage "LT P168 Upd Card";
        Row: Record "LT P168 Upd Row";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey(2);
        TP.NameF.SetValue('Edited');
        Log.Wipe();
        TP.RefreshPlain.Invoke();
        Observer.Observe('update', Log.Joined());
        Observer.Observe('name', TP.NameF.Value());
        Row.Get(2);
        Observer.Observe('stored', Row.Name);
        TP.Close();
        Observer.Expect('update', 'AGR:2;act:Update(false);act:after;AGR:2;Find:=;AGR:2;AGC:2');
        Observer.Expect('name', 'Edited');
        Observer.Expect('stored', 'Edited');
        Observer.Verify();
    end;
}
