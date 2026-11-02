// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); tables 93859-93861, pages 93862-93865, test codeunit 93857
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: Part A: a card with OnFindRecord / OnNextRecord that search ANOTHER record (a page-global temporary buffer) and never move Rec
//   (the Analysis by Dimensions shape), run by Page.Run(Id, Rec) with a temporary record (SourceTableTemporary card) and with a stored
//   record (database card); the buffer is empty (the trigger answers false) or holds one row (answers true). OnOpenPage changes a field of
//   Rec first (Opt := 5). Part B: GoToKey on a find list (OnFindRecord, OnNextRecord, OnAfterGetRecord, OnAfterGetCurrRecord) of 70 rows:
//   keys in the third block of the client's 20 row windows, views of exactly 20 and 40 rows, a missing key with the result used and unused.
//   Log format: o = OnOpenPage, F:<Which>:<Code of Rec>=<answer> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord, R:<code>:<Opt> =
//   OnAfterGetRecord, C:<code>:<Opt> = OnAfterGetCurrRecord; the list: F:<Which>=<found>, N:<Steps>=<moved>, R:<n>, C:<n>.
// Neighbours: pages/lt-be-card-onfindrecord/BeCardOnFindRecord.al, pagefindrecord/QcFindViewTests.al,
//   pages/lt-y61-page-probes/Y61GoToKeyEdges.al (45 rows, second block), pages/lt-y41-page-probes/Y41GoToKeyFindListCurr.al.
// BC versions: all (CI)

