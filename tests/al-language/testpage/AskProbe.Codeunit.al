// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: ASK Line (60916), ASK Probe (60917)
//
// What an action's OnAction saw, recorded at the moment it ran.
//
// SingleInstance because the observation has to survive the page: the assertion happens in
// the test method after Close(), by which point the action's Rec is long gone. And the
// existence check deliberately uses its OWN Record variable rather than the action's Rec —
// a buffer that has never been written still answers with the values a test just set, so
// only an independent lookup can tell "the row exists" from "the page remembers it".

codeunit 60917 "ASK Probe"
{
    SingleInstance = true;

    var
        Ran: Boolean;
        RowExisted: Boolean;
        LineNoSeen: Integer;
        DescrSeen: Text[50];

    procedure Reset()
    begin
        Ran := false;
        RowExisted := false;
        LineNoSeen := 0;
        DescrSeen := '';
    end;

    procedure Observe(HeaderNo: Code[20]; CurrentLineNo: Integer; CurrentDescr: Text[50])
    var
        Line: Record "ASK Line";
    begin
        Ran := true;
        LineNoSeen := CurrentLineNo;
        DescrSeen := CurrentDescr;
        Line.SetRange("No.", HeaderNo);
        Line.SetRange("Line No.", CurrentLineNo);
        RowExisted := not Line.IsEmpty();
    end;

    procedure GetRan(): Boolean
    begin
        exit(Ran);
    end;

    procedure GetRowExisted(): Boolean
    begin
        exit(RowExisted);
    end;

    procedure GetLineNoSeen(): Integer
    begin
        exit(LineNoSeen);
    end;

    procedure GetDescrSeen(): Text[50]
    begin
        exit(DescrSeen);
    end;
}
