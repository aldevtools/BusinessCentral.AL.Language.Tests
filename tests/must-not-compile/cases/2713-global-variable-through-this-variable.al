// @expect AL0161 | 'Tag' is inaccessible due to its protection level
// A global variable of a codeunit is not reachable through a Codeunit variable named "this".
codeunit 50000 "MNC This Global"
{
    var
        "this": Codeunit "MNC This Global";
        Tag: Integer;

    procedure P()
    begin
        "this".Tag := 1;
    end;
}
