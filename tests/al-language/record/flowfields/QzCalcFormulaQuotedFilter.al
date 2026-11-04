// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcformula-property
// Scope: in-scope
// Fixtures for the QZ_* test in codeunit "W4 CalcFields Tests" (W4CalcFields.al): tables 87689 and 87690.
// Facts: a CalcFormula where() condition filter('...') whose text holds a quoted literal next to filter operators: filter('<>'''''),
//   filter(''''''), filter(<> ''), and quoted literals with | and * inside (filter('''x|y'''), filter('''A*''')) next to the unquoted forms.

table 87689 "LT QZ CF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Hdr; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Hdr, LineNo) { Clustered = true; } }
}

table 87690 "LT QZ CF Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; QuotedNotEmpty; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('<>'''''))); Editable = false; }
        field(3; QuotedEmpty; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter(''''''))); Editable = false; }
        field(4; PlainNotEmpty; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter(<> ''))); Editable = false; }
        field(5; QuotedPipe; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('''x|y'''))); Editable = false; }
        field(6; PlainPipe; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('x|y'))); Editable = false; }
        field(7; QuotedStar; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('''A*'''))); Editable = false; }
        field(8; PlainStar; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('A*'))); Editable = false; }
        field(9; QuotedNotX; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ CF Line" where(Hdr = field(Code), Name = filter('<>''x'''))); Editable = false; }
    }

    keys { key(PK; Code) { Clustered = true; } }
}
