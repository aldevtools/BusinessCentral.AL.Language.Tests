// Probe (observe only): the member names and ordinals of the platform options FieldType and IsolationLevel, read through Evaluate of an ordinal and Format.
// Settles docs/probes-needed.md row 115 (batch 4). Object id 68070.

codeunit 68070 "W4 Platform Option Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvalFieldType(Ordinal: Integer; var Result: Text)
    var
        FT: FieldType;
    begin
        Evaluate(FT, Format(Ordinal));
        Result := Format(FT, 0, 2);
    end;

    [TryFunction]
    local procedure TryEvalIsolation(Ordinal: Integer; var Result: Text)
    var
        IL: IsolationLevel;
    begin
        Evaluate(IL, Format(Ordinal));
        Result := Format(IL, 0, 2);
    end;

    [Test]
    procedure IsolationLevel_OrdinalsByEvaluate()
    var
        Result: Text;
        List: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        for i := 0 to 10 do begin
            if TryEvalIsolation(i, Result) then
                List += Format(i) + '=' + Result + ','
            else begin
                List += Format(i) + '=error:' + GetLastErrorText() + ',';
                ClearLastError();
            end;
        end;
        Observer.Observe('isolationlevel_by_ordinal', List);
        Observer.Expect('isolationlevel_by_ordinal', '0=Default,1=ReadUncommitted,2=ReadCommitted,3=RepeatableRead,4=UpdLock,5=error:''5'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,6=error:''6'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,7=error:''7'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,8=error:''8'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,9=error:''9'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,10=error:''10'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock,');
        Observer.Verify();
    end;

    [Test]
    procedure FieldType_FormatForms()
    var
        FT: FieldType;
        Observer: Codeunit "Probe Observer";
    begin
        FT := FieldType::Code;
        Observer.Observe('code_default', Format(FT));
        Observer.Observe('code_0_1', Format(FT, 0, 1));
        Observer.Observe('code_0_2', Format(FT, 0, 2));
        FT := FieldType::Integer;
        Observer.Observe('integer_0_1', Format(FT, 0, 1));
        FT := FieldType::BigInteger;
        Observer.Observe('biginteger_0_1', Format(FT, 0, 1));
        Observer.Expect('code_default', 'Code');
        Observer.Expect('code_0_1', 'Code');
        Observer.Expect('code_0_2', 'Code');
        Observer.Expect('integer_0_1', 'Integer');
        Observer.Expect('biginteger_0_1', 'BigInteger');
        Observer.Verify();
    end;
}
