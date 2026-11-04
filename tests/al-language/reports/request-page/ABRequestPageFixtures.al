// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: none (this file holds them); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: fixtures for the request page trigger probes (issue 628 items 6 to 18): report 77070 has a request page with a source table and every
// record trigger of a page, reportextension 77072 adds the same triggers (except OnFindRecord and OnNextRecord, which an extension refuses: must-not-compile 0948,
// 0949); report 77071 has a plain request page that reportextension 77073 extends.

report 77070 "LT AB RP Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "LT AB Row")
        {
            column(Id; Id) { }

            trigger OnPreDataItem()
            begin
                Log.Add('report OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('report OnAfterGetRecord ' + Format(T.Id));
            end;
        }
    }

    requestpage
    {
        SourceTable = "LT AB Row";

        layout
        {
            area(Content)
            {
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }

            trigger OnOpenPage()
            begin
                Log.Add('base OnOpenPage ' + Format(Rec.Count));
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('base OnAfterGetRecord ' + Format(Rec.Id));
            end;

            trigger OnAfterGetCurrRecord()
            begin
                Log.Add('base OnAfterGetCurrRecord ' + Format(Rec.Id));
            end;

            trigger OnNewRecord(BelowxRec: Boolean)
            begin
                Log.Add('base OnNewRecord ' + Format(BelowxRec));
            end;

            trigger OnInsertRecord(BelowxRec: Boolean): Boolean
            begin
                Log.Add('base OnInsertRecord ' + Format(BelowxRec));
                exit(true);
            end;

            trigger OnModifyRecord(): Boolean
            begin
                Log.Add('base OnModifyRecord ' + Format(Rec.Name));
                exit(true);
            end;

            trigger OnDeleteRecord(): Boolean
            begin
                Log.Add('base OnDeleteRecord ' + Format(Rec.Name));
                exit(true);
            end;

            trigger OnQueryClosePage(CloseAction: Action): Boolean
            begin
                Log.Add('base OnQueryClosePage ' + Format(CloseAction));
                exit(not Flags.Veto());
            end;

            trigger OnClosePage()
            begin
                Log.Add('base OnClosePage ' + Format(Rec.Count));
            end;

            trigger OnFindRecord(Which: Text): Boolean
            begin
                Log.Add('base OnFindRecord ' + Format(Which));
                exit(true);
            end;

            trigger OnNextRecord(Steps: Integer): Integer
            begin
                Log.Add('base OnNextRecord ' + Format(Steps));
                exit(Steps);
            end;


        var
            Log: Codeunit "LT AB Log";
            Flags: Codeunit "LT AB Flags";
    }

    trigger OnPreReport()
    begin
        Log.Add('report OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('report OnPostReport');
    end;

    var
        Log: Codeunit "LT AB Log";
}

report 77071 "LT AB RP Plain Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "LT AB Row")
        {
            column(Id; Id) { }
        }
    }

    requestpage
    {
        SourceTable = "LT AB Row";

        layout
        {
            area(Content)
            {
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('plain OnPreReport');
    end;

    var
        Log: Codeunit "LT AB Log";
}
