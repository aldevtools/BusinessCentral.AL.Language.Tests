// @expect AL0175 | Operator '<' cannot be applied to operands of type 'Joker' and 'Joker'
// @expect AL0175 | Operator '>' cannot be applied to operands of type 'Joker' and 'Joker'
// Ordering two FieldRef values (type Joker). '<>' and '=' between two FieldRef values compile:
// tests/al-language/recordref/lt-y49-blob-compare/Y49BlobCompare.al (writer Y49, gap cycle 5 G5-07).
codeunit 50000 "MNC Y49 FR Order"
{
    procedure Less(var RA: RecordRef; var RB: RecordRef): Boolean
    begin
        exit(RA.Field(1).Value < RB.Field(1).Value);
    end;

    procedure Greater(var RA: RecordRef; var RB: RecordRef): Boolean
    begin
        exit(RA.Field(1).Value > RB.Field(1).Value);
    end;
}
