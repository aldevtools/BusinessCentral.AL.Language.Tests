// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-onqueryclosepage-trigger
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6291 (reporter's repro, passed on real BC): a ModalPageHandler that raises an error on a Worksheet with a ListPart. The platform calls the ListPart OnQueryClosePage with Action::None, then the Worksheet with Action::LookupCancel, and RunModal raises the handler error. Objects for WbModalHandlerCloseTests.al; WbModalPart.al, WbModalRow.al and WbCloseTrace.al belong to it.

page 90604 "LT WB Modal Worksheet"
{
    PageType = Worksheet;

    layout
    {
        area(Content)
        {
            part(Lines; "LT WB Modal Part")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RaisePageError)
            {
                ApplicationArea = All;
                Caption = 'Raise Page Error';

                trigger OnAction()
                begin
                    Error('Page failure');
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CloseTrace: Codeunit "LT WB Close Trace";
    begin
        CloseTrace.Add('Page', CloseAction);
        exit(CloseTrace.IsCloseAllowed());
    end;
}
