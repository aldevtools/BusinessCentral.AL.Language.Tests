// @expect AL0193 | Argument 2: cannot convert from 'Date' to the type of Argument 1 'DateTime'
// @expect AL0193 | Argument 2: cannot convert from 'Date' to the type of Argument 1 'DateTime'
// @expect AL0193 | Argument 3: cannot convert from 'Date' to the type of Argument 1 'DateTime'
// @expect AL0193 | Argument 2: cannot convert from 'Text' to the type of Argument 1 'DateFormula'
// @expect AL0193 | Argument 3: cannot convert from 'Text' to the type of Argument 1 'DateFormula'
// A Date is not accepted as the value of a DateTime field in Validate, SetRange or SetFilter's argument, and a Text is not accepted as the value of a
// DateFormula field in SetRange or SetFilter's argument (the empty-text filter on such a field is written inside the filter text:
// tests/al-language/misc/lt-y70-assumptions/Y70Probes.al FilterDateFormula_EmptyText). A Variant holding a Date converts at run time
// (Y70Probes.al DateToDateTime_Paths); issue 649 item 16 is must-not-compile case 1193.
table 52681 "MNC Y70 Row"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; DF; DateFormula) { }
        field(3; Stamp; DateTime) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 52681 "MNC Y70 Date Args"
{
    procedure Probe()
    var
        Row: Record "MNC Y70 Row";
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        Row.Validate(Stamp, D);
        Row.SetRange(Stamp, D);
        Row.SetFilter(Stamp, '%1', D);
        Row.SetRange(DF, '');
        Row.SetFilter(DF, '<>%1', '');
    end;
}
