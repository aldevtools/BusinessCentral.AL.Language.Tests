// Probe: Format of a DateTime in the year 9999 (and 9998) with standard formats 0 to 3 and 9, directly and through a Variant parameter (as an
// assert library compares two Variants with Format(V, 0, 2)).
// Gap cycle 5, spec G5-12 (writer Y49). Object ids: codeunit 92946.
// Fixtures used: Probe Observer (codeunit 69160).
// Culture and time zone: the corpus tier runs en-US; the DateTime is shown in the session time zone (format 9 shows UTC).

codeunit 92946 "LT Y49 DateTime 9999"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryFmt(V: Variant; N: Integer; var Res: Text)
    begin
        Res := Format(V, 0, N);
    end;

    local procedure Fmt(V: Variant; N: Integer): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryFmt(V, N, Res) then
            exit('[' + Res + ']');
        Res := 'raised ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Res);
    end;

    [TryFunction]
    local procedure TryFmtDirect(DT: DateTime; N: Integer; var Res: Text)
    begin
        Res := Format(DT, 0, N);
    end;

    local procedure FmtDirect(DT: DateTime; N: Integer): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryFmtDirect(DT, N, Res) then
            exit('[' + Res + ']');
        Res := 'raised ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Res);
    end;

    local procedure ObsAll(Name: Text; DT: DateTime)
    var
        Numbers: List of [Integer];
        N: Integer;
    begin
        Numbers.AddRange(0, 1, 2, 3, 9);
        foreach N in Numbers do begin
            Observer.Observe(Name + ' ' + Format(N), FmtDirect(DT, N));
            Observer.Observe(Name + ' ' + Format(N) + ' variant', Fmt(DT, N));
        end;
    end;

    [Test]
    procedure DtFormat9999_Numbers_Max()
    begin
        ObsAll('max', CreateDateTime(99991231D, 235959.999T));
        Observer.Finish();
    end;

    [Test]
    procedure DtFormat9999_Numbers_Midnight()
    begin
        ObsAll('midnight', CreateDateTime(99991231D, 000000T));
        Observer.Finish();
    end;

    [Test]
    procedure DtFormat9999_Numbers_NewYearNoon()
    begin
        ObsAll('jan1 noon', CreateDateTime(99990101D, 120000T));
        Observer.Finish();
    end;

    [Test]
    procedure DtFormat9999_Numbers_NoMs()
    begin
        ObsAll('no ms', CreateDateTime(99991231D, 235959T));
        Observer.Finish();
    end;

    [Test]
    procedure DtFormat9998_Numbers()
    begin
        ObsAll('9998', CreateDateTime(99981231D, 235959.999T));
        Observer.Finish();
    end;

    [Test]
    procedure DtFormat9999_AssertShape()
    var
        A: DateTime;
        B: DateTime;
        VA: Variant;
        VB: Variant;
    begin
        A := CreateDateTime(DMY2Date(31, 12, 9999), 235959.999T);
        B := CreateDateTime(CalcDate('<CY>', 99990601D), 235959.999T);
        VA := A;
        VB := B;
        Observer.Observe('equal fmt 2', Format(Fmt(VA, 2) = Fmt(VB, 2)));
        Observer.Observe('equal', Format(A = B));
        Observer.Observe('typeof', Format(VA.IsDateTime) + ' ' + Format(VB.IsDateTime));
        Observer.Finish();
    end;
}
