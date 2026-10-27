// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73869 (log), table 73870, pages 73871, 73872 and 73873, codeunit 73874; writer QD: pages 86530 to 86533; writer QV: enum 87462, table 87461, pages 87460 and 87463 to 87465; writer RK: pages 88068 to 88073
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Find list" (Page reads after an action, and a list that ends inside its window, corpus bump 7)
// Facts: log of OnFindRecord (F), OnNextRecord (N), OnAfterGetRecord (R) and OnAfterGetCurrRecord (C) when a TestPage opens a list and moves First, Next, Last and Previous,
//   on an ascending view, on a descending view (Rec.Ascending(false) in OnOpenPage) and for a list without OnFindRecord, over 3 and over 25 rows
// BC versions: 29 (27 and 28 by CI)

codeunit 73869 "LT PnF FL Log"
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

table 73870 "LT PnF FL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73871 "LT PnF FL Asc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 73872 "LT PnF FL Desc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

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

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 73873 "LT PnF FL Plain Desc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

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

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

codeunit 73874 "LT PnF Find List Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT PnF FL Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Id := i;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure MovesAsc(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Asc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    local procedure MovesDesc(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    local procedure MovesPlain(Rows: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Plain Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', Log.Take());
        P.Next();
        Observer.Observe(Prefix + 'next', Log.Take());
        P.Last();
        Observer.Observe(Prefix + 'last', Log.Take());
        P.Previous();
        Observer.Observe(Prefix + 'prev', Log.Take());
        P.First();
        Observer.Observe(Prefix + 'first', Log.Take());
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure FindList_Ascending_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(3, 'asc3_', Observer);
        Observer.Expect('asc3_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R1;N(-1);F(=);R1;C;');
        Observer.Expect('asc3_next', 'R2;F(=);R2;C;');
        Observer.Expect('asc3_last', 'R3;F(=);R3;C;');
        Observer.Expect('asc3_prev', 'R2;F(=);R2;C;');
        Observer.Expect('asc3_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Ascending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(25, 'asc25_', Observer);
        Observer.Expect('asc25_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asc25_next', 'R2;F(=);R2;C;');
        Observer.Expect('asc25_last', 'R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);F(=);R25;C;');
        Observer.Expect('asc25_prev', 'R24;F(=);R24;C;');
        Observer.Expect('asc25_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Descending_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(3, 'desc3_', Observer);
        Observer.Expect('desc3_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc3_next', '');
        Observer.Expect('desc3_last', '');
        Observer.Expect('desc3_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc3_first', 'R3;F(=);R3;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_Descending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(25, 'desc25_', Observer);
        Observer.Expect('desc25_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R21;R1;F(=);R1;C;');
        Observer.Expect('desc25_next', '');
        Observer.Expect('desc25_last', '');
        Observer.Expect('desc25_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc25_first', 'R21;N(-1);R22;N(-1);R23;N(-1);R24;N(-1);R25;N(-1);F(=);R25;C;');
        Observer.Verify();
    end;

    [Test]
    procedure FindList_PlainDescending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesPlain(3, 'plain3_', Observer);
        MovesPlain(25, 'plain25_', Observer);
        Observer.Expect('plain3_open', 'R3;R2;R1;R3;R3;C;');
        Observer.Expect('plain3_next', 'R2;R2;C;');
        Observer.Expect('plain3_last', 'R1;R1;C;');
        Observer.Expect('plain3_prev', 'R2;R2;C;');
        Observer.Expect('plain3_first', 'R3;R3;C;');
        Observer.Expect('plain25_open', 'R25;R24;R23;R22;R21;R20;R19;R18;R17;R16;R15;R14;R13;R12;R11;R10;R9;R8;R7;R6;R25;R25;C;');
        Observer.Expect('plain25_next', 'R24;R24;C;');
        Observer.Expect('plain25_last', 'R6;R5;R4;R3;R2;R1;R1;C;');
        Observer.Expect('plain25_prev', 'R2;R2;C;');
        Observer.Expect('plain25_first', 'R25;R25;C;');
        Observer.Verify();
    end;
    // Writer PW: trust-refusals probe list "descending find list step back": the open of the descending OnFindRecord list (with
    // OnAfterGetCurrRecord) at 1, 2, 19, 20 and 21 rows (3 and 25 are pinned above), and the ascending list at 19, 20 and 21 rows.
    [Test]
    procedure PW_FindList_Descending_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(1, 'desc1_', Observer);
        Observer.Expect('desc1_open', 'F(=><);R1;N(1);N(-1);F(=);R1;C;');
        Observer.Expect('desc1_next', '');
        Observer.Expect('desc1_last', '');
        Observer.Expect('desc1_prev', '');
        Observer.Expect('desc1_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_2Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(2, 'desc2_', Observer);
        Observer.Expect('desc2_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc2_next', '');
        Observer.Expect('desc2_last', '');
        Observer.Expect('desc2_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc2_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_19Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(19, 'desc19_', Observer);
        Observer.Expect('desc19_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc19_next', '');
        Observer.Expect('desc19_last', '');
        Observer.Expect('desc19_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc19_first', 'R19;F(=);R19;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(20, 'desc20_', Observer);
        Observer.Expect('desc20_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R1;F(=);R1;C;');
        Observer.Expect('desc20_next', '');
        Observer.Expect('desc20_last', '');
        Observer.Expect('desc20_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc20_first', 'R20;F(=);R20;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Descending_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesDesc(21, 'desc21_', Observer);
        Observer.Expect('desc21_open', 'F(=><);R1;N(1);N(-1);R2;N(-1);R3;N(-1);R4;N(-1);R5;N(-1);R6;N(-1);R7;N(-1);R8;N(-1);R9;N(-1);R10;N(-1);R11;N(-1);R12;N(-1);R13;N(-1);R14;N(-1);R15;N(-1);R16;N(-1);R17;N(-1);R18;N(-1);R19;N(-1);R20;N(-1);R21;R1;F(=);R1;C;');
        Observer.Expect('desc21_next', '');
        Observer.Expect('desc21_last', '');
        Observer.Expect('desc21_prev', 'R2;F(=);R2;C;');
        Observer.Expect('desc21_first', 'R21;N(-1);R21;F(=);R21;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_19Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(19, 'asce19_', Observer);
        Observer.Expect('asce19_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce19_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce19_last', 'R19;F(=);R19;C;');
        Observer.Expect('asce19_prev', 'R18;F(=);R18;C;');
        Observer.Expect('asce19_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(20, 'asce20_', Observer);
        Observer.Expect('asce20_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce20_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce20_last', 'R20;N(1);R20;F(=);R20;C;');
        Observer.Expect('asce20_prev', 'R19;F(=);R19;C;');
        Observer.Expect('asce20_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_FindList_Ascending_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MovesAsc(21, 'asce21_', Observer);
        Observer.Expect('asce21_open', 'F(=><);R1;N(1);R2;N(1);R3;N(1);R4;N(1);R5;N(1);R6;N(1);R7;N(1);R8;N(1);R9;N(1);R10;N(1);R11;N(1);R12;N(1);R13;N(1);R14;N(1);R15;N(1);R16;N(1);R17;N(1);R18;N(1);R19;N(1);R20;R1;N(-1);F(=);R1;C;');
        Observer.Expect('asce21_next', 'R2;F(=);R2;C;');
        Observer.Expect('asce21_last', 'R20;N(1);R21;N(1);F(=);R21;C;');
        Observer.Expect('asce21_prev', 'R20;F(=);R20;C;');
        Observer.Expect('asce21_first', 'R1;F(=);R1;C;');
        Observer.Verify();
    end;

    // Writer PW: trust-refusals probe list "rows a GoToKey past a full 20-row window reads": GoToKey on the OnFindRecord lists after the open
    // read a full window. Each step's trigger log.
    local procedure PwGoToAsc(Rows: Integer; K1: Integer; K2: Integer; K3: Integer; ObserveFirst: Boolean; ObserveRest: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Asc";
        Row: Record "LT PnF FL Row";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Log.Take();
        Row.Get(K1);
        if ObserveFirst then
            Observer.Observe('goto' + Format(K1), Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take())
        else
            P.GoToRecord(Row);
        Log.Take();
        if ObserveRest then begin
            Observer.Observe('goToKey' + Format(K2), Format(P.GoToKey(K2)) + '|' + P.Id.Value() + '|' + Log.Take());
            Observer.Observe('goToKey' + Format(K3), Format(P.GoToKey(K3)) + '|' + P.Id.Value() + '|' + Log.Take());
            P.Next();
            Observer.Observe('next', P.Id.Value() + '|' + Log.Take());
        end;
        P.Close();
        Log.Take();
    end;

    local procedure PwGoToDesc(Rows: Integer; K1: Integer; K2: Integer; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT PnF FL Desc";
    begin
        Seed(Rows);
        Log.Take();
        P.OpenView();
        Log.Take();
        Observer.Observe('goToKey' + Format(K1), Format(P.GoToKey(K1)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('goToKey' + Format(K2), Format(P.GoToKey(K2)) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Next();
        Observer.Observe('next', P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(25, 23, 5, 25, true, true, Observer);
        Observer.Expect('goto23', 'Yes|23|R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;');
        Observer.Expect('goToKey5', 'Yes|5|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;');
        Observer.Expect('goToKey25', 'Yes|25|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;');
        Observer.Expect('next', '25|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_45Rows_FarJump()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(45, 40, 21, 45, true, false, Observer);
        Observer.Expect('goto40', 'Yes|40|R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;N(1);R21;N(1);R22;N(1);R23;N(1);R24;N(1);R25;N(1);R26;N(1);R27;N(1);R28;N(1);R29;N(1);R30;N(1);R31;N(1);R32;N(1);R33;N(1);R34;N(1);R35;N(1);R36;N(1);R37;N(1);R38;N(1);R39;N(1);R40;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;R26;F(=);R26;C;R27;F(=);R27;C;R28;F(=);R28;C;R29;F(=);R29;C;R30;F(=);R30;C;R31;F(=);R31;C;R32;F(=);R32;C;R33;F(=);R33;C;R34;F(=);R34;C;R35;F(=);R35;C;R36;F(=);R36;C;R37;F(=);R37;C;R38;F(=);R38;C;R39;F(=);R39;C;R40;N(1);R41;N(1);R42;N(1);R43;N(1);R44;N(1);R45;N(1);R40;F(=);R40;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Ascending_45Rows_AfterFarJump()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToAsc(45, 40, 21, 45, false, true, Observer);
        Observer.Expect('goToKey21', 'Yes|21|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;');
        Observer.Expect('goToKey45', 'Yes|45|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;R26;F(=);R26;C;R27;F(=);R27;C;R28;F(=);R28;C;R29;F(=);R29;C;R30;F(=);R30;C;R31;F(=);R31;C;R32;F(=);R32;C;R33;F(=);R33;C;R34;F(=);R34;C;R35;F(=);R35;C;R36;F(=);R36;C;R37;F(=);R37;C;R38;F(=);R38;C;R39;F(=);R39;C;R40;F(=);R40;C;R41;F(=);R41;C;R42;F(=);R42;C;R43;F(=);R43;C;R44;F(=);R44;C;R45;F(=);R45;C;');
        Observer.Expect('next', '45|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GoToKey_Descending_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwGoToDesc(25, 3, 20, Observer);
        Observer.Expect('goToKey3', 'Yes|3|R21;N(-1);R22;N(-1);R23;N(-1);R24;N(-1);R25;N(-1);F(=);R25;C;R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;R19;F(=);R19;C;R18;F(=);R18;C;R17;F(=);R17;C;R16;F(=);R16;C;R15;F(=);R15;C;R14;F(=);R14;C;R13;F(=);R13;C;R12;F(=);R12;C;R11;F(=);R11;C;R10;F(=);R10;C;R9;F(=);R9;C;R8;F(=);R8;C;R7;F(=);R7;C;R6;F(=);R6;C;R5;F(=);R5;C;R4;F(=);R4;C;R3;F(=);R3;C;');
        Observer.Expect('goToKey20', 'Yes|20|R25;F(=);R25;C;R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;');
        Observer.Expect('next', '19|R19;F(=);R19;C;');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Page row window" item 7: a find list that opens on its LAST row with rows above it. Is the opening
    // row read (OnAfterGetRecord) before OnNextRecord(-1)? Trigger log (O = OnOpenPage) at open, then of Next and Previous; current row.
    // Pages 86151 (with OnAfterGetCurrRecord) and 86152 (without) position in OnOpenPage with FindLast; LT PnF FL Asc is opened on a handed
    // last row (SetRecord, Run, trapped).
    local procedure PwOpenLast(Rows: Integer; WithCurr: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P1: TestPage "LT PW FL Last Curr";
        P2: TestPage "LT PW FL Last Plain";
    begin
        Seed(Rows);
        Log.Take();
        if WithCurr then begin
            P1.OpenView();
            Observer.Observe('open', P1.Id.Value() + '|' + Log.Take());
            Observer.Observe('next', Format(P1.Next()) + '|' + P1.Id.Value() + '|' + Log.Take());
            Observer.Observe('previous', Format(P1.Previous()) + '|' + P1.Id.Value() + '|' + Log.Take());
            P1.Close();
        end else begin
            P2.OpenView();
            Observer.Observe('open', P2.Id.Value() + '|' + Log.Take());
            Observer.Observe('next', Format(P2.Next()) + '|' + P2.Id.Value() + '|' + Log.Take());
            Observer.Observe('previous', Format(P2.Previous()) + '|' + P2.Id.Value() + '|' + Log.Take());
            P2.Close();
        end;
        Log.Take();
    end;

    [Test]
    procedure PW_OpenOnLastRow_WithCurrRecord_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwOpenLast(3, true, Observer);
        Observer.Expect('open', '3|O;F(=>);R3;N(1);N(-1);R2;N(-1);R1;N(-1);R3;F(=);R3;C;');
        Observer.Expect('next', 'No|3|');
        Observer.Expect('previous', 'Yes|2|R2;F(=);R2;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_OpenOnLastRow_WithCurrRecord_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwOpenLast(25, true, Observer);
        Observer.Expect('open', '25|O;F(=>);R25;N(1);N(-1);R24;N(-1);R23;N(-1);R22;N(-1);R21;N(-1);R20;N(-1);R19;N(-1);R18;N(-1);R17;N(-1);R16;N(-1);R15;N(-1);R14;N(-1);R13;N(-1);R12;N(-1);R11;N(-1);R10;N(-1);R9;N(-1);R8;N(-1);R7;N(-1);R6;N(-1);R5;R25;F(=);R25;C;');
        Observer.Expect('next', 'No|25|');
        Observer.Expect('previous', 'Yes|24|R24;F(=);R24;C;');
        Observer.Verify();
    end;

    [Test]
    procedure PW_OpenOnLastRow_NoCurrRecord_3Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwOpenLast(3, false, Observer);
        Observer.Expect('open', '3|O;F(=>);R3;N(1);N(-1);R2;N(-1);R1;N(-1);');
        Observer.Expect('next', 'No|3|');
        Observer.Expect('previous', 'Yes|2|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_OpenOnLastRow_NoCurrRecord_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwOpenLast(25, false, Observer);
        Observer.Expect('open', '25|O;F(=>);R25;N(1);N(-1);R24;N(-1);R23;N(-1);R22;N(-1);R21;N(-1);R20;N(-1);R19;N(-1);R18;N(-1);R17;N(-1);R16;N(-1);R15;N(-1);R14;N(-1);R13;N(-1);R12;N(-1);R11;N(-1);R10;N(-1);R9;N(-1);R8;N(-1);R7;N(-1);R6;N(-1);R5;');
        Observer.Expect('next', 'No|25|');
        Observer.Expect('previous', 'Yes|24|');
        Observer.Verify();
    end;

    [Test]
    procedure PW_OpenOnHandedLastRow_3Rows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        Row: Record "LT PnF FL Row";
        Pg: Page "LT PnF FL Asc";
        P: TestPage "LT PnF FL Asc";
    begin
        Seed(3);
        Row.Get(3);
        Log.Take();
        P.Trap();
        Pg.SetRecord(Row);
        Pg.Run();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
        Observer.Expect('open', '3|F(=>);R3;N(1);N(-1);R2;N(-1);R1;N(-1);R3;F(=);R3;C;');
        Observer.Expect('next', 'Yes|0|C;');
        Observer.Expect('previous', 'Yes|3|R3;F(=);R3;C;');
        Observer.Verify();
    end;

    // Writer QD (al-runtime-rs PR "OnFindRecord on pages whose SourceTableView filters"): what First, Next, Last, Previous and GoToKey ask a
    // list with OnFindRecord (with and without OnNextRecord) whose SourceTableView is descending with a WHERE part, over 6 rows (the view keeps
    // 1, 3, 5) and 25 rows (the view keeps 2..24); and GoToKey past the rows the client holds on a list with OnFindRecord only and 25 rows.
    // Each step: result|current Id|trigger log (F = OnFindRecord, N = OnNextRecord, R = OnAfterGetRecord, C = OnAfterGetCurrRecord).
    [Test]
    procedure QD_DescView_FindOnly_6Rows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QD FL DescView Find";
    begin
        Seed(6);
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('08_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('09_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('10_gotokey2_out', Format(P.GoToKey(2)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey3', Format(P.GoToKey(3)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_gotokey1', Format(P.GoToKey(1)) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
        Observer.Expect('open', '1|F(=><);R1;R3;R5;R1;F(=);R1;C;');
        Observer.Expect('01_first', 'Yes|5|R5;F(=);R5;C;');
        Observer.Expect('02_next', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('03_next', 'Yes|1|R1;F(=);R1;C;');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_last', 'Yes|1|');
        Observer.Expect('06_previous', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('07_previous', 'Yes|5|R5;F(=);R5;C;');
        Observer.Expect('08_previous_top', 'No|5|');
        Observer.Expect('09_first', 'Yes|5|');
        Observer.Expect('10_gotokey2_out', 'No|5|R3;F(=);R3;C;R1;F(=);R1;C;R5;F(=);R5;C;');
        Observer.Expect('11_gotokey3', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('12_gotokey1', 'Yes|1|R5;F(=);R5;C;R3;F(=);R3;C;R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure QD_DescView_FindNext_6Rows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QD FL DescView FindNext";
    begin
        Seed(6);
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('08_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('09_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('10_gotokey2_out', Format(P.GoToKey(2)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey3', Format(P.GoToKey(3)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_gotokey1', Format(P.GoToKey(1)) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
        Observer.Expect('open', '1|F(=><);R1;N(1);N(-1);R3;N(-1);R5;N(-1);R1;F(=);R1;C;');
        Observer.Expect('01_first', 'Yes|5|R5;F(=);R5;C;');
        Observer.Expect('02_next', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('03_next', 'Yes|1|R1;F(=);R1;C;');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_last', 'Yes|1|');
        Observer.Expect('06_previous', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('07_previous', 'Yes|5|R5;F(=);R5;C;');
        Observer.Expect('08_previous_top', 'No|5|');
        Observer.Expect('09_first', 'Yes|5|');
        Observer.Expect('10_gotokey2_out', 'No|5|R3;F(=);R3;C;R1;F(=);R1;C;R5;F(=);R5;C;');
        Observer.Expect('11_gotokey3', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('12_gotokey1', 'Yes|1|R5;F(=);R5;C;R3;F(=);R3;C;R1;F(=);R1;C;');
        Observer.Verify();
    end;

    [Test]
    procedure QD_DescView_FindOnly_25Rows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QD FL DescView25";
    begin
        Seed(25);
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_gotokey4', Format(P.GoToKey(4)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_gotokey1_out', Format(P.GoToKey(1)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_gotokey20', Format(P.GoToKey(20)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('08_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
        Observer.Expect('open', '2|F(=><);R2;R3;R4;R5;R6;R7;R8;R9;R10;R11;R12;R13;R14;R15;R16;R17;R18;R19;R20;R21;R22;R2;F(=);R2;C;');
        Observer.Expect('01_next', 'No|2|');
        Observer.Expect('02_last', 'Yes|2|');
        Observer.Expect('03_previous', 'Yes|3|R3;F(=);R3;C;');
        Observer.Expect('04_first', 'Yes|24|R22;R23;R24;F(=);R24;C;');
        Observer.Expect('05_gotokey4', 'Yes|4|R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;R19;F(=);R19;C;R18;F(=);R18;C;R17;F(=);R17;C;R16;F(=);R16;C;R15;F(=);R15;C;R14;F(=);R14;C;R13;F(=);R13;C;R12;F(=);R12;C;R11;F(=);R11;C;R10;F(=);R10;C;R9;F(=);R9;C;R8;F(=);R8;C;R7;F(=);R7;C;R6;F(=);R6;C;R5;F(=);R5;C;R4;F(=);R4;C;');
        Observer.Expect('06_gotokey1_out', 'No|4|R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;R19;F(=);R19;C;R18;F(=);R18;C;R17;F(=);R17;C;R16;F(=);R16;C;R15;F(=);R15;C;R14;F(=);R14;C;R13;F(=);R13;C;R12;F(=);R12;C;R11;F(=);R11;C;R10;F(=);R10;C;R9;F(=);R9;C;R8;F(=);R8;C;R7;F(=);R7;C;R6;F(=);R6;C;R5;F(=);R5;C;R4;F(=);R4;C;R3;F(=);R3;C;R2;F(=);R2;C;R4;F(=);R4;C;');
        Observer.Expect('07_gotokey20', 'Yes|20|R24;F(=);R24;C;R23;F(=);R23;C;R22;F(=);R22;C;R21;F(=);R21;C;R20;F(=);R20;C;');
        Observer.Expect('08_next', 'Yes|19|R19;F(=);R19;C;');
        Observer.Verify();
    end;

    [Test]
    procedure QD_FindOnly_25Rows_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QD FL FindOnly";
    begin
        Seed(25);
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_gotokey23', Format(P.GoToKey(23)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_gotokey5', Format(P.GoToKey(5)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_gotokey25', Format(P.GoToKey(25)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_gotokey26_none', Format(P.GoToKey(26)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('08_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Log.Take();
        Observer.Expect('open', '1|F(=><);R1;R2;R3;R4;R5;R6;R7;R8;R9;R10;R11;R12;R13;R14;R15;R16;R17;R18;R19;R20;R1;F(=);R1;C;');
        Observer.Expect('01_gotokey23', 'Yes|23|R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;R21;R22;R23;R24;R25;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;');
        Observer.Expect('02_gotokey5', 'Yes|5|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;');
        Observer.Expect('03_gotokey25', 'Yes|25|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;');
        Observer.Expect('04_gotokey26_none', 'No|25|R1;F(=);R1;C;R2;F(=);R2;C;R3;F(=);R3;C;R4;F(=);R4;C;R5;F(=);R5;C;R6;F(=);R6;C;R7;F(=);R7;C;R8;F(=);R8;C;R9;F(=);R9;C;R10;F(=);R10;C;R11;F(=);R11;C;R12;F(=);R12;C;R13;F(=);R13;C;R14;F(=);R14;C;R15;F(=);R15;C;R16;F(=);R16;C;R17;F(=);R17;C;R18;F(=);R18;C;R19;F(=);R19;C;R20;F(=);R20;C;R21;F(=);R21;C;R22;F(=);R22;C;R23;F(=);R23;C;R24;F(=);R24;C;R25;F(=);R25;C;');
        Observer.Expect('05_previous', 'Yes|24|R24;F(=);R24;C;');
        Observer.Expect('06_first', 'Yes|1|R1;F(=);R1;C;');
        Observer.Expect('07_last', 'Yes|25|R25;F(=);R25;C;');
        Observer.Expect('08_next_end', 'No|25|');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5682): the moves of a TestPage on the lists 87460, 87463, 87464 and 87465 (descending view, WHERE on the
    // non-key field Kind; rows 1..6, the view keeps 5, 3, 1). Each step: result|Id shown|trigger log since the step before
    // (F(which)=found:Id = OnFindRecord, N(steps)=moved:Id = OnNextRecord, C = OnAfterGetCurrRecord, R = OnAfterGetRecord).
    local procedure QvSeedKinds()
    var
        Row: Record "LT QV FL Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 6 do begin
            Row.Init();
            Row.Id := I;
            if I mod 2 = 0 then
                Row.Kind := Row.Kind::B
            else
                Row.Kind := Row.Kind::A;
            Row.Insert();
        end;
    end;

    [Test]
    procedure QV_DescKind_FindOnly_Moves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        Row: Record "LT QV FL Row";
        P: TestPage "LT QV FL DescKind Find";
    begin
        QvSeedKinds();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(3);
        Observer.Observe('08_gotorecord3', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(1);
        Observer.Observe('09_gotorecord1', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(2);
        Observer.Observe('10_gotorecord2_out', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey5', Format(P.GoToKey(5)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('01_first', 'Yes|5|');
        Observer.Expect('02_next', 'Yes|3|');
        Observer.Expect('03_next', 'Yes|1|');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_previous', 'Yes|3|');
        Observer.Expect('06_last', 'Yes|1|');
        Observer.Expect('07_first', 'Yes|5|');
        Observer.Expect('08_gotorecord3', 'Yes|3|');
        Observer.Expect('09_gotorecord1', 'Yes|1|');
        Observer.Expect('10_gotorecord2_out', 'No|1|');
        Observer.Expect('11_gotokey5', 'Yes|5|');
        Observer.Expect('12_previous_top', 'No|5|');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QV_DescKind_FindNext_Moves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        Row: Record "LT QV FL Row";
        P: TestPage "LT QV FL DescKind FindNext";
    begin
        QvSeedKinds();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(3);
        Observer.Observe('08_gotorecord3', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(1);
        Observer.Observe('09_gotorecord1', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(2);
        Observer.Observe('10_gotorecord2_out', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey5', Format(P.GoToKey(5)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:3;N(-1)=-1:5;N(-1)=0:5;');
        Observer.Expect('01_first', 'Yes|5|');
        Observer.Expect('02_next', 'Yes|3|');
        Observer.Expect('03_next', 'Yes|1|');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_previous', 'Yes|3|');
        Observer.Expect('06_last', 'Yes|1|');
        Observer.Expect('07_first', 'Yes|5|');
        Observer.Expect('08_gotorecord3', 'Yes|3|');
        Observer.Expect('09_gotorecord1', 'Yes|1|');
        Observer.Expect('10_gotorecord2_out', 'No|1|');
        Observer.Expect('11_gotokey5', 'Yes|5|');
        Observer.Expect('12_previous_top', 'No|5|');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QV_DescKind_FindCurr_Moves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        Row: Record "LT QV FL Row";
        P: TestPage "LT QV FL DescKind FindCurr";
    begin
        QvSeedKinds();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(3);
        Observer.Observe('08_gotorecord3', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(1);
        Observer.Observe('09_gotorecord1', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(2);
        Observer.Observe('10_gotorecord2_out', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey5', Format(P.GoToKey(5)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', '1|F(=><)=Yes:1;F(=)=Yes:1;C1;');
        Observer.Expect('01_first', 'Yes|5|F(=)=Yes:5;C5;');
        Observer.Expect('02_next', 'Yes|3|F(=)=Yes:3;C3;');
        Observer.Expect('03_next', 'Yes|1|F(=)=Yes:1;C1;');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_previous', 'Yes|3|F(=)=Yes:3;C3;');
        Observer.Expect('06_last', 'Yes|1|F(=)=Yes:1;C1;');
        Observer.Expect('07_first', 'Yes|5|F(=)=Yes:5;C5;');
        Observer.Expect('08_gotorecord3', 'Yes|3|F(=)=Yes:3;C3;');
        Observer.Expect('09_gotorecord1', 'Yes|1|F(=)=Yes:5;C5;F(=)=Yes:3;C3;F(=)=Yes:1;C1;');
        Observer.Expect('10_gotorecord2_out', 'No|1|F(=)=Yes:5;C5;F(=)=Yes:3;C3;F(=)=Yes:1;C1;');
        Observer.Expect('11_gotokey5', 'Yes|5|F(=)=Yes:5;C5;');
        Observer.Expect('12_previous_top', 'No|5|');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QV_DescKind_FindGet_Moves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF FL Log";
        Row: Record "LT QV FL Row";
        P: TestPage "LT QV FL DescKind FindGet";
    begin
        QvSeedKinds();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe('01_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('02_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('03_next', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('04_next_end', Format(P.Next()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('05_previous', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('06_last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('07_first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(3);
        Observer.Observe('08_gotorecord3', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(1);
        Observer.Observe('09_gotorecord1', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Row.Get(2);
        Observer.Observe('10_gotorecord2_out', Format(P.GoToRecord(Row)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('11_gotokey5', Format(P.GoToKey(5)) + '|' + P.Id.Value() + '|' + Log.Take());
        Observer.Observe('12_previous_top', Format(P.Previous()) + '|' + P.Id.Value() + '|' + Log.Take());
        P.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', '1|F(=><)=Yes:1;R1;R3;R5;');
        Observer.Expect('01_first', 'Yes|5|');
        Observer.Expect('02_next', 'Yes|3|');
        Observer.Expect('03_next', 'Yes|1|');
        Observer.Expect('04_next_end', 'No|1|');
        Observer.Expect('05_previous', 'Yes|3|');
        Observer.Expect('06_last', 'Yes|1|');
        Observer.Expect('07_first', 'Yes|5|');
        Observer.Expect('08_gotorecord3', 'Yes|3|');
        Observer.Expect('09_gotorecord1', 'Yes|1|');
        Observer.Expect('10_gotorecord2_out', 'No|1|');
        Observer.Expect('11_gotokey5', 'Yes|5|');
        Observer.Expect('12_previous_top', 'No|5|');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    // Writer RK (AL Runner issue 5739, reporter's page shape; extends the QV probes of issue 5682): a List with OnFindRecord (with and without
    // OnNextRecord) and no row trigger, over a SourceTableView that is descending or ascending, with or without a WHERE on the non-key field
    // Kind, holding 1 (AL Runner issue 5738), 5, 20, 21 and 25 rows (the client window holds 20). Each test opens the page with OpenView, calls First, Next until it
    // answers false, Last, then Previous until it answers false. Observed: open = Id shown|log; first and last = result|Id|log; walk and back =
    // the Id after each move that answered true, followed by [log] when the move called the page, then end:<Id shown after the move that
    // answered false>[log]; close = log of Close. Log entries: F(which)=found:Id = OnFindRecord, N(steps)=moved:Id = OnNextRecord.
    local procedure RkSeed(Rows: Integer)
    var
        Row: Record "LT QV FL Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to Rows do begin
            Row.Init();
            Row.Id := I;
            if I mod 2 = 0 then
                Row.Kind := Row.Kind::B
            else
                Row.Kind := Row.Kind::A;
            Row.Insert();
        end;
    end;

    local procedure RkStep(Entries: Text): Text
    begin
        if Entries = '' then
            exit('');
        exit('[' + Entries + ']');
    end;

    local procedure RkMoves_DescKind_Find(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QV FL DescKind Find";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    // The reporter's case of AL Runner issue 5738: Id 1 (Kind A) and Id 2 (Kind B), the view keeps one row.
    [Test]
    procedure RK_DescKind_Find_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(2);
        RkMoves_DescKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_Find_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(10);
        RkMoves_DescKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|9|');
        Observer.Expect('walk', '7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,end:9');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_Find_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(40);
        RkMoves_DescKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|39|');
        Observer.Expect('walk', '37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,end:39');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_Find_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(42);
        RkMoves_DescKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|41|');
        Observer.Expect('walk', '39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,end:41');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    // The reporter's case of AL Runner issue 5739: 50 rows, the view keeps the 25 odd Ids (on BC: open on 1 asking F(=><) once, then no call).
    [Test]
    procedure RK_DescKind_Find_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(50);
        RkMoves_DescKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|49|');
        Observer.Expect('walk', '47,45,43,41,39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,end:49');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_DescKind_FindNext(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT QV FL DescKind FindNext";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_DescKind_FindNext_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(2);
        RkMoves_DescKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_FindNext_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(10);
        RkMoves_DescKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:3;N(-1)=-1:5;N(-1)=-1:7;N(-1)=-1:9;N(-1)=0:9;');
        Observer.Expect('first', 'Yes|9|');
        Observer.Expect('walk', '7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,end:9');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_FindNext_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(40);
        RkMoves_DescKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:3;N(-1)=-1:5;N(-1)=-1:7;N(-1)=-1:9;N(-1)=-1:11;N(-1)=-1:13;N(-1)=-1:15;N(-1)=-1:17;N(-1)=-1:19;N(-1)=-1:21;N(-1)=-1:23;N(-1)=-1:25;N(-1)=-1:27;N(-1)=-1:29;N(-1)=-1:31;N(-1)=-1:33;N(-1)=-1:35;N(-1)=-1:37;N(-1)=-1:39;N(-1)=0:39;');
        Observer.Expect('first', 'Yes|39|');
        Observer.Expect('walk', '37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,end:39');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_FindNext_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(42);
        RkMoves_DescKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:3;N(-1)=-1:5;N(-1)=-1:7;N(-1)=-1:9;N(-1)=-1:11;N(-1)=-1:13;N(-1)=-1:15;N(-1)=-1:17;N(-1)=-1:19;N(-1)=-1:21;N(-1)=-1:23;N(-1)=-1:25;N(-1)=-1:27;N(-1)=-1:29;N(-1)=-1:31;N(-1)=-1:33;N(-1)=-1:35;N(-1)=-1:37;N(-1)=-1:39;N(-1)=-1:41;');
        Observer.Expect('first', 'Yes|41|N(-1)=0:41;');
        Observer.Expect('walk', '39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,end:41');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_DescKind_FindNext_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(50);
        RkMoves_DescKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:3;N(-1)=-1:5;N(-1)=-1:7;N(-1)=-1:9;N(-1)=-1:11;N(-1)=-1:13;N(-1)=-1:15;N(-1)=-1:17;N(-1)=-1:19;N(-1)=-1:21;N(-1)=-1:23;N(-1)=-1:25;N(-1)=-1:27;N(-1)=-1:29;N(-1)=-1:31;N(-1)=-1:33;N(-1)=-1:35;N(-1)=-1:37;N(-1)=-1:39;N(-1)=-1:41;');
        Observer.Expect('first', 'Yes|49|N(-1)=-1:43;N(-1)=-1:45;N(-1)=-1:47;N(-1)=-1:49;N(-1)=0:49;');
        Observer.Expect('walk', '47,45,43,41,39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,end:49');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_AscKind_Find(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL AscKind Find";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_AscKind_Find_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(2);
        RkMoves_AscKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_Find_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(10);
        RkMoves_AscKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,end:9');
        Observer.Expect('last', 'Yes|9|');
        Observer.Expect('back', '7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_Find_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(40);
        RkMoves_AscKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,end:39');
        Observer.Expect('last', 'Yes|39|');
        Observer.Expect('back', '37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_Find_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(42);
        RkMoves_AscKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,end:41');
        Observer.Expect('last', 'Yes|41|');
        Observer.Expect('back', '39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_Find_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(50);
        RkMoves_AscKind_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,end:49');
        Observer.Expect('last', 'Yes|49|');
        Observer.Expect('back', '47,45,43,41,39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_AscKind_FindNext(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL AscKind FindNext";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_AscKind_FindNext_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(2);
        RkMoves_AscKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_FindNext_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(10);
        RkMoves_AscKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:3;N(1)=1:5;N(1)=1:7;N(1)=1:9;N(1)=0:9;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,end:9');
        Observer.Expect('last', 'Yes|9|');
        Observer.Expect('back', '7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_FindNext_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(40);
        RkMoves_AscKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:3;N(1)=1:5;N(1)=1:7;N(1)=1:9;N(1)=1:11;N(1)=1:13;N(1)=1:15;N(1)=1:17;N(1)=1:19;N(1)=1:21;N(1)=1:23;N(1)=1:25;N(1)=1:27;N(1)=1:29;N(1)=1:31;N(1)=1:33;N(1)=1:35;N(1)=1:37;N(1)=1:39;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39[N(1)=0:39;],end:39');
        Observer.Expect('last', 'Yes|39|');
        Observer.Expect('back', '37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_FindNext_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(42);
        RkMoves_AscKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:3;N(1)=1:5;N(1)=1:7;N(1)=1:9;N(1)=1:11;N(1)=1:13;N(1)=1:15;N(1)=1:17;N(1)=1:19;N(1)=1:21;N(1)=1:23;N(1)=1:25;N(1)=1:27;N(1)=1:29;N(1)=1:31;N(1)=1:33;N(1)=1:35;N(1)=1:37;N(1)=1:39;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39[N(1)=1:41;N(1)=0:41;],41,end:41');
        Observer.Expect('last', 'Yes|41|');
        Observer.Expect('back', '39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_AscKind_FindNext_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(50);
        RkMoves_AscKind_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:3;N(1)=1:5;N(1)=1:7;N(1)=1:9;N(1)=1:11;N(1)=1:13;N(1)=1:15;N(1)=1:17;N(1)=1:19;N(1)=1:21;N(1)=1:23;N(1)=1:25;N(1)=1:27;N(1)=1:29;N(1)=1:31;N(1)=1:33;N(1)=1:35;N(1)=1:37;N(1)=1:39;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39[N(1)=1:41;N(1)=1:43;N(1)=1:45;N(1)=1:47;N(1)=1:49;N(1)=0:49;],41,43,45,47,49,end:49');
        Observer.Expect('last', 'Yes|49|');
        Observer.Expect('back', '47,45,43,41,39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_Desc_Find(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL Desc Find";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_Desc_Find_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(1);
        RkMoves_Desc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_Find_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(5);
        RkMoves_Desc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|5|');
        Observer.Expect('walk', '4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,end:5');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_Find_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(20);
        RkMoves_Desc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|20|');
        Observer.Expect('walk', '19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,end:20');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_Find_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(21);
        RkMoves_Desc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|21|');
        Observer.Expect('walk', '20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,end:21');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_Find_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(25);
        RkMoves_Desc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|25|');
        Observer.Expect('walk', '24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,end:25');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_Desc_FindNext(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL Desc FindNext";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_Desc_FindNext_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(1);
        RkMoves_Desc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_FindNext_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(5);
        RkMoves_Desc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:2;N(-1)=-1:3;N(-1)=-1:4;N(-1)=-1:5;N(-1)=0:5;');
        Observer.Expect('first', 'Yes|5|');
        Observer.Expect('walk', '4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,end:5');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_FindNext_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(20);
        RkMoves_Desc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:2;N(-1)=-1:3;N(-1)=-1:4;N(-1)=-1:5;N(-1)=-1:6;N(-1)=-1:7;N(-1)=-1:8;N(-1)=-1:9;N(-1)=-1:10;N(-1)=-1:11;N(-1)=-1:12;N(-1)=-1:13;N(-1)=-1:14;N(-1)=-1:15;N(-1)=-1:16;N(-1)=-1:17;N(-1)=-1:18;N(-1)=-1:19;N(-1)=-1:20;N(-1)=0:20;');
        Observer.Expect('first', 'Yes|20|');
        Observer.Expect('walk', '19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,end:20');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_FindNext_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(21);
        RkMoves_Desc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:2;N(-1)=-1:3;N(-1)=-1:4;N(-1)=-1:5;N(-1)=-1:6;N(-1)=-1:7;N(-1)=-1:8;N(-1)=-1:9;N(-1)=-1:10;N(-1)=-1:11;N(-1)=-1:12;N(-1)=-1:13;N(-1)=-1:14;N(-1)=-1:15;N(-1)=-1:16;N(-1)=-1:17;N(-1)=-1:18;N(-1)=-1:19;N(-1)=-1:20;N(-1)=-1:21;');
        Observer.Expect('first', 'Yes|21|N(-1)=0:21;');
        Observer.Expect('walk', '20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,end:21');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Desc_FindNext_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(25);
        RkMoves_Desc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=-1:2;N(-1)=-1:3;N(-1)=-1:4;N(-1)=-1:5;N(-1)=-1:6;N(-1)=-1:7;N(-1)=-1:8;N(-1)=-1:9;N(-1)=-1:10;N(-1)=-1:11;N(-1)=-1:12;N(-1)=-1:13;N(-1)=-1:14;N(-1)=-1:15;N(-1)=-1:16;N(-1)=-1:17;N(-1)=-1:18;N(-1)=-1:19;N(-1)=-1:20;N(-1)=-1:21;');
        Observer.Expect('first', 'Yes|25|N(-1)=-1:22;N(-1)=-1:23;N(-1)=-1:24;N(-1)=-1:25;N(-1)=0:25;');
        Observer.Expect('walk', '24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,end:25');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_Asc_Find(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL Asc Find";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_Asc_Find_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(1);
        RkMoves_Asc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_Find_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(5);
        RkMoves_Asc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,end:5');
        Observer.Expect('last', 'Yes|5|');
        Observer.Expect('back', '4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_Find_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(20);
        RkMoves_Asc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,end:20');
        Observer.Expect('last', 'Yes|20|');
        Observer.Expect('back', '19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_Find_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(21);
        RkMoves_Asc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,end:21');
        Observer.Expect('last', 'Yes|21|');
        Observer.Expect('back', '20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_Find_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(25);
        RkMoves_Asc_Find('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,end:25');
        Observer.Expect('last', 'Yes|25|');
        Observer.Expect('back', '24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    local procedure RkMoves_Asc_FindNext(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PnF FL Log";
        P: TestPage "LT RK FL Asc FindNext";
        Walk: Text;
        Steps: Integer;
    begin
        Log.Take();
        P.OpenView();
        Observer.Observe(Prefix + 'open', P.Id.Value() + '|' + Log.Take());
        Observer.Observe(Prefix + 'first', Format(P.First()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Next() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'walk', Walk);
        Observer.Observe(Prefix + 'last', Format(P.Last()) + '|' + P.Id.Value() + '|' + Log.Take());
        Walk := '';
        Steps := 0;
        while P.Previous() and (Steps < 60) do begin
            Walk += P.Id.Value() + RkStep(Log.Take()) + ',';
            Steps += 1;
        end;
        Walk += 'end:' + P.Id.Value() + RkStep(Log.Take());
        Observer.Observe(Prefix + 'back', Walk);
        P.Close();
        Observer.Observe(Prefix + 'close', Log.Take());
    end;

    [Test]
    procedure RK_Asc_FindNext_1Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(1);
        RkMoves_Asc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=0:1;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', 'end:1');
        Observer.Expect('last', 'Yes|1|');
        Observer.Expect('back', 'end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_FindNext_5Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(5);
        RkMoves_Asc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:2;N(1)=1:3;N(1)=1:4;N(1)=1:5;N(1)=0:5;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,end:5');
        Observer.Expect('last', 'Yes|5|');
        Observer.Expect('back', '4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_FindNext_20Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(20);
        RkMoves_Asc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:2;N(1)=1:3;N(1)=1:4;N(1)=1:5;N(1)=1:6;N(1)=1:7;N(1)=1:8;N(1)=1:9;N(1)=1:10;N(1)=1:11;N(1)=1:12;N(1)=1:13;N(1)=1:14;N(1)=1:15;N(1)=1:16;N(1)=1:17;N(1)=1:18;N(1)=1:19;N(1)=1:20;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20[N(1)=0:20;],end:20');
        Observer.Expect('last', 'Yes|20|');
        Observer.Expect('back', '19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_FindNext_21Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(21);
        RkMoves_Asc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:2;N(1)=1:3;N(1)=1:4;N(1)=1:5;N(1)=1:6;N(1)=1:7;N(1)=1:8;N(1)=1:9;N(1)=1:10;N(1)=1:11;N(1)=1:12;N(1)=1:13;N(1)=1:14;N(1)=1:15;N(1)=1:16;N(1)=1:17;N(1)=1:18;N(1)=1:19;N(1)=1:20;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20[N(1)=1:21;N(1)=0:21;],21,end:21');
        Observer.Expect('last', 'Yes|21|');
        Observer.Expect('back', '20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure RK_Asc_FindNext_25Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RkSeed(25);
        RkMoves_Asc_FindNext('', Observer);
        Observer.Expect('open', '1|F(=><)=Yes:1;N(1)=1:2;N(1)=1:3;N(1)=1:4;N(1)=1:5;N(1)=1:6;N(1)=1:7;N(1)=1:8;N(1)=1:9;N(1)=1:10;N(1)=1:11;N(1)=1:12;N(1)=1:13;N(1)=1:14;N(1)=1:15;N(1)=1:16;N(1)=1:17;N(1)=1:18;N(1)=1:19;N(1)=1:20;N(-1)=0:1;');
        Observer.Expect('first', 'Yes|1|');
        Observer.Expect('walk', '2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20[N(1)=1:21;N(1)=1:22;N(1)=1:23;N(1)=1:24;N(1)=1:25;N(1)=0:25;],21,22,23,24,25,end:25');
        Observer.Expect('last', 'Yes|25|');
        Observer.Expect('back', '24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,end:1');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    // ---- Writer SF, al-runner issue 5887: a temporary list (and the same list as a ListPart on a ListPlus host that Page.Run opens
    // with a filter) whose OnFindRecord and OnNextRecord walk a position global (rows on every day 1 to 40, inserted on demand) and
    // whose OnAfterGetRecord sets that global from Rec; no OnAfterGetCurrRecord. It opens on day 10, so the first window (days 10 to
    // 29) is full and OnNextRecord(-1) from the first row answers a step. Objects 89310 to 89315 at the end of this file.
    // Log: F(<Which>)=<found Y/N>:<day after the call>, N(<Steps>)=<answer>:<day after the call>, R<day> = OnAfterGetRecord,
    // U(<host>):<day> = the host refills the part.

    [Test]
    procedure SF_DayList_OpensOnDayTen_Next_Previous()
    var
        Log: Codeunit "LT PnF FL Log";
        List: TestPage "LT SF Day List";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        List.OpenView();
        Observer.Observe('open', List."Day No.".Value() + '|' + Log.Take());
        List.Next();
        Observer.Observe('next', List."Day No.".Value() + '|' + Log.Take());
        List.Previous();
        Observer.Observe('previous', List."Day No.".Value() + '|' + Log.Take());
        List.Close();
        Observer.Expect('open', '10|F(=><)=Y:10;R10;N(1)=1:11;R11;N(1)=1:12;R12;N(1)=1:13;R13;N(1)=1:14;R14;N(1)=1:15;R15;N(1)=1:16;R16;N(1)=1:17;R17;N(1)=1:18;R18;N(1)=1:19;R19;N(1)=1:20;R20;N(1)=1:21;R21;N(1)=1:22;R22;N(1)=1:23;R23;N(1)=1:24;R24;N(1)=1:25;R25;N(1)=1:26;R26;N(1)=1:27;R27;N(1)=1:28;R28;N(1)=1:29;R29;R10;N(-1)=-1:9;R9;N(-1)=-1:8;R8;N(-1)=-1:7;R7;N(-1)=-1:6;R6;N(-1)=-1:5;R5;N(-1)=-1:4;R4;N(-1)=-1:3;R3;N(-1)=-1:2;R2;N(-1)=-1:1;R1;N(-1)=0:1;');
        Observer.Expect('next', '11|');
        Observer.Expect('previous', '10|');
        Observer.Verify();
    end;

    [Test]
    procedure SF_DayHost_RunWithFilter_OpensPart()
    var
        Log: Codeunit "LT PnF FL Log";
        HostRow: Record "LT SF Day Host";
        Host: TestPage "LT SF Day Host";
        Observer: Codeunit "Probe Observer";
    begin
        HostRow.DeleteAll();
        HostRow.Code := 'A';
        HostRow.Insert();
        HostRow.Code := 'B';
        HostRow.Insert();
        Log.Take();
        HostRow.SetRange(Code, 'A');
        Host.Trap();
        Page.Run(Page::"LT SF Day Host", HostRow);
        Observer.Observe('open', Host.Lines."Day No.".Value() + '|' + Log.Take());
        Observer.Observe('filter', Host.Filter.GetFilter(Code));
        Host.Close();
        Observer.Expect('open', '10|U(A):0;F(=><)=Y:10;R10;N(1)=1:11;R11;N(1)=1:12;R12;N(1)=1:13;R13;N(1)=1:14;R14;N(1)=1:15;R15;N(1)=1:16;R16;N(1)=1:17;R17;N(1)=1:18;R18;N(1)=1:19;R19;N(1)=1:20;R20;N(1)=1:21;R21;N(1)=1:22;R22;N(1)=1:23;R23;N(1)=1:24;R24;N(1)=1:25;R25;N(1)=1:26;R26;N(1)=1:27;R27;N(1)=1:28;R28;N(1)=1:29;R29;R10;N(-1)=-1:9;R9;N(-1)=-1:8;R8;N(-1)=-1:7;R7;N(-1)=-1:6;R6;N(-1)=-1:5;R5;N(-1)=-1:4;R4;N(-1)=-1:3;R3;N(-1)=-1:2;R2;N(-1)=-1:1;R1;N(-1)=0:1;');
        Observer.Expect('filter', 'A');
        HostRow.Reset();
        HostRow.DeleteAll();
        Observer.Verify();
    end;
}

// Writer PW: an OnFindRecord / OnNextRecord / OnAfterGetRecord list that positions itself on the last row in OnOpenPage (with OnAfterGetCurrRecord).
page 86151 "LT PW FL Last Curr"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('O');
        if Rec.FindLast() then;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

// Writer PW: an OnFindRecord / OnNextRecord / OnAfterGetRecord list that positions itself on the last row in OnOpenPage (no OnAfterGetCurrRecord).
page 86152 "LT PW FL Last Plain"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('O');
        if Rec.FindLast() then;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;
}

// Writer QD: lists with OnFindRecord over a descending SourceTableView with a WHERE part, and a list with OnFindRecord only.
page 86530 "LT QD FL DescView Find"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";
    SourceTableView = sorting(Id) order(descending) where(Id = filter(1 | 3 | 5));

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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 86531 "LT QD FL DescView FindNext"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";
    SourceTableView = sorting(Id) order(descending) where(Id = filter(1 | 3 | 5));

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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('N(' + Format(Steps) + ')');
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 86532 "LT QD FL DescView25"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";
    SourceTableView = sorting(Id) order(descending) where(Id = filter(2 .. 24));

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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

page 86533 "LT QD FL FindOnly"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF FL Row";

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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C');
    end;
}

// Writer QV (AL Runner issue 5682): lists over a descending SourceTableView whose WHERE part filters a non-key enum field (Kind = A keeps
// the odd Ids of 1..6), with OnFindRecord only (the reporter's page) and with OnFindRecord plus one more trigger each, to see which trigger
// makes BC ask the page on a move.
enum 87462 "LT QV FL Kind"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

table 87461 "LT QV FL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT QV FL Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 87460 "LT QV FL DescKind Find"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

page 87463 "LT QV FL DescKind FindNext"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

page 87464 "LT QV FL DescKind FindCurr"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('C' + Format(Rec.Id));
    end;
}

page 87465 "LT QV FL DescKind FindGet"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF FL Log";
    begin
        Log.Add('R' + Format(Rec.Id));
    end;
}

// Writer RK (AL Runner issue 5739): the QV lists above with the other SourceTableView shapes: ascending with the WHERE on Kind, and
// descending and ascending without a WHERE; with OnFindRecord only and with OnFindRecord plus OnNextRecord, no row trigger.

page 88068 "LT RK FL AscKind Find"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(ascending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

page 88069 "LT RK FL AscKind FindNext"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(ascending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

page 88070 "LT RK FL Desc Find"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

page 88071 "LT RK FL Desc FindNext"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

page 88072 "LT RK FL Asc Find"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(ascending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

page 88073 "LT RK FL Asc FindNext"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QV FL Row";
    SourceTableView = sorting(Id) order(ascending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT PnF FL Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT PnF FL Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

// Writer SF (al-runner issue 5887): the day-walking list, part and host of the SF_Day* tests in codeunit 73874. Days are fixed dates
// (2030-01-01 = day 1 to 2030-02-09 = day 40), so nothing depends on the run date. The walker logs through LT PnF FL Log (73869).
table 89310 "LT SF Day Row"
{
    TableType = Temporary;

    fields
    {
        field(1; Day; Date) { }
        field(2; "Day No."; Integer) { }
    }

    keys
    {
        key(PK; Day) { Clustered = true; }
    }
}

table 89311 "LT SF Day Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 89312 "LT SF Day Walker"
{
    var
        Log: Codeunit "LT PnF FL Log";

    procedure DayNo(Day: Date): Integer
    begin
        if Day = 0D then
            exit(0);
        exit(Day - 20291231D);
    end;

    local procedure FirstDay(): Date
    begin
        exit(20300101D);
    end;

    local procedure LastDay(): Date
    begin
        exit(20300209D);
    end;

    local procedure StartDay(): Date
    begin
        exit(20300110D);
    end;

    procedure Find(var Row: Record "LT SF Day Row" temporary; var Pos: Date; Which: Text): Boolean
    var
        i: Integer;
        Found: Boolean;
    begin
        if Pos = 0D then
            Pos := StartDay();
        for i := 1 to StrLen(Which) do
            if not Found then
                case Which[i] of
                    '=':
                        Found := (Pos >= FirstDay()) and (Pos <= LastDay());
                    '>':
                        if Pos < LastDay() then begin
                            Pos := Pos + 1;
                            Found := true;
                        end;
                    '<':
                        if Pos > FirstDay() then begin
                            Pos := Pos - 1;
                            Found := true;
                        end;
                    '-':
                        begin
                            Pos := FirstDay();
                            Found := true;
                        end;
                    '+':
                        begin
                            Pos := LastDay();
                            Found := true;
                        end;
                end;
        if Found then
            Fill(Row, Pos);
        Log.Add('F(' + Which + ')=' + YesNo(Found) + ':' + Format(DayNo(Pos)));
        exit(Found);
    end;

    procedure Next(var Row: Record "LT SF Day Row" temporary; var Pos: Date; Steps: Integer): Integer
    var
        Target: Date;
        Result: Integer;
    begin
        if Row.Day <> Pos then
            Pos := Row.Day;
        Target := Pos + Steps;
        if Target < FirstDay() then
            Target := FirstDay();
        if Target > LastDay() then
            Target := LastDay();
        Result := Target - Pos;
        if Result <> 0 then begin
            Pos := Target;
            Fill(Row, Pos);
        end;
        Log.Add('N(' + Format(Steps) + ')=' + Format(Result) + ':' + Format(DayNo(Pos)));
        exit(Result);
    end;

    procedure Read(var Row: Record "LT SF Day Row" temporary; var Pos: Date)
    begin
        Pos := Row.Day;
        Log.Add('R' + Format(DayNo(Row.Day)));
    end;

    procedure LogRefill(HostCode: Code[10]; Pos: Date)
    begin
        Log.Add('U(' + HostCode + '):' + Format(DayNo(Pos)));
    end;

    local procedure Fill(var Row: Record "LT SF Day Row" temporary; Day: Date)
    begin
        if not Row.Get(Day) then begin
            Row.Init();
            Row.Day := Day;
            Row."Day No." := DayNo(Day);
            Row.Insert();
        end;
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Y');
        exit('N');
    end;
}

page 89313 "LT SF Day Part"
{
    PageType = ListPart;
    SourceTable = "LT SF Day Row";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Day No."; Rec."Day No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Walker.Find(Rec, Pos, Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Walker.Next(Rec, Pos, Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        Walker.Read(Rec, Pos);
    end;

    var
        Walker: Codeunit "LT SF Day Walker";
        Pos: Date;

    procedure Refill(HostCode: Code[10])
    begin
        Walker.LogRefill(HostCode, Pos);
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;
}

page 89314 "LT SF Day List"
{
    PageType = List;
    SourceTable = "LT SF Day Row";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Day No."; Rec."Day No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Walker.Find(Rec, Pos, Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Walker.Next(Rec, Pos, Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        Walker.Read(Rec, Pos);
    end;

    var
        Walker: Codeunit "LT SF Day Walker";
        Pos: Date;
}

page 89315 "LT SF Day Host"
{
    PageType = ListPlus;
    SourceTable = "LT SF Day Host";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
            }
            part(Lines; "LT SF Day Part")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrPage.Lines.Page.Refill(Rec.Code);
    end;
}
