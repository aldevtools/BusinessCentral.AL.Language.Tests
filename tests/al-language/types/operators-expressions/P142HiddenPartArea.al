// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 74550, SingleInstance log 74551 (used only by test codeunit 74558), part pages 74552-74554, host pages 74555-74557
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74550 "LT P142 Host Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74551 "LT P142 Part Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 74552 "LT P142 Part A"
{
    PageType = ListPart;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Ping(): Text
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('A-Ping(rec=' + Format(Rec.Id) + ',count=' + Format(Rec.Count()) + ')');
        exit('A-pong');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('A-OnOpenPage(count=' + Format(Rec.Count()) + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('A-OnAfterGetRecord:' + Format(Rec.Id));
    end;
}

page 74553 "LT P142 Part B"
{
    PageType = ListPart;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Ping(): Text
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('B-Ping(rec=' + Format(Rec.Id) + ',count=' + Format(Rec.Count()) + ')');
        exit('B-pong');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('B-OnOpenPage(count=' + Format(Rec.Count()) + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('B-OnAfterGetRecord:' + Format(Rec.Id));
    end;
}

page 74554 "LT P142 Part C"
{
    PageType = ListPart;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Ping(): Text
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('C-Ping(rec=' + Format(Rec.Id) + ',count=' + Format(Rec.Count()) + ')');
        exit('C-pong');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('C-OnOpenPage(count=' + Format(Rec.Count()) + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P142 Part Log";
    begin
        Log.Add('C-OnAfterGetRecord:' + Format(Rec.Id));
    end;
}

page 74555 "LT P142 Host A"
{
    PageType = Card;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P142 Part A")
            {
                ApplicationArea = Service;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P142 Part Log";
        Pong: Text;
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        Pong := CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping:' + Pong);
    end;
}

page 74556 "LT P142 Host B"
{
    PageType = Card;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P142 Part B")
            {
                ApplicationArea = Basic;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P142 Part Log";
        Pong: Text;
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        Pong := CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping:' + Pong);
    end;
}

page 74557 "LT P142 Host C"
{
    PageType = Card;
    SourceTable = "LT P142 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P142 Part C")
            {
                // no ApplicationArea on this part
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P142 Part Log";
        Pong: Text;
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        Pong := CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping:' + Pong);
    end;
}

codeunit 74558 "LT P142 Hidden Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P142 Host Row";
        Log: Codeunit "LT P142 Part Log";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        R.Id := 2;
        R.Insert();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenA(var Host: TestPage "LT P142 Host A")
    begin
        Host.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenB(var Host: TestPage "LT P142 Host B")
    begin
        Host.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenC(var Host: TestPage "LT P142 Host C")
    begin
        Host.OpenView();
    end;

    [TryFunction]
    local procedure TryPartVisibleA(var Host: TestPage "LT P142 Host A"; var Vis: Boolean)
    begin
        Vis := Host.PartCtl.Visible();
    end;

    [TryFunction]
    local procedure TryPartVisibleB(var Host: TestPage "LT P142 Host B"; var Vis: Boolean)
    begin
        Vis := Host.PartCtl.Visible();
    end;

    [TryFunction]
    local procedure TryPartVisibleC(var Host: TestPage "LT P142 Host C"; var Vis: Boolean)
    begin
        Vis := Host.PartCtl.Visible();
    end;

    [Test]
    procedure P142_ServiceAreaPartRemoved()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P142 Part Log";
        Host: TestPage "LT P142 Host A";
        Previous: Text;
        Vis: Boolean;
        Opened: Boolean;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        Opened := TryOpenA(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part_found', Format(TryPartVisibleA(Host, Vis)) + '|' + Format(Vis));
        Observer.Observe('part_error', CopyStr(GetLastErrorText(), 1, 300));
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log_after_next', Log.Dump());
            Host.Close();
        end;
        ApplicationArea(Previous);
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '|');
        Observer.Expect('log', '[host-OnAfterGetCurrRecord | A-Ping(rec=0,count=2) | host-after-Ping:A-pong]');
        Observer.Expect('part_found', 'No|No');
        Observer.Expect('part_error', 'The part with ID = n was not found on the page.');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log_after_next', '[host-OnAfterGetCurrRecord | A-Ping(rec=0,count=2) | host-after-Ping:A-pong]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_BasicAreaPartKept()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P142 Part Log";
        Host: TestPage "LT P142 Host B";
        Previous: Text;
        Vis: Boolean;
        Opened: Boolean;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        Opened := TryOpenB(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part_found', Format(TryPartVisibleB(Host, Vis)) + '|' + Format(Vis));
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log_after_next', Log.Dump());
            Host.Close();
        end;
        ApplicationArea(Previous);
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '|');
        Observer.Expect('log', '[B-OnOpenPage(count=2) | host-OnAfterGetCurrRecord | B-Ping(rec=0,count=2) | host-after-Ping:B-pong | B-OnAfterGetRecord:1 | B-OnAfterGetRecord:2 | B-OnAfterGetRecord:1]');
        Observer.Expect('part_found', 'Yes|Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log_after_next', '[host-OnAfterGetCurrRecord | B-Ping(rec=1,count=2) | host-after-Ping:B-pong]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_NoAreaPart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P142 Part Log";
        Host: TestPage "LT P142 Host C";
        Previous: Text;
        Vis: Boolean;
        Opened: Boolean;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        Opened := TryOpenC(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part_found', Format(TryPartVisibleC(Host, Vis)) + '|' + Format(Vis));
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log_after_next', Log.Dump());
            Host.Close();
        end;
        ApplicationArea(Previous);
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '|');
        Observer.Expect('log', '[C-OnOpenPage(count=2) | host-OnAfterGetCurrRecord | C-Ping(rec=0,count=2) | host-after-Ping:C-pong | C-OnAfterGetRecord:1 | C-OnAfterGetRecord:2 | C-OnAfterGetRecord:1]');
        Observer.Expect('part_found', 'Yes|Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log_after_next', '[host-OnAfterGetCurrRecord | C-Ping(rec=1,count=2) | host-after-Ping:C-pong]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_ServiceAreaPart_AllAreasEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P142 Part Log";
        Host: TestPage "LT P142 Host A";
        Previous: Text;
        Opened: Boolean;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('');
        Opened := TryOpenA(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then
            Host.Close();
        ApplicationArea(Previous);
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '|');
        Observer.Expect('log', '[A-OnOpenPage(count=2) | host-OnAfterGetCurrRecord | A-Ping(rec=0,count=2) | host-after-Ping:A-pong | A-OnAfterGetRecord:1 | A-OnAfterGetRecord:2 | A-OnAfterGetRecord:1]');
        Observer.Verify();
    end;
}
