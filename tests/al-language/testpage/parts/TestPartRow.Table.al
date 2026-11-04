// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
//
// Backing table for the TestPart surface suite (codeunit 60341).
//
// The primary key is DELIBERATELY COMPOSITE (two fields). TestPart.GoToKey() takes a
// variadic list of key values and the platform raises
// NavTestInvalidNumberOfKeyFieldValuesException when the count does not match the number of
// primary key fields -- a negative case that a single-field key CANNOT express, because
// GoToKey('X') would then be correct. Every other part fixture in this repository keys on
// one field, which is why this suite needs its own table rather than reusing one.

table 60341 "ALT TestPart Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
        // Validated field: any value starting with 'BAD' is refused. This is what gives the
        // part a REAL validation error to count, rather than relying on a type-conversion
        // failure whose message is a platform localization detail.
        field(4; Grade; Text[20])
        {
            trigger OnValidate()
            begin
                if CopyStr(Grade, 1, 3) = 'BAD' then
                    Error(GradeRefusedErr, Grade);
            end;
        }
    }

    keys
    {
        key(PK; Grp, "Line No.") { Clustered = true; }
    }

    var
        GradeRefusedErr: Label 'ALT TestPart refuses the grade %1.', Comment = '%1 = the refused grade value';
}
