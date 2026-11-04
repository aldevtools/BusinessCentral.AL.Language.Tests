// @expect AL0132 | '"MNC UB X"' does not contain a definition for 'OnlyA'
// In a TableNo codeunit X is the enum type: a member only the field's enum has does not exist.
// Positive companion: tests/al-language/types/lt-enum-type-before-rec-field/EnumTypeBeforeRecField.al (issue 6129).
enum 50000 "MNC UB Field Enum" { value(0; Zero) { } value(1; Both) { } value(10; OnlyA) { } }
enum 50001 "MNC UB X" { value(0; Zero) { } value(2; Both) { } value(20; OnlyX) { } }
table 50002 "MNC UB Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "MNC UB X"; Enum "MNC UB Field Enum") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 50003 "MNC UB Cu"
{
    TableNo = "MNC UB Rec";
    procedure P(): Integer
    begin
        exit("MNC UB X"::OnlyA.AsInteger());
    end;
}
