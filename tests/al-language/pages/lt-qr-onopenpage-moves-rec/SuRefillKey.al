// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: own objects 89650 - 89655 (writer SU); Probe Observer (69160); tests in this file (codeunit 89655); writer TW adds 90144 - 90147 and the TW_ tests (al-runner issue 6115: the same pages with a ListPart)
// Probe: al-runner issues 6008 and 5871 (reporter's real-BC measurements on 29.0); own objects, own rows. A Worksheet over a table with the
//   key ByName (Name) next to its primary key (Id). Page "LT SU Name Ws" calls Rec.SetCurrentKey(Name) in OnOpenPage; page "LT SU Id Ws" is the
//   same page in the primary key (control). A header field's OnDrillDown marks the flagged rows (MarkedOnly(false), ClearMarks, a copy of Rec
//   walked with FindSet, Get + Mark for each flagged row, MarkedOnly(true)) and calls CurrPage.Update(false). Action MarkAct does the same
//   marking from an action, action RefreshAct only calls CurrPage.Update(false). Log: R<Id> = OnAfterGetRecord, C<Id> = OnAfterGetCurrRecord.
// Rows: Id 1 (M, flagged no), 2 (C, flagged), 3 (T, flagged), 4 (A, no), 5 (P, flagged); order in the key ByName: 4, 2, 1, 5, 3.
//   Tests: <page>_DrillDown_GoToRecord (open, drilldown, GoToRecord on two rows), _Filter_Refill (TestPage.Filter.SetFilter, then moves),
//   _Action_Update (RefreshAct then moves), _Action_Mark (MarkAct then GoToRecord).
// Facts: in the key ByName a refill and every row made current read the row three times before OnAfterGetCurrRecord (R4;R4;R4;C4); in the primary
//   key twice. Drilldown, mark and control values: confirmed on a BC 29 SaaS sandbox, 2026-10-28, and equal on the Linux legs (the reporter's
//   Windows OnPrem log in al-runner issue 6008 differs; noted in that issue).
// BC versions: 27, 28, 29

table 89650 "LT SU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

codeunit 89651 "LT SU Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 89652 "LT SU Marks"
{
    procedure MarkFlagged(var Row: Record "LT SU Row")
    var
        RowsInView: Record "LT SU Row";
    begin
        Row.MarkedOnly(false);
        Row.ClearMarks();
        RowsInView.Copy(Row);
        if RowsInView.FindSet() then
            repeat
                if RowsInView.Flag then begin
                    Row.Get(RowsInView.Id);
                    Row.Mark(true);
                end;
            until RowsInView.Next() = 0;
        Row.MarkedOnly(true);
    end;
}

page 89653 "LT SU Name Ws"
{
    PageType = Worksheet;
    SourceTable = "LT SU Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Marks.MarkFlagged(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Marks.MarkFlagged(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RefreshAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SU Log";
        Marks: Codeunit "LT SU Marks";
        Tile: Integer;
}

page 89654 "LT SU Id Ws"
{
    PageType = Worksheet;
    SourceTable = "LT SU Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Marks.MarkFlagged(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Marks.MarkFlagged(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RefreshAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SU Log";
        Marks: Codeunit "LT SU Marks";
        Tile: Integer;
}

