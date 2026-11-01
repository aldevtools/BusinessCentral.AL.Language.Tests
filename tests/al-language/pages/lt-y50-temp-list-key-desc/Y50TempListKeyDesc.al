// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects tables 92964 - 92965, pages 92972 - 92973, codeunits 92966 - 92967 (writer Y50)
// Probe: measured on the SaaS sandbox BC 29 and the corpus CI matrix 27.5, 28.5, 29.0 (identical); every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-19: a List over a temporary source whose OnOpenPage fills Rec, then changes the key (SetCurrentKey on
//   "Sent At") and the direction (Ascending(false)), and leaves Rec's buffer on a row that is not the first of the view, or on a key no
//   row has (the Sent Emails / Email Outbox shape: TransferFields into Rec before deciding not to insert). QrMovedTests.al pins the
//   primary key only. Source rows S: Id 1 (2024-01-04), 2 (2024-01-02), 3 (2024-01-01), 4 (2024-01-03), so the "Sent At" order is
//   3, 2, 4, 1. Modes: NONE_BUFFER (no row, buffer = row 2), ALL_LASTINS (rows 1..4 inserted in Id order), SOME_BUFFER (rows 1 and 3,
//   buffer = row 2). Log: empty= and open rec= from OnOpenPage, R: OnAfterGetRecord, C: OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

table 92964 "LT Y50 TK Mail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Sent At"; DateTime) { }
        field(3; Subj; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(BySent; "Sent At") { }
    }
}

table 92965 "LT Y50 TK Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Sent At"; DateTime) { }
        field(3; Subj; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92966 "LT Y50 TK Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;
        NoDesc: Boolean;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetMode(NewMode: Text; NewNoDesc: Boolean)
    begin
        Mode := NewMode;
        NoDesc := NewNoDesc;
    end;

    procedure KeepAscending(): Boolean
    begin
        exit(NoDesc);
    end;

    // The fill of the Sent Emails shape: TransferFields first, Insert only for the rows the mode keeps.
    procedure Fill(var Mail: Record "LT Y50 TK Mail")
    var
        Source: Record "LT Y50 TK Source";
    begin
        if Source.FindSet() then
            repeat
                Mail.TransferFields(Source);
                if Keep(Source.Id) then
                    Mail.Insert();
            until Source.Next() = 0;
        if Mode <> 'ALL_LASTINS' then begin
            Source.Get(2);
            Mail.TransferFields(Source);
        end;
    end;

    local procedure Keep(Id: Integer): Boolean
    begin
        case Mode of
            'NONE_BUFFER':
                exit(false);
            'ALL_LASTINS':
                exit(true);
            'SOME_BUFFER':
                exit(Id in [1, 3]);
        end;
    end;
}

page 92972 "LT Y50 TK List"
{
    PageType = List;
    SourceTable = "LT Y50 TK Mail";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field("Sent At"; Rec."Sent At")
                {
                    ApplicationArea = All;
                }
                field(Subj; Rec.Subj)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Rec.SetCurrentKey("Sent At");
        Log.Add('empty=' + Format(Rec.IsEmpty()));
        if not Log.KeepAscending() then
            Rec.Ascending(false);
        Log.Add('open rec=' + Format(Rec.Id));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y50 TK Log";
}

page 92973 "LT Y50 TK List Pk"
{
    PageType = List;
    SourceTable = "LT Y50 TK Mail";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Subj; Rec.Subj)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Add('empty=' + Format(Rec.IsEmpty()));
        Rec.Ascending(false);
        Log.Add('open rec=' + Format(Rec.Id));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y50 TK Log";
}

