// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-closingdate-method
// Scope: in-scope. Format and Evaluate of a closing date under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053; arithmetic on a closing date; WorkDate set to a closing date.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75401 (LT GL Closing Date)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

codeunit 75401 "LT GL Closing Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormatStd(D: Date; Std: Integer; var Txt: Text)
    begin
        Txt := Format(D, 0, Std);
    end;

    [TryFunction]
    local procedure TryFormatPicture(D: Date; Picture: Text; var Txt: Text)
    begin
        Txt := Format(D, 0, Picture);
    end;

    [TryFunction]
    local procedure TryEvaluate(var D: Date; Txt: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(D, Txt);
    end;

    local procedure Std(D: Date; N: Integer): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormatStd(D, N, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Pic(D: Date; Picture: Text): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormatPicture(D, Picture, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // ok flag | the normal date (XML form) | whether the result is a closing date
    local procedure Eval(Txt: Text): Text
    var
        D: Date;
        Ok: Boolean;
    begin
        D := DMY2Date(1, 1, 2000);
        ClearLastError();
        if not TryEvaluate(D, Txt, Ok) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Format(Ok, 0, 9) + '|' + Format(NormalDate(D), 0, 9) + '|closing=' + Format(D <> NormalDate(D), 0, 9));
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        CD: Date;
        CD2: Date;
        Names: List of [Text];
        Results: List of [Text];
        Inputs: List of [Text];
        T: Text;
        Own: Text;
        i: Integer;
    begin
        CD := ClosingDate(DMY2Date(31, 12, 2023));
        CD2 := ClosingDate(DMY2Date(5, 1, 2024));
        Inputs.AddRange('C12/31/23', 'U12/31/23', 'S12/31/23', 'c12/31/23', 'u12/31/23', 'C01/05/24', 'U01/05/24', '12/31/23');
        GlobalLanguage(Lang);
        Names.Add('Format');
        Results.Add('[' + Format(CD) + ']');
        Names.Add('Format 5 Jan 2024');
        Results.Add('[' + Format(CD2) + ']');
        Names.Add('Format length 12');
        Results.Add('[' + Format(CD, 12) + ']');
        Names.Add('std 0, 1, 2');
        Results.Add(Std(CD, 0) + Std(CD, 1) + Std(CD, 2));
        Names.Add('std 4, 7, 9');
        Results.Add(Std(CD, 4) + Std(CD, 7) + Std(CD, 9));
        Names.Add('picture <Closing>');
        Results.Add(Pic(CD, '<Closing>'));
        Names.Add('picture <Closing><Day,2>.<Month,2>.<Year4>');
        Results.Add(Pic(CD, '<Closing><Day,2>.<Month,2>.<Year4>'));
        Names.Add('picture <Closing> of a normal date');
        Results.Add(Pic(DMY2Date(31, 12, 2023), '<Closing><Year4>'));
        Own := Format(CD);
        Names.Add('Evaluate of its own Format');
        Results.Add(Eval(Own));
        foreach T in Inputs do begin
            Names.Add('Evaluate ' + T);
            Results.Add(Eval(T));
        end;
        GlobalLanguage(1033);
        for i := 1 to Names.Count() do
            Observer.Observe(Names.Get(i), Results.Get(i));
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_FormatEvaluate_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1053);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer; var Txt: Text)
    var
        CD: Date;
        D: Date;
    begin
        CD := ClosingDate(DMY2Date(31, 12, 2023));
        D := DMY2Date(31, 12, 2023);
        case Op of
            1:
                Txt := Format(CD - D);
            2:
                Txt := Format(D - CD);
            3:
                Txt := Format(CD - CD);
            4:
                Txt := Format(CD + 1, 0, 9);
            5:
                Txt := Format(CD - 1, 0, 9);
            6:
                Txt := Format(NormalDate(CD) - D);
            7:
                Txt := Format(CD > D, 0, 9) + '|' + Format(CD = D, 0, 9) + '|' + Format(CD < DMY2Date(1, 1, 2024), 0, 9);
            8:
                Txt := Format(CalcDate('<1D>', CD), 0, 9);
            9:
                Txt := Format(Date2DMY(CD, 1)) + '|' + Format(Date2DMY(CD, 2)) + '|' + Format(Date2DMY(CD, 3)) + '|' + Format(Date2DWY(CD, 1));
            10:
                Txt := Format(ClosingDate(CD) = CD, 0, 9);
            11:
                Txt := Format(CreateDateTime(CD, 0T) = CreateDateTime(D, 0T), 0, 9);
        end;
    end;

    local procedure Op(N: Integer): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryOp(N, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ClosingDate_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('CD - D', Op(1));
        Observer.Observe('D - CD', Op(2));
        Observer.Observe('CD - CD', Op(3));
        Observer.Observe('CD + 1', Op(4));
        Observer.Observe('CD - 1', Op(5));
        Observer.Observe('NormalDate(CD) - D', Op(6));
        Observer.Observe('CD > D, CD = D, CD < next day', Op(7));
        Observer.Observe('CalcDate <1D> of CD', Op(8));
        Observer.Observe('Date2DMY 1 2 3, Date2DWY 1 of CD', Op(9));
        Observer.Observe('ClosingDate(CD) = CD', Op(10));
        Observer.Observe('CreateDateTime(CD) = CreateDateTime(D)', Op(11));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetWorkDate(D: Date)
    begin
        WorkDate(D);
    end;

    local procedure WorkDateLine(D: Date): Text
    var
        Old: Date;
        Txt: Text;
    begin
        Old := WorkDate();
        ClearLastError();
        if TrySetWorkDate(D) then
            Txt := Format(NormalDate(WorkDate()), 0, 9) + '|closing=' + Format(WorkDate() <> NormalDate(WorkDate()), 0, 9) + '|equal=' + Format(WorkDate() = D, 0, 9) + '|[' + Format(WorkDate()) + ']'
        else
            Txt := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        WorkDate(Old);
        exit(Txt);
    end;

    [Test]
    procedure ClosingDate_WorkDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('WorkDate(closing 2023-12-31)', WorkDateLine(ClosingDate(DMY2Date(31, 12, 2023))));
        Observer.Observe('WorkDate(closing 2024-02-29)', WorkDateLine(ClosingDate(DMY2Date(29, 2, 2024))));
        Observer.Observe('WorkDate(normal 2023-12-31)', WorkDateLine(DMY2Date(31, 12, 2023)));
        Observer.Finish();
    end;
}
