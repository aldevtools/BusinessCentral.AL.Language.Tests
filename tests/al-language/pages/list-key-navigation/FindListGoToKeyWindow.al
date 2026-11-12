// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope (Cloud). TestPage.
// Fixtures used: Probe Observer (codeunit 69160); own tables 64775 64776, log codeunit 64777, pages 64778 64779 64780 64781, test
//   codeunit 64782
// Probe (values from the CI runs on BC 27.5, 28.5 and 29.0, the same on all three). Area: moves on lists longer than the rows the client reads at once, and GoToRecord on a list that serves its rows
//   from OnFindRecord (Rec.Find, no OnNextRecord) and has OnAfterGetRecord and OnAfterGetCurrRecord (the shape of a sales document
//   subform, al-runner issues 7377 and 7398). Cells: a plain list of 60 rows walked with Next() to the end, GoToRecord onto row 45 then
//   Previous(); the find list of 60 rows opened on its own, GoToRecord onto row 50, and onto row 5 then row 50; the find list as a part
//   standing on its second row, an action that inserts a row after it, GoToRecord onto the inserted row and onto the first row.
//   Pinned nearby: pages/long-list-open/LastOnLongList.al (Last() on long lists), Y7344ListFirstWindow.al, pages/extensions/
//   PCCurrRecordReads.al (a find list of 3 rows). Not pinned: the cells above.
// Observed: the result of each move, the row shown after it and the log (F:<which> OnFindRecord, R:<n> OnAfterGetRecord,
//   C:<n> OnAfterGetCurrRecord); for the plain list the number of steps and the last row.
// local object: the find triggers of the pages and the row counts are what the test checks
// BC versions: 27, 28, 29

table 64775 "PGA FW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; Descr; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Doc", "Line No.") { Clustered = true; }
    }
}

table 64776 "PGA FW Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 64777 "PGA FW Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 64778 "PGA FW Plain List"
{
    PageType = List;
    SourceTable = "PGA FW Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 64779 "PGA FW Find List"
{
    PageType = List;
    SourceTable = "PGA FW Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PGA FW Log";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('F:' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;
}

page 64780 "PGA FW Find Part"
{
    PageType = ListPart;
    SourceTable = "PGA FW Row";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertAfter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "PGA FW Row";
                begin
                    Log.Add('ACT:' + Format(Rec."Line No."));
                    Row := Rec;
                    Row."Line No." := Rec."Line No." + 5000;
                    Row.Descr := 'inserted';
                    Row.Insert();
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA FW Log";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('F:' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;
}

page 64781 "PGA FW Doc"
{
    PageType = Document;
    SourceTable = "PGA FW Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PGA FW Find Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc" = field("No.");
            }
        }
    }
}

