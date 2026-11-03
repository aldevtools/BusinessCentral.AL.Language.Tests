// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: request page field properties Importance, NotBlank, DecimalPlaces, MinValue, MaxValue, BlankZero, MultiLine, ClosingDates and ShowMandatory on the fields of a processing only report;
// what TestRequestPage exposes (Visible, Editable, Caption, Value, IsMandatory, SetValue errors). The handlers collect facts in a list that the test replays.

report 71679 "LT P119 Rep Fields"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NameCtl; NameVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Name Ctl';
                        Importance = Promoted;
                        NotBlank = true;
                    }
                    field(AmtCtl; AmtVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Amt Ctl';
                        DecimalPlaces = 2 : 3;
                        MinValue = 1;
                        MaxValue = 10;
                    }
                    field(BlankCtl; BlankVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Blank Ctl';
                        BlankZero = true;
                    }
                    field(NoteCtl; NoteVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Note Ctl';
                        MultiLine = true;
                    }
                    field(DateCtl; DateVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Date Ctl';
                        ClosingDates = true;
                    }
                    field(MandCtl; MandVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Mand Ctl';
                        ShowMandatory = true;
                    }
                }
            }
        }
    }

    var
        NameVar: Text[50];
        AmtVar: Decimal;
        BlankVar: Decimal;
        NoteVar: Text;
        DateVar: Date;
        MandVar: Text[30];
}

