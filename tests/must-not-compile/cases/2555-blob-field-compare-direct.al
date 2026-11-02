// @expect AL0175 | Operator '<>' cannot be applied to operands of type 'Blob' and 'Blob'
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Blob' and 'Blob'
// Two Blob fields of Record variables compared directly. Through RecordRef.Field(..).Value the same comparison compiles and runs:
// tests/al-language/recordref/lt-y49-blob-compare/Y49BlobCompare.al (writer Y49, gap cycle 5 G5-07).
table 50000 "MNC Y49 Blob"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Bin; Blob) { }
    }
    keys { key(PK; Id) { } }
}

codeunit 50001 "MNC Y49 Blob Cmp"
{
    procedure Differs(var A: Record "MNC Y49 Blob"; var B: Record "MNC Y49 Blob"): Boolean
    begin
        exit(A.Bin <> B.Bin);
    end;

    procedure Same(var A: Record "MNC Y49 Blob"; var B: Record "MNC Y49 Blob"): Boolean
    begin
        exit(A.Bin = B.Bin);
    end;
}
