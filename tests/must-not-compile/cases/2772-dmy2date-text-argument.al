// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// DMY2Date takes numeric arguments: a Text variable for the day does not convert.
codeunit 50000 "MNC DMY2Date Text Arg"
{
    procedure P()
    var
        D: Date;
        T: Text;
    begin
        T := '1';
        D := DMY2Date(T, 1, 2024);
    end;
}