codeunit 89655 "LT SU Refill Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SU Log";

    local procedure Seed()
    var
        Row: Record "LT SU Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'M', false);
        AddRow(2, 'C', true);
        AddRow(3, 'T', true);
        AddRow(4, 'A', false);
        AddRow(5, 'P', true);
        Log.Take();
    end;

    local procedure AddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Row: Record "LT SU Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Flag := Flag;
        Row.Insert();
    end;

    [Test]
    procedure Name_DrillDown_GoToRecord()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Name Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Observer.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '4:R4;R2;R1;R5;R3;R4;R4;R4;C4;');
        Observer.Expect('drilldown', '4:');
        Observer.Expect('goto 3', 'Yes/3:R3;R3;R5;R2;R3;R3;R3;C3;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;R2;C2;R5;R5;R5;C5;');
        Observer.Expect('goto 1', 'No/5:R2;R2;R2;C2;R5;R5;R5;C5;R3;R3;R3;C3;R5;R5;R5;C5;');
        Observer.Expect('next', 'Yes/3:R3;R3;R3;C3;');
        Observer.Expect('first', 'Yes/2:R2;R2;R2;C2;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_Filter_Refill()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Name Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Filter.SetFilter(Id, '2..4');
        Observer.Observe('filter', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Observer.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(4);
        Observer.Observe('goto 4', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1 outside', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '4:R4;R2;R1;R5;R3;R4;R4;R4;C4;');
        Observer.Expect('filter', '4:R4;R2;R3;R4;R4;R4;C4;');
        Observer.Expect('goto 2', 'Yes/2:R2;R2;R2;C2;');
        Observer.Expect('goto 4', 'Yes/4:R4;R4;R4;C4;');
        Observer.Expect('goto 1 outside', 'No/4:R2;R2;R2;C2;R3;R3;R3;C3;R4;R4;R4;C4;');
        Observer.Expect('last', 'Yes/3:R3;R3;R3;C3;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_Action_Update()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Name Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.RefreshAct.Invoke();
        Observer.Observe('update', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Observer.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '4:R4;R2;R1;R5;R3;R4;R4;R4;C4;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;R2;C2;R1;R1;R1;C1;R5;R5;R5;C5;');
        Observer.Expect('update', '5:R5;R5;R5;R5;R3;R5;R1;R2;R4;R5;R5;R5;C5;');
        Observer.Expect('goto 2', 'Yes/2:R4;R4;R4;C4;R2;R2;R2;C2;');
        Observer.Expect('goto 3', 'Yes/3:R4;R4;R4;C4;R2;R2;R2;C2;R1;R1;R1;C1;R5;R5;R5;C5;R3;R3;R3;C3;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_Action_Mark()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Name Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.MarkAct.Invoke();
        Observer.Observe('mark', P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '4:R4;R2;R1;R5;R3;R4;R4;R4;C4;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;R2;C2;R1;R1;R1;C1;R5;R5;R5;C5;');
        Observer.Expect('mark', '3:R5;R3;R3;R3;R5;R2;R3;R3;R3;C3;');
        Observer.Expect('goto 3', 'Yes/3:R2;R2;R2;C2;R5;R5;R5;C5;R3;R3;R3;C3;');
        Observer.Expect('goto 1', 'No/3:R2;R2;R2;C2;R5;R5;R5;C5;R3;R3;R3;C3;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_DrillDown_GoToRecord()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Id Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Observer.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('first', Format(P.First()) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R5;R1;R1;C1;');
        Observer.Expect('drilldown', '1:');
        Observer.Expect('goto 3', 'No/5:R5;R3;R2;R5;R5;C5;R2;R2;C2;R3;R3;C3;R5;R5;C5;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;C2;R3;R3;C3;R5;R5;C5;');
        Observer.Expect('goto 1', 'No/5:R2;R2;C2;R3;R3;C3;R5;R5;C5;');
        Observer.Expect('next', 'No/5:');
        Observer.Expect('first', 'Yes/2:R2;R2;C2;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_Filter_Refill()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Id Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Filter.SetFilter(Id, '2..4');
        Observer.Observe('filter', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Observer.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(4);
        Observer.Observe('goto 4', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1 outside', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Observer.Observe('last', Format(P.Last()) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R5;R1;R1;C1;');
        Observer.Expect('filter', '2:R2;R3;R4;R2;R2;C2;');
        Observer.Expect('goto 2', 'Yes/2:');
        Observer.Expect('goto 4', 'Yes/4:R3;R3;C3;R4;R4;C4;');
        Observer.Expect('goto 1 outside', 'No/4:R2;R2;C2;R3;R3;C3;R4;R4;C4;');
        Observer.Expect('last', 'Yes/4:');
        Observer.Verify();
    end;

    [Test]
    procedure Id_Action_Update()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Id Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.RefreshAct.Invoke();
        Observer.Observe('update', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Observer.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R5;R1;R1;C1;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;C2;R3;R3;C3;R4;R4;C4;R5;R5;C5;');
        Observer.Expect('update', '5:R5;R5;R5;R4;R3;R2;R1;R5;R5;C5;');
        Observer.Expect('goto 2', 'Yes/2:R1;R1;C1;R2;R2;C2;');
        Observer.Expect('goto 3', 'Yes/3:R1;R1;C1;R2;R2;C2;R3;R3;C3;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_Action_Mark()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT SU Id Ws";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        Row.Get(5);
        Observer.Observe('goto 5', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.MarkAct.Invoke();
        Observer.Observe('mark', P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Observer.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Observer.Observe('goto 1', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R5;R1;R1;C1;');
        Observer.Expect('goto 5', 'Yes/5:R2;R2;C2;R3;R3;C3;R4;R4;C4;R5;R5;C5;');
        Observer.Expect('mark', '5:R5;R5;R5;R3;R2;R5;R5;C5;');
        Observer.Expect('goto 3', 'Yes/3:R2;R2;C2;R3;R3;C3;');
        Observer.Expect('goto 1', 'No/3:R2;R2;C2;R3;R3;C3;R5;R5;C5;R3;R3;C3;');
        Observer.Verify();
    end;

    // ---- writer TW (al-runner issue 6115, reporter's real-BC 29.0 run): the same marking drilldown with a ListPart linked by SubPageLink
    //      (page "LT TW Name Ws Part" in the key ByName, "LT TW Id Ws Part" in the primary key). Rows: 1 N4 flagged, 2 N3, 3 N2 flagged, 4 N1;
    //      one detail row per row. In the key ByName the drilldown marks 3 then 1 and leaves Rec on row 1. ----
    local procedure TwSeed()
    var
        Row: Record "LT SU Row";
        Detail: Record "LT TW Su Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
        TwAddRow(1, 'N4', true);
        TwAddRow(2, 'N3', false);
        TwAddRow(3, 'N2', true);
        TwAddRow(4, 'N1', false);
        Log.Take();
    end;

    local procedure TwAddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Detail: Record "LT TW Su Detail";
    begin
        AddRow(Id, Name, Flag);
        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Description := 'D' + Format(Id);
        Detail.Insert();
    end;

    [Test]
    procedure TW_NameKeyWithPart_GoToRecordOfRecsRow()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT TW Name Ws Part";
        Obs: Codeunit "Probe Observer";
    begin
        TwSeed();
        P.OpenView();
        Obs.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Obs.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        Obs.Observe('goto 1', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Obs.Observe('part', P.Details.Description.Value());
        P.Close();
        Obs.Expect('open', '4:R4;R3;R2;R1;R4;R4;R4;C4;');
        Obs.Expect('drilldown', '4:');
        Obs.Expect('goto 1', 'Yes/1:R1;R1;R3;R1;R1;R1;C1;');
        Obs.Expect('part', 'D1');
        Obs.Verify();
    end;

    [Test]
    procedure TW_NameKeyWithPart_GoToRecordOfUnmarkedRow()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT TW Name Ws Part";
        Obs: Codeunit "Probe Observer";
    begin
        TwSeed();
        P.OpenView();
        Obs.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Obs.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Obs.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Obs.Expect('open', '4:R4;R3;R2;R1;R4;R4;R4;C4;');
        Obs.Expect('drilldown', '4:');
        Obs.Expect('goto 2', 'No/1:R1;R1;R3;R1;R1;R1;C1;R3;R3;R3;C3;R1;R1;R1;C1;');
        Obs.Verify();
    end;

    [Test]
    procedure TW_IdKeyWithPart_GoToRecordOfRecsRow()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT TW Id Ws Part";
        Obs: Codeunit "Probe Observer";
    begin
        TwSeed();
        P.OpenView();
        Obs.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Obs.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(3);
        Obs.Observe('goto 3', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        Obs.Observe('part', P.Details.Description.Value());
        P.Close();
        Obs.Expect('open', '1:R1;R2;R3;R4;R1;R1;C1;');
        Obs.Expect('drilldown', '1:');
        Obs.Expect('goto 3', 'Yes/3:R3;R1;R3;R3;C3;');
        Obs.Expect('part', 'D3');
        Obs.Verify();
    end;

    [Test]
    procedure TW_IdKeyWithPart_GoToRecordOfUnmarkedRow()
    var
        Row: Record "LT SU Row";
        P: TestPage "LT TW Id Ws Part";
        Obs: Codeunit "Probe Observer";
    begin
        TwSeed();
        P.OpenView();
        Obs.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.FlaggedTile.Drilldown();
        Obs.Observe('drilldown', P.Id.Value() + ':' + Log.Take());
        Row.Get(2);
        Obs.Observe('goto 2', Format(P.GoToRecord(Row)) + '/' + P.Id.Value() + ':' + Log.Take());
        P.Close();
        Obs.Expect('open', '1:R1;R2;R3;R4;R1;R1;C1;');
        Obs.Expect('drilldown', '1:');
        Obs.Expect('goto 2', 'No/1:R3;R1;R3;R3;C3;R1;R1;C1;');
        Obs.Verify();
    end;
}

// ---- writer TW (al-runner issue 6115): a detail table, a ListPart over it and the two worksheets again with that part (SubPageLink Id). ----
table 90144 "LT TW Su Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[50]) { }
    }

    keys
    {
        key(PK; Id, "Line No.") { Clustered = true; }
    }
}

page 90145 "LT TW Su Detail Part"
{
    PageType = ListPart;
    SourceTable = "LT TW Su Detail";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Id; Rec.Id) { }
                field("Line No."; Rec."Line No.") { }
                field(Description; Rec.Description) { }
            }
        }
    }
}

page 90146 "LT TW Name Ws Part"
{
    PageType = Worksheet;
    SourceTable = "LT SU Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
                {
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Marks.MarkFlagged(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
            part(Details; "LT TW Su Detail Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SU Log";
        Marks: Codeunit "LT SU Marks";
        Tile: Integer;
}

page 90147 "LT TW Id Ws Part"
{
    PageType = Worksheet;
    SourceTable = "LT SU Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
                {
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Marks.MarkFlagged(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
            part(Details; "LT TW Su Detail Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SU Log";
        Marks: Codeunit "LT SU Marks";
        Tile: Integer;
}
