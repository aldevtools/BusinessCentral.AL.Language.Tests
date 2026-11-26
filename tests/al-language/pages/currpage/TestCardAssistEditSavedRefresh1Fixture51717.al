// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51717 "Next Refresh Card"
{
    PageType = Card;
    SourceTable = "Next Refresh Header";
    SourceTableView = where(Active = const(true));
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Reference; Rec.Reference)
                {
                    trigger OnAssistEdit()
                    var
                        Sync: Codeunit "Next Refresh Sync";
                    begin
                        Sync.RunSync(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field(Refresh; Rec.Result) { }
                field(ObservedResult; ObservedResult) { }
            }
            part(Lines; "Next Refresh Lines")
            {
                SubPageLink = "Header Id" = field(Id);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Trace: Codeunit "Next Refresh Trace";
    begin
        Trace.RecordRead();
        ObservedResult := Rec.Result;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        Error('Refreshing the current row must not navigate with OnNextRecord');
    end;

    var
        ObservedResult: Text[40];
}
