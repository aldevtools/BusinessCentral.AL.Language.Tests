// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: tables of RptFixtures.al; the SingleInstance log 73840 of RptRequestPage.al (its tests are in codeunit 73850 only)
// Probe (writer RI, al-runtime-rs issue 5691): a request page handler whose SetValue raises (an OnValidate error, a value that cannot be
//   evaluated) and does not catch it: the error the caller of Report.Run gets, and which request page triggers run on the close. The tests
//   are in RptRequestPage.al (codeunit 73850, procedures RI_*). Not a test codeunit.
// BC versions: 27, 28, 29

report 88060 "LT RI Rp Refused"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ApplyCtl; ApplyVal)
                {
                    ApplicationArea = All;
                    Caption = 'Apply';

                    trigger OnValidate()
                    begin
                        L.Add('validate apply=' + Format(ApplyVal));
                        if ApplyVal then
                            Error('LT RI apply rejected');
                    end;
                }
                field(IntCtl; IntVal)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        L.Add('validate int=' + Format(IntVal));
                    end;
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction) + ' apply=' + Format(ApplyVal) + ' int=' + Format(IntVal));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage');
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('OnPreReport apply=' + Format(ApplyVal) + ' int=' + Format(IntVal));
    end;

    var
        ApplyVal: Boolean;
        IntVal: Integer;
        L: Codeunit "LT RpT Request Log";
}
