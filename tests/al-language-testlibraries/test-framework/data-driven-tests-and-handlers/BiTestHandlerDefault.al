// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods#add-lifecycle-handlers-to-test-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI DD Source (81602) and LT BI DD Case Data (81601) from BiDataDriven.al; own objects 81624, 81644, 81645, 81690 - 81695, enumextensions 81652, 81654
// local object: the enum extension of DefaultTestHandler applies to every test codeunit of the app, so it needs its own objects
// Corpus issues (al-runner 7179, 7180, 7181, runtime 18): measured on the corpus CI BC tiers.
//   - [TestDataSource(Codeunit::"Name", 'set') and [TestDataSource(<id>, 'set')] in one test codeunit that has no [Test] procedure at all;
//   - an enum extension of DefaultTestHandler: which test codeunits it reaches, its order against TestHandlers, and the callbacks
//     around OnRun, plain tests and the cases of a data-driven procedure;
//   - whether a handler codeunit keeps its variables between callbacks, and what a handler can change that a test sees.
// Probe: observed values (Probe Observer Finish).
// BC versions: 29
#if BC29PLUS
codeunit 81690 "LT BI DH Log Only"
{
    SingleInstance = true;

    var
        Entries: Text;
        Marker: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    begin
        exit(Entries);
    end;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;
}

codeunit 81691 "LT BI DH Log Default Only"
{
    SingleInstance = true;

    var
        Entries: Text;
        Marker: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    begin
        exit(Entries);
    end;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;
}

codeunit 81692 "LT BI DH Log Combo"
{
    SingleInstance = true;

    var
        Entries: Text;
        Marker: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    begin
        exit(Entries);
    end;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;
}

codeunit 81693 "LT BI DH Default" implements ITestHandler
{
    var
        Counter: Integer;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('bCU', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('aCU', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('bP', Context, false);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('aP', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('bC', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('aC', Context, true);
    end;

    local procedure Handle(Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Common: Codeunit "LT BI DH Common";
        Entry: Text;
    begin
        Counter += 1;
        Entry := 'D.' + Callback + '(' + Context.ProcedureName() + '|' + Context.TestCaseName() + '|n=' + Format(Counter);
        if WithSuccess then
            Entry += '|' + Format(Context.Success());
        Common.Record(Context.CodeunitId(), Entry + ')', 'D', Callback, Context.ProcedureName());
    end;
}

enumextension 81652 "LT BI DH Default" extends DefaultTestHandler
{
    value(81652; "LT BI DH Default")
    {
        Implementation = ITestHandler = "LT BI DH Default";
    }
}

codeunit 81694 "LT BI DH Own" implements ITestHandler
{
    var
        Counter: Integer;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('bCU', Context, false);
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        Handle('aCU', Context, true);
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('bP', Context, false);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        Handle('aP', Context, true);
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('bC', Context, false);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        Handle('aC', Context, true);
    end;

    local procedure Handle(Callback: Text; Context: TestHandlerContext; WithSuccess: Boolean)
    var
        Common: Codeunit "LT BI DH Common";
        Entry: Text;
    begin
        Counter += 1;
        Entry := 'O.' + Callback + '(' + Context.ProcedureName() + '|' + Context.TestCaseName() + '|n=' + Format(Counter);
        if WithSuccess then
            Entry += '|' + Format(Context.Success());
        Common.Record(Context.CodeunitId(), Entry + ')', 'O', Callback, Context.ProcedureName());
    end;
}

enumextension 81654 "LT BI DH Own" extends TestHandler
{
    value(81654; "LT BI DH Own")
    {
        Implementation = ITestHandler = "LT BI DH Own";
    }
}

codeunit 81695 "LT BI DH Common"
{
    // Each test codeunit has its own SingleInstance log (no log is shared between test codeunits).
    procedure Record(CodeunitId: Integer; Entry: Text; Prefix: Text; Callback: Text; ProcName: Text)
    var
        LogOnly: Codeunit "LT BI DH Log Only";
        LogDefaultOnly: Codeunit "LT BI DH Log Default Only";
        LogCombo: Codeunit "LT BI DH Log Combo";
        Marker: Text;
    begin
        Marker := 'set by ' + Prefix + ' in ' + Callback + ' of ' + ProcName;
        case CodeunitId of
            81624:
                begin
                    LogOnly.Add(Entry);
                    if Callback = 'bP' then
                        LogOnly.SetMarker(Marker);
                end;
            81644:
                begin
                    LogDefaultOnly.Add(Entry);
                    if Callback = 'bP' then
                        LogDefaultOnly.SetMarker(Marker);
                end;
            81645:
                begin
                    LogCombo.Add(Entry);
                    if Callback = 'bP' then
                        LogCombo.SetMarker(Marker);
                end;
        end;
    end;
}

// Test codeunit with no [Test] procedure: both attribute forms (Codeunit::"Name" and the numeric id) in one codeunit.
// Data-driven procedures run in alphabetical order of the name: Rows1 then Rows2. The observation runs in the last case of Rows2.
codeunit 81624 "LT BI DD Only"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TestDataSource(Codeunit::"LT BI DD Source", 'Set1')]
    procedure Rows1(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI DH Log Only";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Log.Add('run1(' + CaseData.CaseText() + ')');
    end;

    [TestDataSource(81602, 'Set1')]
    procedure Rows2(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI DH Log Only";
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Log.Add('run2(' + CaseData.CaseText() + ')');
        if CaseData.CaseText() = 'gamma' then begin
            Observer.Observe('log', Log.Take());
            Observer.Observe('marker', Log.GetMarker());
            Observer.Finish();
        end;
    end;
}

// A test codeunit without TestHandlers: the default handler runs for it. OnRun logs too (order against bCU and bP).
codeunit 81644 "LT BI DH Default Only"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT BI DH Log Default Only";
    begin
        Log.Add('OnRun');
    end;

    [Test]
    procedure BiDh_A_Plain()
    var
        Log: Codeunit "LT BI DH Log Default Only";
    begin
        Log.Add('body A marker=' + Log.GetMarker());
    end;

    [Test]
    procedure BiDh_B_Plain()
    var
        Log: Codeunit "LT BI DH Log Default Only";
    begin
        Log.Add('body B marker=' + Log.GetMarker());
    end;

    [Test]
    procedure BiDh_Z_Observe()
    var
        Log: Codeunit "LT BI DH Log Default Only";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}

// Default handler and TestHandlers together, with a data-driven procedure; the observation runs in the last case of ZRows.
codeunit 81645 "LT BI DH Combo"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI DH Own";

    trigger OnRun()
    var
        Log: Codeunit "LT BI DH Log Combo";
    begin
        Log.Add('OnRun');
    end;

    [Test]
    procedure BiDh_A_Plain()
    var
        Log: Codeunit "LT BI DH Log Combo";
    begin
        Log.Add('body A marker=' + Log.GetMarker());
    end;

    [TestDataSource(81602, 'Set1')]
    procedure ZRows(Context: Interface ITestContext)
    var
        Log: Codeunit "LT BI DH Log Combo";
        Observer: Codeunit "Probe Observer";
        CaseData: Interface "LT BI DD Case Data";
    begin
        CaseData := Context as "LT BI DD Case Data";
        Log.Add('body ' + CaseData.CaseText() + ' marker=' + Log.GetMarker());
        if CaseData.CaseText() = 'gamma' then begin
            Observer.Observe('log', Log.Take());
            Observer.Finish();
        end;
    end;
}

#endif
