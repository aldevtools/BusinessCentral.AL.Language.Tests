// @expect AL0193 | Argument 3: cannot convert from 'Guid' to the type of Argument 1 'Media'
// SetFilter on a Media field with a Guid as the %1 argument (a Media value as the argument compiles).
// Writer SO (2026-10-28), aldevtools/BusinessCentral.AL.Runner#5991.
table 50000 "MNC SO Media Row"
{
    fields { field(1; Id; Integer) { } field(2; Pic; Media) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC SO Caller"
{
    procedure Probe()
    var
        Row: Record "MNC SO Media Row";
        Other: Record "MNC SO Media Row";
        Id: Guid;
    begin
        Row.SetFilter(Pic, '<>%1', Id);
    end;
}
