// Cross-app fixture of writer Y64 (al-runner issue 6653), app C (depends on A, B and D). See tests/al-language-xapp-a/Y64XaObjects.al.

reportextension 61360 "LT Y64 XC Report Ext C" extends "LT Y64 XA Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                ExtLog.Add('C-ext:beforepredataitem');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                ExtLog.Add('C-ext:afteraftergetrecord');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(MyOption)
            {
                field(MyFieldC; MyVarC)
                {
                    ApplicationArea = All;
                    Caption = 'My field C';
                }
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('C-ext:rp open');
        end;
    }

    trigger OnPreReport()
    begin
        ExtLog.Add('C-ext:prereport');
    end;

    var
        ExtLog: Codeunit "LT Y64 XA Log";
        MyVarC: Text[10];
}
