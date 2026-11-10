// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A compound assignment to ApplicationArea: `ApplicationArea += 'x'` is refused; `ApplicationArea := 'x'` compiles (tests/al-language/pages/application-area/ApplicationAreaAssignForm.al). (al-runner 7597)
codeunit 50000 "MNC C2398"
{
    procedure Run1()
    begin
        ApplicationArea += 'x';
    end;
}
