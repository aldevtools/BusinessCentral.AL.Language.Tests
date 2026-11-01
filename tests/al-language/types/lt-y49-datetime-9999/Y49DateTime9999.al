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
        Observer.Expect('max 0', '[12/31/9999 11:59 PM]');
        Observer.Expect('max 0 variant', '[12/31/9999 11:59 PM]');
        Observer.Expect('max 1', '[12/31/9999 11:59:59.999 PM]');
        Observer.Expect('max 1 variant', '[12/31/9999 11:59:59.999 PM]');
        Observer.Expect('max 2', '[12/31/9999 11:59 PM]');
        Observer.Expect('max 2 variant', '[12/31/9999 11:59 PM]');
        Observer.Expect('max 3', '[12/31/9999 11:59:59 PM]');
        Observer.Expect('max 3 variant', 'raised Standard format number 3 does not exist for the type ''Variant''. [InvalidStandardFormat]');
        Observer.Expect('max 9', '[9999-12-31T23:59:59.999Z]');
        Observer.Expect('max 9 variant', '[9999-12-31T23:59:59.999Z]');
        Observer.Verify();
    end;

    [Test]
    procedure DtFormat9999_Numbers_Midnight()
    begin
        ObsAll('midnight', CreateDateTime(99991231D, 000000T));
        Observer.Expect('midnight 0', '[12/31/9999 12:00 AM]');
        Observer.Expect('midnight 0 variant', '[12/31/9999 12:00 AM]');
        Observer.Expect('midnight 1', '[12/31/9999 12:00:00 AM]');
        Observer.Expect('midnight 1 variant', '[12/31/9999 12:00:00 AM]');
        Observer.Expect('midnight 2', '[12/31/9999 12:00 AM]');
        Observer.Expect('midnight 2 variant', '[12/31/9999 12:00 AM]');
        Observer.Expect('midnight 3', '[12/31/9999 12:00:00 AM]');
        Observer.Expect('midnight 3 variant', 'raised Standard format number 3 does not exist for the type ''Variant''. [InvalidStandardFormat]');
        Observer.Expect('midnight 9', '[9999-12-31T00:00:00Z]');
        Observer.Expect('midnight 9 variant', '[9999-12-31T00:00:00Z]');
        Observer.Verify();
    end;

    [Test]
    procedure DtFormat9999_Numbers_NewYearNoon()
    begin
        ObsAll('jan1 noon', CreateDateTime(99990101D, 120000T));
        Observer.Expect('jan1 noon 0', '[01/01/9999 12:00 PM]');
        Observer.Expect('jan1 noon 0 variant', '[01/01/9999 12:00 PM]');
        Observer.Expect('jan1 noon 1', '[01/01/9999 12:00:00 PM]');
        Observer.Expect('jan1 noon 1 variant', '[01/01/9999 12:00:00 PM]');
        Observer.Expect('jan1 noon 2', '[01/01/9999 12:00 PM]');
        Observer.Expect('jan1 noon 2 variant', '[01/01/9999 12:00 PM]');
        Observer.Expect('jan1 noon 3', '[01/01/9999 12:00:00 PM]');
        Observer.Expect('jan1 noon 3 variant', 'raised Standard format number 3 does not exist for the type ''Variant''. [InvalidStandardFormat]');
        Observer.Expect('jan1 noon 9', '[9999-01-01T12:00:00Z]');
        Observer.Expect('jan1 noon 9 variant', '[9999-01-01T12:00:00Z]');
        Observer.Verify();
    end;

    [Test]
    procedure DtFormat9999_Numbers_NoMs()
    begin
        ObsAll('no ms', CreateDateTime(99991231D, 235959T));
        Observer.Expect('no ms 0', '[12/31/9999 11:59 PM]');
        Observer.Expect('no ms 0 variant', '[12/31/9999 11:59 PM]');
        Observer.Expect('no ms 1', '[12/31/9999 11:59:59 PM]');
        Observer.Expect('no ms 1 variant', '[12/31/9999 11:59:59 PM]');
        Observer.Expect('no ms 2', '[12/31/9999 11:59 PM]');
        Observer.Expect('no ms 2 variant', '[12/31/9999 11:59 PM]');
        Observer.Expect('no ms 3', '[12/31/9999 11:59:59 PM]');
        Observer.Expect('no ms 3 variant', 'raised Standard format number 3 does not exist for the type ''Variant''. [InvalidStandardFormat]');
        Observer.Expect('no ms 9', '[9999-12-31T23:59:59Z]');
        Observer.Expect('no ms 9 variant', '[9999-12-31T23:59:59Z]');
        Observer.Verify();
    end;

    [Test]
    procedure DtFormat9998_Numbers()
    begin
        ObsAll('9998', CreateDateTime(99981231D, 235959.999T));
        Observer.Expect('9998 0', '[12/31/9998 11:59 PM]');
        Observer.Expect('9998 0 variant', '[12/31/9998 11:59 PM]');
        Observer.Expect('9998 1', '[12/31/9998 11:59:59.999 PM]');
        Observer.Expect('9998 1 variant', '[12/31/9998 11:59:59.999 PM]');
        Observer.Expect('9998 2', '[12/31/9998 11:59 PM]');
        Observer.Expect('9998 2 variant', '[12/31/9998 11:59 PM]');
        Observer.Expect('9998 3', '[12/31/9998 11:59:59 PM]');
        Observer.Expect('9998 3 variant', 'raised Standard format number 3 does not exist for the type ''Variant''. [InvalidStandardFormat]');
        Observer.Expect('9998 9', '[9998-12-31T23:59:59.999Z]');
        Observer.Expect('9998 9 variant', '[9998-12-31T23:59:59.999Z]');
        Observer.Verify();
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
        Observer.Expect('equal fmt 2', 'Yes');
        Observer.Expect('equal', 'Yes');
        Observer.Expect('typeof', 'Yes Yes');
        Observer.Verify();
    end;

    // Which years show two digits with format 2 (2024 shows '03/05/24', 9998 and 9999 show four digits).
    [Test]
    procedure DtFormat_YearWidth_Format2()
    var
        Years: List of [Integer];
        Y: Integer;
    begin
        Years.AddRange(1753, 1899, 1900, 1929, 1930, 1999, 2000, 2029, 2030, 2049, 2050, 2099, 2100, 2999, 5000);
        foreach Y in Years do
            Observer.Observe(Format(Y), FmtDirect(CreateDateTime(DMY2Date(15, 6, Y), 120000T), 2) + ' ' + Format(DMY2Date(15, 6, Y), 0, 1));
        Observer.Finish();
    end;
}
