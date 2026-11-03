// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetrecord-page-trigger
// Scope: in-scope
// Fixtures used: self-contained table 69182, codeunit 69182 (log), pages 69182 to 69184, page extensions 69182 and 69183, codeunit 69183 (tests)
// Probe: written against a real BC 27.5 service tier through TestPage; every literal below is what that tier produced. Other BC versions were not measured.
//
// Which page triggers run again after an action, and in which order (log of the triggers of a base page and its extension; AGR = OnAfterGetRecord, AGCR = OnAfterGetCurrRecord,
// each as base then extension):
// - Open of a card: AGR, AGCR. Open of a list of 3 rows: 5 times AGR, then AGCR (the TestPage list reads more rows than the table has: its look-ahead is not a contract).
// - An action (no change, Rec.Modify() or only an in-memory change of Rec) is followed by the same reads, whatever the action did: a card AGR before the action runs, then after it
//   AGR, AGR, AGCR; a list AGR before it, then 6 times AGR and AGCR. After the in-memory change the TestPage still reads Name 'memory', after Modify() 'modified'.
// - Moving the cursor (Next / Last / First) reads the rows it passes and ends with AGCR once.
// - A page with OnFindRecord / OnNextRecord: open calls OnFindRecord('=><'), walks the rows with OnNextRecord(1) until it answers 0, steps back with OnNextRecord(-1), then
//   OnFindRecord('=') and AGR / AGCR of the current row; every move is "AGR of the new row, OnFindRecord('='), AGR, AGCR".
// DIRTY page (a field changed through the TestPage with SetValue before the action; tests Card_DirtyPage_... and List_DirtyPage_...): SetValue itself runs none of the base or
// extension read triggers. Each action (no change, Rec.Modify(), in-memory change) then reads exactly as on a clean page: a card AGR before the action body, then AGR, AGR, AGCR
// after it; a list AGR before it, then 6 times AGR and AGCR; Next after a dirty SetValue reads like a clean Next (card AGR, AGCR; list AGR, AGR, AGCR). The edited value survives
// the action (Name reads the dirty value, 'modified' after the action's Modify(), 'memory' after its in-memory change).
// BC versions: 27.5

table 69182 "PC Row"
{
    DataClassification = SystemMetadata;

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

codeunit 69182 "PC Log"
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

page 69182 "PC Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "PC Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoChange)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action NoChange');
                end;
            }
            action(ModifyRec)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action ModifyRec');
                    Rec.Name := 'modified';
                    Rec.Modify();
                end;
            }
            action(ChangeInMemory)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action ChangeInMemory');
                    Rec.Name := 'memory';
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('base:OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('base:OnAfterGetRecord');
    end;
}

