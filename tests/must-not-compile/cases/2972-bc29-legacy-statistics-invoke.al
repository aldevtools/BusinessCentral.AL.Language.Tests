// @from 29
// @expect AL0132 | 'TestPage Sales Invoice' does not contain a definition for 'Statistics'
// BC29 no longer exposes the legacy action. Verified with the official AL compiler and BC29 symbols.
codeunit 50171 "MNC Legacy Stats Invoke"
{
    procedure Probe()
    var
        View: TestPage "Sales Invoice";
    begin
        View.Statistics.Invoke();
    end;
}
