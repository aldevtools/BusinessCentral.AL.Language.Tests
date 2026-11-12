// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51726 "Linked Part Detail"
{
    PageType = CardPart;
    SourceTable = "Linked Part Detail Row";
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code)
                {
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        Detail: Record "Linked Part Detail Row";
                        FilterGroup: Integer;
                        DetailCode: Text;
                    begin
                        FilterGroup := Rec.FilterGroup();
                        Rec.FilterGroup(4);
                        DetailCode := Rec.GetFilter(Code);
                        Rec.FilterGroup(FilterGroup);

                        Detail.Code := CopyStr(DetailCode, 1, MaxStrLen(Detail.Code));
                        Detail."Before Assist" := Rec.Code;
                        Detail.Marker := 1;
                        Detail.Insert(true);
                        Rec := Detail;
                    end;
                }
                field(Marker; Rec.Marker)
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.Marker += 1;
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
}
