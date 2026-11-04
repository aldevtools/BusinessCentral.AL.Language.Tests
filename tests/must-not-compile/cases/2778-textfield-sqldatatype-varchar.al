// @expect AL0843 | The property 'SQLDataType' can only be used if the field's type is 'Code'.
// SQLDataType Varchar on a Text field.
table 59990 "MNC Y82 T" { fields { field(1; Id; Integer) { } field(2; T; Text[10]) { SQLDataType = Varchar; } } keys { key(PK; Id) { Clustered = true; } } }
