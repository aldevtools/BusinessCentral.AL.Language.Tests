// Two Option members named "" (quoted empty) in an Option table field are refused.
// @expect AL0152 | The value '' is used more than once
table 53302 "MNC OB T3"
{
    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = "",A,""; }
    }
    keys { key(PK; PK) { Clustered = true; } }
}
