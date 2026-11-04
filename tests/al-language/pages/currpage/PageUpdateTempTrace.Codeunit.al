// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The trigger recorder for "ALT Page Update Temp New Test" alone. SingleInstance so the page
// can write to it and the test read it back within one test. Not shared with any other suite's
// recorder: a SingleInstance codeunit keeps its state between test codeunits, so a shared one
// would make each suite's result depend on execution order.

codeunit 60871 "ALT Page Update Temp Trace"
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

    procedure CountOf(Tag: Text): Integer
    var
        Found: Integer;
        Remaining: Text;
        Position: Integer;
    begin
        Remaining := Order;
        Position := StrPos(Remaining, Tag + ';');
        while Position > 0 do begin
            Found += 1;
            Remaining := CopyStr(Remaining, Position + StrLen(Tag) + 1);
            Position := StrPos(Remaining, Tag + ';');
        end;
        exit(Found);
    end;
}
