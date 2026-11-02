// @expect AL0169 | The option value 'Decimal' is not valid. Check the enum definition for valid values.
// SQLDataType takes Varchar, Integer, BigInteger or Variant.
table 59990 "MNC Y82 T" { fields { field(1; Id; Code[10]) { SQLDataType = Decimal; } } keys { key(PK; Id) { Clustered = true; } } }
