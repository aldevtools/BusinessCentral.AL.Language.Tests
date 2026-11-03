// @expect AL0132 | 'Codeunit "MNC This Record"' does not contain a definition for 'Init'
// this is the codeunit, not the Record variable "this": this.Init() does not compile.
codeunit 50000 "MNC This Record"
{
    var
        "this": Record Customer;

    procedure P()
    begin
        this.Init();
    end;
}
