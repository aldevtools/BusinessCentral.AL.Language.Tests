// @expect AL0843 | The property 'SQLDataType' can only be used if the field's type is 'Code'.
// SQLDataType Variant on an Option field.
table 59990 "MNC Y82 T" { fields { field(1; Id; Integer) { } field(2; O; Option) { OptionMembers = A,B; SQLDataType = Variant; } } keys { key(PK; Id) { Clustered = true; } } }
