// @expect AL0427 | Field "Opt As Enum" cannot be converted to type Option.
// A lookup FlowField of type Enum over an Option field does not compile (writer Y20, al-runner issue 6481). The other direction, an Option
// lookup FlowField over an Enum field, compiles and gives the ordinal: tests/al-language/record/lt-flowfield-lookup-enum/Y20FlowFieldLookupEnumIntoOption.al.
enum 52350 "MNC Y20 E2350"
{
    Extensible = false;
    value(0; Zero) { }
    value(1; One) { }
}
table 52351 "MNC Y20 Src2350"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Zero,One; }
    }
}
table 52350 "MNC Y20 T2350"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Opt As Enum"; Enum "MNC Y20 E2350")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("MNC Y20 Src2350".Opt where(Id = field(Id)));
        }
    }
}
