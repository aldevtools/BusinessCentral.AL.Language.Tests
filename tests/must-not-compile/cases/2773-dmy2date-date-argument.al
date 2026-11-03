// @expect AL0133 | Argument 3: cannot convert from 'Date' to 'Integer'
// DMY2Date takes numeric arguments: a Date variable for the year does not convert.
codeunit 50000 "MNC DMY2Date Date Arg"
{
    procedure P()
    var
        D: Date;
        Y: Date;
    begin
        D := DMY2Date(1, 1, Y);
    end;
}
