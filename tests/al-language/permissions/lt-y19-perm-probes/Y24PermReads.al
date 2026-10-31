// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y24PermObjects.al (91936-91978); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 (permission enforcement in stages), stage 2 probes, writer Y24:
//   P14 read shapes under a set without R on the table, with rows and on an empty table: Get of an existing and of a missing key,
//       Find('='), Find('-'), FindLast, FindSet + Next, IsEmpty, CountApprox, CalcSums, SetLoadFields + FindFirst, RecordRef.FindFirst;
//   P15 FlowField shapes: SetAutoCalcFields + FindFirst, CalcFormula Lookup, Exist, Sum and Count, a FlowField read through a TestPage
//       field, with r and with nothing on the CalcFormula table;
//   P19 ReadPermission and WritePermission with r, rimd, I, IM, IMD, RIMD and a set without the table, from the test and from a
//       codeunit whose Permissions property names the table (rimd).
// Shape (CpPermLeads.al): each case reseeds with no set assigned, assigns the set (Permissions Mock.Set: the set plus All Objects), runs ONE
//   operation inside asserterror that ends with the own error 'LT Y24 ok <result>', observes text and code, clears the assignment.
// Facts (BC 27.5, 28.5, 29.0): with rows, every read shape fails with Read (DB:ClientReadDenied), except CalcSums, which fails with
//   IndirectRead, and Get of a missing key, which raises RecordNotFound. On an empty table no shape raises a permission error. A
//   FlowField read by SetAutoCalcFields + FindFirst works with nothing on the CalcFormula table; CalcFields of Lookup, Exist, Sum and
//   Count fails with IndirectRead; a TestPage control showing that FlowField is not on the page ("The field with ID = n is not found
//   on the page."). With r on the CalcFormula table everything works. ReadPermission needs R (r only inside an object whose Permissions
//   property names the table); WritePermission needs I, M and D together (IMD: Yes; I or IM: No), r/i/m/d inside such an object.
// BC versions: 27, 28, 29

