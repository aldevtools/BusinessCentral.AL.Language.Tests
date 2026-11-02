// @expect AL0126 | No overload for method 'ReadFrom' takes 0 arguments. Candidates: built-in method 'ReadFrom(Text)', built-in method 'ReadFrom(InStream)'
// JsonObject.ReadFrom has two one-argument overloads (Text, InStream): the assignment form is checked as a call without arguments. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2368"
{
    procedure Run1()
    var
        J: JsonObject;
    begin
        J.ReadFrom := '{}';
    end;
}
