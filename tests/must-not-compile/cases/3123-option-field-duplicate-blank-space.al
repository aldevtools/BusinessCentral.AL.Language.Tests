// Two Option members named " " (one space) in an Option table field are refused.
// @expect AL0152 | The value ' ' is used more than once
table 53303 "MNC OB T4"
{
    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",A," "; }
    }
    keys { key(PK; PK) { Clustered = true; } }
}