codeunit 91975 "LT Y24 Perm Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y24 Perm Helper";
        Y19Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y24_P14_ReadShapesWithRows()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP14(Observer, 'rows_', false);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('rows_get_existing|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_get_existing|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_get_missing|text', 'The LT Y24 Row does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('rows_get_missing|code', 'DB:RecordNotFound');
        Observer.Expect('rows_find_eq|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_find_eq|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_find_minus|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_find_minus|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_findlast|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_findlast|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_findset_next|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_findset_next|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_isempty|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_isempty|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_countapprox|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_countapprox|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_calcsums|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('rows_calcsums|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_setloadfields_findfirst|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_setloadfields_findfirst|code', 'DB:ClientReadDenied');
        Observer.Expect('rows_recref_findfirst|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests)');
        Observer.Expect('rows_recref_findfirst|code', 'DB:ClientReadDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y24_P14_ReadShapesEmptyTable()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP14(Observer, 'empty_', true);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('empty_get_existing|text', 'The LT Y24 Row does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('empty_get_existing|code', 'DB:RecordNotFound');
        Observer.Expect('empty_get_missing|text', 'The LT Y24 Row does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('empty_get_missing|code', 'DB:RecordNotFound');
        Observer.Expect('empty_find_eq|text', 'LT Y24 ok No');
        Observer.Expect('empty_find_eq|code', 'Dialog');
        Observer.Expect('empty_find_minus|text', 'LT Y24 ok No 0');
        Observer.Expect('empty_find_minus|code', 'Dialog');
        Observer.Expect('empty_findlast|text', 'LT Y24 ok No 0');
        Observer.Expect('empty_findlast|code', 'Dialog');
        Observer.Expect('empty_findset_next|text', 'LT Y24 ok findset No');
        Observer.Expect('empty_findset_next|code', 'Dialog');
        Observer.Expect('empty_isempty|text', 'LT Y24 ok Yes');
        Observer.Expect('empty_isempty|code', 'Dialog');
        Observer.Expect('empty_countapprox|text', 'LT Y24 ok Yes');
        Observer.Expect('empty_countapprox|code', 'Dialog');
        Observer.Expect('empty_calcsums|text', 'LT Y24 ok 0');
        Observer.Expect('empty_calcsums|code', 'Dialog');
        Observer.Expect('empty_setloadfields_findfirst|text', 'LT Y24 ok No 0');
        Observer.Expect('empty_setloadfields_findfirst|code', 'Dialog');
        Observer.Expect('empty_recref_findfirst|text', 'LT Y24 ok No');
        Observer.Expect('empty_recref_findfirst|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y24_P15_FlowFieldsNothingOnSource()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP15(Observer, 'none_', 'LT Y24 FF Parent R');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('none_autocalc_findfirst|text', 'LT Y24 ok Yes 12');
        Observer.Expect('none_autocalc_findfirst|code', 'Dialog');
        Observer.Expect('none_calc_lookup|text', 'Sorry, the current permissions prevented the action. (TableData 91937 LT Y24 FF Child IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('none_calc_lookup|code', 'DB:ClientReadDenied');
        Observer.Expect('none_calc_exist|text', 'Sorry, the current permissions prevented the action. (TableData 91937 LT Y24 FF Child IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('none_calc_exist|code', 'DB:ClientReadDenied');
        Observer.Expect('none_calc_sum|text', 'Sorry, the current permissions prevented the action. (TableData 91937 LT Y24 FF Child IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('none_calc_sum|code', 'DB:ClientReadDenied');
        Observer.Expect('none_calc_count|text', 'Sorry, the current permissions prevented the action. (TableData 91937 LT Y24 FF Child IndirectRead: AL Language Coverage Tests)');
        Observer.Expect('none_calc_count|code', 'DB:ClientReadDenied');
        Observer.Expect('none_testpage_field|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('none_testpage_field|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y24_P15_FlowFieldsIndirectReadOnSource()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP15(Observer, 'indr_', 'LT Y24 FF Child Ind');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('indr_autocalc_findfirst|text', 'LT Y24 ok Yes 12');
        Observer.Expect('indr_autocalc_findfirst|code', 'Dialog');
        Observer.Expect('indr_calc_lookup|text', 'LT Y24 ok 5');
        Observer.Expect('indr_calc_lookup|code', 'Dialog');
        Observer.Expect('indr_calc_exist|text', 'LT Y24 ok Yes');
        Observer.Expect('indr_calc_exist|code', 'Dialog');
        Observer.Expect('indr_calc_sum|text', 'LT Y24 ok 12');
        Observer.Expect('indr_calc_sum|code', 'Dialog');
        Observer.Expect('indr_calc_count|text', 'LT Y24 ok 2');
        Observer.Expect('indr_calc_count|code', 'Dialog');
        Observer.Expect('indr_testpage_field|text', 'LT Y24 ok 12');
        Observer.Expect('indr_testpage_field|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y24_P19_ReadWritePermission()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP19(Observer, 'none', 'LT Y24 None');
        RunP19(Observer, 'ind_r', 'LT Y24 Ind R');
        RunP19(Observer, 'ind_rimd', 'LT Y24 Ind RIMD');
        RunP19(Observer, 'i', 'LT Y24 I');
        RunP19(Observer, 'im', 'LT Y24 IM');
        RunP19(Observer, 'imd', 'LT Y24 IMD');
        RunP19(Observer, 'rimd', 'LT Y24 RIMD');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Expect('none|test', 'No/No');
        Observer.Expect('none|object_rimd', 'No/No');
        Observer.Expect('ind_r|test', 'No/No');
        Observer.Expect('ind_r|object_rimd', 'Yes/No');
        Observer.Expect('ind_rimd|test', 'No/No');
        Observer.Expect('ind_rimd|object_rimd', 'Yes/Yes');
        Observer.Expect('i|test', 'No/No');
        Observer.Expect('i|object_rimd', 'No/No');
        Observer.Expect('im|test', 'No/No');
        Observer.Expect('im|object_rimd', 'No/No');
        Observer.Expect('imd|test', 'No/Yes');
        Observer.Expect('imd|object_rimd', 'No/Yes');
        Observer.Expect('rimd|test', 'Yes/Yes');
        Observer.Expect('rimd|object_rimd', 'Yes/Yes');
        Observer.Verify();
    end;

    local procedure RunP14(var Observer: Codeunit "Probe Observer"; Prefix: Text; Empty: Boolean)
    begin
        RunCase(Observer, Prefix + 'get_existing', 'LT Y24 None', 1, Empty);
        RunCase(Observer, Prefix + 'get_missing', 'LT Y24 None', 2, Empty);
        RunCase(Observer, Prefix + 'find_eq', 'LT Y24 None', 3, Empty);
        RunCase(Observer, Prefix + 'find_minus', 'LT Y24 None', 4, Empty);
        RunCase(Observer, Prefix + 'findlast', 'LT Y24 None', 5, Empty);
        RunCase(Observer, Prefix + 'findset_next', 'LT Y24 None', 6, Empty);
        RunCase(Observer, Prefix + 'isempty', 'LT Y24 None', 7, Empty);
        RunCase(Observer, Prefix + 'countapprox', 'LT Y24 None', 8, Empty);
        RunCase(Observer, Prefix + 'calcsums', 'LT Y24 None', 9, Empty);
        RunCase(Observer, Prefix + 'setloadfields_findfirst', 'LT Y24 None', 10, Empty);
        RunCase(Observer, Prefix + 'recref_findfirst', 'LT Y24 None', 11, Empty);
    end;

    local procedure RunP15(var Observer: Codeunit "Probe Observer"; Prefix: Text; SetName: Code[20])
    begin
        RunCase(Observer, Prefix + 'autocalc_findfirst', SetName, 21, false);
        RunCase(Observer, Prefix + 'calc_lookup', SetName, 22, false);
        RunCase(Observer, Prefix + 'calc_exist', SetName, 23, false);
        RunCase(Observer, Prefix + 'calc_sum', SetName, 24, false);
        RunCase(Observer, Prefix + 'calc_count', SetName, 25, false);
        RunCase(Observer, Prefix + 'testpage_field', SetName, 26, false);
    end;

    local procedure RunP19(var Observer: Codeunit "Probe Observer"; Tag: Text; SetName: Code[20])
    var
        Row: Record "LT Y24 Row";
        Reader: Codeunit "LT Y24 Perm Reader";
    begin
        Mock.ClearAssignments();
        Mock.Set(SetName);
        Observer.Observe(Tag + '|test', Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
        Observer.Observe(Tag + '|object_rimd', Reader.ReadWrite());
        Mock.ClearAssignments();
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer; Empty: Boolean)
    begin
        Mock.ClearAssignments();
        if Empty then
            Helper.SeedEmpty()
        else
            Helper.Seed();
        Mock.Set(SetName);
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y24 Row";
        Parent: Record "LT Y24 FF Parent";
        Card: TestPage "LT Y24 FF Parent Card";
        RecRef: RecordRef;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    Row.Get(1);
                    Result := 'value ' + Format(Row.Value);
                end;
            2:
                begin
                    Row.Get(99);
                    Result := 'value ' + Format(Row.Value);
                end;
            3:
                begin
                    Row.Id := 1;
                    Result := Format(Row.Find('='));
                end;
            4:
                Result := Format(Row.Find('-')) + ' ' + Format(Row.Id);
            5:
                Result := Format(Row.FindLast()) + ' ' + Format(Row.Id);
            6:
                if Row.FindSet() then
                    Result := 'next ' + Format(Row.Next()) + ' ' + Format(Row.Id)
                else
                    Result := 'findset No';
            7:
                Result := Format(Row.IsEmpty());
            8:
                Result := Format(Row.CountApprox() >= 0);
            9:
                begin
                    Row.CalcSums(Value);
                    Result := Format(Row.Value);
                end;
            10:
                begin
                    Row.SetLoadFields(Value);
                    Result := Format(Row.FindFirst()) + ' ' + Format(Row.Value);
                end;
            11:
                begin
                    RecRef.Open(Database::"LT Y24 Row");
                    Result := Format(RecRef.FindFirst());
                end;
            21:
                begin
                    Parent.SetAutoCalcFields(SumAmount);
                    Result := Format(Parent.FindFirst()) + ' ' + Format(Parent.SumAmount);
                end;
            22:
                begin
                    Parent.Get(1);
                    Parent.CalcFields(LookupAmount);
                    Result := Format(Parent.LookupAmount);
                end;
            23:
                begin
                    Parent.Get(1);
                    Parent.CalcFields(HasChild);
                    Result := Format(Parent.HasChild);
                end;
            24:
                begin
                    Parent.Get(1);
                    Parent.CalcFields(SumAmount);
                    Result := Format(Parent.SumAmount);
                end;
            25:
                begin
                    Parent.Get(1);
                    Parent.CalcFields(CountChild);
                    Result := Format(Parent.CountChild);
                end;
            26:
                begin
                    Card.OpenView();
                    Parent.Id := 1;
                    Card.GoToRecord(Parent);
                    Result := Card.SumCtl.Value();
                    Card.Close();
                end;
        end;
        Error('LT Y24 ok %1', Result);
    end;
}
