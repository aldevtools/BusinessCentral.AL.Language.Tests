// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72892, page 72893, log codeunit 72894 (used by codeunit 72895 only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the OnInit/OnOpenPage log of Page.Run twice on one variable, of Clear then Run, of a method call before Run; Clear of a TestPage before opening, while open, and the reopen afterwards
// BC versions: 29 (27 and 28 by CI)

table 72892 "LT PgVar Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72894 "LT PgVar Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Reset()
    begin
        Log := '';
    end;

    procedure Add(S: Text)
    begin
        Log += S;
    end;

    procedure Get(): Text
    begin
        exit(Log);
    end;
}

page 72893 "LT PgVar Card"
{
    PageType = Card;
    SourceTable = "LT PgVar Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    var
        L: Codeunit "LT PgVar Log";
    begin
        L.Add('I');
    end;

    trigger OnOpenPage()
    var
        L: Codeunit "LT PgVar Log";
    begin
        L.Add('O');
    end;
}

codeunit 72895 "LT PgVar Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryClear(var TP: TestPage "LT PgVar Card")
    begin
        Clear(TP);
    end;

    [TryFunction]
    local procedure TryOpen(var TP: TestPage "LT PgVar Card")
    begin
        TP.OpenEdit();
    end;

    [TryFunction]
    local procedure TryClose(var TP: TestPage "LT PgVar Card")
    begin
        TP.Close();
    end;

    local procedure Seed()
    var
        Row: Record "LT PgVar Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [PageHandler]
    procedure PageH(var TP: TestPage "LT PgVar Card")
    begin
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure PageVar_RunTwiceOnOneVariable()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT PgVar Log";
        P: Page "LT PgVar Card";
        Row: Record "LT PgVar Row";
    begin
        Seed();
        L.Reset();
        Row.Get(1);
        P.SetRecord(Row);
        P.Run();
        Observer.Observe('afterFirstRun', L.Get());
        P.Run();
        Observer.Observe('afterSecondRun', L.Get());
        Clear(P);
        P.SetRecord(Row);
        P.Run();
        Observer.Observe('afterClearAndRun', L.Get());
        Observer.Expect('afterFirstRun', 'IO');
        Observer.Expect('afterSecondRun', 'IOIO');
        Observer.Expect('afterClearAndRun', 'IOIOIO');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure PageVar_MethodCallBeforeRun()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT PgVar Log";
        P: Page "LT PgVar Card";
        Row: Record "LT PgVar Row";
    begin
        Seed();
        L.Reset();
        Row.Get(1);
        P.SetRecord(Row);
        Observer.Observe('afterSetRecord', L.Get());
        P.Run();
        Observer.Observe('afterRun', L.Get());
        Clear(P);
        Observer.Observe('afterClear', L.Get());
        P.SetRecord(Row);
        Observer.Observe('afterClearSetRecord', L.Get());
        P.Run();
        Observer.Observe('afterSecondRun', L.Get());
        Observer.Expect('afterSetRecord', 'I');
        Observer.Expect('afterRun', 'IO');
        Observer.Expect('afterClear', 'IO');
        Observer.Expect('afterClearSetRecord', 'IOI');
        Observer.Expect('afterSecondRun', 'IOIO');
        Observer.Verify();
    end;

    [Test]
    procedure TestPageVar_ClearClosedOpenAndReopen()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT PgVar Log";
        TP: TestPage "LT PgVar Card";
    begin
        Seed();
        L.Reset();
        if TryClear(TP) then
            Observer.Observe('clearClosed', 'ok log=' + L.Get())
        else
            Observer.ObserveError('clearClosed');
        if TryOpen(TP) then
            Observer.Observe('openAfterClearClosed', 'ok log=' + L.Get() + ' id=' + TP.Id.Value())
        else
            Observer.ObserveError('openAfterClearClosed');
        if TryClear(TP) then
            Observer.Observe('clearOpen', 'ok log=' + L.Get())
        else
            Observer.ObserveError('clearOpen');
        if TryClose(TP) then
            Observer.Observe('closeAfterClearOpen', 'ok')
        else
            Observer.ObserveError('closeAfterClearOpen');
        if TryOpen(TP) then
            Observer.Observe('reopenAfterClearOpen', 'ok log=' + L.Get())
        else
            Observer.ObserveError('reopenAfterClearOpen');
        if TryClose(TP) then
            Observer.Observe('closeReopened', 'ok')
        else
            Observer.ObserveError('closeReopened');
        Observer.Expect('clearClosed', 'ok log=');
        Observer.Expect('openAfterClearClosed', 'ok log=IO id=1');
        Observer.Expect('clearOpen', 'ok log=IO');
        Observer.Expect('closeAfterClearOpen|text', 'The TestPage is not open.');
        Observer.Expect('closeAfterClearOpen|code', 'TestPageNotOpened');
        Observer.Expect('reopenAfterClearOpen', 'ok log=IOIO');
        Observer.Expect('closeReopened', 'ok');
        Observer.Verify();
    end;
}
