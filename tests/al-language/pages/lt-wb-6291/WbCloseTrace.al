// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

codeunit 90602 "LT WB Close Trace"
{
    SingleInstance = true;

    procedure Reset(AllowCloseValue: Boolean)
    begin
        Trace := '';
        AllowClose := AllowCloseValue;
    end;

    procedure Add(Source: Text; CloseAction: Action)
    begin
        if Trace <> '' then
            Trace += '|';
        Trace += Source + ':' + Format(CloseAction, 0, 9);
    end;

    procedure GetTrace(): Text
    begin
        exit(Trace);
    end;

    procedure IsCloseAllowed(): Boolean
    begin
        exit(AllowClose);
    end;

    var
        Trace: Text;
        AllowClose: Boolean;
}
