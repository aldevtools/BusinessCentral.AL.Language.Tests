// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 70403, SingleInstance log 70405 (used only by test codeunit 70413), pages 70403-70407
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a part with Visible = Flag (false at open) and a host OnAfterGetCurrRecord calling CurrPage.Part.Page.Ping(): is the part's code (the call, OnOpenPage, OnAfterGetRecord) run

table 70403 "LT P99 Host Row"
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

codeunit 70405 "LT P99 Part Log"
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

page 70403 "LT P99 Part"
{
    PageType = ListPart;
    SourceTable = "LT P99 Host Row";
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

    procedure Ping()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('part-Ping');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('part-OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('part-OnAfterGetRecord:' + Format(Rec.Id));
    end;
}

page 70404 "LT P99 Host FlagFalse"
{
    PageType = Card;
    SourceTable = "LT P99 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P99 Part")
            {
                ApplicationArea = All;
                Visible = Flag;
            }
        }
    }

    var
        Flag: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping');
    end;
}

page 70405 "LT P99 Host FlagOpen"
{
    PageType = Card;
    SourceTable = "LT P99 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P99 Part")
            {
                ApplicationArea = All;
                Visible = Flag;
            }
        }
    }

    var
        Flag: Boolean;

    trigger OnOpenPage()
    begin
        Flag := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping');
    end;
}

page 70406 "LT P99 Host Static"
{
    PageType = Card;
    SourceTable = "LT P99 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P99 Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping');
    end;
}

page 70407 "LT P99 Host FlagLate"
{
    PageType = Card;
    SourceTable = "LT P99 Host Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT P99 Part")
            {
                ApplicationArea = All;
                Visible = Flag;
            }
        }
    }

    var
        Flag: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P99 Part Log";
    begin
        Log.Add('host-OnAfterGetCurrRecord');
        Flag := true;
        CurrPage.PartCtl.Page.Ping();
        Log.Add('host-after-Ping');
    end;
}

codeunit 70413 "LT P99 InvisiblePart"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P99 Host Row";
        Log: Codeunit "LT P99 Part Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenFalse(var Host: TestPage "LT P99 Host FlagFalse")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenOpen(var Host: TestPage "LT P99 Host FlagOpen")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenStatic(var Host: TestPage "LT P99 Host Static")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenLate(var Host: TestPage "LT P99 Host FlagLate")
    begin
        Host.OpenEdit();
    end;

    [Test]
    procedure P99_FlagFalseAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Part Log";
        Host: TestPage "LT P99 Host FlagFalse";
    begin
        Seed();
        Observer.Observe('opened', Format(TryOpenFalse(Host)));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part-visible', Format(Host.PartCtl.Visible()));
        Log.Reset();
        Observer.Observe('next', Format(Host.Next()));
        Observer.Observe('log-after-next', Log.Dump());
        Host.Close();
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '[part-OnOpenPage | host-OnAfterGetCurrRecord | part-Ping | host-after-Ping | part-OnAfterGetRecord:1 | part-OnAfterGetRecord:2 | part-OnAfterGetRecord:1]');
        Observer.Expect('part-visible', 'No');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log-after-next', '[host-OnAfterGetCurrRecord | part-Ping | host-after-Ping]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_FlagTrueInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Part Log";
        Host: TestPage "LT P99 Host FlagOpen";
    begin
        Seed();
        Observer.Observe('opened', Format(TryOpenOpen(Host)));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part-visible', Format(Host.PartCtl.Visible()));
        Host.Close();
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '[part-OnOpenPage | host-OnAfterGetCurrRecord | part-Ping | host-after-Ping | part-OnAfterGetRecord:1 | part-OnAfterGetRecord:2 | part-OnAfterGetRecord:1]');
        Observer.Expect('part-visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P99_StaticInvisible()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Part Log";
        Host: TestPage "LT P99 Host Static";
    begin
        Seed();
        Observer.Observe('opened', Format(TryOpenStatic(Host)));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        asserterror Observer.Observe('part-visible', Format(Host.PartCtl.Visible()));
        Observer.ObserveError('af317');
        Host.Close();
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '[host-OnAfterGetCurrRecord | part-Ping | host-after-Ping]');
        Observer.Expect('af317|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('af317|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P99_FlagTrueInOnAfterGetCurrRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P99 Part Log";
        Host: TestPage "LT P99 Host FlagLate";
    begin
        Seed();
        Observer.Observe('opened', Format(TryOpenLate(Host)));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part-visible', Format(Host.PartCtl.Visible()));
        Host.Close();
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '[part-OnOpenPage | host-OnAfterGetCurrRecord | part-Ping | host-after-Ping | part-OnAfterGetRecord:1 | part-OnAfterGetRecord:2 | part-OnAfterGetRecord:1]');
        Observer.Expect('part-visible', 'Yes');
        Observer.Verify();
    end;
}