codeunit 92967 "LT Y50 TK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y50 TK Log";

    local procedure Seed(Mode: Text; NoDesc: Boolean)
    var
        Source: Record "LT Y50 TK Source";
    begin
        Source.DeleteAll();
        AddSource(1, 4);
        AddSource(2, 2);
        AddSource(3, 1);
        AddSource(4, 3);
        Log.SetMode(Mode, NoDesc);
        Log.Take();
    end;

    local procedure AddSource(Id: Integer; Day: Integer)
    var
        Source: Record "LT Y50 TK Source";
    begin
        Source.Id := Id;
        Source."Sent At" := CreateDateTime(DMY2Date(Day, 1, 2024), 100000T);
        Source.Subj := 'S' + Format(Id);
        Source.Insert();
    end;

    local procedure Walk(var TP: TestPage "LT Y50 TK List"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if TP.First() then
            repeat
                Rows += TP.Id.Value() + ',';
                i += 1;
            until (not TP.Next()) or (i >= 10);
        exit(Rows);
    end;

    local procedure WalkPk(var TP: TestPage "LT Y50 TK List Pk"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if TP.First() then
            repeat
                Rows += TP.Id.Value() + ',';
                i += 1;
            until (not TP.Next()) or (i >= 10);
        exit(Rows);
    end;

    // T1, the Sent Emails shape: no row inserted, Rec's buffer holds row 2.
    [Test]
    procedure G519_EmptyView_BufferFilled()
    var
        Mail: Record "LT Y50 TK Mail";
        TP: TestPage "LT Y50 TK List";
    begin
        Seed('NONE_BUFFER', false);
        TP.Trap();
        Page.Run(Page::"LT Y50 TK List");
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Mail.Id := 2;
        Observer.Observe('gotorecord', Format(TP.GoToRecord(Mail)) + '/' + TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('first', Format(TP.First()) + '/' + TP.Id.Value() + ':' + Log.Take());
        TP.Close();
        Observer.Expect('open', ':empty=Yes;open rec=2;C:0');
        Observer.Expect('gotorecord', 'No/:');
        Observer.Expect('first', 'No/:');
        Observer.Verify();
    end;

    // T2, the CleanEmailOutbox shape: every row inserted, Rec on the last inserted (Id 4).
    [Test]
    procedure G519_Rows_LastInserted_KeyDesc()
    var
        TP: TestPage "LT Y50 TK List";
    begin
        Seed('ALL_LASTINS', false);
        TP.Trap();
        Page.Run(Page::"LT Y50 TK List");
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', Walk(TP));
        TP.Close();
        Observer.Expect('open', '4:empty=No;open rec=4;R:4;R:4;R:2;R:3;R:4;R:1;R:4;R:4;R:4;C:4');
        Observer.Expect('walk', '1,4,2,3,');
        Observer.Verify();
    end;

    // T3: rows 1 and 3 inserted, the buffer holds row 2 (not inserted).
    [Test]
    procedure G519_Rows_BufferNotInserted_KeyDesc()
    var
        TP: TestPage "LT Y50 TK List";
    begin
        Seed('SOME_BUFFER', false);
        TP.Trap();
        Page.Run(Page::"LT Y50 TK List");
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', Walk(TP));
        TP.Close();
        Observer.Expect('open', '3:empty=No;open rec=2;R:3;R:1;R:3;R:3;R:3;C:3');
        Observer.Expect('walk', '1,3,');
        Observer.Verify();
    end;

    // T4: T1 opened by OpenView.
    [Test]
    procedure G519_EmptyView_BufferFilled_OpenView()
    var
        Mail: Record "LT Y50 TK Mail";
        TP: TestPage "LT Y50 TK List";
    begin
        Seed('NONE_BUFFER', false);
        TP.OpenView();
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Mail.Id := 2;
        Observer.Observe('gotorecord', Format(TP.GoToRecord(Mail)) + '/' + TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('first', Format(TP.First()) + '/' + TP.Id.Value() + ':' + Log.Take());
        TP.Close();
        Observer.Expect('open', ':empty=Yes;open rec=2');
        Observer.Expect('gotorecord', 'No/:');
        Observer.Expect('first', 'No/:');
        Observer.Verify();
    end;

    // T5: primary key, descending only.
    [Test]
    procedure G519_Rows_LastInserted_PkDesc()
    var
        TP: TestPage "LT Y50 TK List Pk";
    begin
        Seed('ALL_LASTINS', false);
        TP.Trap();
        Page.Run(Page::"LT Y50 TK List Pk");
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', WalkPk(TP));
        TP.Close();
        Observer.Expect('open', '4:empty=No;open rec=4;R:4;R:3;R:2;R:1;R:4;R:4;C:4');
        Observer.Expect('walk', '4,3,2,1,');
        Observer.Verify();
    end;

    // T6: changed key, ascending.
    [Test]
    procedure G519_Rows_LastInserted_KeyAsc()
    var
        TP: TestPage "LT Y50 TK List";
    begin
        Seed('ALL_LASTINS', true);
        TP.Trap();
        Page.Run(Page::"LT Y50 TK List");
        Observer.Observe('open', TP.Id.Value() + ':' + Log.Take());
        Observer.Observe('walk', Walk(TP));
        TP.Close();
        Observer.Expect('open', '4:empty=No;open rec=4;R:4;R:4;R:1;R:4;R:2;R:3;R:4;R:4;R:4;C:4');
        Observer.Expect('walk', '3,2,4,1,');
        Observer.Verify();
    end;
}
