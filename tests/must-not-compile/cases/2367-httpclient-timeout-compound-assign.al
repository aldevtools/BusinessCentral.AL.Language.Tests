// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A compound assignment to a method-like member is refused; the plain form C.Timeout := 5000 compiles. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2367"
{
    procedure Run1()
    var
        C: HttpClient;
    begin
        C.Timeout += 1;
    end;
}
