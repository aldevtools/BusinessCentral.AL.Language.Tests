// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject has scope OnPrem).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 99470-99474
// Probe: corpus issue 652 item 16, writer AZ: the exception class of more error kinds, ToString of an exception raised below OnRun
// (in a nested procedure and in another codeunit), and Equals between a last-error exception and objects that are not exceptions.
// Already pinned: lt-dotnet-interop/GetLastErrorObjectKinds.al (TestField, Modify/Delete of a missing row, Evaluate, division by zero, Equals
// between two last-error exceptions).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtAzExc) { }
        type("System.Object"; LtAzObj) { }
        type("System.String"; LtAzString) { }
    }
}

table 99470 "LT AZ Lek Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[5]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 99471 "LT AZ Lek Deep"
{
    procedure Raise()
    begin
        Error('LT AZ deep error');
    end;
}

codeunit 99472 "LT AZ Lek Thrower"
{
    var
        Mode: Integer;

    trigger OnRun()
    var
        Row: Record "LT AZ Lek Row";
        Deep: Codeunit "LT AZ Lek Deep";
        Short: Text[3];
        Long: Text;
        Big: Integer;
        Info: ErrorInfo;
    begin
        case Mode of
            1:
                Nested();
            2:
                Deep.Raise();
            3:
                begin
                    Row.DeleteAll();
                    Row.Id := 1;
                    Row.Insert();
                    Row.Insert();
                end;
            4:
                begin
                    Long := 'abcdef';
                    Short := Long;
                end;
            5:
                begin
                    Big := 2147483647;
                    Big := Big + 1;
                end;
            6:
                begin
                    Row.Id := 7;
                    Row.FieldError(Name, 'is wrong');
                end;
            7:
                begin
                    Info.Message := 'LT AZ errorinfo without create';
                    Error(Info);
                end;
            8:
                Row.Get(-4242);
        end;
    end;

    local procedure Nested()
    begin
        Error('LT AZ nested error');
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 99473 "LT AZ Lek Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunMode(Mode: Integer; var Exc: DotNet LtAzExc; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Thrower: Codeunit "LT AZ Lek Thrower";
    begin
        Commit();
        Thrower.SetMode(Mode);
        Observer.Observe(Name + '_ran', Format(Thrower.Run()));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_text', GetLastErrorText());
        Exc := GetLastErrorObject();
        Observer.Observe(Name + '_class', Exc.GetType().FullName);
        Observer.Observe(Name + '_message', Exc.Message);
    end;

    [Test]
    procedure Kinds_ClassAndMessage()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(3, Exc, Observer, 'dupinsert');
        RunMode(4, Exc, Observer, 'textoverflow');
        RunMode(5, Exc, Observer, 'intoverflow');
        RunMode(6, Exc, Observer, 'fielderror');
        RunMode(7, Exc, Observer, 'errorinfo_nocreate');
        Observer.Expect('dupinsert_ran', 'No');
        Observer.Expect('dupinsert_code', 'DB:RecordExists');
        Observer.Expect('dupinsert_text', 'The record in table LT AZ Lek Row already exists. Identification fields and values: Id=''1''');
        Observer.Expect('dupinsert_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideDuplicateKeyException');
        Observer.Expect('dupinsert_message', 'The record in table LT AZ Lek Row already exists. Identification fields and values: Id=''1''');
        Observer.Expect('textoverflow_ran', 'No');
        Observer.Expect('textoverflow_code', 'StringLengthExceeded');
        Observer.Expect('textoverflow_text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('textoverflow_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLStringLengthExceededException');
        Observer.Expect('textoverflow_message', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('intoverflow_ran', 'No');
        Observer.Expect('intoverflow_code', 'AL:Overflow');
        Observer.Expect('intoverflow_text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('intoverflow_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException');
        Observer.Expect('intoverflow_message', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('fielderror_ran', 'No');
        Observer.Expect('fielderror_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_text', 'Name is wrong in LT AZ Lek Row Id=''7''.');
        Observer.Expect('fielderror_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideException');
        Observer.Expect('fielderror_message', 'Name is wrong in LT AZ Lek Row Id=''7''.');
        Observer.Expect('errorinfo_nocreate_ran', 'No');
        Observer.Expect('errorinfo_nocreate_code', 'Dialog');
        Observer.Expect('errorinfo_nocreate_text', 'LT AZ errorinfo without create');
        Observer.Expect('errorinfo_nocreate_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('errorinfo_nocreate_message', 'LT AZ errorinfo without create');
        Observer.Verify();
    end;

    [Test]
    procedure Kinds_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(8, Exc, Observer, 'getmissing');
        Observer.Expect('getmissing_ran', 'No');
        Observer.Expect('getmissing_code', 'DB:RecordNotFound');
        Observer.Expect('getmissing_text', 'The LT AZ Lek Row does not exist. Identification fields and values: Id=''-4242''');
        Observer.Expect('getmissing_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('getmissing_message', 'The LT AZ Lek Row does not exist. Identification fields and values: Id=''-4242''');
        Observer.Verify();
    end;

    [Test]
    procedure ToString_NestedProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(1, Exc, Observer, 'nested');
        Observer.Observe('nested_tostring', Exc.ToString());
        Observer.Observe('nested_format', Format(Exc));
        Observer.Expect('nested_ran', 'No');
        Observer.Expect('nested_code', 'Dialog');
        Observer.Expect('nested_text', 'LT AZ nested error');
        Observer.Expect('nested_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('nested_message', 'LT AZ nested error');
        Observer.Expect('nested_tostring', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT AZ nested error\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.Nested()\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.OnRunAsync(INavRecordHandle εrec)\n   at Microsoft.Dynamics.Nav.Runtime.NavCodeunit.DoRunAsync(DataError errorLevel, NavRecord record)');
        Observer.Expect('nested_format', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT AZ nested error\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.Nested()\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.OnRunAsync(INavRecordHandle εrec)\n   at Microsoft.Dynamics.Nav.Runtime.NavCodeunit.DoRunAsync(DataError errorLevel, NavRecord record)');
        Observer.Verify();
    end;

    [Test]
    procedure ToString_OtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(2, Exc, Observer, 'deep');
        Observer.Observe('deep_tostring', Exc.ToString());
        Observer.Expect('deep_ran', 'No');
        Observer.Expect('deep_code', 'Dialog');
        Observer.Expect('deep_text', 'LT AZ deep error');
        Observer.Expect('deep_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('deep_message', 'LT AZ deep error');
        // BC 29 adds the ValueTaskExtensions frame between the two codeunits; BC 27.5 and 28.5 do not.
#if BC29PLUS
        Observer.Expect('deep_tostring', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT AZ deep error\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99471.Raise()\n   at Microsoft.Dynamics.Nav.Types.ValueTaskExtensions.ManualResetValueTaskSource`1.GetResult(Int16 token)\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.OnRunAsync(INavRecordHandle εrec)\n   at Microsoft.Dynamics.Nav.Runtime.NavCodeunit.DoRunAsync(DataError errorLevel, NavRecord record)');
#else
        Observer.Expect('deep_tostring', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT AZ deep error\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99471.Raise()\n   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99472.OnRunAsync(INavRecordHandle εrec)\n   at Microsoft.Dynamics.Nav.Runtime.NavCodeunit.DoRunAsync(DataError errorLevel, NavRecord record)');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Equals_NonExceptionObjects()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
        Obj: DotNet LtAzObj;
        Str: DotNet LtAzString;
        Same: DotNet LtAzObj;
    begin
        RunMode(1, Exc, Observer, 'nested');
        Str := 'LT AZ nested error';
        Observer.Observe('equals_string_of_message', Format(Exc.Equals(Str)));
        Obj := Obj.Object();
        Observer.Observe('equals_new_object', Format(Exc.Equals(Obj)));
        Same := Exc;
        Observer.Observe('equals_self_as_object', Format(Exc.Equals(Same)));
        Observer.Observe('object_equals_exception', Format(Same.Equals(Exc)));
        Observer.Expect('nested_ran', 'No');
        Observer.Expect('nested_code', 'Dialog');
        Observer.Expect('nested_text', 'LT AZ nested error');
        Observer.Expect('nested_class', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('nested_message', 'LT AZ nested error');
        Observer.Expect('equals_string_of_message', 'No');
        Observer.Expect('equals_new_object', 'No');
        Observer.Expect('equals_self_as_object', 'Yes');
        Observer.Expect('object_equals_exception', 'Yes');
        Observer.Verify();
    end;
}
