// The member "" of an Option table field has no name to write after Rec.Opt::"" (not defined).
// @expect AL0132 | 'Opt' does not contain a definition for ''
table 53310 "MNC OB T11"
{
    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,""; }
    }
    keys { key(PK; PK) { Clustered = true; } }
}
codeunit 53311 "MNC OB C12"
{
    procedure P()
    var
        R: Record "MNC OB T11";
    begin
        R.Opt := R.Opt::"";
    end;
}