codeunit 64782 "PGA FW Find List GoToKey"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA FW Log";

    local procedure Initialize(Count: Integer)
    var
        Row: Record "PGA FW Row";
        Head: Record "PGA FW Head";
        i: Integer;
    begin
        Observer.Discard();
        Row.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'Q1';
        Head.Insert();
        for i := 1 to Count do begin
            Row.Init();
            Row."Doc" := 'Q1';
            Row."Line No." := i * 10000;
            Row.Descr := 'row' + Format(i);
            Row.Insert();
        end;
        Log.Take();
    end;

    [Test]
    procedure Plain_60Rows_OpenView_NextToTheEnd()
    var
        P: TestPage "PGA FW Plain List";
        Steps: Integer;
    begin
        Initialize(60);
        P.OpenView();
        Observer.Observe('opened on', P."Line No.".Value());
        while P.Next() do
            Steps += 1;
        Observer.Observe('steps', Format(Steps));
        Observer.Observe('last shown', P."Line No.".Value());
        Observer.Expect('opened on', '10000');
        Observer.Expect('steps', '59');
        Observer.Expect('last shown', '600000');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_60Rows_OpenView_GoToRecord45_ThenPrevious()
    var
        Row: Record "PGA FW Row";
        P: TestPage "PGA FW Plain List";
    begin
        Initialize(60);
        Row.Get('Q1', 450000);
        P.OpenView();
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('shown', P."Line No.".Value());
        Observer.Observe('previous', Format(P.Previous()));
        Observer.Observe('shown after previous', P."Line No.".Value());
        Observer.Expect('goto', 'Yes');
        Observer.Expect('shown', '450000');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('shown after previous', '440000');
        Observer.Verify();
    end;

    [Test]
    procedure Find_60Rows_OpenEdit_GoToRecord50()
    var
        Row: Record "PGA FW Row";
        P: TestPage "PGA FW Find List";
    begin
        Initialize(60);
        Row.Get('Q1', 500000);
        P.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('log-goto', Log.Take());
        Observer.Observe('shown', P.Descr.Value());
        Observer.Expect('log-open', 'F:=><;R:10000;R:20000;R:30000;R:40000;R:50000;R:60000;R:70000;R:80000;R:90000;R:100000;R:110000;R:120000;R:130000;R:140000;R:150000;R:160000;R:170000;R:180000;R:190000;R:200000;R:10000;F:=;R:10000;C:10000');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('log-goto', 'R:20000;F:=;R:20000;C:20000;R:30000;F:=;R:30000;C:30000;R:40000;F:=;R:40000;C:40000;R:50000;F:=;R:50000;C:50000;R:60000;F:=;R:60000;C:60000;R:70000;F:=;R:70000;C:70000;R:80000;F:=;R:80000;C:80000;R:90000;F:=;R:90000;C:90000;R:100000;F:=;R:100000;C:100000;R:110000;F:=;R:110000;C:110000;R:120000;F:=;R:120000;C:120000;R:130000;F:=;R:130000;C:130000;R:140000;F:=;R:140000;C:140000;R:150000;F:=;R:150000;C:150000;R:160000;F:=;R:160000;C:160000;R:170000;F:=;R:170000;C:170000;R:180000;F:=;R:180000;C:180000;R:190000;F:=;R:190000;C:190000;R:200000;R:210000;R:220000;R:230000;R:240000;R:250000;R:260000;R:270000;R:280000;R:290000;R:300000;R:310000;R:320000;R:330000;R:340000;R:350000;R:360000;R:370000;R:380000;R:390000;R:400000;R:200000;F:=;R:200000;C:200000;R:210000;F:=;R:210000;C:210000;R:220000;F:=;R:220000;C:220000;R:230000;F:=;R:230000;C:230000;R:240000;F:=;R:240000;C:240000;R:250000;F:=;R:250000;C:250000;R:260000;F:=;R:260000;C:260000;R:270000;F:=;R:270000;C:270000;R:280000;F:=;R:280000;C:280000;R:290000;F:=;R:290000;C:290000;R:300000;F:=;R:300000;C:300000;R:310000;F:=;R:310000;C:310000;R:320000;F:=;R:320000;C:320000;R:330000;F:=;R:330000;C:330000;R:340000;F:=;R:340000;C:340000;R:350000;F:=;R:350000;C:350000;R:360000;F:=;R:360000;C:360000;R:370000;F:=;R:370000;C:370000;R:380000;F:=;R:380000;C:380000;R:390000;F:=;R:390000;C:390000;R:400000;R:410000;R:420000;R:430000;R:440000;R:450000;R:460000;R:470000;R:480000;R:490000;R:500000;R:510000;R:520000;R:530000;R:540000;R:550000;R:560000;R:570000;R:580000;R:590000;R:600000;R:400000;F:=;R:400000;C:400000;R:410<MORE>');
        Observer.Verify();
    end;

    [Test]
    procedure Find_60Rows_OpenEdit_GoToRecord5_ThenGoToRecord50()
    var
        Row: Record "PGA FW Row";
        P: TestPage "PGA FW Find List";
    begin
        Initialize(60);
        P.OpenEdit();
        Log.Take();
        Row.Get('Q1', 50000);
        Observer.Observe('goto5', Format(P.GoToRecord(Row)));
        Observer.Observe('log-goto5', Log.Take());
        Row.Get('Q1', 500000);
        Observer.Observe('goto50', Format(P.GoToRecord(Row)));
        Observer.Observe('log-goto50', Log.Take());
        Observer.Observe('shown', P.Descr.Value());
        Observer.Expect('goto5', 'Yes');
        Observer.Expect('log-goto5', 'R:20000;F:=;R:20000;C:20000;R:30000;F:=;R:30000;C:30000;R:40000;F:=;R:40000;C:40000;R:50000;F:=;R:50000;C:50000');
        Observer.Expect('goto50', 'Yes');
        Observer.Expect('log-goto50', 'R:10000;F:=;R:10000;C:10000;R:20000;F:=;R:20000;C:20000;R:30000;F:=;R:30000;C:30000;R:40000;F:=;R:40000;C:40000;R:50000;F:=;R:50000;C:50000;R:60000;F:=;R:60000;C:60000;R:70000;F:=;R:70000;C:70000;R:80000;F:=;R:80000;C:80000;R:90000;F:=;R:90000;C:90000;R:100000;F:=;R:100000;C:100000;R:110000;F:=;R:110000;C:110000;R:120000;F:=;R:120000;C:120000;R:130000;F:=;R:130000;C:130000;R:140000;F:=;R:140000;C:140000;R:150000;F:=;R:150000;C:150000;R:160000;F:=;R:160000;C:160000;R:170000;F:=;R:170000;C:170000;R:180000;F:=;R:180000;C:180000;R:190000;F:=;R:190000;C:190000;R:200000;R:210000;R:220000;R:230000;R:240000;R:250000;R:260000;R:270000;R:280000;R:290000;R:300000;R:310000;R:320000;R:330000;R:340000;R:350000;R:360000;R:370000;R:380000;R:390000;R:400000;R:200000;F:=;R:200000;C:200000;R:210000;F:=;R:210000;C:210000;R:220000;F:=;R:220000;C:220000;R:230000;F:=;R:230000;C:230000;R:240000;F:=;R:240000;C:240000;R:250000;F:=;R:250000;C:250000;R:260000;F:=;R:260000;C:260000;R:270000;F:=;R:270000;C:270000;R:280000;F:=;R:280000;C:280000;R:290000;F:=;R:290000;C:290000;R:300000;F:=;R:300000;C:300000;R:310000;F:=;R:310000;C:310000;R:320000;F:=;R:320000;C:320000;R:330000;F:=;R:330000;C:330000;R:340000;F:=;R:340000;C:340000;R:350000;F:=;R:350000;C:350000;R:360000;F:=;R:360000;C:360000;R:370000;F:=;R:370000;C:370000;R:380000;F:=;R:380000;C:380000;R:390000;F:=;R:390000;C:390000;R:400000;R:410000;R:420000;R:430000;R:440000;R:450000;R:460000;R:470000;R:480000;R:490000;R:500000;R:510000;R:520000;R:530000;R:540000;R:550000;R:560000;R:570000;R:580000;R:590000;R:600000;R:400000;F:=;R:400000;C:400000;R:410000;F:=;R:410000;C:410000;R:420000;F:=;R:420000;C:<MORE>');
        Observer.Verify();
    end;

    [Test]
    procedure FindPart_SecondRow_ActionInserts_GoToRecordInserted()
    var
        Head: Record "PGA FW Head";
        Row: Record "PGA FW Row";
        P: TestPage "PGA FW Doc";
    begin
        Initialize(2);
        Head.Get('Q1');
        P.OpenEdit();
        P.GoToRecord(Head);
        Log.Take();
        Row.Get('Q1', 20000);
        Observer.Observe('goto2', Format(P.Lines.GoToRecord(Row)));
        Observer.Observe('log-goto2', Log.Take());
        P.Lines.InsertAfter.Invoke();
        Observer.Observe('log-action', Log.Take());
        Row.Get('Q1', 25000);
        Observer.Observe('goto-inserted', Format(P.Lines.GoToRecord(Row)));
        Observer.Observe('log-goto-inserted', Log.Take());
        Observer.Observe('shown', P.Lines.Descr.Value());
        Observer.Expect('goto2', 'Yes');
        Observer.Expect('log-goto2', 'R:20000;F:=;R:20000;C:20000');
        Observer.Expect('log-action', 'R:20000;ACT:20000;R:20000;F:=>;R:20000;R:25000;R:20000;R:10000;R:20000;F:=;R:20000;C:20000');
        Observer.Expect('goto-inserted', 'Yes');
        Observer.Expect('log-goto-inserted', 'R:10000;F:=;R:10000;C:10000;R:20000;F:=;R:20000;C:20000;R:25000;F:=;R:25000;C:25000');
        Observer.Expect('shown', 'inserted');
        Observer.Verify();
    end;

    [Test]
    procedure FindPart_SecondRow_GoToRecordFirstRow()
    var
        Head: Record "PGA FW Head";
        Row: Record "PGA FW Row";
        P: TestPage "PGA FW Doc";
    begin
        Initialize(3);
        Head.Get('Q1');
        P.OpenEdit();
        P.GoToRecord(Head);
        Row.Get('Q1', 20000);
        P.Lines.GoToRecord(Row);
        Log.Take();
        Row.Get('Q1', 10000);
        Observer.Observe('goto1', Format(P.Lines.GoToRecord(Row)));
        Observer.Observe('log-goto1', Log.Take());
        Row.Get('Q1', 30000);
        Observer.Observe('goto3', Format(P.Lines.GoToRecord(Row)));
        Observer.Observe('log-goto3', Log.Take());
        Observer.Expect('goto1', 'Yes');
        Observer.Expect('log-goto1', 'R:10000;F:=;R:10000;C:10000');
        Observer.Expect('goto3', 'Yes');
        Observer.Expect('log-goto3', 'R:20000;F:=;R:20000;C:20000;R:30000;F:=;R:30000;C:30000');
        Observer.Verify();
    end;
}
