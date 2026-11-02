// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93859,93860,93861; page 93862,93863,93864; codeunit 93857
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
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): see the Expect lines. A card whose OnFindRecord searches another buffer: OnOpenPage runs
//   first (Opt := 5), then OnFindRecord('=') and, when it answers false, OnFindRecord('=><'); the page opens (no error) with a blank
//   record (code, opt and name empty) and Next, Previous and First answer No; when the buffer holds a row the handed record is shown
//   (code V1, opt 5, name hit) after F:=:V1=Yes. Same for a temporary and a stored source. The find list walks one row at a time from the
//   current row, also past the second block of 20 rows: GoToKey('N055') from the first row logs R, F:=, R, C for every row from 002 to 055
//   (after the first two windows are read with OnNextRecord); the next GoToKey('N065'), a key after the current row, starts again at
//   row 001 and walks to 065 (reading the window up to 070 on the way); from 033 a key 047 also starts again at 001. Views of exactly
//   20 rows (key 020 as the last row), 21 and 40 rows walk the same way, and a Next after the last row answers No and logs nothing.
//   A missing key from the first row of 70 rows answers No after walking all rows and back to row 001 (stays on N001); with the result
//   unused it raises 'The row does not exist on the TestPage.' (TestRowNotFound) after the same walk.
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
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log', 'o:V1;F:=:V1=No;F:=><:V1=No;R:V1:1;C::0');
        Observer.Expect('code', '');
        Observer.Expect('opt', '');
        Observer.Expect('name', '');
        Observer.Expect('close log', 'R:V1:1');
        Observer.Verify();
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
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log', 'o:V1;F:=:V1=No;F:=><:V1=No;R:V1:1;C::0');
        Observer.Expect('code', '');
        Observer.Expect('opt', '');
        Observer.Expect('name', '');
        Observer.Expect('close log', 'R:V1:1');
        Observer.Verify();
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
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log', 'o:V1;F:=:V1=Yes;R:V1:5;C:V1:5');
        Observer.Expect('code', 'V1');
        Observer.Expect('opt', '5');
        Observer.Expect('name', 'hit');
        Observer.Expect('close log', '');
        Observer.Verify();
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
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log', 'o:V1;F:=:V1=Yes;R:V1:5;C:V1:5');
        Observer.Expect('code', 'V1');
        Observer.Expect('opt', '5');
        Observer.Expect('name', 'hit');
        Observer.Expect('close log', '');
        Observer.Verify();
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
        Observer.Expect('next', 'No');
        Observer.Expect('next log', 'R:V1:1;N:1=0');
        Observer.Expect('previous', 'No');
        Observer.Expect('previous log', 'N:-1=0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', 'F:-:V1=No;R:V1:1;C::0');
        Observer.Expect('run ok', 'Yes');
        Observer.Verify();
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
        Observer.Expect('open log', 'F:=><=Yes;R:001;N:1=1;R:002;N:1=1;R:003;N:1=1;R:004;N:1=1;R:005;N:1=1;R:006;N:1=1;R:007;N:1=1;R:008;N:1=1;R:009;N:1=1;R:010;N:1=1;R:011;N:1=1;R:012;N:1=1;R:013;N:1=1;R:014;N:1=1;R:015;N:1=1;R:016;N:1=1;R:017;N:1=1;R:018;N:1=1;R:019;N:1=1;R:020;R:001;N:-1=0;F:==Yes;R:001;C:001');
        Observer.Expect('open no', 'N001');
        Observer.Expect('goto 055', 'Yes');
        Observer.Expect('goto 055 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=1;R:022;N:1=1;R:023;N:1=1;R:024;N:1=1;R:025;N:1=1;R:026;N:1=1;R:027;N:1=1;R:028;N:1=1;R:029;N:1=1;R:030;N:1=1;R:031;N:1=1;R:032;N:1=1;R:033;N:1=1;R:034;N:1=1;R:035;N:1=1;R:036;N:1=1;R:037;N:1=1;R:038;N:1=1;R:039;N:1=1;R:040;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;N:1=1;R:041;N:1=1;R:042;N:1=1;R:043;N:1=1;R:044;N:1=1;R:045;N:1=1;R:046;N:1=1;R:047;N:1=1;R:048;N:1=1;R:049;N:1=1;R:050;N:1=1;R:051;N:1=1;R:052;N:1=1;R:053;N:1=1;R:054;N:1=1;R:055;N:1=1;R:056;N:1=1;R:057;N:1=1;R:058;N:1=1;R:059;N:1=1;R:060;R:040;F:==Yes;R:040;C:040;R:041;F:==Yes;R:041;C:041;R:042;F:==Yes;R:042;C:042;R:043;F:==Yes;R:043;C:043;R:044;F:==Yes;R:044;C:044;R:045;F:==Yes;R:045;C:045;R:046;F:==Yes;R:046;C:046;R:047;F:==Yes;R:047;C:047;R:048;F:==Yes;R:048;C:048;R:049;F:==Yes;R:049;C:049;R:050;F:==Yes;R:050;C:050;R:051;F:==Yes;R:051;C:051;R:052;F:==Yes;R:052;C:052;R:053;F:==Yes;R:053;C:053;R:054;F:==Yes;R:054;C:054;R:055;F:==Yes;R:055;C:055');
        Observer.Expect('goto 055 no', 'N055');
        Observer.Expect('goto 065', 'Yes');
        Observer.Expect('goto 065 log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;F:==Yes;R:040;C:040;R:041;F:==Yes;R:041;C:041;R:042;F:==Yes;R:042;C:042;R:043;F:==Yes;R:043;C:043;R:044;F:==Yes;R:044;C:044;R:045;F:==Yes;R:045;C:045;R:046;F:==Yes;R:046;C:046;R:047;F:==Yes;R:047;C:047;R:048;F:==Yes;R:048;C:048;R:049;F:==Yes;R:049;C:049;R:050;F:==Yes;R:050;C:050;R:051;F:==Yes;R:051;C:051;R:052;F:==Yes;R:052;C:052;R:053;F:==Yes;R:053;C:053;R:054;F:==Yes;R:054;C:054;R:055;F:==Yes;R:055;C:055;R:056;F:==Yes;R:056;C:056;R:057;F:==Yes;R:057;C:057;R:058;F:==Yes;R:058;C:058;R:059;F:==Yes;R:059;C:059;R:060;N:1=1;R:061;N:1=1;R:062;N:1=1;R:063;N:1=1;R:064;N:1=1;R:065;N:1=1;R:066;N:1=1;R:067;N:1=1;R:068;N:1=1;R:069;N:1=1;R:070;N:1=0;R:060;F:==Yes;R:060;C:060;R:061;F:==Yes;R:061;C:061;R:062;F:==Yes;R:062;C:062;R:063;F:==Yes;R:063;C:063;R:064;F:==Yes;R:064;C:064;R:065;F:==Yes;R:065;C:065');
        Observer.Expect('goto 065 no', 'N065');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'R:066;F:==Yes;R:066;C:066');
        Observer.Expect('next no', 'N066');
        Observer.Verify();
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
        Observer.Expect('goto 047', 'Yes');
        Observer.Expect('goto 047 log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;N:1=1;R:041;N:1=1;R:042;N:1=1;R:043;N:1=1;R:044;N:1=1;R:045;N:1=1;R:046;N:1=1;R:047;N:1=1;R:048;N:1=1;R:049;N:1=1;R:050;N:1=1;R:051;N:1=1;R:052;N:1=1;R:053;N:1=1;R:054;N:1=1;R:055;N:1=1;R:056;N:1=1;R:057;N:1=1;R:058;N:1=1;R:059;N:1=1;R:060;R:040;F:==Yes;R:040;C:040;R:041;F:==Yes;R:041;C:041;R:042;F:==Yes;R:042;C:042;R:043;F:==Yes;R:043;C:043;R:044;F:==Yes;R:044;C:044;R:045;F:==Yes;R:045;C:045;R:046;F:==Yes;R:046;C:046;R:047;F:==Yes;R:047;C:047');
        Observer.Expect('goto 047 no', 'N047');
        Observer.Verify();
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
        Observer.Expect('open log', 'F:=><=Yes;R:001;N:1=1;R:002;N:1=1;R:003;N:1=1;R:004;N:1=1;R:005;N:1=1;R:006;N:1=1;R:007;N:1=1;R:008;N:1=1;R:009;N:1=1;R:010;N:1=1;R:011;N:1=1;R:012;N:1=1;R:013;N:1=1;R:014;N:1=1;R:015;N:1=1;R:016;N:1=1;R:017;N:1=1;R:018;N:1=1;R:019;N:1=1;R:020;R:001;N:-1=0;F:==Yes;R:001;C:001');
        Observer.Expect('goto 020', 'Yes');
        Observer.Expect('goto 020 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=0;R:020;F:==Yes;R:020;C:020');
        Observer.Expect('goto 020 no', 'N020');
        Observer.Expect('next', 'No');
        Observer.Expect('next log', '');
        Observer.Verify();
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
        Observer.Expect('goto 021', 'Yes');
        Observer.Expect('goto 021 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=1;R:022;N:1=1;R:023;N:1=1;R:024;N:1=1;R:025;N:1=1;R:026;N:1=1;R:027;N:1=1;R:028;N:1=1;R:029;N:1=1;R:030;N:1=1;R:031;N:1=1;R:032;N:1=1;R:033;N:1=1;R:034;N:1=1;R:035;N:1=1;R:036;N:1=1;R:037;N:1=1;R:038;N:1=1;R:039;N:1=1;R:040;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021');
        Observer.Expect('goto 040', 'Yes');
        Observer.Expect('goto 040 log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;N:1=0;R:040;F:==Yes;R:040;C:040');
        Observer.Expect('goto 040 no', 'N040');
        Observer.Expect('next', 'No');
        Observer.Expect('next log', '');
        Observer.Verify();
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
        Observer.Expect('goto 021', 'Yes');
        Observer.Expect('goto 021 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=0;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021');
        Observer.Expect('goto 021 no', 'N021');
        Observer.Verify();
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
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=1;R:022;N:1=1;R:023;N:1=1;R:024;N:1=1;R:025;N:1=1;R:026;N:1=1;R:027;N:1=1;R:028;N:1=1;R:029;N:1=1;R:030;N:1=1;R:031;N:1=1;R:032;N:1=1;R:033;N:1=1;R:034;N:1=1;R:035;N:1=1;R:036;N:1=1;R:037;N:1=1;R:038;N:1=1;R:039;N:1=1;R:040;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;N:1=1;R:041;N:1=1;R:042;N:1=1;R:043;N:1=1;R:044;N:1=1;R:045;N:1=1;R:046;N:1=1;R:047;N:1=1;R:048;N:1=1;R:049;N:1=1;R:050;N:1=1;R:051;N:1=1;R:052;N:1=1;R:053;N:1=1;R:054;N:1=1;R:055;N:1=1;R:056;N:1=1;R:057;N:1=1;R:058;N:1=1;R:059;N:1=1;R:060;R:040;F:==Yes;R:040;C:040;R:041;F:==Yes;R:041;C:041;R:042;F:==Yes;R:042;C:042;R:043;F:==Yes;R:043;C:043;R:044;F:==Yes;R:044;C:044;R:045;F:==Yes;R:045;C:045;R:046;F:==Yes;R:046;C:046;R:047;F:==Yes;R:047;C:047;R:048;F:==Yes;R:048;C:048;R:049;F:==Yes;R:049;C:049;R:050;F:==Yes;R:050;C:050;R:051;F:==Yes;R:051;C:051;R:052;F:==Yes;R:052;C:052;R:053;F:==Yes;R:053;C:053;R:054;F:==Yes;R:054;C:054;R:055;F:==Yes;R:055;C:055;R:056;F:==Yes;R:056;C:056;R:057;F:==Yes;R:057;C:057;R:058;F:==Yes;R:058;C:058;R:059;F:==Yes;R:059;C:059;R:060;N:1=1;R:061;N:1=1;R:062;N:1=1;R:063;N:1=1;R:064;N:1=1;R:065;N:1=1;R:066;N:1=1;R:067;N:1=1;R:068;N:1=1;R:069;N:1=1;R:070;N:1=0;R:060;F:==Yes;R:060;C:060;R:061;F:==Yes;R:061;C:061;R:062;F:==Yes;R:062;C:062;R:063;F:==Yes;R:063;C:063;R:064;F:==Yes;R:064;C:064;R:065;F:==Yes;R:065;C:065;R:066;F:==Yes;R:066;C:066;R:067;F:==Yes;R:067;C:067;R:068;F:==Yes;R:068;C:068;R:069;F:==Yes;R:069;C:069;R:070;F:==Yes;R:070;C:070;R:001;F:==Yes;R:001;C:001');
        Observer.Expect('miss no', 'N001');
        Observer.Expect('unused ok', 'No');
        Observer.Expect('unused|text', 'The row does not exist on the TestPage.');
        Observer.Expect('unused|code', 'TestRowNotFound');
        Observer.Expect('unused log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033;R:034;F:==Yes;R:034;C:034;R:035;F:==Yes;R:035;C:035;R:036;F:==Yes;R:036;C:036;R:037;F:==Yes;R:037;C:037;R:038;F:==Yes;R:038;C:038;R:039;F:==Yes;R:039;C:039;R:040;F:==Yes;R:040;C:040;R:041;F:==Yes;R:041;C:041;R:042;F:==Yes;R:042;C:042;R:043;F:==Yes;R:043;C:043;R:044;F:==Yes;R:044;C:044;R:045;F:==Yes;R:045;C:045;R:046;F:==Yes;R:046;C:046;R:047;F:==Yes;R:047;C:047;R:048;F:==Yes;R:048;C:048;R:049;F:==Yes;R:049;C:049;R:050;F:==Yes;R:050;C:050;R:051;F:==Yes;R:051;C:051;R:052;F:==Yes;R:052;C:052;R:053;F:==Yes;R:053;C:053;R:054;F:==Yes;R:054;C:054;R:055;F:==Yes;R:055;C:055;R:056;F:==Yes;R:056;C:056;R:057;F:==Yes;R:057;C:057;R:058;F:==Yes;R:058;C:058;R:059;F:==Yes;R:059;C:059;R:060;F:==Yes;R:060;C:060;R:061;F:==Yes;R:061;C:061;R:062;F:==Yes;R:062;C:062;R:063;F:==Yes;R:063;C:063;R:064;F:==Yes;R:064;C:064;R:065;F:==Yes;R:065;C:065;R:066;F:==Yes;R:066;C:066;R:067;F:==Yes;R:067;C:067;R:068;F:==Yes;R:068;C:068;R:069;F:==Yes;R:069;C:069;R:070;F:==Yes;R:070;C:070;R:001;F:==Yes;R:001;C:001');
        Observer.Expect('unused no', 'N001');
        Observer.Verify();
    end;



}
