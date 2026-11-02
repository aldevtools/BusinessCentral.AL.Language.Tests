// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): RecordId < RecordId (= compiles).
// @expect AL0175 | Operator '<' cannot be applied to operands of type 'RecordId' and 'RecordId'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        R: RecordId;
        R2: RecordId;
    begin
        if R < R2 then;
    end;
}
