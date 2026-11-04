// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The trigger recorder for "ALT Page Update Gone Test" (67300) alone. SingleInstance so the page
// can write to it and the test read it back within one test. Not shared with any other suite's
// recorder: a SingleInstance codeunit keeps its state between test codeunits, so a shared one
// would make each suite's result depend on execution order.

codeunit 67301 "ALT Page Update Gone Trace"
{
    SingleInstance = true;

    var
        Order: Text;

    procedure Reset()
    begin
        Order := '';
    end;

    procedure Note(Tag: Text)
    begin
        Order += Tag + ';';
    end;

    procedure Get(): Text
    begin
        exit(Order);
    end;

    // What was recorded after the action's own 'ActionEnd' marker: the refresh, and nothing
    // the client raised before the action ran.
    procedure AfterActionEnd(): Text
    var
        Position: Integer;
    begin
        Position := StrPos(Order, 'ActionEnd;');
        if Position = 0 then
            exit('<no ActionEnd>');
        exit(CopyStr(Order, Position + StrLen('ActionEnd;')));
    end;
}