pageextension 69182 "PC Card Ext" extends "PC Card"
{
    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('ext:OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('ext:OnAfterGetRecord');
    end;
}

page 69183 "PC List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "PC Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoChange)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action NoChange');
                end;
            }
            action(ModifyRec)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action ModifyRec');
                    Rec.Name := 'modified';
                    Rec.Modify();
                end;
            }
            action(ChangeInMemory)
            {
                trigger OnAction()
                var
                    Log: Codeunit "PC Log";
                begin
                    Log.Add('base:action ChangeInMemory');
                    Rec.Name := 'memory';
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('base:OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('base:OnAfterGetRecord');
    end;
}

pageextension 69183 "PC List Ext" extends "PC List"
{
    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('ext:OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('ext:OnAfterGetRecord');
    end;
}

page 69184 "PC Find List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "PC Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('OnFindRecord(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "PC Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('OnNextRecord(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('OnAfterGetRecord(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PC Log";
    begin
        Log.Add('OnAfterGetCurrRecord(' + Format(Rec.Id) + ')');
    end;
}

codeunit 69183 "PC Reads Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "PC Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure Card_ReadsAfterEachAction()
    var
        Pg: TestPage "PC Card";
        Log: Codeunit "PC Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open', Log.Take());
        Pg.NoChange.Invoke();
        Observer.Observe('action_no_change', Log.Take());
        Pg.ModifyRec.Invoke();
        Observer.Observe('action_modify', Log.Take());
        Observer.Observe('name_after_modify', Pg.Name.Value());
        Pg.ChangeInMemory.Invoke();
        Observer.Observe('action_change_in_memory', Log.Take());
        Observer.Observe('name_after_memory_change', Pg.Name.Value());
        Pg.Next();
        Observer.Observe('next', Log.Take());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('action_no_change', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action NoChange;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('action_modify', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ModifyRec;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_modify', 'modified');
        Observer.Expect('action_change_in_memory', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ChangeInMemory;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_memory_change', 'memory');
        Observer.Expect('next', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ReadsAfterEachAction()
    var
        Pg: TestPage "PC List";
        Log: Codeunit "PC Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open', Log.Take());
        Pg.NoChange.Invoke();
        Observer.Observe('action_no_change', Log.Take());
        Pg.ModifyRec.Invoke();
        Observer.Observe('action_modify', Log.Take());
        Observer.Observe('name_after_modify', Pg.Name.Value());
        Pg.ChangeInMemory.Invoke();
        Observer.Observe('action_change_in_memory', Log.Take());
        Observer.Observe('name_after_memory_change', Pg.Name.Value());
        Pg.Next();
        Observer.Observe('next', Log.Take());
        Pg.Last();
        Observer.Observe('last', Log.Take());
        Pg.First();
        Observer.Observe('first', Log.Take());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('action_no_change', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action NoChange;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('action_modify', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ModifyRec;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_modify', 'modified');
        Observer.Expect('action_change_in_memory', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ChangeInMemory;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_memory_change', 'memory');
        Observer.Expect('next', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('last', 'base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('first', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;





    [Test]
    procedure FindList_OnFindRecordAndOnNextRecord()
    var
        Pg: TestPage "PC Find List";
        Log: Codeunit "PC Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open', Log.Take());
        Pg.Next();
        Observer.Observe('next', Log.Take());
        Pg.Last();
        Observer.Observe('last', Log.Take());
        Pg.Previous();
        Observer.Observe('previous', Log.Take());
        Pg.First();
        Observer.Observe('first', Log.Take());
        Pg.GoToKey(2);
        Observer.Observe('gotokey_2', Log.Take());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'OnFindRecord(=><);OnAfterGetRecord(1);OnNextRecord(1)=1;OnAfterGetRecord(2);OnNextRecord(1)=1;OnAfterGetRecord(3);OnNextRecord(1)=0;OnAfterGetRecord(1);OnNextRecord(-1)=0;OnFindRecord(=);OnAfterGetRecord(1);OnAfterGetCurrRecord(1);');
        Observer.Expect('next', 'OnAfterGetRecord(2);OnFindRecord(=);OnAfterGetRecord(2);OnAfterGetCurrRecord(2);');
        Observer.Expect('last', 'OnAfterGetRecord(3);OnFindRecord(=);OnAfterGetRecord(3);OnAfterGetCurrRecord(3);');
        Observer.Expect('previous', 'OnAfterGetRecord(2);OnFindRecord(=);OnAfterGetRecord(2);OnAfterGetCurrRecord(2);');
        Observer.Expect('first', 'OnAfterGetRecord(1);OnFindRecord(=);OnAfterGetRecord(1);OnAfterGetCurrRecord(1);');
        Observer.Expect('gotokey_2', 'OnAfterGetRecord(2);OnFindRecord(=);OnAfterGetRecord(2);OnAfterGetCurrRecord(2);');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure Card_DirtyPage_ReadsAfterEachAction()
    var
        Pg: TestPage "PC Card";
        Log: Codeunit "PC Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(2);
        Pg.OpenEdit();
        Log.Take();
        Pg.Name.SetValue('dirty');
        Observer.Observe('set_value', Log.Take());
        Pg.NoChange.Invoke();
        Observer.Observe('action_no_change_dirty', Log.Take());
        Observer.Observe('name_after_no_change', Pg.Name.Value());
        Pg.Name.SetValue('dirty2');
        Log.Take();
        Pg.ModifyRec.Invoke();
        Observer.Observe('action_modify_dirty', Log.Take());
        Observer.Observe('name_after_modify', Pg.Name.Value());
        Pg.Name.SetValue('dirty3');
        Log.Take();
        Pg.ChangeInMemory.Invoke();
        Observer.Observe('action_change_in_memory_dirty', Log.Take());
        Observer.Observe('name_after_memory_change', Pg.Name.Value());
        Pg.Name.SetValue('dirty4');
        Log.Take();
        Pg.Next();
        Observer.Observe('next_dirty', Log.Take());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('set_value', '');
        Observer.Expect('action_no_change_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action NoChange;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_no_change', 'dirty');
        Observer.Expect('action_modify_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ModifyRec;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_modify', 'modified');
        Observer.Expect('action_change_in_memory_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ChangeInMemory;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_memory_change', 'memory');
        Observer.Expect('next_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_DirtyPage_ReadsAfterEachAction()
    var
        Pg: TestPage "PC List";
        Log: Codeunit "PC Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(3);
        Pg.OpenEdit();
        Log.Take();
        Pg.Name.SetValue('dirty');
        Observer.Observe('set_value', Log.Take());
        Pg.NoChange.Invoke();
        Observer.Observe('action_no_change_dirty', Log.Take());
        Observer.Observe('name_after_no_change', Pg.Name.Value());
        Pg.Name.SetValue('dirty2');
        Log.Take();
        Pg.ModifyRec.Invoke();
        Observer.Observe('action_modify_dirty', Log.Take());
        Observer.Observe('name_after_modify', Pg.Name.Value());
        Pg.Name.SetValue('dirty3');
        Log.Take();
        Pg.ChangeInMemory.Invoke();
        Observer.Observe('action_change_in_memory_dirty', Log.Take());
        Observer.Observe('name_after_memory_change', Pg.Name.Value());
        Pg.Name.SetValue('dirty4');
        Log.Take();
        Pg.Next();
        Observer.Observe('next_dirty', Log.Take());
        Pg.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('set_value', '');
        Observer.Expect('action_no_change_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action NoChange;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_no_change', 'dirty');
        Observer.Expect('action_modify_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ModifyRec;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_modify', 'modified');
        Observer.Expect('action_change_in_memory_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:action ChangeInMemory;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('name_after_memory_change', 'memory');
        Observer.Expect('next_dirty', 'base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetRecord;ext:OnAfterGetRecord;base:OnAfterGetCurrRecord;ext:OnAfterGetCurrRecord;');
        Observer.Expect('close', '');
        Observer.Verify();
    end;
}
