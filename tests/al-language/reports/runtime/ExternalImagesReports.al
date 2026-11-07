// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-enableexternalimages-property
// Scope: in-scope
// Fixtures used: none (two reports read by codeunit 75510 "LT Y Report Props Tests")
// Facts: two reports with the same dataset (a number, a text holding an external image URL, a decimal and a date); one sets
//   EnableExternalImages = true, the other does not set it. Writer P6924 (al-runtime-rs triage of issue 6924, row 2.18): does the
//   property change Report.SaveAs Xml?
// local object: the test checks a property of the report's own definition (EnableExternalImages).
// BC versions: 27-29

report 95270 "REP ExtImages On"
{
    UsageCategory = None;
    UseRequestPage = false;
    EnableExternalImages = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = filter(1 .. 2));
            column(NumCol; Number) { }
            column(ImageUrl; ImageUrl) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }

            trigger OnAfterGetRecord()
            begin
                ImageUrl := 'https://example.com/images/' + Format(Number) + '.png';
                Amt := Number * 1.5;
            end;
        }
    }

    trigger OnInitReport()
    begin
        DayVal := DMY2Date(31, 1, 2025);
    end;

    var
        ImageUrl: Text;
        Amt: Decimal;
        DayVal: Date;
}

report 95271 "REP ExtImages Off"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = filter(1 .. 2));
            column(NumCol; Number) { }
            column(ImageUrl; ImageUrl) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }

            trigger OnAfterGetRecord()
            begin
                ImageUrl := 'https://example.com/images/' + Format(Number) + '.png';
                Amt := Number * 1.5;
            end;
        }
    }

    trigger OnInitReport()
    begin
        DayVal := DMY2Date(31, 1, 2025);
    end;

    var
        ImageUrl: Text;
        Amt: Decimal;
        DayVal: Date;
}
