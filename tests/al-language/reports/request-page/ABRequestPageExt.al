// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: reports 77070 and 77071 (ABRequestPageFixtures.al); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), codeunit "LT AB Log" (77050)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: the triggers of a request page extension next to the triggers of the base request page: order, arguments and return values; an extension on a
// request page that has no triggers of its own.

reportextension 77072 "LT AB RP Report Ext" extends "LT AB RP Report"
{
    requestpage
    {
            trigger OnOpenPage()
            begin
                Log.Add('ext OnOpenPage ' + Format(0));
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('ext OnAfterGetRecord ' + Format(0));
            end;

            trigger OnAfterGetCurrRecord()
            begin
                Log.Add('ext OnAfterGetCurrRecord ' + Format(0));
            end;

            trigger OnNewRecord(BelowxRec: Boolean)
            begin
                Log.Add('ext OnNewRecord ' + Format(BelowxRec));
            end;

            trigger OnInsertRecord(BelowxRec: Boolean): Boolean
            begin
                Log.Add('ext OnInsertRecord ' + Format(BelowxRec));
                exit(true);
            end;

            trigger OnModifyRecord(): Boolean
            begin
                Log.Add('ext OnModifyRecord ' + Format(0));
                exit(true);
            end;

            trigger OnDeleteRecord(): Boolean
            begin
                Log.Add('ext OnDeleteRecord ' + Format(0));
                exit(true);
            end;

            trigger OnQueryClosePage(CloseAction: Action): Boolean
            begin
                Log.Add('ext OnQueryClosePage ' + Format(CloseAction));
                exit(not Flags.Veto());
            end;

            trigger OnClosePage()
            begin
                Log.Add('ext OnClosePage ' + Format(0));
            end;


        var
            Log: Codeunit "LT AB Log";
            Flags: Codeunit "LT AB Flags";
    }
}

reportextension 77073 "LT AB RP Plain Report Ext" extends "LT AB RP Plain Report"
{
    requestpage
    {
            trigger OnOpenPage()
            begin
                Log.Add('ext2 OnOpenPage ' + Format(0));
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('ext2 OnAfterGetRecord ' + Format(0));
            end;

            trigger OnAfterGetCurrRecord()
            begin
                Log.Add('ext2 OnAfterGetCurrRecord ' + Format(0));
            end;

            trigger OnNewRecord(BelowxRec: Boolean)
            begin
                Log.Add('ext2 OnNewRecord ' + Format(BelowxRec));
            end;

            trigger OnInsertRecord(BelowxRec: Boolean): Boolean
            begin
                Log.Add('ext2 OnInsertRecord ' + Format(BelowxRec));
                exit(true);
            end;

            trigger OnModifyRecord(): Boolean
            begin
                Log.Add('ext2 OnModifyRecord ' + Format(0));
                exit(true);
            end;

            trigger OnDeleteRecord(): Boolean
            begin
                Log.Add('ext2 OnDeleteRecord ' + Format(0));
                exit(true);
            end;

            trigger OnQueryClosePage(CloseAction: Action): Boolean
            begin
                Log.Add('ext2 OnQueryClosePage ' + Format(CloseAction));
                exit(not Flags.Veto());
            end;

            trigger OnClosePage()
            begin
                Log.Add('ext2 OnClosePage ' + Format(0));
            end;


        var
            Log: Codeunit "LT AB Log";
            Flags: Codeunit "LT AB Flags";
    }
}
