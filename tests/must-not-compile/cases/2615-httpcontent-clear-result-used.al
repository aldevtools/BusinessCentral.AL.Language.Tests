// @expect AL0122 | Cannot implicitly convert type 'None' to 'Boolean'. Use an explicit conversion or change the type.
// HttpContent.Clear() returns nothing: its result cannot be assigned to a Boolean (gap cycle 6, spec G6-23 step GH4, writer Y62).
// The statement form runs: network/lt-y62-content-headers/Y62ContentHeaders.al GetHeaders_AfterContentClear_FreshRequest.
codeunit 50000 "MNC Content Clear Result"
{
    procedure Probe(): Boolean
    var
        Req: HttpRequestMessage;
        Result: Boolean;
    begin
        Result := Req.Content.Clear();
        exit(Result);
    end;
}
