// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80700-80713 (AzEventObjects.al)
// Probe: corpus issue 651 (queries and event subscribers), items 9 (subscriber without a sender), 11 and 13, writer AZ (item 10 is pinned in events/W4ValidateOrderAndCurrFieldNo.al) (item 12: a TestPage has no Delete method, must-not-compile case 1212).
// BC versions: 27, 28, 29

codeunit 80709 "LT AZ Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AZ Ev Log";

    // ---- item 9: a reportextension event with IncludeSender = true; subscribers with and without a Report sender ----

    [Test]
    procedure ReportExtensionEvent_IncludeSender()
    var
        Rep: Report "LT AZ Ev Report";
    begin
        Rep.UseRequestPage(false);
        Rep.SetMark('m1');
        Log.Start();
        Rep.Run();
        Observer.Observe('log', Log.Stop());
        Observer.Expect('log', 'nosender N=7;withsender N=7 mark=m1;');
        Observer.Verify();
    end;

    // ---- item 11: GetDatabaseTableTriggerSetup and OnDatabaseInsert when the table is written in a second company ----

    [Test]
    procedure GlobalTriggerSetup_SecondCompany()
    var
        Company: Record Company;
        Row: Record "LT AZ Ev Row";
        Other: Record "LT AZ Ev Row";
        OtherName: Text;
    begin
        Company.SetFilter(Name, '<>%1', CompanyName());
        if Company.FindFirst() then
            OtherName := Company.Name;
        Observer.Observe('other_company_found', Format(OtherName <> ''));
        if OtherName <> '' then begin
            Log.Start();
            Row.Id := 1;
            Row.Insert(true);
            Observer.Observe('first_company', Log.Stop().Replace(CompanyName(), '<current>'));
            Log.Start();
            Other.ChangeCompany(OtherName);
            Other.Id := 2;
            Other.Insert(true);
            Observer.Observe('second_company', Log.Stop().Replace(OtherName, '<other>').Replace(CompanyName(), '<current>'));
            Log.Start();
            Row.Id := 3;
            Row.Insert(true);
            Observer.Observe('first_again', Log.Stop().Replace(CompanyName(), '<current>'));
        end;
        Observer.Expect('other_company_found', 'Yes');
        Observer.Expect('first_company', 'setup company=<current>;oninsert id=1 recrefcompany=<current> company=<current>;');
        Observer.Expect('second_company', 'oninsert id=2 recrefcompany=<other> company=<current>;');
        Observer.Expect('first_again', 'oninsert id=3 recrefcompany=<current> company=<current>;');
        Observer.Verify();
    end;

    // ---- item 13: the number after the page event name in Event Subscription rows ----

    local procedure Published(FunctionName: Text): Text
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT AZ Ev Page Subs");
        Sub.SetRange("Subscriber Function", FunctionName);
        if not Sub.FindFirst() then
            exit('<none>');
        exit(Sub."Published Function");
    end;

    [Test]
    procedure PageEventNumbers_WhatTheyDependOn()
    var
        Name: Text;
    begin
        foreach Name in 'OneActX,OneActY,TwoActX,TwoActY,ThreeActX,ThreeActY,OneValX,OneValY,TwoValX,TwoValY,ThreeValX,ThreeValY'.Split(',') do
            Observer.Observe(Name, Published(Name));
        Observer.Observe('act_same_name_other_page_equal', Format(Published('OneActX') = Published('TwoActX')));
        Observer.Observe('act_other_order_equal', Format(Published('OneActX') = Published('ThreeActX')));
        Observer.Observe('act_other_name_equal', Format(Published('OneActX') = Published('OneActY')));
        Observer.Observe('val_same_name_other_page_equal', Format(Published('OneValX') = Published('TwoValX')));
        Observer.Observe('val_other_order_equal', Format(Published('OneValX') = Published('ThreeValX')));
        Observer.Observe('val_other_name_equal', Format(Published('OneValX') = Published('OneValY')));
        Observer.Expect('OneActX', 'OnAfterActionEvent - 363211597');
        Observer.Expect('OneActY', 'OnAfterActionEvent - 274485020');
        Observer.Expect('TwoActX', 'OnAfterActionEvent - 2065181460');
        Observer.Expect('TwoActY', 'OnAfterActionEvent - 1592089219');
        Observer.Expect('ThreeActX', 'OnAfterActionEvent - 1874278911');
        Observer.Expect('ThreeActY', 'OnAfterActionEvent - 1236582294');
        Observer.Expect('OneValX', 'OnAfterValidateEvent - 1633924696');
        Observer.Expect('OneValY', 'OnAfterValidateEvent - 996228079');
        Observer.Expect('TwoValX', 'OnAfterValidateEvent - 289487247');
        Observer.Expect('TwoValY', 'OnAfterValidateEvent - 927183864');
        Observer.Expect('ThreeValX', 'OnAfterValidateEvent - 1847725402');
        Observer.Expect('ThreeValY', 'OnAfterValidateEvent - 1809545277');
        Observer.Expect('act_same_name_other_page_equal', 'No');
        Observer.Expect('act_other_order_equal', 'No');
        Observer.Expect('act_other_name_equal', 'No');
        Observer.Expect('val_same_name_other_page_equal', 'No');
        Observer.Expect('val_other_order_equal', 'No');
        Observer.Expect('val_other_name_equal', 'No');
        Observer.Verify();
    end;
}
