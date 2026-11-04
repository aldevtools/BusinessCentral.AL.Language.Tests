// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
//
// What a StartSession worker's OnRun observed, written from inside the worker's own
// (separate, background) session so the test's polling loop can read it from the caller's
// session once the worker has run.
table 60394 "SS Worker Result"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Marker"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Seen Value"; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Marker")
        {
            Clustered = true;
        }
    }
}
