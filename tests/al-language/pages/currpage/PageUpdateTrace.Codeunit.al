// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// A SingleInstance trigger-order recorder. The suite's central claim is about WHEN a trigger
// fires relative to another trigger's return, and a counter cannot say that -- an ordered
// string can. SingleInstance is what lets the page write to it and the test read it back
// within one test, without the page and the test sharing a record.

codeunit 60492 "ALT Page Update Trace"
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
