// Two-top cross-app subscriber order probe (writer TT, al-runner 6924 waldo). Subscriber of this app (M) and the raiser of the event; the
// subscribers of the other apps are tests/al-language-xapp-a/TtXaOrder.al, tests/al-language-xapp-n/TtXnOrder.al and
// tests/al-language-xapp-t/TtXtOrder.al. All four append a tag to the Display Name of a temporary Company named 'LT TT ORDER'.

codeunit 97800 "LT TT M Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT TT ORDER' then
            exit;
        Rec."Display Name" += 'M;';
    end;
}

codeunit 97801 "LT TT Raiser"
{
    procedure RaiseCompany(): Text
    var
        TempCompany: Record Company temporary;
    begin
        TempCompany.Init();
        TempCompany.Name := 'LT TT ORDER';
        TempCompany.Insert();
        TempCompany."Display Name" := '';
        TempCompany.Modify();
        exit(TempCompany."Display Name");
    end;
}
