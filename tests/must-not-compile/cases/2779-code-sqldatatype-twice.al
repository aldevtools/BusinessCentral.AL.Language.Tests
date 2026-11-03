// @expect AL0317 | A property with the same name has already been declared.
// SQLDataType set twice on a field.
table 59990 "MNC Y82 T" { fields { field(1; Id; Code[10]) { SQLDataType = Integer; SQLDataType = Varchar; } } keys { key(PK; Id) { Clustered = true; } } }
