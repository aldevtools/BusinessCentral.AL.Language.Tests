// @expect AL0126 | No overload for method 'DMY2Date' takes 4 arguments.
// DMY2Date takes at most three arguments.
codeunit 50000 "MNC DMY2Date Four Args"
{
    procedure P()
    var
        D: Date;
    begin
        D := DMY2Date(1, 1, 2024, 1);
    end;
}
