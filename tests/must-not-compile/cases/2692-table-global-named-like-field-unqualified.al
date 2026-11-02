// @expect AL0275 | 'Gateway' is an ambiguous reference between 'Gateway' defined by the extension 'Must Not Compile by AL Language (1.0.0.0)' and 'Gateway' defined by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A table global variable with the name of one of the table's own fields compiles, and so do the unqualified name and Rec.Gateway, but this.Gateway is ambiguous (AL0275).
// The accepted forms: tests/al-language/types/lt-y71-value-conversions/Y71ValueConversions.al (TableProcedure_FieldNamedLikeGlobal).
table 52692 "MNC Y71 Gate Tbl"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Gateway; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Gateway: Text[30];

    procedure Probe(): Text
    begin
        exit(this.Gateway);
    end;
}
