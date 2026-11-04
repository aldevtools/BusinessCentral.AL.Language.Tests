// Batch 5, md:268 (WorkDate): the date shorthands t, today, workdate and their upper-case forms in a Date control (only w is pinned).
// The page below is read through a TestPage; the page variable GDate is validated, the trigger echoes it as text.

page 67068 "W5 Date Shorthand"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(GDate; GDate)
                {
                    ApplicationArea = All;
                    Caption = 'GDate';

                    trigger OnValidate()
                    begin
                        GEcho := Format(GDate, 0, 9);
                    end;
                }
                field(GEcho; GEcho)
                {
                    ApplicationArea = All;
                    Caption = 'GEcho';
                }
            }
        }
    }

    var
        GDate: Date;
        GEcho: Text;
}

codeunit 67069 "W5 WorkDate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // md:268: each spelling is typed into the Date control while WorkDate is 2031-12-31 (not today). The result is named: today, workdate, other (with its text) or an error.
    [Test]
    procedure DateControl_Shorthand_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "W5 Date Shorthand";
        OldWorkDate: Date;
    begin
        OldWorkDate := WorkDate();
        WorkDate(20311231D);
        Page.OpenEdit();
        Observer.Observe('w', TypeShorthand(Page, 'w'));
        Observer.Observe('t', TypeShorthand(Page, 't'));
        Observer.Observe('today', TypeShorthand(Page, 'today'));
        Observer.Observe('workdate', TypeShorthand(Page, 'workdate'));
        Observer.Observe('td', TypeShorthand(Page, 'td'));
        Page.Close();
        WorkDate(OldWorkDate);
        Observer.Observe('workdate_restored', Format(WorkDate() = OldWorkDate));
        Observer.Expect('w', 'workdate');
        Observer.Expect('t', 'today');
        Observer.Expect('today', 'today');
        Observer.Expect('workdate', 'workdate');
        Observer.Expect('td', 'error: Validation error for Field: GDate,  Message = ''Your entry of ''td'' is not an acceptable value for ''GDate''. The format of the Date ''td'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.''');
        Observer.Expect('workdate_restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DateControl_Shorthand_UpperCase()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "W5 Date Shorthand";
        OldWorkDate: Date;
    begin
        OldWorkDate := WorkDate();
        WorkDate(20311231D);
        Page.OpenEdit();
        Observer.Observe('W', TypeShorthand(Page, 'W'));
        Observer.Observe('T', TypeShorthand(Page, 'T'));
        Observer.Observe('TODAY', TypeShorthand(Page, 'TODAY'));
        Observer.Observe('Today', TypeShorthand(Page, 'Today'));
        Observer.Observe('WORKDATE', TypeShorthand(Page, 'WORKDATE'));
        Observer.Observe('WorkDate', TypeShorthand(Page, 'WorkDate'));
        Page.Close();
        WorkDate(OldWorkDate);
        Observer.Observe('workdate_restored', Format(WorkDate() = OldWorkDate));
        Observer.Expect('W', 'workdate');
        Observer.Expect('T', 'today');
        Observer.Expect('TODAY', 'today');
        Observer.Expect('Today', 'today');
        Observer.Expect('WORKDATE', 'workdate');
        Observer.Expect('WorkDate', 'workdate');
        Observer.Expect('workdate_restored', 'Yes');
        Observer.Verify();
    end;

    local procedure TypeShorthand(var Page: TestPage "W5 Date Shorthand"; Spelling: Text): Text
    var
        Typed: Date;
        Ok: Boolean;
    begin
        Page.GDate.SetValue(19990101D);
        ClearLastError();
        Ok := TrySetValue(Page, Spelling);
        if not Ok then begin
            Spelling := 'error: ' + GetLastErrorText();
            ClearLastError();
            exit(Spelling);
        end;
        if not Evaluate(Typed, Page.GEcho.Value(), 9) then
            exit('echo not a date: ' + Page.GEcho.Value());
        if Typed = Today() then
            exit('today');
        if Typed = WorkDate() then
            exit('workdate');
        exit('other: ' + Page.GEcho.Value());
    end;

    [TryFunction]
    local procedure TrySetValue(var Page: TestPage "W5 Date Shorthand"; Spelling: Text)
    begin
        Page.GDate.SetValue(Spelling);
    end;
}
