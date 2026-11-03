// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
// Fixtures used: Install StartSession Marker (60447)
//
// The worker "Install StartSession Probe" (60445) asks StartSession to run. Its only effect is
// the marker row, so the absence of that row is what shows the worker never ran.

codeunit 60448 "Install StartSession Worker"
{
    trigger OnRun()
    var
        Marker: Record "Install StartSession Marker";
    begin
        if Marker.Get('RAN') then
            exit;
        Marker.Init();
        Marker."Code" := 'RAN';
        Marker."Value" := 42;
        Marker.Insert();
    end;
}
