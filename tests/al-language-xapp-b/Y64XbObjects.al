// Cross-app fixtures of writer Y64 (al-runner issues 6653 and 6644), app B (depends on A, not on D). See tests/al-language-xapp-a/Y64XaObjects.al.

reportextension 61355 "LT Y64 XB Report Ext B" extends "LT Y64 XA Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                ExtLog.Add('B-ext:beforepredataitem');
            end;

            trigger OnAfterAfterGetRecord()
            begin
                ExtLog.Add('B-ext:afteraftergetrecord');
            end;

            trigger OnAfterPostDataItem()
            begin
                ExtLog.Add('B-ext:afterpostdataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            addafter(MyOption)
            {
                field(MyFieldB; MyVarB)
                {
                    ApplicationArea = All;
                    Caption = 'My field B';
                }
            }
        }

        trigger OnOpenPage()
        begin
            ExtLog.Add('B-ext:rp open');
        end;

        trigger OnClosePage()
        begin
            ExtLog.Add('B-ext:rp close');
        end;
    }

    trigger OnPreReport()
    begin
        ExtLog.Add('B-ext:prereport');
    end;

    trigger OnPostReport()
    begin
        ExtLog.Add('B-ext:postreport');
    end;

    var
        ExtLog: Codeunit "LT Y64 XA Log";
        MyVarB: Integer;
}

codeunit 61355 "LT Y64 XB Install Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y64 XA Install Hub", 'OnY64InstallProbe', '', false, false)]
    local procedure OnProbe(InstallingApp: Text)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('B-sub|' + InstallingApp);
    end;
}
