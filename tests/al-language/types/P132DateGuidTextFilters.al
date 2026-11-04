// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73708
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73708 "LT P132 Filter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Gd; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73709 "LT P132 Date Guid Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P132 Filter Row";
        G: Guid;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Dt := 20240115D;
        Evaluate(G, '{AAAAAAAA-0000-0000-0000-000000000001}');
        R.Gd := G;
        R.Insert();
        R.Id := 2;
        R.Dt := 20240131D;
        Evaluate(G, '{BBBBBBBB-0000-0000-0000-000000000002}');
        R.Gd := G;
        R.Insert();
        R.Id := 3;
        R.Dt := 20240229D;
        Clear(R.Gd);
        R.Insert();
        R.Id := 4;
        R.Dt := 0D;
        Evaluate(G, '{CCCCCCCC-0000-0000-0000-000000000004}');
        R.Gd := G;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryFilterDate(var R: Record "LT P132 Filter Row"; Txt: Text)
    begin
        R.SetFilter(Dt, Txt);
    end;

    [TryFunction]
    local procedure TryFilterGuid(var R: Record "LT P132 Filter Row"; Txt: Text)
    begin
        R.SetFilter(Gd, Txt);
    end;

    [TryFunction]
    local procedure TryViewDate(var R: Record "LT P132 Filter Row"; Txt: Text)
    begin
        R.SetView('WHERE(Dt=FILTER(' + Txt + '))');
    end;

    [TryFunction]
    local procedure TryViewGuid(var R: Record "LT P132 Filter Row"; Txt: Text)
    begin
        R.SetView('WHERE(Gd=FILTER(' + Txt + '))');
    end;

    local procedure Ids(var R: Record "LT P132 Filter Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id);
            until R.Next() = 0;
        exit(Result);
    end;

    local procedure DateFilter(var Observer: Codeunit "Probe Observer"; ObsName: Text; Txt: Text)
    var
        R: Record "LT P132 Filter Row";
    begin
        if TryFilterDate(R, Txt) then
            Observer.Observe(ObsName, 'ok ids=' + Ids(R) + ' same=' + Format(R.GetFilter(Dt) = Txt))
        else begin
            Observer.Observe(ObsName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    local procedure DateView(var Observer: Codeunit "Probe Observer"; ObsName: Text; Txt: Text)
    var
        R: Record "LT P132 Filter Row";
    begin
        if TryViewDate(R, Txt) then
            Observer.Observe(ObsName, 'ok ids=' + Ids(R) + ' same=' + Format(R.GetFilter(Dt) = Txt))
        else begin
            Observer.Observe(ObsName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    local procedure GuidFilter(var Observer: Codeunit "Probe Observer"; ObsName: Text; Txt: Text)
    var
        R: Record "LT P132 Filter Row";
    begin
        if TryFilterGuid(R, Txt) then
            Observer.Observe(ObsName, 'ok ids=' + Ids(R) + ' filter=' + R.GetFilter(Gd))
        else begin
            Observer.Observe(ObsName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    local procedure GuidView(var Observer: Codeunit "Probe Observer"; ObsName: Text; Txt: Text)
    var
        R: Record "LT P132 Filter Row";
    begin
        if TryViewGuid(R, Txt) then
            Observer.Observe(ObsName, 'ok ids=' + Ids(R) + ' filter=' + R.GetFilter(Gd))
        else begin
            Observer.Observe(ObsName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure P132_SetFilter_Date_Formulas()
    var
        Observer: Codeunit "Probe Observer";
        OldWork: Date;
    begin
        Seed();
        OldWork := WorkDate();
        WorkDate(20240115D);
        DateFilter(Observer, 'f_1M', '1M');
        DateFilter(Observer, 'f_minus_1M', '-1M');
        DateFilter(Observer, 'f_CM', 'CM');
        DateFilter(Observer, 'f_wrapped_CM', '<CM>');
        DateFilter(Observer, 'f_wrapped_1M', '<1M>');
        DateFilter(Observer, 'f_1D', '1D');
        DateFilter(Observer, 'f_minus_1D', '-1D');
        DateFilter(Observer, 'f_D', 'D');
        DateFilter(Observer, 'f_W', 'W');
        DateFilter(Observer, 'f_T', 'T');
        DateFilter(Observer, 'f_WD1', 'WD1');
        DateFilter(Observer, 'f_1W', '1W');
        DateFilter(Observer, 'f_CY', 'CY');
        DateFilter(Observer, 'f_1Y', '1Y');
        DateFilter(Observer, 'f_0D', '0D');
        DateFilter(Observer, 'f_zero', '0');
        DateFilter(Observer, 'f_range_1M_CM', '1M..CM');
        DateFilter(Observer, 'f_gt_1M', '>1M');
        DateFilter(Observer, 'f_lt_1M', '<1M');
        DateFilter(Observer, 'f_1M_or_CM', '1M|CM');
        WorkDate(OldWork);
        Observer.Expect('f_1M', 'ok ids= same=No');
        Observer.Expect('f_minus_1M', 'ok ids= same=No');
        Observer.Expect('f_CM', 'ok ids= same=No');
        Observer.Expect('f_wrapped_CM', 'ok ids= same=No');
        Observer.Expect('f_wrapped_1M', 'ok ids= same=No');
        Observer.Expect('f_1D', 'ok ids= same=No');
        Observer.Expect('f_minus_1D', 'ok ids= same=No');
        Observer.Expect('f_D', 'ok ids=1 same=No');
        Observer.Expect('f_W', 'ok ids=1 same=No');
        Observer.Expect('f_T', 'ok ids= same=No');
        Observer.Expect('f_WD1', 'ok ids= same=No');
        Observer.Expect('f_1W', 'ok ids= same=No');
        Observer.Expect('f_CY', 'ok ids= same=No');
        Observer.Expect('f_1Y', 'ok ids= same=No');
        Observer.Expect('f_0D', 'ok ids= same=No');
        Observer.Expect('f_zero', 'error:The filter "0" is not valid for the Dt field on the LT P132 Filter Row table. The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('f_range_1M_CM', 'ok ids=123 same=No');
        Observer.Expect('f_gt_1M', 'ok ids=123 same=No');
        Observer.Expect('f_lt_1M', 'ok ids=4 same=No');
        Observer.Expect('f_1M_or_CM', 'ok ids= same=No');
        Observer.Verify();
    end;

    [Test]
    procedure P132_SetFilter_Date_EmptyAndRegionShapes()
    var
        Observer: Codeunit "Probe Observer";
        OldWork: Date;
    begin
        Seed();
        OldWork := WorkDate();
        WorkDate(20240115D);
        DateFilter(Observer, 'f_empty', '');
        DateFilter(Observer, 'f_quoted_empty', '''''');
        DateFilter(Observer, 'f_space', ' ');
        DateFilter(Observer, 'f_011524', '011524');
        DateFilter(Observer, 'f_slash_short', '01/15/24');
        DateFilter(Observer, 'f_slash_long', '01/15/2024');
        DateFilter(Observer, 'f_slash_nopad', '1/15/24');
        DateFilter(Observer, 'f_dot_short', '15.01.24');
        DateFilter(Observer, 'f_day_only', '15');
        DateFilter(Observer, 'f_year_only', '2024');
        DateFilter(Observer, 'f_range_slash', '01/15/24..01/31/24');
        DateFilter(Observer, 'f_iso_range', '2024-01-15..2024-01-31');
        DateFilter(Observer, 'f_text', 'abc');
        DateFilter(Observer, 'f_month_name', 'Jan 15, 2024');
        DateFilter(Observer, 'f_not_empty', '<>''''');
        DateFilter(Observer, 'f_star', '*');
        WorkDate(OldWork);
        Observer.Expect('f_empty', 'ok ids=1234 same=Yes');
        Observer.Expect('f_quoted_empty', 'ok ids=4 same=Yes');
        Observer.Expect('f_space', 'ok ids=1234 same=No');
        Observer.Expect('f_011524', 'ok ids=1 same=No');
        Observer.Expect('f_slash_short', 'ok ids=1 same=Yes');
        Observer.Expect('f_slash_long', 'ok ids=1 same=No');
        Observer.Expect('f_slash_nopad', 'ok ids=1 same=No');
        Observer.Expect('f_dot_short', 'error:The filter "15.01.24" is not valid for the Dt field on the LT P132 Filter Row table. The format of the Date ''15.01.24'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('f_day_only', 'ok ids=1 same=No');
        Observer.Expect('f_year_only', 'error:The filter "2024" is not valid for the Dt field on the LT P132 Filter Row table. The format of the Date ''2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('f_range_slash', 'ok ids=12 same=Yes');
        Observer.Expect('f_iso_range', 'ok ids=12 same=No');
        Observer.Expect('f_text', 'error:The filter "abc" is not valid for the Dt field on the LT P132 Filter Row table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('f_month_name', 'error:The filter "Jan 15, 2024" is not valid for the Dt field on the LT P132 Filter Row table. The format of the Date ''Jan 15, 2024'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('f_not_empty', 'ok ids=123 same=Yes');
        Observer.Expect('f_star', 'ok ids= same=No');
        Observer.Verify();
    end;





    [Test]
    procedure P132_SetView_Date_Texts()
    var
        Observer: Codeunit "Probe Observer";
        OldWork: Date;
    begin
        Seed();
        OldWork := WorkDate();
        WorkDate(20240115D);
        DateView(Observer, 'v_1M', '1M');
        DateView(Observer, 'v_CM', 'CM');
        DateView(Observer, 'v_minus_1D', '-1D');
        DateView(Observer, 'v_W', 'W');
        DateView(Observer, 'v_T', 'T');
        DateView(Observer, 'v_empty', '');
        DateView(Observer, 'v_quoted_empty', '''''');
        DateView(Observer, 'v_011524', '011524');
        DateView(Observer, 'v_slash_short', '01/15/24');
        DateView(Observer, 'v_iso', '2024-01-15');
        DateView(Observer, 'v_text', 'abc');
        WorkDate(OldWork);
        Observer.Expect('v_1M', 'ok ids= same=No');
        Observer.Expect('v_CM', 'ok ids= same=No');
        Observer.Expect('v_minus_1D', 'ok ids= same=No');
        Observer.Expect('v_W', 'ok ids=1 same=No');
        Observer.Expect('v_T', 'ok ids= same=No');
        Observer.Expect('v_empty', 'ok ids=1234 same=No');
        Observer.Expect('v_quoted_empty', 'ok ids=4 same=Yes');
        Observer.Expect('v_011524', 'ok ids=1 same=No');
        Observer.Expect('v_slash_short', 'ok ids=1 same=Yes');
        Observer.Expect('v_iso', 'ok ids=1 same=No');
        Observer.Expect('v_text', 'error:The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|InvalidFilterExpression:Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure P132_SetFilter_Guid_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        GuidFilter(Observer, 'f_empty', '');
        GuidFilter(Observer, 'f_quoted_empty', '''''');
        GuidFilter(Observer, 'f_space', ' ');
        GuidFilter(Observer, 'f_1M', '1M');
        GuidFilter(Observer, 'f_zero', '0');
        GuidFilter(Observer, 'f_null_guid', '{00000000-0000-0000-0000-000000000000}');
        GuidFilter(Observer, 'f_braces_upper', '{AAAAAAAA-0000-0000-0000-000000000001}');
        GuidFilter(Observer, 'f_braces_lower', '{aaaaaaaa-0000-0000-0000-000000000001}');
        GuidFilter(Observer, 'f_no_braces', 'AAAAAAAA-0000-0000-0000-000000000001');
        GuidFilter(Observer, 'f_no_braces_lower', 'aaaaaaaa-0000-0000-0000-000000000001');
        GuidFilter(Observer, 'f_no_dashes', 'AAAAAAAA000000000000000000000001');
        GuidFilter(Observer, 'f_short', 'AAAAAAAA');
        GuidFilter(Observer, 'f_text', 'abc');
        GuidFilter(Observer, 'f_not_empty', '<>''''');
        GuidFilter(Observer, 'f_not_null', '<>{00000000-0000-0000-0000-000000000000}');
        GuidFilter(Observer, 'f_star', '*');
        GuidFilter(Observer, 'f_wildcard', '{AAAAAAAA*');
        GuidFilter(Observer, 'f_or', '{AAAAAAAA-0000-0000-0000-000000000001}|{BBBBBBBB-0000-0000-0000-000000000002}');
        GuidFilter(Observer, 'f_range', '{AAAAAAAA-0000-0000-0000-000000000001}..{BBBBBBBB-0000-0000-0000-000000000002}');
        GuidFilter(Observer, 'f_gt', '>{AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_empty', 'ok ids=1234 filter=');
        Observer.Expect('f_quoted_empty', 'error:The filter "''''" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_space', 'ok ids=1234 filter=');
        Observer.Expect('f_1M', 'error:The filter "1M" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_zero', 'error:The filter "0" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_null_guid', 'ok ids=3 filter={00000000-0000-0000-0000-000000000000}');
        Observer.Expect('f_braces_upper', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_braces_lower', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_no_braces', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_no_braces_lower', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_no_dashes', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('f_short', 'error:The filter "AAAAAAAA" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_text', 'error:The filter "abc" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_not_empty', 'error:The filter "<>''''" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_not_null', 'ok ids=124 filter=<>{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('f_star', 'error:The filter "*" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_wildcard', 'error:The filter "{AAAAAAAA*" is not valid for the Gd field on the LT P132 Filter Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|Filter:CSide');
        Observer.Expect('f_or', 'ok ids=12 filter={AAAAAAAA-0000-0000-0000-000000000001}|{BBBBBBBB-0000-0000-0000-000000000002}');
        Observer.Expect('f_range', 'ok ids=12 filter={AAAAAAAA-0000-0000-0000-000000000001}..{BBBBBBBB-0000-0000-0000-000000000002}');
        Observer.Expect('f_gt', 'ok ids=24 filter=>{AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Verify();
    end;





    [Test]
    procedure P132_SetView_Guid_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        GuidView(Observer, 'v_empty', '');
        GuidView(Observer, 'v_quoted_empty', '''''');
        GuidView(Observer, 'v_1M', '1M');
        GuidView(Observer, 'v_zero', '0');
        GuidView(Observer, 'v_null_guid', '{00000000-0000-0000-0000-000000000000}');
        GuidView(Observer, 'v_braces_upper', '{AAAAAAAA-0000-0000-0000-000000000001}');
        GuidView(Observer, 'v_braces_lower', '{aaaaaaaa-0000-0000-0000-000000000001}');
        GuidView(Observer, 'v_no_braces', 'AAAAAAAA-0000-0000-0000-000000000001');
        GuidView(Observer, 'v_text', 'abc');
        GuidView(Observer, 'v_not_empty', '<>''''');
        GuidView(Observer, 'v_date_like', '011524');
        GuidView(Observer, 'v_iso_date_like', '2024-01-15');
        Observer.Expect('v_empty', 'ok ids=1234 filter===');
        Observer.Expect('v_quoted_empty', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_1M', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_zero', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_null_guid', 'ok ids=3 filter={00000000-0000-0000-0000-000000000000}');
        Observer.Expect('v_braces_upper', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('v_braces_lower', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('v_no_braces', 'ok ids=1 filter={AAAAAAAA-0000-0000-0000-000000000001}');
        Observer.Expect('v_text', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_not_empty', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_date_like', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Expect('v_iso_date_like', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidFilterExpression:InvalidGuidFormat');
        Observer.Verify();
    end;




}