table 93859 "LT Y72 Find P"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Opt; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 93860 "LT Y72 Find Buf"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 93861 "LT Y72 Find Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; D; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 93862 "LT Y72 Find Card Temp"
{
    PageType = Card;
    SourceTable = "LT Y72 Find P";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            field(OptCtl; Rec.Opt) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        TempBuf: Record "LT Y72 Find Buf" temporary;

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
    begin
        Rec.Opt := 5;
        Log.AddLine('o:' + Rec.Code);
        if Rec.Code = 'V1' then
            if Rec.Name = 'hit' then begin
                TempBuf.Code := 'BUF1';
                TempBuf.Insert();
            end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Record "LT Y61 Log";
        Answer: Boolean;
    begin
        Answer := TempBuf.Find(Which);
        Log.AddLine('F:' + Which + ':' + Rec.Code + '=' + Format(Answer));
        exit(Answer);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Record "LT Y61 Log";
        Moved: Integer;
    begin
        Moved := TempBuf.Next(Steps);
        Log.AddLine('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('R:' + Rec.Code + ':' + Format(Rec.Opt));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + Rec.Code + ':' + Format(Rec.Opt));
    end;
}

page 93863 "LT Y72 Find Card Stored"
{
    PageType = Card;
    SourceTable = "LT Y72 Find P";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            field(OptCtl; Rec.Opt) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        TempBuf: Record "LT Y72 Find Buf" temporary;

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
    begin
        Rec.Opt := 5;
        Log.AddLine('o:' + Rec.Code);
        if Rec.Name = 'hit' then begin
            TempBuf.Code := 'BUF1';
            TempBuf.Insert();
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Record "LT Y61 Log";
        Answer: Boolean;
    begin
        Answer := TempBuf.Find(Which);
        Log.AddLine('F:' + Which + ':' + Rec.Code + '=' + Format(Answer));
        exit(Answer);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Record "LT Y61 Log";
        Moved: Integer;
    begin
        Moved := TempBuf.Next(Steps);
        Log.AddLine('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('R:' + Rec.Code + ':' + Format(Rec.Opt));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + Rec.Code + ':' + Format(Rec.Opt));
    end;
}

page 93864 "LT Y72 Find Item List"
{
    PageType = List;
    SourceTable = "LT Y72 Find Item";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(DCtl; Rec.D) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Record "LT Y61 Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.AddLine('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Record "LT Y61 Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.AddLine('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('R:' + CopyStr(Rec."No.", 2));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + CopyStr(Rec."No.", 2));
    end;
}

codeunit 93857 "LT Y72 Find Pages Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Log: Record "LT Y61 Log";
        P: Record "LT Y72 Find P";
        Item: Record "LT Y72 Find Item";
    begin
        ClearLastError();
        Observer.Discard();
        P.DeleteAll();
        Item.DeleteAll();
        Log.ClearLog();
    end;

    local procedure SeedItems(Rows: Integer)
    var
        Item: Record "LT Y72 Find Item";
        i: Integer;
    begin
        for i := 1 to Rows do begin
            Item.Init();
            Item."No." := 'N' + Format(i, 0, '<Integer,3><Filler Character,0>');
            Item.D := 'd' + Format(i);
            Item.Insert();
        end;
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y61 Log";
    begin
        exit(Log.Take());
    end;

    local procedure MakeP(var P: Record "LT Y72 Find P"; Code: Code[10]; Name: Text[30])
    begin
        P.Init();
        P.Code := Code;
        P.Name := Name;
        P.Opt := 1;
        P.Insert();
    end;

    [TryFunction]
    local procedure TryRunTempCard(var P: Record "LT Y72 Find P")
    begin
        Page.Run(Page::"LT Y72 Find Card Temp", P);
    end;

    [TryFunction]
    local procedure TryRunStoredCard(var P: Record "LT Y72 Find P")
    begin
        Page.Run(Page::"LT Y72 Find Card Stored", P);
    end;

    [TryFunction]
    local procedure TryGoToKey(var P: TestPage "LT Y72 Find Item List"; No: Code[20])
    begin
        P.GoToKey(No);
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordMiss()
    var
        Handed: Record "LT Y72 Find P" temporary;
        P: TestPage "LT Y72 Find Card Temp";
        Ok: Boolean;
    begin
        Seed();
        MakeP(Handed, 'V1', 'miss');
        P.Trap();
        Ok := TryRunTempCard(Handed);
        Observer.Observe('run ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', TakeLog());
        if Ok then begin
            Observer.Observe('code', P.CodeCtl.Value());
            Observer.Observe('opt', P.OptCtl.Value());
            Observer.Observe('name', P.NameCtl.Value());
            P.Close();
            Observer.Observe('close log', TakeLog());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordMiss_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordMiss_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordMiss_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordMiss()
    var
        Handed: Record "LT Y72 Find P";
        P: TestPage "LT Y72 Find Card Stored";
        Ok: Boolean;
    begin
        Seed();
        MakeP(Handed, 'V1', 'miss');
        Handed.Get('V1');
        P.Trap();
        Ok := TryRunStoredCard(Handed);
        Observer.Observe('run ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', TakeLog());
        if Ok then begin
            Observer.Observe('code', P.CodeCtl.Value());
            Observer.Observe('opt', P.OptCtl.Value());
            Observer.Observe('name', P.NameCtl.Value());
            P.Close();
            Observer.Observe('close log', TakeLog());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordMiss_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordMiss_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordMiss_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordHit()
    var
        Handed: Record "LT Y72 Find P" temporary;
        P: TestPage "LT Y72 Find Card Temp";
        Ok: Boolean;
    begin
        Seed();
        MakeP(Handed, 'V1', 'hit');
        P.Trap();
        Ok := TryRunTempCard(Handed);
        Observer.Observe('run ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', TakeLog());
        if Ok then begin
            Observer.Observe('code', P.CodeCtl.Value());
            Observer.Observe('opt', P.OptCtl.Value());
            Observer.Observe('name', P.NameCtl.Value());
            P.Close();
            Observer.Observe('close log', TakeLog());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordHit_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordHit_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_OtherRecordHit_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordHit()
    var
        Handed: Record "LT Y72 Find P";
        P: TestPage "LT Y72 Find Card Stored";
        Ok: Boolean;
    begin
        Seed();
        MakeP(Handed, 'V1', 'hit');
        Handed.Get('V1');
        P.Trap();
        Ok := TryRunStoredCard(Handed);
        Observer.Observe('run ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', TakeLog());
        if Ok then begin
            Observer.Observe('code', P.CodeCtl.Value());
            Observer.Observe('opt', P.OptCtl.Value());
            Observer.Observe('name', P.NameCtl.Value());
            P.Close();
            Observer.Observe('close log', TakeLog());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordHit_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordHit_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_StoredHanded_OtherRecordHit_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_Miss_ThenAction()
    var
        Handed: Record "LT Y72 Find P" temporary;
        P: TestPage "LT Y72 Find Card Temp";
        Ok: Boolean;
    begin
        Seed();
        MakeP(Handed, 'V1', 'miss');
        P.Trap();
        Ok := TryRunTempCard(Handed);
        TakeLog();
        if Ok then begin
            Observer.Observe('next', Format(P.Next()));
            Observer.Observe('next log', TakeLog());
            Observer.Observe('previous', Format(P.Previous()));
            Observer.Observe('previous log', TakeLog());
            Observer.Observe('first', Format(P.First()));
            Observer.Observe('first log', TakeLog());
            P.Close();
        end;
        Observer.Observe('run ok', Format(Ok));
        Observer.Finish();
    end;

    [Test]
    procedure CardFind_TempHanded_Miss_ThenAction_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_Miss_ThenAction_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure CardFind_TempHanded_Miss_ThenAction_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock()
    var
        P: TestPage "LT Y72 Find Item List";
    begin
        Seed();
        SeedItems(70);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open no', P.NoCtl.Value());
        Observer.Observe('goto 055', Format(P.GoToKey('N055')));
        Observer.Observe('goto 055 log', TakeLog());
        Observer.Observe('goto 055 no', P.NoCtl.Value());
        Observer.Observe('goto 065', Format(P.GoToKey('N065')));
        Observer.Observe('goto 065 log', TakeLog());
        Observer.Observe('goto 065 no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next log', TakeLog());
        Observer.Observe('next no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_FromSecondBlock()
    var
        P: TestPage "LT Y72 Find Item List";
    begin
        Seed();
        SeedItems(70);
        P.OpenView();
        P.GoToKey('N033');
        TakeLog();
        Observer.Observe('goto 047', Format(P.GoToKey('N047')));
        Observer.Observe('goto 047 log', TakeLog());
        Observer.Observe('goto 047 no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_FromSecondBlock_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_FromSecondBlock_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_FromSecondBlock_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly20()
    var
        P: TestPage "LT Y72 Find Item List";
    begin
        Seed();
        SeedItems(20);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('goto 020', Format(P.GoToKey('N020')));
        Observer.Observe('goto 020 log', TakeLog());
        Observer.Observe('goto 020 no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next log', TakeLog());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly20_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly20_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly20_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly40()
    var
        P: TestPage "LT Y72 Find Item List";
    begin
        Seed();
        SeedItems(40);
        P.OpenView();
        TakeLog();
        Observer.Observe('goto 021', Format(P.GoToKey('N021')));
        Observer.Observe('goto 021 log', TakeLog());
        Observer.Observe('goto 040', Format(P.GoToKey('N040')));
        Observer.Observe('goto 040 log', TakeLog());
        Observer.Observe('goto 040 no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next log', TakeLog());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly40_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly40_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly40_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly21()
    var
        P: TestPage "LT Y72 Find Item List";
    begin
        Seed();
        SeedItems(21);
        P.OpenView();
        TakeLog();
        Observer.Observe('goto 021', Format(P.GoToKey('N021')));
        Observer.Observe('goto 021 log', TakeLog());
        Observer.Observe('goto 021 no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly21_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly21_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_Exactly21_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_Missing()
    var
        P: TestPage "LT Y72 Find Item List";
        Ok: Boolean;
    begin
        Seed();
        SeedItems(70);
        P.OpenView();
        TakeLog();
        Observer.Observe('miss ret', Format(P.GoToKey('N999')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        P.First();
        TakeLog();
        Ok := TryGoToKey(P, 'N999');
        Observer.Observe('unused ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('unused');
        Observer.Observe('unused log', TakeLog());
        Observer.Observe('unused no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_Missing_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_Missing_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure FindList_GoToKey_ThirdBlock_Missing_More3()
    begin
        Observer.More();
    end;
}