codeunit 71680 "LT P119 RepFields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Facts: List of [Text];

    [Test]
    [HandlerFunctions('StateHandler')]
    procedure P119_ReportFieldState()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Fields");
        Replay(Observer);
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-editable', 'Yes');
        Observer.Expect('name-caption', 'Name Ctl');
        Observer.Expect('name-value', '');
        Observer.Expect('amt-visible', 'Yes');
        Observer.Expect('amt-value', '0.00');
        Observer.Expect('blank-value', '');
        Observer.Expect('note-visible', 'Yes');
        Observer.Expect('note-value', '');
        Observer.Expect('date-value', '');
        Observer.Expect('mand-visible', 'Yes');
        Observer.Expect('mand-value', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MinMaxHandler')]
    procedure P119_ReportMinMax()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Fields");
        Replay(Observer);
        Observer.Expect('five', '5.00');
        Observer.Expect('zero-err', 'Validation error for Field: AmtCtl,  Message = ''The value must be greater than or equal to 1. Value: 0.00.''');
        Observer.Expect('zero-code', 'TestValidation');
        Observer.Expect('eleven-err', 'Validation error for Field: AmtCtl,  Message = ''The value must be less than or equal to 10. Value: 11.00.''');
        Observer.Expect('eleven-code', 'TestValidation');
        Observer.Expect('ten', '10.00');
        Observer.Expect('one', '1.00');
        Observer.Expect('neg-err', 'Validation error for Field: AmtCtl,  Message = ''The value must be greater than or equal to 1. Value: -3.00.''');
        Observer.Expect('after', '1.00');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DecimalHandler')]
    procedure P119_ReportDecimalAndBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Fields");
        Replay(Observer);
        Observer.Expect('amt-long', '1.235');
        Observer.Expect('amt-two', '2.00');
        Observer.Expect('amt-two-five', '2.50');
        Observer.Expect('blank-initial', '');
        Observer.Expect('blank-five', '5.00');
        Observer.Expect('blank-zero', '');
        Observer.Expect('blank-neg', '-2.00');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NotBlankHandler')]
    procedure P119_ReportNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Fields");
        Replay(Observer);
        Observer.Expect('filled', 'filled');
        Observer.Expect('blank-err', 'Validation error for Field: NameCtl,  Message = '' must be filled in. Enter a value.''');
        Observer.Expect('blank-code', 'TestValidation');
        Observer.Expect('after', 'filled');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DateHandler')]
    procedure P119_ReportClosingDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Fields");
        Replay(Observer);
        Observer.Expect('normal', '2/1/2025');
        Observer.Expect('closing', 'C12/31/2025');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure StateHandler(var RP: TestRequestPage "LT P119 Rep Fields")
    begin
        Facts.Add('name-visible=' + Format(RP.NameCtl.Visible()));
        Facts.Add('name-editable=' + Format(RP.NameCtl.Editable()));
        Facts.Add('name-caption=' + RP.NameCtl.Caption());
        Facts.Add('name-value=' + RP.NameCtl.Value());
        Facts.Add('amt-visible=' + Format(RP.AmtCtl.Visible()));
        Facts.Add('amt-value=' + RP.AmtCtl.Value());
        Facts.Add('blank-value=' + RP.BlankCtl.Value());
        Facts.Add('note-visible=' + Format(RP.NoteCtl.Visible()));
        Facts.Add('note-value=' + RP.NoteCtl.Value());
        Facts.Add('date-value=' + RP.DateCtl.Value());
        Facts.Add('mand-visible=' + Format(RP.MandCtl.Visible()));
        Facts.Add('mand-value=' + RP.MandCtl.Value());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure MinMaxHandler(var RP: TestRequestPage "LT P119 Rep Fields")
    begin
        RP.AmtCtl.SetValue(5);
        Facts.Add('five=' + RP.AmtCtl.Value());
        asserterror RP.AmtCtl.SetValue(0);
        Facts.Add('zero-err=' + GetLastErrorText());
        Facts.Add('zero-code=' + GetLastErrorCode());
        ClearLastError();
        asserterror RP.AmtCtl.SetValue(11);
        Facts.Add('eleven-err=' + GetLastErrorText());
        Facts.Add('eleven-code=' + GetLastErrorCode());
        ClearLastError();
        RP.AmtCtl.SetValue(10);
        Facts.Add('ten=' + RP.AmtCtl.Value());
        RP.AmtCtl.SetValue(1);
        Facts.Add('one=' + RP.AmtCtl.Value());
        asserterror RP.AmtCtl.SetValue(-3);
        Facts.Add('neg-err=' + GetLastErrorText());
        ClearLastError();
        Facts.Add('after=' + RP.AmtCtl.Value());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure DecimalHandler(var RP: TestRequestPage "LT P119 Rep Fields")
    begin
        RP.AmtCtl.SetValue(1.23456);
        Facts.Add('amt-long=' + RP.AmtCtl.Value());
        RP.AmtCtl.SetValue(2);
        Facts.Add('amt-two=' + RP.AmtCtl.Value());
        RP.AmtCtl.SetValue(2.5);
        Facts.Add('amt-two-five=' + RP.AmtCtl.Value());
        Facts.Add('blank-initial=' + RP.BlankCtl.Value());
        RP.BlankCtl.SetValue(5);
        Facts.Add('blank-five=' + RP.BlankCtl.Value());
        RP.BlankCtl.SetValue(0);
        Facts.Add('blank-zero=' + RP.BlankCtl.Value());
        RP.BlankCtl.SetValue(-2);
        Facts.Add('blank-neg=' + RP.BlankCtl.Value());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure NotBlankHandler(var RP: TestRequestPage "LT P119 Rep Fields")
    begin
        RP.NameCtl.SetValue('filled');
        Facts.Add('filled=' + RP.NameCtl.Value());
        asserterror RP.NameCtl.SetValue('');
        Facts.Add('blank-err=' + GetLastErrorText());
        Facts.Add('blank-code=' + GetLastErrorCode());
        ClearLastError();
        Facts.Add('after=' + RP.NameCtl.Value());
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure DateHandler(var RP: TestRequestPage "LT P119 Rep Fields")
    begin
        RP.DateCtl.SetValue(DMY2Date(1, 2, 2025));
        Facts.Add('normal=' + RP.DateCtl.Value());
        RP.DateCtl.SetValue(ClosingDate(DMY2Date(31, 12, 2025)));
        Facts.Add('closing=' + RP.DateCtl.Value());
        RP.Cancel().Invoke();
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        Line: Text;
        Pos: Integer;
    begin
        foreach Line in Facts do begin
            Pos := StrPos(Line, '=');
            Observer.Observe(CopyStr(Line, 1, Pos - 1), CopyStr(Line, Pos + 1));
        end;
    end;
}
