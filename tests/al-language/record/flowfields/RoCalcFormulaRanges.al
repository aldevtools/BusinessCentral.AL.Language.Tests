// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-calcformula-property
// Scope: in-scope
// Fixtures for the RO_* test in codeunit "W4 CalcFields Tests" (W4CalcFields.al): tables 88440 and 88441 (writer RO, al-runner issue 5745).
// Facts: a CalcFormula where() condition filter('...') whose quoted text holds ranges and unions: on a Code field
//   ('10|200..299|400..499', '200..299', '..199', '400..', '<>10&<>250', '>=400', 'A..C|X', '10 | 200..299'), the unquoted
//   form on the Code field, the same quoted text on a Text and an Integer field, and a count() with the quoted union.

table 88440 "LT RO CF Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cat; Code[20]) { }
        field(3; Txt; Text[20]) { }
        field(4; Num; Integer) { }
        field(5; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 88441 "LT RO CF Sum"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; QuotedUnion; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('10|200..299|400..499'))); Editable = false; }
        field(3; PlainUnion; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter(10 | 200 .. 299 | 400 .. 499))); Editable = false; }
        field(4; QuotedRange; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('200..299'))); Editable = false; }
        field(5; QuotedUpTo; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('..199'))); Editable = false; }
        field(6; QuotedFrom; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('400..'))); Editable = false; }
        field(7; QuotedNotAnd; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('<>10&<>250'))); Editable = false; }
        field(8; QuotedGe; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('>=400'))); Editable = false; }
        field(9; QuotedLetters; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('A..C|X'))); Editable = false; }
        field(10; QuotedSpaces; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Cat = filter('10 | 200..299'))); Editable = false; }
        field(11; TextUnion; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Txt = filter('10|200..299|400..499'))); Editable = false; }
        field(12; IntUnion; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT RO CF Entry".Amount where(Num = filter('10|200..299|400..499'))); Editable = false; }
        field(13; CountUnion; Integer) { FieldClass = FlowField; CalcFormula = count("LT RO CF Entry" where(Cat = filter('10|200..299|400..499'))); Editable = false; }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}
