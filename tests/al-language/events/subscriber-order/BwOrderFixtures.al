// Fixtures of the subscriber order probes (writer BW; al-runtime-rs ADR-046 amendment 1, probes Q1 to Q3; corpus #664 item 152).
// The five subscriber codeunits P..T (folders a-order, b-order, c-order) log each "Extension Triggers" install call of this app into
// "LT BW Install Log" (no company, AutoIncrement Id = run order), together with how many Company Triggers calls the subscriber of cross-app
// fixture A counted in the same session (Q3). Install code must never fail (check-install-triggers.py): every write is `if Insert() then;`
// into a DataPerCompany = false table.

table 83960 "LT BW Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Routine; Text[30]) { }
        field(3; Part; Text[30]) { }
        field(4; Company; Text[60]) { }
        field(5; "Session Id"; Integer) { }
        field(6; "XA Company Open Calls"; Integer) { }
        field(7; Context; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// An ordinary integration event of this app, with the same five subscribers (P..T).
codeunit 83965 "LT BW Order Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnBwLocalOrder(var Log: Text)
    begin
    end;

    procedure Raise(): Text
    var
        Log: Text;
    begin
        OnBwLocalOrder(Log);
        exit(Log);
    end;
}

codeunit 83966 "LT BW Install Writer"
{
    procedure WriteRow(Routine: Text; Part: Text)
    var
        Row: Record "LT BW Install Log";
        XaCount: Codeunit "LT BW XA Company Open Count";
    begin
        Row.Init();
        Row.Routine := CopyStr(Routine, 1, MaxStrLen(Row.Routine));
        Row.Part := CopyStr(Part, 1, MaxStrLen(Row.Part));
        Row.Company := CopyStr(CompanyName(), 1, MaxStrLen(Row.Company));
        Row."Session Id" := SessionId();
        Row."XA Company Open Calls" := XaCount.Calls();
        Row.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Row.Context));
        if Row.Insert() then;
    end;
}
