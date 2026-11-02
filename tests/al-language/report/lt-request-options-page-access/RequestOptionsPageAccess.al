// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-requestoptionspage-method
// Scope: in-scope (Cloud). A must-compile test: the fact is that this file compiles; the [Test] only makes the codeunit run.
// Fixtures used: none.
// Probe: compiled with AL 16.2 (BC 27 symbols), AL 17.0 (BC 28), AL 18.1 (BC 29) and AL 30 (BC 29); the same verdict on all four.
// CurrReport.RequestOptionsPage (and the bare RequestOptionsPage) is accessible in the code OF THE REQUEST PAGE: a control's OnValidate
// (al-runner issue 6631: CurrReport.RequestOptionsPage.Update(false)), OnLookup, OnAssistEdit and OnDrillDown, a request page action's
// OnAction, the request page triggers OnInit, OnOpenPage, OnAfterGetRecord, OnClosePage and OnQueryClosePage, and a procedure declared
// in the request page. Update() without argument and a read of Caption compile there too.
// Outside the request page (OnInitReport, OnPreReport, OnPostReport, OnPreDataItem, OnAfterGetRecord of a data item, a report
// procedure) CurrReport.RequestOptionsPage gives AL0161 'RequestOptionsPage' is inaccessible due to its protection level:
// must-not-compile cases 2514 (report procedure) and 2580 to 2584.
// BC versions: 27 - 29
report 93010 "LT ROP Access"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Int; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Direction; Direction)
                {
                    ApplicationArea = All;
                    Caption = 'Direction';

                    trigger OnValidate()
                    begin
                        CurrReport.RequestOptionsPage.Update(false);
                    end;
                }
                field(NoArg; Note)
                {
                    ApplicationArea = All;
                    Caption = 'Note';

                    trigger OnValidate()
                    begin
                        CurrReport.RequestOptionsPage.Update();
                        if CurrReport.RequestOptionsPage.Caption = '' then
                            Note := '';
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrReport.RequestOptionsPage.Update(false);
                    end;

                    trigger OnAssistEdit()
                    begin
                        CurrReport.RequestOptionsPage.Update(false);
                    end;
                }
                field(Bare; Count)
                {
                    ApplicationArea = All;
                    Caption = 'Count';

                    trigger OnValidate()
                    begin
                        RequestOptionsPage.Update(false);
                    end;

                    trigger OnDrillDown()
                    begin
                        CurrReport.RequestOptionsPage.Update(false);
                    end;
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(Refresh)
                {
                    ApplicationArea = All;
                    Caption = 'Refresh';

                    trigger OnAction()
                    begin
                        CurrReport.RequestOptionsPage.Update(false);
                    end;
                }
            }
        }

        trigger OnInit()
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;

        trigger OnOpenPage()
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;

        trigger OnAfterGetRecord()
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;

        trigger OnClosePage()
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;

        local procedure RefreshPage()
        begin
            CurrReport.RequestOptionsPage.Update(false);
        end;
    }

    var
        Direction: Option Export,Import;
        Note: Text[30];
        Count: Integer;
}

codeunit 93011 "LT ROP Access Compiles"
{
    Subtype = Test;

    [Test]
    procedure RequestOptionsPage_InRequestPageCode_Compiles()
    begin
    end;
}
