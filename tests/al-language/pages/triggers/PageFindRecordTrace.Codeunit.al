// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
//
// A SingleInstance recorder for the page triggers under test. The suite's row assertions say
// WHICH rows the client saw; this says WHETHER the page's own OnFindRecord/OnNextRecord
// produced them. Both halves are needed: rows alone cannot distinguish a client that asked
// the page from one that happened to read the same rows off the table, and a call count alone
// cannot say the answer was used.
//
// SingleInstance is what lets the page write and the test read within one test without the
// two sharing a record.

codeunit 60672 "ALT Page Find Rec Trace"
{
    SingleInstance = true;

    var
        FindCalls: Integer;
        NextCalls: Integer;
        UnexpectedSteps: Text;

    procedure Reset()
    begin
        FindCalls := 0;
        NextCalls := 0;
        UnexpectedSteps := '';
    end;

    procedure NoteFind()
    begin
        FindCalls += 1;
    end;

    // Every Steps value BC was observed to pass is 1 or -1 (BC 28.4). A value outside that is
    // recorded rather than asserted on here, so a version that pages in larger jumps shows up
    // as a readable string in the one test that reports it instead of as an opaque failure.
    procedure NoteNext(Steps: Integer)
    begin
        NextCalls += 1;
        if (Steps <> 1) and (Steps <> -1) then
            UnexpectedSteps += Format(Steps) + ';';
    end;

    procedure GetFindCalls(): Integer
    begin
        exit(FindCalls);
    end;

    procedure GetNextCalls(): Integer
    begin
        exit(NextCalls);
    end;

    procedure GetUnexpectedSteps(): Text
    begin
        exit(UnexpectedSteps);
    end;
}
