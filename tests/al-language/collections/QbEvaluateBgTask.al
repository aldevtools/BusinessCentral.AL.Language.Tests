// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); page LT CN BgTask Card (84898, session/lt-cn-session-leads/CnIsolatedStorageLeads.al);
//   own codeunits 86394 - 86399
// Probe: writer QB, corpus issue #626 items 11, 12 and 15 (the Evaluate part): Evaluate into HttpRequestType, PageStyle and
//   PageBackgroundTaskErrorLevel, by member name, by number and for an invalid name and ordinal. Called in the test session, Evaluate
//   ends the test session on the Linux containers (ACHttpRequestType.al, ACPageStyle.al, types/lt-page-style/PageStyle.al), so here it
//   runs in the worker of a page background task (TestPage.RunPageBackgroundTask), which is a session of its own.
// BC versions: 27, 28, 29

// LINUX SUSPECT (BC 29.0, corpus CI run 39418527129): each worker fails before it runs with "Unexpected CLR exception thrown.:
//   System.InvalidOperationException: C# compilation has failed for the application object CodeUnit_86394" (86395, 86399 the same), an
//   error no TryFunction catches. So Evaluate into these three types does not compile on the service tier (the AL compiler accepts it).
//   Not asserted until a Windows container shows what BC does: the file compiles only with the symbol LTQB_EVALUATE_PROBE, which no CI leg
//   defines (windows-queue.md, row QB 626.11/12/15).
#if LTQB_EVALUATE_PROBE
codeunit 86394 "LT QB Eval Worker Http"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Input: Text;
        V: HttpRequestType;
        Ok: Boolean;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Input', Input);
        Ok := Evaluate(V, Input);
        Results.Add('Ret', Format(Ok, 0, 9));
        Results.Add('Value', Format(V));
        Results.Add('Ordinal', Format(V, 0, 2));
        if not Ok then
            Results.Add('LastError', GetLastErrorText());
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 86395 "LT QB Eval Worker Style"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Input: Text;
        V: PageStyle;
        Ok: Boolean;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Input', Input);
        Ok := Evaluate(V, Input);
        Results.Add('Ret', Format(Ok, 0, 9));
        Results.Add('Value', Format(V));
        Results.Add('Ordinal', Format(V, 0, 2));
        if not Ok then
            Results.Add('LastError', GetLastErrorText());
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 86399 "LT QB Eval Worker Level"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Input: Text;
        V: PageBackgroundTaskErrorLevel;
        Ok: Boolean;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Input', Input);
        Ok := Evaluate(V, Input);
        Results.Add('Ret', Format(Ok, 0, 9));
        Results.Add('Value', Format(V));
        Results.Add('Ordinal', Format(V, 0, 2));
        if not Ok then
            Results.Add('LastError', GetLastErrorText());
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 86396 "LT QB Eval HttpRequestType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_HttpRequestType_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Get,Post,Put,Patch,Delete,get,0,4,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run(Codeunit::"LT QB Eval Worker Http", Input));
        Observer.Finish();
    end;

    local procedure Run(WorkerId: Integer; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results, WorkerId) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text]; WorkerId: Integer)
    begin
        Results := Card.RunPageBackgroundTask(WorkerId, Params, false);
    end;
}

codeunit 86397 "LT QB Eval PageStyle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_PageStyle_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate,strong,0,9,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run(Codeunit::"LT QB Eval Worker Style", Input));
        Observer.Finish();
    end;

    local procedure Run(WorkerId: Integer; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results, WorkerId) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text]; WorkerId: Integer)
    begin
        Results := Card.RunPageBackgroundTask(WorkerId, Params, false);
    end;
}

codeunit 86398 "LT QB Eval PbtErrorLevel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QB_Evaluate_PageBackgroundTaskErrorLevel_InBgTask()
    var
        Observer: Codeunit "Probe Observer";
        Input: Text;
    begin
        foreach Input in 'Ignore,Warning,Error,warning,0,2,Foo,99, '.Split(',') do
            Observer.Observe(Input, Run(Codeunit::"LT QB Eval Worker Level", Input));
        Observer.Finish();
    end;

    local procedure Run(WorkerId: Integer; Input: Text): Text
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
        Result: Text;
    begin
        Params.Add('Input', Input);
        Card.OpenView();
        ClearLastError();
        if TryRun(Card, Params, Results, WorkerId) then begin
            foreach K in Results.Keys() do
                Result += K + '=' + Results.Get(K) + ';';
        end else
            Result := 'error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        Card.Close();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRun(var Card: TestPage "LT CN BgTask Card"; Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text]; WorkerId: Integer)
    begin
        Results := Card.RunPageBackgroundTask(WorkerId, Params, false);
    end;
}
#endif
