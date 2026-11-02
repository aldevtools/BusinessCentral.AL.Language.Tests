// @expect AL0293 | Property value 0 is not in the field's OptionMembers.
// An Option field's InitValue that is a number: `InitValue = 0` is refused (the number names no member), while `InitValue = 1` and `InitValue = 2`
// compile and start the field at the member of that ordinal (runs: tests/al-language/misc/lt-y70-assumptions/Y70Probes.al OptionInitValue_Ordinal).
table 52680 "MNC Y70 Option Zero"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Day; Option)
        {
            OptionMembers = Sunday,Monday,Tuesday;
            InitValue = 0;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
