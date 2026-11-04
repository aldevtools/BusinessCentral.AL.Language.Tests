// Worker codeunit run by TestPageBgTask_Tests.al's page background tasks, both via
// CurrPage.EnqueueBackgroundTask (Test Page BgTask Card's OnAfterGetCurrRecord) and via
// TestPage.RunPageBackgroundTask. Reads its parameters through Page.GetBackgroundParameters()
// and reports back through Page.SetBackgroundTaskResult(), exactly as an AL author would.
//
// A "No." parameter starting with 'FAIL-' deliberately raises an AL error instead of
// returning a result, so the completion-error path (OnPageBackgroundTaskError) can be
// exercised as faithfully as the completion-success path.

codeunit 60791 "Test Page BgTask Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        RowNo: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('No', RowNo);
        if RowNo.StartsWith('FAIL-') then
            Error('Test Page BgTask Worker deliberately failed for %1', RowNo);
        Results.Add('Count', 'BG:' + RowNo);
        Page.SetBackgroundTaskResult(Results);
    end;
}
