//sub:report
// Invoke on an action of a request page (md:220): the error text with the action id, Visible and Enabled of the actions, and whether OnAction ran.
// The ids of the three actions are fixed by the report id and the action names; the text is observed as BC writes it.

codeunit 67741 "W3 Action Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 67742 "W3 Action Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(StampText)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                        L.Add('OnAction StampText');
                        CtlVal := 99;
                    end;
                }
                action(HiddenAct)
                {
                    ApplicationArea = All;
                    Visible = false;

                    trigger OnAction()
                    begin
                        L.Add('OnAction HiddenAct');
                    end;
                }
                action(DisabledAct)
                {
                    ApplicationArea = All;
                    Enabled = false;

                    trigger OnAction()
                    begin
                        L.Add('OnAction DisabledAct');
                    end;
                }
            }
        }
    }

    var
        CtlVal: Integer;
        L: Codeunit "W3 Action Log";

    trigger OnPreReport()
    begin
        L.Add('PreReport ctl=' + Format(CtlVal));
    end;
}

codeunit 67743 "W3 Action Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 Action Log";

    [TryFunction]
    local procedure TryVisible(var RP: TestRequestPage "W3 Action Rpt"; Which: Integer; var Answer: Boolean)
    begin
        case Which of
            1:
                Answer := RP.StampText.Visible();
            2:
                Answer := RP.HiddenAct.Visible();
            3:
                Answer := RP.DisabledAct.Visible();
        end;
    end;

    [TryFunction]
    local procedure TryEnabled(var RP: TestRequestPage "W3 Action Rpt"; Which: Integer; var Answer: Boolean)
    begin
        case Which of
            1:
                Answer := RP.StampText.Enabled();
            2:
                Answer := RP.HiddenAct.Enabled();
            3:
                Answer := RP.DisabledAct.Enabled();
        end;
    end;

    [TryFunction]
    local procedure TryInvoke(var RP: TestRequestPage "W3 Action Rpt"; Which: Integer)
    begin
        case Which of
            1:
                RP.StampText.Invoke();
            2:
                RP.HiddenAct.Invoke();
            3:
                RP.DisabledAct.Invoke();
        end;
    end;

    local procedure Describe(var RP: TestRequestPage "W3 Action Rpt"; Which: Integer; Name: Text)
    var
        Answer: Boolean;
    begin
        if TryVisible(RP, Which, Answer) then
            L.Add(Name + ' visible=' + Format(Answer))
        else
            L.Add(Name + ' visible error=' + GetLastErrorText());
        if TryEnabled(RP, Which, Answer) then
            L.Add(Name + ' enabled=' + Format(Answer))
        else
            L.Add(Name + ' enabled error=' + GetLastErrorText());
        if TryInvoke(RP, Which) then
            L.Add(Name + ' invoked')
        else
            L.Add(Name + ' invoke error=' + GetLastErrorText());
    end;

    [RequestPageHandler]
    procedure ActionHandler(var RP: TestRequestPage "W3 Action Rpt")
    begin
        Describe(RP, 1, 'StampText');
        Describe(RP, 2, 'HiddenAct');
        Describe(RP, 3, 'DisabledAct');
        L.Add('ctl after invokes=' + RP.Ctl.Value());
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    procedure Actions_InvokeVisibleEnabled_AndTheRunAfterwards()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
    begin
        Row.DeleteAll();
        Commit();
        L.Take();
        Report.Run(Report::"W3 Action Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'StampText visible error=The action with ID = n is not found on the page.;StampText enabled error=The action with ID = n is not found on the page.;StampText invoke error=The action with ID = n is not found on the page.;HiddenAct visible error=The action with ID = n is not found on the page.;HiddenAct enabled error=The action with ID = n is not found on the page.;HiddenAct invoke error=The action with ID = n is not found on the page.;DisabledAct visible error=The action with ID = n is not found on the page.;DisabledAct enabled error=The action with ID = n is not found on the page.;DisabledAct invoke error=The action with ID = n is not found on the page.;ctl after invokes=0;PreReport ctl=0;');
        Observer.Verify();
    end;
}
