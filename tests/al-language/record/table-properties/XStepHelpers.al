// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope (probe of issue 611)
// Fixtures used: objects in XTableObjects.al
// Probe (issue 611): helper codeunits that run one database step inside Codeunit.Run, so a probe can observe the error text of a step
// that may or may not fail (a TryFunction cannot contain Insert or Modify). Object id 75041 (75040 is unused).
codeunit 75041 "LT X Linked Step"
{
    TableNo = "LT X Props Linked";

    var
        Step: Integer;

    procedure SetStep(NewStep: Integer)
    begin
        Step := NewStep;
    end;

    trigger OnRun()
    begin
        case Step of
            1:
                Rec.Insert();
            2:
                if Rec.Count() < 0 then
                    Error('unreachable');
        end;
    end;
}
