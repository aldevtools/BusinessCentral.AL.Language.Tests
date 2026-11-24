// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// local object: observations and owned task IDs must survive installation and a new test session.
table 99467 "INST Task Observation"
{
    DataPerCompany = false;
    fields
    {
        field(1; Scope; Text[30]) { }
        field(2; Scenario; Code[20]) { }
        field(3; TaskId; Guid) { }
        field(4; TargetCompany; Text[30]) { }
        field(5; Existed; Boolean) { }
        field(6; Cancelled; Boolean) { }
        field(7; ExistsAtEnd; Boolean) { }
    }
    keys { key(PK; Scope, Scenario) { Clustered = true; } }
}
