// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject and DotNet have scope OnPrem).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; own objects 99320 - 99324
// Pinned (writer Y76): (1) al-runtime-rs assumption exception-tostring-stack-frames: every line of ToString and Format of the exception
// GetLastErrorObject answers after an error caught by a TryFunction, by asserterror, after Get of a missing row, after a division by zero and after a
// dialog error three procedures deep. (2) al-runtime-rs assumption dotnet-generic-result-type: WorkbookReader.GetWorksheetByName (a method that is
// generic only, its type parameter is its return type) assigned to a DotNet variable of the sheet type, of System.Object, to a Variant, used
// without assignment, and called through a property read.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtY76Exc) { }
        type("System.Object"; LtY76Obj) { }
    }
    assembly("Microsoft.Dynamics.Nav.OpenXml")
    {
        type("Microsoft.Dynamics.Nav.OpenXml.Spreadsheet.WorkbookReader"; LtY76WbReader) { }
        type("Microsoft.Dynamics.Nav.OpenXml.Spreadsheet.WorksheetReader"; LtY76WsReader) { }
    }
}

table 99320 "LT Y76 Lek Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 99321 "LT Y76 Lek Thrower"
{
    var
        Mode: Integer;

    trigger OnRun()
    var
        Row: Record "LT Y76 Lek Row";
        Zero: Integer;
        Result: Integer;
    begin
        case Mode of
            1:
                Level1();
            2:
                Row.Get(-4242);
            3:
                begin
                    Result := 1 div Zero;
                end;
        end;
    end;

    local procedure Level1()
    begin
        Level2();
    end;

    local procedure Level2()
    begin
        Level3();
    end;

    local procedure Level3()
    begin
        Error('LT Y76 three deep');
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 99322 "LT Y76 Lek Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryError()
    begin
        Error('LT Y76 try');
    end;

    [TryFunction]
    local procedure TryGetMissing()
    var
        Row: Record "LT Y76 Lek Row";
    begin
        Row.Get(-4242);
    end;

    [TryFunction]
    local procedure TryDivide()
    var
        Zero: Integer;
        Result: Integer;
    begin
        Result := 1 div Zero;
    end;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; ExpectedHead: Text; ExpectedFrame: Text)
    var
        Exc: DotNet LtY76Exc;
        Full: Text;
        Head: Text;
        Cr: Text[1];
        Lf: Text[1];
        P: Integer;
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Exc := GetLastErrorObject();
        Full := Exc.ToString();
        P := StrPos(Full, '   at ');
        Head := CopyStr(Full, 1, P - 1);
        Head := DelChr(Head, '=', Cr + Lf);
        Observer.Expect(Name + '_head', ExpectedHead);
        Observer.Observe(Name + '_head', Head);
        Observer.Expect(Name + '_frame', 'Yes');
        Observer.Observe(Name + '_frame', Format(StrPos(Full, ExpectedFrame) > 0));
        Observer.Expect(Name + '_format_equal', 'Yes');
        Observer.Observe(Name + '_format_equal', Format(Format(Exc) = Full));
    end;

    [Test]
    procedure Y76_TryFunction_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryError() then;
        Describe(Observer, 'try', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y76 try', 'Codeunit99322.TryError()');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Asserterror_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('LT Y76 assert');
        Describe(Observer, 'assert', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y76 assert', 'NavMethodScope.AssertErrorAsync');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_TryFunction_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryGetMissing() then;
        Describe(Observer, 'try_get', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException: The LT Y76 Lek Row does not exist. Identification fields and values: Id=''-4242''', 'Codeunit99322.TryGetMissing()');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Asserterror_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y76 Lek Row";
    begin
        asserterror Row.Get(-4242);
        Describe(Observer, 'assert_get', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException: The LT Y76 Lek Row does not exist. Identification fields and values: Id=''-4242''', 'NavMethodScope.AssertErrorAsync');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_TryFunction_Division()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryDivide() then;
        Describe(Observer, 'try_div', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero. ---> System.DivideByZeroException: Attempted to divide by zero.', 'Codeunit99322.TryDivide()');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Asserterror_Division()
    var
        Observer: Codeunit "Probe Observer";
        Zero: Integer;
        Result: Integer;
    begin
        asserterror Result := 1 div Zero;
        Describe(Observer, 'assert_div', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero. ---> System.DivideByZeroException: Attempted to divide by zero.', 'NavMethodScope.AssertErrorAsync');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_CodeunitRun_ThreeDeep_GetMissing_Division()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT Y76 Lek Thrower";
    begin
        Commit();
        Thrower.SetMode(1);
        if Thrower.Run() then;
        Describe(Observer, 'deep', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y76 three deep', 'Codeunit99321.Level1()');
        Thrower.SetMode(2);
        if Thrower.Run() then;
        Describe(Observer, 'run_get', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException: The LT Y76 Lek Row does not exist. Identification fields and values: Id=''-4242''', 'Codeunit99321.OnRunAsync');
        Thrower.SetMode(3);
        if Thrower.Run() then;
        Describe(Observer, 'run_div', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero. ---> System.DivideByZeroException: Attempted to divide by zero.', 'Codeunit99321.OnRunAsync');
        Observer.Verify();
    end;
}

codeunit 99323 "LT Y76 Generic Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BuildBook(var TempBlob: Codeunit "Temp Blob")
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        OutS: OutStream;
    begin
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.CreateNewBook('Sheet1');
        TempExcelBuffer.EnterCell(TempExcelBuffer, 1, 1, 'Test', false, false, false);
        TempExcelBuffer.WriteSheet('', '', '');
        TempBlob.CreateOutStream(OutS);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SaveToStream(OutS, true);
    end;

    [Test]
    procedure Y76_GetWorksheetByName_AssignedToSheetType()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Reader: DotNet LtY76WbReader;
        Sheet: DotNet LtY76WsReader;
    begin
        BuildBook(TempBlob);
        TempBlob.CreateInStream(InS);
        Reader := Reader.Open(InS);
        Observer.Expect('has sheet', 'Yes');
        Observer.Observe('has sheet', Format(Reader.HasWorksheet('Sheet1')));
        Sheet := Reader.GetWorksheetByName('Sheet1');
        Observer.Expect('sheet is null', 'No');
        Observer.Observe('sheet is null', Format(IsNull(Sheet)));
        Observer.Expect('sheet name', 'Sheet1');
        Observer.Observe('sheet name', Sheet.Name);
        Observer.Verify();
    end;

    [Test]
    procedure Y76_GetWorksheetByName_OtherTargets()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Reader: DotNet LtY76WbReader;
        AsObject: DotNet LtY76Obj;
        AsVariant: Variant;
    begin
        BuildBook(TempBlob);
        TempBlob.CreateInStream(InS);
        Reader := Reader.Open(InS);
        Observer.Expect('to object', 'ok null=No');
        Observer.Expect('to variant', 'ok');
        Observer.Expect('is null call', 'ok');
        Observer.Expect('statement', 'ok');
        Observer.Expect('missing sheet', 'E[A call to Microsoft.Dynamics.Nav.OpenXml.Spreadsheet.WorkbookReader.GetWorksheetByName failed with this message: The worksheet cannot be found. (Parameter ''NoSuchSheet'')|DotNetInvoke:Argument]');
        ClearLastError();
        if TryAssignObject(Reader, AsObject) then
            Observer.Observe('to object', 'ok null=' + Format(IsNull(AsObject)))
        else
            Observer.Observe('to object', 'E[' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        if TryAssignVariant(Reader, AsVariant) then
            Observer.Observe('to variant', 'ok')
        else
            Observer.Observe('to variant', 'E[' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        if TryIsNull(Reader) then
            Observer.Observe('is null call', 'ok')
        else
            Observer.Observe('is null call', 'E[' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        if TryStatement(Reader) then
            Observer.Observe('statement', 'ok')
        else
            Observer.Observe('statement', 'E[' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        if TryMissing(Reader) then
            Observer.Observe('missing sheet', 'ok')
        else
            Observer.Observe('missing sheet', 'E[' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ']');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAssignObject(var Reader: DotNet LtY76WbReader; var Target: DotNet LtY76Obj)
    begin
        Target := Reader.GetWorksheetByName('Sheet1');
    end;

    [TryFunction]
    local procedure TryAssignVariant(var Reader: DotNet LtY76WbReader; var Target: Variant)
    begin
        Target := Reader.GetWorksheetByName('Sheet1');
    end;

    [TryFunction]
    local procedure TryIsNull(var Reader: DotNet LtY76WbReader)
    begin
        if IsNull(Reader.GetWorksheetByName('Sheet1')) then
            exit;
    end;

    [TryFunction]
    local procedure TryStatement(var Reader: DotNet LtY76WbReader)
    begin
        Reader.GetWorksheetByName('Sheet1');
    end;

    [TryFunction]
    local procedure TryMissing(var Reader: DotNet LtY76WbReader)
    var
        Sheet: DotNet LtY76WsReader;
    begin
        Sheet := Reader.GetWorksheetByName('NoSuchSheet');
    end;
}
