// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: blank option members of a table field (OptionMembers with " ", "" and an unquoted empty member at the first, middle and last position), with and without an OptionCaption:
//        Format, FieldRef.Value, OptionMembers, OptionCaption, OptionString, EnumValueCount, GetEnumValueName, GetEnumValueCaption, Evaluate and FieldRef.Value assignment of '' and ' ', SetFilter and SetRange.
// BC versions: 27, 28, 29

codeunit 67804 "LT OB Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Nul(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 0;
        T := '';
        T += C;
        exit(T);
    end;

    local procedure Desc(T: Text): Text
    var
        i: Integer;
        Code: Integer;
        R: Text;
    begin
        R := '[' + T + ']' + Format(StrLen(T));
        if StrLen(T) > 0 then begin
            R += ':';
            for i := 1 to StrLen(T) do begin
                if i > 4 then
                    break;
                Code := T[i];
                if i > 1 then
                    R += ',';
                R += Format(Code);
            end;
        end;
        exit(R);
    end;


    [TryFunction]
    local procedure TryInfo(var FR: FieldRef; What: Integer; Index: Integer; var Res: Text)
    begin
        case What of
            1:
                Res := FR.OptionMembers();
            2:
                Res := FR.OptionCaption();
            3:
                Res := Format(FR.EnumValueCount());
            4:
                Res := FR.GetEnumValueName(Index);
            5:
                Res := FR.GetEnumValueCaption(Index);
            6:
                Res := FR.OptionString();
        end;
    end;

    local procedure Info(var FR: FieldRef; What: Integer; Index: Integer): Text
    var
        Res: Text;
    begin
        Res := '';
        ClearLastError();
        if TryInfo(FR, What, Index, Res) then
            exit('[' + Res + ']');
        exit('err:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;


    [Test]
    procedure OptionBlank_FS_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[ ]1:32');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[ ]1:32');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[ ,A,B]');
        Observer.Expect('caption', '[ ,A,B]');
        Observer.Expect('string', '[ ,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[ ]');
        Observer.Expect('cap1', '[ ]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[ ,A,B]');
        Observer.Expect('caption', '[Blank0,A,B]');
        Observer.Expect('string', '[ ,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[ ]');
        Observer.Expect('cap1', '[Blank0]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FS";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FS";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetFS(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFS(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        R.SetRange(Opt, R.Opt::" ");
        Observer.Observe('rng_o0', Format(R.Count()) + '|' + OrdsFS(R) + '|' + R.GetFilter(Opt));
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row FS table. ''" "'' is not an option. The existing options are:  ,A,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row FS table. ''""'' is not an option. The existing options are:  ,A,B');
        Observer.Expect('flt_z', 'ok|1|0,|'' ''');
        Observer.Expect('flt_A', 'ok|1|1,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row FS table. A value is expected after the ''<>''.');
        Observer.Expect('rng_o0', '1|0,|'' ''');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[ ]1:32');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[ ]1:32');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A, ,B]');
        Observer.Expect('caption', '[A, ,B]');
        Observer.Expect('string', '[A, ,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[ ]');
        Observer.Expect('cap2', '[ ]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A, ,B]');
        Observer.Expect('caption', '[A,Blank1,B]');
        Observer.Expect('string', '[A, ,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[ ]');
        Observer.Expect('cap2', '[Blank1]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MS";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'Yes|1');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'Yes|1');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'Yes|1');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'Yes|1');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MS";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetMS(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMS(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        R.SetRange(Opt, R.Opt::" ");
        Observer.Observe('rng_o1', Format(R.Count()) + '|' + OrdsMS(R) + '|' + R.GetFilter(Opt));
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row MS table. ''" "'' is not an option. The existing options are: A, ,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row MS table. ''""'' is not an option. The existing options are: A, ,B');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row MS table. A value is expected after the ''<>''.');
        Observer.Expect('rng_o1', '1|1,|'' ''');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[ ]1:32');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[ ]1:32');
        Observer.Expect('members', '[A,B, ]');
        Observer.Expect('caption', '[A,B, ]');
        Observer.Expect('string', '[A,B, ]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[ ]');
        Observer.Expect('cap3', '[ ]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LS";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[Blank2]6:66,108,97,110');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[Blank2]6:66,108,97,110');
        Observer.Expect('members', '[A,B, ]');
        Observer.Expect('caption', '[A,B,Blank2]');
        Observer.Expect('string', '[A,B, ]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[ ]');
        Observer.Expect('cap3', '[Blank2]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LS";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LS";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetLS(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLS(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        R.SetRange(Opt, R.Opt::" ");
        Observer.Observe('rng_o2', Format(R.Count()) + '|' + OrdsLS(R) + '|' + R.GetFilter(Opt));
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row LS table. ''" "'' is not an option. The existing options are: A,B, ');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row LS table. ''""'' is not an option. The existing options are: A,B, ');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row LS table. A value is expected after the ''<>''.');
        Observer.Expect('rng_o2', '1|2,|'' ''');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[0]1:48');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[0]1:48');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[,A,B]');
        Observer.Expect('caption', '[,A,B]');
        Observer.Expect('string', '[,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[,A,B]');
        Observer.Expect('caption', '[Blank0,A,B]');
        Observer.Expect('string', '[,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[Blank0]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FQ";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FQ";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFQ(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsFQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row FQ table. ''" "'' is not an option. The existing options are: ,A,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row FQ table. ''""'' is not an option. The existing options are: ,A,B');
        Observer.Expect('flt_z', 'ok|1|0,|0');
        Observer.Expect('flt_A', 'ok|1|1,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row FQ table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[1]1:49');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[1]1:49');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A,,B]');
        Observer.Expect('caption', '[A,,B]');
        Observer.Expect('string', '[A,,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[]');
        Observer.Expect('cap2', '[]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A,,B]');
        Observer.Expect('caption', '[A,Blank1,B]');
        Observer.Expect('string', '[A,,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[]');
        Observer.Expect('cap2', '[Blank1]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MQ";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MQ";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMQ(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsMQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row MQ table. ''" "'' is not an option. The existing options are: A,,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row MQ table. ''""'' is not an option. The existing options are: A,,B');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row MQ table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[2]1:50');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[2]1:50');
        Observer.Expect('members', '[A,B,]');
        Observer.Expect('caption', '[A,B,]');
        Observer.Expect('string', '[A,B,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LQ";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[Blank2]6:66,108,97,110');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[Blank2]6:66,108,97,110');
        Observer.Expect('members', '[A,B,]');
        Observer.Expect('caption', '[A,B,Blank2]');
        Observer.Expect('string', '[A,B,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[Blank2]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LQ";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LQ";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLQ(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsLQ(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row LQ table. ''" "'' is not an option. The existing options are: A,B,');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row LQ table. ''""'' is not an option. The existing options are: A,B,');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row LQ table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[0]1:48');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[0]1:48');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[,A,B]');
        Observer.Expect('caption', '[,A,B]');
        Observer.Expect('string', '[,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[,A,B]');
        Observer.Expect('caption', '[Blank0,A,B]');
        Observer.Expect('string', '[,A,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[Blank0]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FU";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row FU";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetFU(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetFU(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsFU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row FU table. ''" "'' is not an option. The existing options are: ,A,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row FU table. ''""'' is not an option. The existing options are: ,A,B');
        Observer.Expect('flt_z', 'ok|1|0,|0');
        Observer.Expect('flt_A', 'ok|1|1,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row FU table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[1]1:49');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[1]1:49');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A,,B]');
        Observer.Expect('caption', '[A,,B]');
        Observer.Expect('string', '[A,,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[]');
        Observer.Expect('cap2', '[]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[Blank1]6:66,108,97,110');
        Observer.Expect('fmt2', '[B]1:66');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[B]1:66');
        Observer.Expect('members', '[A,,B]');
        Observer.Expect('caption', '[A,Blank1,B]');
        Observer.Expect('string', '[A,,B]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[]');
        Observer.Expect('cap2', '[Blank1]');
        Observer.Expect('name3', '[B]');
        Observer.Expect('cap3', '[B]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MU";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row MU";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetMU(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetMU(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsMU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row MU table. ''" "'' is not an option. The existing options are: A,,B');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row MU table. ''""'' is not an option. The existing options are: A,,B');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row MU table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[2]1:50');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[2]1:50');
        Observer.Expect('members', '[A,B,]');
        Observer.Expect('caption', '[A,B,]');
        Observer.Expect('string', '[A,B,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LU";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[A]1:65');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[A]1:65');
        Observer.Expect('fmt1', '[B]1:66');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[B]1:66');
        Observer.Expect('fmt2', '[Blank2]6:66,108,97,110');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[Blank2]6:66,108,97,110');
        Observer.Expect('members', '[A,B,]');
        Observer.Expect('caption', '[A,B,Blank2]');
        Observer.Expect('string', '[A,B,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[A]');
        Observer.Expect('cap1', '[A]');
        Observer.Expect('name2', '[B]');
        Observer.Expect('cap2', '[B]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[Blank2]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LU";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row LU";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetLU(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetLU(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsLU(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row LU table. ''" "'' is not an option. The existing options are: A,B,');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row LU table. ''""'' is not an option. The existing options are: A,B,');
        Observer.Expect('flt_z', 'ok|1|0,|A');
        Observer.Expect('flt_A', 'ok|1|0,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row LU table. A value is expected after the ''<>''.');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS1";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[ ]1:32');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[ ]1:32');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[2]1:50');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[2]1:50');
        Observer.Expect('members', '[ ,A,]');
        Observer.Expect('caption', '[ ,A,]');
        Observer.Expect('string', '[ ,A,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[ ]');
        Observer.Expect('cap1', '[ ]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS1";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[Blank2]6:66,108,97,110');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[Blank2]6:66,108,97,110');
        Observer.Expect('members', '[ ,A,]');
        Observer.Expect('caption', '[Blank0,A,Blank2]');
        Observer.Expect('string', '[ ,A,]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[ ]');
        Observer.Expect('cap1', '[Blank0]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[]');
        Observer.Expect('cap3', '[Blank2]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS1";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS1";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS1(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        R.SetRange(Opt, R.Opt::" ");
        Observer.Observe('rng_o0', Format(R.Count()) + '|' + OrdsQS1(R) + '|' + R.GetFilter(Opt));
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row QS1 table. ''" "'' is not an option. The existing options are:  ,A,');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row QS1 table. ''""'' is not an option. The existing options are:  ,A,');
        Observer.Expect('flt_z', 'ok|1|0,|'' ''');
        Observer.Expect('flt_A', 'ok|1|1,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row QS1 table. A value is expected after the ''<>''.');
        Observer.Expect('rng_o0', '1|0,|'' ''');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Field_ReadPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS2";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.Opt := 0;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt0', Desc(Format(R.Opt)));
        Observer.Observe('fmt0_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.Opt := 1;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt1', Desc(Format(R.Opt)));
        Observer.Observe('fmt1_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.Opt := 2;
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('fmt2', Desc(Format(R.Opt)));
        Observer.Observe('fmt2_9', Desc(Format(R.Opt, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(2);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[0]1:48');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[0]1:48');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[ ]1:32');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[ ]1:32');
        Observer.Expect('members', '[,A, ]');
        Observer.Expect('caption', '[,A, ]');
        Observer.Expect('string', '[,A, ]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[ ]');
        Observer.Expect('cap3', '[ ]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Field_ReadCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS2";
        RR: RecordRef;
        FR: FieldRef;
        k: Integer;
    begin
        R.DeleteAll();
        R.Init();
        R.PK := 1;
        R.OptCap := 0;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt0', Desc(Format(R.OptCap)));
        Observer.Observe('fmt0_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv0', Desc(Format(FR.Value)));
        R.OptCap := 1;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt1', Desc(Format(R.OptCap)));
        Observer.Observe('fmt1_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv1', Desc(Format(FR.Value)));
        R.OptCap := 2;
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('fmt2', Desc(Format(R.OptCap)));
        Observer.Observe('fmt2_9', Desc(Format(R.OptCap, 0, 9)));
        Observer.Observe('frv2', Desc(Format(FR.Value)));
        RR.GetTable(R);
        FR := RR.Field(3);
        Observer.Observe('members', Info(FR, 1, 0));
        Observer.Observe('caption', Info(FR, 2, 0));
        Observer.Observe('string', Info(FR, 6, 0));
        Observer.Observe('count', Info(FR, 3, 0));
        Observer.Observe('name0', Info(FR, 4, 0));
        Observer.Observe('cap0', Info(FR, 5, 0));
        Observer.Observe('name1', Info(FR, 4, 1));
        Observer.Observe('cap1', Info(FR, 5, 1));
        Observer.Observe('name2', Info(FR, 4, 2));
        Observer.Observe('cap2', Info(FR, 5, 2));
        Observer.Observe('name3', Info(FR, 4, 3));
        Observer.Observe('cap3', Info(FR, 5, 3));
        Observer.Expect('fmt0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt0_9', '[0]1:48');
        Observer.Expect('frv0', '[Blank0]6:66,108,97,110');
        Observer.Expect('fmt1', '[A]1:65');
        Observer.Expect('fmt1_9', '[1]1:49');
        Observer.Expect('frv1', '[A]1:65');
        Observer.Expect('fmt2', '[Blank2]6:66,108,97,110');
        Observer.Expect('fmt2_9', '[2]1:50');
        Observer.Expect('frv2', '[Blank2]6:66,108,97,110');
        Observer.Expect('members', '[,A, ]');
        Observer.Expect('caption', '[Blank0,A,Blank2]');
        Observer.Expect('string', '[,A, ]');
        Observer.Expect('count', '[3]');
        Observer.Expect('name0', '[]');
        Observer.Expect('cap0', '[]');
        Observer.Expect('name1', '[]');
        Observer.Expect('cap1', '[Blank0]');
        Observer.Expect('name2', '[A]');
        Observer.Expect('cap2', '[A]');
        Observer.Expect('name3', '[ ]');
        Observer.Expect('cap3', '[Blank2]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Field_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS2";
        RR: RecordRef;
        FR: FieldRef;
    begin
        R.Opt := 3;
        Observer.Observe('ev_empty', Format(Evaluate(R.Opt, '')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, '') then begin
            RR.SetTable(R);
            Observer.Observe('fr_empty', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_sp', Format(Evaluate(R.Opt, ' ')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, ' ') then begin
            RR.SetTable(R);
            Observer.Observe('fr_sp', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Opt := 3;
        Observer.Observe('ev_A', Format(Evaluate(R.Opt, 'A')) + '|' + Format(R.Opt, 0, 2));
        R.Opt := 3;
        RR.GetTable(R);
        FR := RR.Field(2);
        ClearLastError();
        if TryAssign(FR, 'A') then begin
            RR.SetTable(R);
            Observer.Observe('fr_A', 'ok|' + Format(R.Opt, 0, 2));
        end else
            Observer.Observe('fr_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
#if BC28PLUS // assigning text to an Option FieldRef.Value raises NotSupportedType in BC 27 and an Evaluate:Format error from BC 28
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('fr_empty', 'err:Evaluate:Format:The value "" can''t be evaluated into type Option.');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('fr_sp', 'err:Evaluate:Format:The value " " can''t be evaluated into type Option.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:Evaluate:Format:The value "A" can''t be evaluated into type Option.');
#else
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('fr_empty', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('fr_sp', 'err:NotSupportedType:The type NavOption is unknown.');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('fr_A', 'err:NotSupportedType:The type NavOption is unknown.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Field_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT OB Row QS2";
        k: Integer;
    begin
        R.DeleteAll();
        for k := 1 to 3 do begin
            R.Init();
            R.PK := k;
            R.Opt := k - 1;
            R.Insert();
        end;
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, '') then
            Observer.Observe('flt_empty', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_empty', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, ' ') then
            Observer.Observe('flt_sp', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_sp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, '" "') then
            Observer.Observe('flt_qsp', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qsp', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, '""') then
            Observer.Observe('flt_qq', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_qq', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, '0') then
            Observer.Observe('flt_z', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_z', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, 'A') then
            Observer.Observe('flt_A', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_A', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        ClearLastError();
        if TrySetQS2(R, '<>' + ' ') then
            Observer.Observe('flt_neg', 'ok|' + Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt))
        else
            Observer.Observe('flt_neg', 'err:' + GetLastErrorCode() + ':' + GetLastErrorText());
        R.Reset();
        R.SetRange(Opt, R.Opt::" ");
        Observer.Observe('rng_o2', Format(R.Count()) + '|' + OrdsQS2(R) + '|' + R.GetFilter(Opt));
        Observer.Expect('flt_empty', 'ok|3|0,1,2,|');
        Observer.Expect('flt_sp', 'ok|3|0,1,2,|');
        Observer.Expect('flt_qsp', 'err:Filter:CSide:The filter "" "" is not valid for the Opt field on the LT OB Row QS2 table. ''" "'' is not an option. The existing options are: ,A, ');
        Observer.Expect('flt_qq', 'err:Filter:CSide:The filter """" is not valid for the Opt field on the LT OB Row QS2 table. ''""'' is not an option. The existing options are: ,A, ');
        Observer.Expect('flt_z', 'ok|1|0,|0');
        Observer.Expect('flt_A', 'ok|1|1,|A');
        Observer.Expect('flt_neg', 'err:Filter:CSide:The filter "<> " is not valid for the Opt field on the LT OB Row QS2 table. A value is expected after the ''<>''.');
        Observer.Expect('rng_o2', '1|2,|'' ''');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAssign(var FR: FieldRef; Txt: Text)
    begin
        FR.Value := Txt;
    end;

    [TryFunction]
    local procedure TrySetFS(var R: Record "LT OB Row FS"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsFS(var R: Record "LT OB Row FS"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetMS(var R: Record "LT OB Row MS"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsMS(var R: Record "LT OB Row MS"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetLS(var R: Record "LT OB Row LS"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsLS(var R: Record "LT OB Row LS"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetFQ(var R: Record "LT OB Row FQ"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsFQ(var R: Record "LT OB Row FQ"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetMQ(var R: Record "LT OB Row MQ"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsMQ(var R: Record "LT OB Row MQ"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetLQ(var R: Record "LT OB Row LQ"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsLQ(var R: Record "LT OB Row LQ"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetFU(var R: Record "LT OB Row FU"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsFU(var R: Record "LT OB Row FU"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetMU(var R: Record "LT OB Row MU"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsMU(var R: Record "LT OB Row MU"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetLU(var R: Record "LT OB Row LU"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsLU(var R: Record "LT OB Row LU"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetQS1(var R: Record "LT OB Row QS1"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsQS1(var R: Record "LT OB Row QS1"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetQS2(var R: Record "LT OB Row QS2"; Txt: Text)
    begin
        R.SetFilter(Opt, Txt);
    end;

    local procedure OrdsQS2(var R: Record "LT OB Row QS2"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Opt, 0, 2) + ',';
            until R.Next() = 0;
        exit(T);
    end;

}
