// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope
// Fixtures used: none; target codeunit of the scheduled tasks the PlT TaskScheduler probes create (never made ready, so it never runs)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74215 "LT PlT Task Target"
{
    trigger OnRun()
    begin
    end;
}

codeunit 74220 "LT PlT Task Failure"
{
    trigger OnRun()
    begin
    end;
}
