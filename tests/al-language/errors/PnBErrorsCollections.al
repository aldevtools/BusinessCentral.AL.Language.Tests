// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), PnBObjects.al (tables 70527, log 70531), self-contained codeunits 70550-70553; writer RO: tests RO_* in 70550
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//   70550: "ErrorInfo | ErrorType() before one was set is refused..." (153); "ErrorInfo | ErrorInfo.Create with 3 arguments..." (154);
//          "Error collection | the scope-exit text for several collected errors is Multiple errors occurred..." (194)
//   70551: "Collection errors | Dictionary.Get(Key) (value form) of a missing key says..." (197);
//          "Unpinned runtime errors | the texts of division by zero, Integer overflow and underflow..." (198)
//   70552: "Partial records | AddLoadFields and SetBaseLoadFields on a record with no SetLoadFields do nothing..." (195)
//   70553: "ModuleInfo | PackageId is the app id with its last byte flipped..." (155); "DataTransfer | outside install code SetTables is accepted..." (157);
//          "WebServiceActionContext | the error text of a duplicate entity key..." (150)
// BC versions: 29 (27 and 28 by CI)

codeunit 70550 "LT PnB ErrorInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Flow: Text;

    [TryFunction]
    local procedure TryErrorType(EI: ErrorInfo; var R: Text)
    begin
        R := Format(EI.ErrorType());
    end;

    [TryFunction]
    local procedure TryRaise(EI: ErrorInfo)
    begin
        Error(EI);
    end;

    [Test]
    procedure ErrorType_BeforeSet_AndRaise()
    var
        Obs: Codeunit "Probe Observer";
        EI: ErrorInfo;
        R: Text;
    begin
        EI := ErrorInfo.Create('PnB message');
        Obs.Observe('typeBeforeSet', Format(TryErrorType(EI, R)) + '/' + R);
        Obs.Observe('typeBeforeSetErr', GetLastErrorText());
        ClearLastError();
        EI.ErrorType := ErrorType::Client;
        Obs.Observe('typeClient', Format(EI.ErrorType()));
        Obs.Observe('raiseClient', Format(TryRaise(EI)));
        Obs.Observe('raiseClientText', GetLastErrorText());
        Obs.Observe('raiseClientCode', GetLastErrorCode());
        ClearLastError();
        EI.ErrorType := ErrorType::Internal;
        Obs.Observe('raiseInternal', Format(TryRaise(EI)));
        Obs.Observe('raiseInternalText', GetLastErrorText());
        Obs.Observe('raiseInternalCode', GetLastErrorCode());
        ClearLastError();
        Obs.Observe('clientOrdinal', Format(ErrorType::Client, 0, 2));
        Obs.Observe('internalOrdinal', Format(ErrorType::Internal, 0, 2));
        Obs.Expect('typeBeforeSet', 'Yes/Client');
        Obs.Expect('typeBeforeSetErr', '');
        Obs.Expect('typeClient', 'Client');
        Obs.Expect('raiseClient', 'No');
        Obs.Expect('raiseClientText', 'PnB message');
        Obs.Expect('raiseClientCode', 'Dialog');
        Obs.Expect('raiseInternal', 'No');
        Obs.Expect('raiseInternalText', 'An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Obs.Expect('raiseInternalCode', 'Dialog');
        Obs.Expect('clientOrdinal', '0');
        Obs.Expect('internalOrdinal', '1');
        Obs.Verify();
    end;

    [Test]
    procedure VerbosityAndDataClassification_Ordinals()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('critical', Format(Verbosity::Critical, 0, 2));
        Obs.Observe('error', Format(Verbosity::Error, 0, 2));
        Obs.Observe('warning', Format(Verbosity::Warning, 0, 2));
        Obs.Observe('normal', Format(Verbosity::Normal, 0, 2));
        Obs.Observe('verbose', Format(Verbosity::Verbose, 0, 2));
        Obs.Observe('customerContent', Format(DataClassification::CustomerContent, 0, 2));
        Obs.Observe('toBeClassified', Format(DataClassification::ToBeClassified, 0, 2));
        Obs.Observe('endUserIdentifiable', Format(DataClassification::EndUserIdentifiableInformation, 0, 2));
        Obs.Observe('accountData', Format(DataClassification::AccountData, 0, 2));
        Obs.Observe('endUserPseudonymous', Format(DataClassification::EndUserPseudonymousIdentifiers, 0, 2));
        Obs.Observe('organizationIdentifiable', Format(DataClassification::OrganizationIdentifiableInformation, 0, 2));
        Obs.Observe('systemMetadata', Format(DataClassification::SystemMetadata, 0, 2));
        Obs.Expect('critical', '1');
        Obs.Expect('error', '2');
        Obs.Expect('warning', '3');
        Obs.Expect('normal', '4');
        Obs.Expect('verbose', '5');
        Obs.Expect('customerContent', '0');
        Obs.Expect('toBeClassified', '1');
        Obs.Expect('endUserIdentifiable', '2');
        Obs.Expect('accountData', '3');
        Obs.Expect('endUserPseudonymous', '4');
        Obs.Expect('organizationIdentifiable', '5');
        Obs.Expect('systemMetadata', '6');
        Obs.Verify();
    end;

    [Test]
    procedure Create_ArgumentCounts()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        EI: ErrorInfo;
    begin
        Row.Id := 7;
        EI := ErrorInfo.Create('m3', true, Row);
        Obs.Observe('3.msg', EI.Message());
        Obs.Observe('3.collectible', Format(EI.Collectible()));
        Obs.Observe('3.field', Format(EI.FieldNo()));
        Obs.Observe('3.recordIdEmpty', Format(Format(EI.RecordId()) = ''));
        EI := ErrorInfo.Create('m4', false, Row, Row.FieldNo(Name));
        Obs.Observe('4.field', Format(EI.FieldNo()));
        Obs.Observe('4.collectible', Format(EI.Collectible()));
        EI := ErrorInfo.Create('m5', false, Row, Row.FieldNo(Name), 42);
        Obs.Observe('5.page', Format(EI.PageNo()));
        Obs.Observe('5.control', EI.ControlName());
        EI := ErrorInfo.Create('m6', false, Row, Row.FieldNo(Name), 42, 'Ctl');
        Obs.Observe('6.page', Format(EI.PageNo()));
        Obs.Observe('6.control', EI.ControlName());
        EI := ErrorInfo.Create('m7', false, Row, Row.FieldNo(Name), 42, 'Ctl', Verbosity::Warning);
        Obs.Observe('7.verbosity', Format(EI.Verbosity()));
        Obs.Observe('7.verbosityOrd', Format(EI.Verbosity(), 0, 2));
        EI := ErrorInfo.Create('m8', false, Row, Row.FieldNo(Name), 42, 'Ctl', Verbosity::Warning, DataClassification::SystemMetadata);
        Obs.Observe('8.dataClass', Format(EI.DataClassification()));
        Obs.Observe('8.dataClassOrd', Format(EI.DataClassification(), 0, 2));
        Obs.Observe('8.control', EI.ControlName());
        Obs.Observe('8.page', Format(EI.PageNo()));
        EI := ErrorInfo.Create();
        Obs.Observe('0.msg', EI.Message());
        Obs.Observe('0.verbosity', Format(EI.Verbosity()));
        Obs.Expect('3.msg', 'm3');
        Obs.Expect('3.collectible', 'Yes');
        Obs.Expect('3.field', '0');
        Obs.Expect('3.recordIdEmpty', 'No');
        Obs.Expect('4.field', '2');
        Obs.Expect('4.collectible', 'No');
        Obs.Expect('5.page', '42');
        Obs.Expect('5.control', '');
        Obs.Expect('6.page', '42');
        Obs.Expect('6.control', 'Ctl');
        Obs.Expect('7.verbosity', 'Warning');
        Obs.Expect('7.verbosityOrd', '3');
        Obs.Expect('8.dataClass', 'SystemMetadata');
        Obs.Expect('8.dataClassOrd', '6');
        Obs.Expect('8.control', 'Ctl');
        Obs.Expect('8.page', '42');
        Obs.Expect('0.msg', '');
        Obs.Expect('0.verbosity', 'Error');
        Obs.Verify();
    end;

    local procedure Raiser(Msg: Text)
    var
        EI: ErrorInfo;
    begin
        EI := ErrorInfo.Create(Msg, true);
        Error(EI);
        Flow += '[after ' + Msg + ']';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTwo()
    begin
        Raiser('first');
        Raiser('second');
        Flow += '[inside ' + Format(GetCollectedErrors().Count()) + ']';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectOne()
    begin
        Raiser('only');
        Flow += '[inside ' + Format(GetCollectedErrors().Count()) + ']';
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectThenPlain()
    begin
        Raiser('collected');
        Error('plain');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNone()
    begin
        Flow += '[none]';
    end;

    [Test]
    procedure Collect_SeveralErrors_ScopeExitText()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Flow := '';
        asserterror CollectTwo();
        Obs.ObserveError('two');
        Obs.Observe('flow', Flow);
        Obs.Expect('two|text', 'Multiple errors occurred during the operation the first of which is: first. All errors can be found under ''Detailed Information''.');
        Obs.Expect('two|code', 'Dialog');
        Obs.Expect('flow', '[after first][after second][inside 2]');
        Obs.Verify();
    end;

    [Test]
    procedure Collect_OneError()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Flow := '';
        asserterror CollectOne();
        Obs.ObserveError('one');
        Obs.Observe('flow', Flow);
        Obs.Expect('one|text', 'only');
        Obs.Expect('one|code', 'Dialog');
        Obs.Expect('flow', '[after only][inside 1]');
        Obs.Verify();
    end;

    [Test]
    procedure Collect_ThenPlainError_DiscardsCollected()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Flow := '';
        asserterror CollectThenPlain();
        Obs.ObserveError('plainAfterCollect');
        Obs.Observe('flow', Flow);
        Obs.Expect('plainAfterCollect|text', 'plain');
        Obs.Expect('plainAfterCollect|code', 'Dialog');
        Obs.Expect('flow', '[after collected]');
        Obs.Verify();
    end;

    [Test]
    procedure Collect_OutsideScope_AndNoErrors()
    var
        Obs: Codeunit "Probe Observer";
        Errs: List of [ErrorInfo];
    begin
        Errs := GetCollectedErrors();
        Obs.Observe('outsideCount', Format(Errs.Count()));
        Errs := GetCollectedErrors(true);
        Obs.Observe('outsideClearCount', Format(Errs.Count()));
        Flow := '';
        CollectNone();
        Obs.Observe('noErrorsFlow', Flow);
        Obs.Observe('noErrorsLast', GetLastErrorText());
        Obs.Expect('outsideCount', '0');
        Obs.Expect('outsideClearCount', '0');
        Obs.Expect('noErrorsFlow', '[none]');
        Obs.Expect('noErrorsLast', '');
        Obs.Verify();
    end;

    // Writer RO (al-runner issue 5766): an ErrorInfo with ErrorType::Internal (or Client) that is collected, read back through
    // GetCollectedErrors: Message, ErrorType, CustomDimensions, DetailedMessage, Collectible and Callstack.
    local procedure RoRaiseFull(ErrType: ErrorType; IsCollectible: Boolean)
    var
        Info: ErrorInfo;
    begin
        Info.Message := 'Full message';
        Info.DetailedMessage := 'Detailed message';
        Info.ErrorType := ErrType;
        Info.CustomDimensions.Add('Dim1', 'Val1');
        Info.Collectible := IsCollectible;
        Error(Info);
    end;

    local procedure RoRaiseNested(ErrType: ErrorType)
    begin
        RoRaiseFull(ErrType, true);
    end;

    // The message goes last and on its own: the Probe Observer cuts a value after "Correlation ID: " up to the next backslash.
    // Callstack: only the frames of this app, joined with a backslash (BC 27.5 also lists the frames of Microsoft's test runner
    // below the test method, BC 28.5 and 29.0 do not).
    local procedure RoObserveInfo(var Obs: Codeunit "Probe Observer"; Name: Text; Info: ErrorInfo)
    var
        DimKey: Text;
        Dims: Text;
        Cr: Text[1];
        Lf: Text[1];
        Line: Text;
        Frames: Text;
    begin
        foreach DimKey in Info.CustomDimensions.Keys() do
            Dims += DimKey + '=' + Info.CustomDimensions.Get(DimKey) + ',';
        Obs.Observe(Name, 'type=' + Format(Info.ErrorType) + ';dims=' + Format(Info.CustomDimensions.Count()) + ':' + Dims +
            ';detailed=' + Info.DetailedMessage + ';collectible=' + Format(Info.Collectible));
        Cr[1] := 13;
        Lf[1] := 10;
        foreach Line in Info.Callstack.Replace(Cr, '').Split(Lf) do
            if Line.Contains('AL Language Coverage Tests by AL Language version') then begin
                if Frames <> '' then
                    Frames += '\';
                Frames += Line;
            end;
        Obs.Observe(Name + ' callstack', Frames);
        Obs.Observe(Name + ' message', Info.Message);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RoCollect(ErrType: ErrorType; Nested: Boolean; Clear: Boolean; var Count: Integer; var Info: ErrorInfo)
    var
        Errors: List of [ErrorInfo];
    begin
        if Nested then
            RoRaiseNested(ErrType)
        else
            RoRaiseFull(ErrType, true);
        Errors := GetCollectedErrors(Clear);
        Count := Errors.Count();
        Errors.Get(1, Info);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RoCollectInternalAndLeave()
    begin
        RoRaiseFull(ErrorType::Internal, true);
    end;

    [Test]
    procedure RO_CollectedErrorInfo_Internal_And_Client()
    var
        Obs: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Count: Integer;
    begin
        RoCollect(ErrorType::Internal, false, true, Count, Info);
        Obs.Observe('internal count', Format(Count));
        RoObserveInfo(Obs, 'internal', Info);
        RoCollect(ErrorType::Client, false, true, Count, Info);
        Obs.Observe('client count', Format(Count));
        RoObserveInfo(Obs, 'client', Info);
        RoCollect(ErrorType::Internal, true, true, Count, Info);
        RoObserveInfo(Obs, 'internal nested', Info);
        Obs.Expect('internal count', '1');
        Obs.Expect('internal', 'type=Internal;dims=1:Dim1=Val1,;detailed=Detailed message;collectible=Yes');
        Obs.Expect('internal callstack', '"LT PnB ErrorInfo"(CodeUnit 70550).RoRaiseFull line 9 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RoCollect line 7 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RO_CollectedErrorInfo_Internal_And_Client line 6 - AL Language Coverage Tests by AL Language version x');
        Obs.Expect('internal message', 'An error has occurred. If the error persists, please contact your system administrator.\r\nCorrelation ID: x');
        Obs.Expect('client count', '1');
        Obs.Expect('client', 'type=Client;dims=1:Dim1=Val1,;detailed=Detailed message;collectible=Yes');
        Obs.Expect('client callstack', '"LT PnB ErrorInfo"(CodeUnit 70550).RoRaiseFull line 9 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RoCollect line 7 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RO_CollectedErrorInfo_Internal_And_Client line 9 - AL Language Coverage Tests by AL Language version x');
        Obs.Expect('client message', 'Full message');
        Obs.Expect('internal nested', 'type=Internal;dims=1:Dim1=Val1,;detailed=Detailed message;collectible=Yes');
        Obs.Expect('internal nested callstack', '"LT PnB ErrorInfo"(CodeUnit 70550).RoRaiseFull line 9 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RoRaiseNested line 2 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RoCollect line 5 - AL Language Coverage Tests by AL Language version x\"LT PnB ErrorInfo"(CodeUnit 70550).RO_CollectedErrorInfo_Internal_And_Client line 12 - AL Language Coverage Tests by AL Language version x');
        Obs.Expect('internal nested message', 'An error has occurred. If the error persists, please contact your system administrator.\r\nCorrelation ID: x');
        Obs.Verify();
    end;

    [Test]
    procedure RO_CollectedErrorInfo_Internal_NotCleared_ScopeExit()
    var
        Obs: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Count: Integer;
    begin
        asserterror RoCollect(ErrorType::Internal, false, false, Count, Info);
        Obs.Observe('kept: count', Format(Count));
        Obs.Observe('kept: message', Info.Message);
        Obs.ObserveError('kept: scope exit');
        asserterror RoCollectInternalAndLeave();
        Obs.ObserveError('left: scope exit');
        Obs.Expect('kept: count', '1');
        Obs.Expect('kept: message', 'An error has occurred. If the error persists, please contact your system administrator.\r\nCorrelation ID: x');
        Obs.Expect('kept: scope exit|text', 'An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Obs.Expect('kept: scope exit|code', 'Dialog');
        Obs.Expect('left: scope exit|text', 'An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        Obs.Expect('left: scope exit|code', 'Dialog');
        Obs.Verify();
    end;
}

codeunit 70551 "LT PnB Runtime Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Dictionary_MissingKeyAndDuplicate()
    var
        Obs: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        V: Integer;
    begin
        D.Add('a', 1);
        asserterror V := D.Get('missing');
        Obs.ObserveError('getValueForm');
        asserterror D.Get('missing', V);
        Obs.ObserveError('getOutForm');
        asserterror D.Add('a', 2);
        Obs.ObserveError('addDuplicate');
        D.Set('missing', 1);
        Obs.Observe('setMissing', 'no error');
        Obs.Observe('removeMissing', Format(D.Remove('missing')));
        asserterror V := D.Get('');
        Obs.ObserveError('emptyKey');
        Obs.Expect('getValueForm|text', 'The given key was not present in the dictionary.');
        Obs.Expect('getValueForm|code', 'KeyNotFound');
        Obs.Expect('getOutForm|text', 'The given key was not present in the dictionary.');
        Obs.Expect('getOutForm|code', 'KeyNotFound');
        Obs.Expect('addDuplicate|text', 'An item with the same key has already been added.');
        Obs.Expect('addDuplicate|code', 'Argument');
        Obs.Expect('setMissing', 'no error');
        Obs.Expect('removeMissing', 'Yes');
        Obs.Expect('emptyKey|text', 'The given key was not present in the dictionary.');
        Obs.Expect('emptyKey|code', 'KeyNotFound');
        Obs.Verify();
    end;

    [Test]
    procedure List_IndexErrors()
    var
        Obs: Codeunit "Probe Observer";
        L: List of [Integer];
        V: Integer;
        Sub: List of [Integer];
    begin
        L.Add(10);
        L.Add(20);
        asserterror V := L.Get(0);
        Obs.ObserveError('get0');
        asserterror V := L.Get(3);
        Obs.ObserveError('get3');
        asserterror V := L.Get(-1);
        Obs.ObserveError('getMinus1');
        asserterror L.RemoveAt(0);
        Obs.ObserveError('removeAt0');
        asserterror L.RemoveAt(3);
        Obs.ObserveError('removeAt3');
        asserterror L.Set(0, 1);
        Obs.ObserveError('set0');
        asserterror L.Set(3, 1);
        Obs.ObserveError('set3');
        Obs.Expect('get0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('get0|code', 'ArgumentOutOfRange');
        Obs.Expect('get3|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('get3|code', 'ArgumentOutOfRange');
        Obs.Expect('getMinus1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('getMinus1|code', 'ArgumentOutOfRange');
        Obs.Expect('removeAt0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('removeAt0|code', 'ArgumentOutOfRange');
        Obs.Expect('removeAt3|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('removeAt3|code', 'ArgumentOutOfRange');
        Obs.Expect('set0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('set0|code', 'ArgumentOutOfRange');
        Obs.Expect('set3|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('set3|code', 'ArgumentOutOfRange');
        Obs.Verify();
    end;

    [Test]
    procedure List_IndexErrors_InsertAndRanges()
    var
        Obs: Codeunit "Probe Observer";
        L: List of [Integer];
        Sub: List of [Integer];
    begin
        L.Add(10);
        L.Add(20);
        asserterror L.Insert(0, 1);
        Obs.ObserveError('insert0');
        asserterror L.Insert(4, 1);
        Obs.ObserveError('insert4');
        asserterror Sub := L.GetRange(2, 5);
        Obs.ObserveError('getRangeBeyond');
        asserterror Sub := L.GetRange(0, 1);
        Obs.ObserveError('getRange0');
        asserterror L.RemoveRange(2, 5);
        Obs.ObserveError('removeRangeBeyond');
        asserterror L.RemoveRange(0, 1);
        Obs.ObserveError('removeRange0');
        Obs.Observe('countBefore', Format(L.Count()));
        L.Insert(3, 30);
        Obs.Observe('insertedAtCountPlus1', Format(L.Count()));
        Obs.Expect('insert0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('insert0|code', 'ArgumentOutOfRange');
        Obs.Expect('insert4|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('insert4|code', 'ArgumentOutOfRange');
        Obs.Expect('getRangeBeyond|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('getRangeBeyond|code', 'Argument');
        Obs.Expect('getRange0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('getRange0|code', 'ArgumentOutOfRange');
        Obs.Expect('removeRangeBeyond|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('removeRangeBeyond|code', 'Argument');
        Obs.Expect('removeRange0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Obs.Expect('removeRange0|code', 'ArgumentOutOfRange');
        Obs.Expect('countBefore', '2');
        Obs.Expect('insertedAtCountPlus1', '3');
        Obs.Verify();
    end;

    [Test]
    procedure KeyRef_FieldIndexPastKey()
    var
        Obs: Codeunit "Probe Observer";
        RR: RecordRef;
        KR: KeyRef;
        FR: FieldRef;
    begin
        RR.Open(Database::"LT PnB Row");
        KR := RR.KeyIndex(1);
        Obs.Observe('fieldCount', Format(KR.FieldCount()));
        FR := KR.FieldIndex(1);
        Obs.Observe('field1', FR.Name());
        asserterror FR := KR.FieldIndex(2);
        Obs.ObserveError('index2');
        asserterror FR := KR.FieldIndex(0);
        Obs.ObserveError('index0');
        asserterror KR := RR.KeyIndex(99);
        Obs.ObserveError('keyIndex99');
        Obs.Expect('fieldCount', '1');
        Obs.Expect('field1', 'Id');
        Obs.Expect('index2|text', 'Index out of bounds.');
        Obs.Expect('index2|code', 'IndexOutOfBounds');
        Obs.Expect('index0|text', 'Index out of bounds.');
        Obs.Expect('index0|code', 'IndexOutOfBounds');
        Obs.Expect('keyIndex99|text', 'Index out of bounds.');
        Obs.Expect('keyIndex99|code', 'IndexOutOfBounds');
        Obs.Verify();
    end;

    [Test]
    procedure Arithmetic_ErrorTexts()
    var
        Obs: Codeunit "Probe Observer";
        I: Integer;
        Zero: Integer;
        D: Decimal;
        ZeroD: Decimal;
        B: BigInteger;
        Small: Integer;
        Byte2: Byte;
    begin
        asserterror I := 5 div Zero;
        Obs.ObserveError('intDiv0');
        asserterror I := 5 mod Zero;
        Obs.ObserveError('intMod0');
        asserterror D := 5 / ZeroD;
        Obs.ObserveError('decDiv0');
        asserterror D := 5 / Zero;
        Obs.ObserveError('decByIntDiv0');
        I := 2147483647;
        asserterror I := I + 1;
        Obs.ObserveError('intOverflow');
        I := -2147483647;
        asserterror I := I - 2;
        Obs.ObserveError('intUnderflow');
        I := 2147483647;
        asserterror I := I * 2;
        Obs.ObserveError('intMulOverflow');
        B := 9223372036854775807L;
        asserterror B := B + 1;
        Obs.ObserveError('bigOverflow');
        Small := 300;
        asserterror Byte2 := Small;
        Obs.ObserveError('byteOverflow');
        D := 79228162514264337593543950335.0;
        asserterror D := D * 10;
        Obs.ObserveError('decimalOverflow');
        Obs.Expect('intDiv0|text', 'Attempted to divide by zero.');
        Obs.Expect('intDiv0|code', 'AL:DivideByZero');
        Obs.Expect('intMod0|text', 'Attempted to divide by zero.');
        Obs.Expect('intMod0|code', 'AL:DivideByZero');
        Obs.Expect('decDiv0|text', 'Attempted to divide by zero.');
        Obs.Expect('decDiv0|code', 'AL:DivideByZero');
        Obs.Expect('decByIntDiv0|text', 'Attempted to divide by zero.');
        Obs.Expect('decByIntDiv0|code', 'AL:DivideByZero');
        Obs.Expect('intOverflow|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('intOverflow|code', 'AL:Overflow');
        Obs.Expect('intUnderflow|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('intUnderflow|code', 'AL:Overflow');
        Obs.Expect('intMulOverflow|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('intMulOverflow|code', 'AL:Overflow');
        Obs.Expect('bigOverflow|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigOverflow|code', 'AL:Overflow');
        Obs.Expect('byteOverflow|text', 'Overflow under conversion of System.Int32 value 300 to System.Byte.');
        Obs.Expect('byteOverflow|code', 'ConversionCast');
        Obs.Expect('decimalOverflow|text', 'Value was either too large or too small for a Decimal.');
        Obs.Expect('decimalOverflow|code', 'AL:Overflow');
        Obs.Verify();
    end;
}

codeunit 70552 "LT PnB Partial Load"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnB Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Amount := 5;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Amount := 6;
        Row.Insert();
    end;

    [Test]
    procedure AddLoadFields_WithoutSet()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
    begin
        Seed();
        Row.AddLoadFields(Name);
        Row.FindFirst();
        Obs.Observe('afterAdd.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Observe('afterAdd.amount', Format(Row.AreFieldsLoaded(Amount)));
        Obs.Observe('afterAdd.both', Format(Row.AreFieldsLoaded(Name, Amount)));
        Obs.Observe('afterAdd.id', Format(Row.AreFieldsLoaded(Id)));
        Row.SetBaseLoadFields();
        Row.FindFirst();
        Obs.Observe('afterBase.amount', Format(Row.AreFieldsLoaded(Amount)));
        Obs.Observe('afterBase.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Expect('afterAdd.name', 'Yes');
        Obs.Expect('afterAdd.amount', 'Yes');
        Obs.Expect('afterAdd.both', 'Yes');
        Obs.Expect('afterAdd.id', 'Yes');
        Obs.Expect('afterBase.amount', 'Yes');
        Obs.Expect('afterBase.name', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure SetLoadFields_ThenRead_AndClear()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        A: Decimal;
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Obs.Observe('set.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Observe('set.amount', Format(Row.AreFieldsLoaded(Amount)));
        Obs.Observe('set.pk', Format(Row.AreFieldsLoaded(Id)));
        A := Row.Amount;
        Obs.Observe('readAmount', Format(A));
        Obs.Observe('afterRead.amount', Format(Row.AreFieldsLoaded(Amount)));
        Row.Next();
        Obs.Observe('afterNext.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Observe('afterNext.amount', Format(Row.AreFieldsLoaded(Amount)));
        Clear(Row);
        Obs.Observe('afterClear.name', Format(Row.AreFieldsLoaded(Name)));
        Row.FindFirst();
        Obs.Observe('afterClearFetch.amount', Format(Row.AreFieldsLoaded(Amount)));
        Obs.Observe('afterClearFetch.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Expect('set.name', 'Yes');
        Obs.Expect('set.amount', 'No');
        Obs.Expect('set.pk', 'Yes');
        Obs.Expect('readAmount', '5');
        Obs.Expect('afterRead.amount', 'Yes');
        Obs.Expect('afterNext.name', 'Yes');
        Obs.Expect('afterNext.amount', 'Yes');
        Obs.Expect('afterClear.name', 'No');
        Obs.Expect('afterClearFetch.amount', 'Yes');
        Obs.Expect('afterClearFetch.name', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure SetBaseLoadFields_OnPartialRecord()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Obs.Observe('before.amount', Format(Row.AreFieldsLoaded(Amount)));
        Row.SetBaseLoadFields();
        Obs.Observe('afterBase.amount', Format(Row.AreFieldsLoaded(Amount)));
        Row.FindFirst();
        Obs.Observe('afterBaseFetch.amount', Format(Row.AreFieldsLoaded(Amount)));
        Row.SetLoadFields(Name);
        Row.AddLoadFields(Amount);
        Row.FindFirst();
        Obs.Observe('add.amount', Format(Row.AreFieldsLoaded(Amount)));
        Obs.Observe('add.name', Format(Row.AreFieldsLoaded(Name)));
        Obs.Observe('add.flag', Format(Row.AreFieldsLoaded(Flag)));
        Obs.Expect('before.amount', 'No');
        Obs.Expect('afterBase.amount', 'No');
        Obs.Expect('afterBaseFetch.amount', 'Yes');
        Obs.Expect('add.amount', 'Yes');
        Obs.Expect('add.name', 'Yes');
        Obs.Expect('add.flag', 'No');
        Obs.Verify();
    end;
}

codeunit 70553 "LT PnB Module Transfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGetModule(Id: Guid; var Info: ModuleInfo)
    begin
        if not NavApp.GetModuleInfo(Id, Info) then
            Error('GetModuleInfo returned false');
    end;

    [Test]
    procedure ModuleInfo_Properties()
    var
        Obs: Codeunit "Probe Observer";
        Info: ModuleInfo;
        Other: ModuleInfo;
        NullId: Guid;
        Unknown: Guid;
        Deps: List of [ModuleDependencyInfo];
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Obs.Observe('idNotNull', Format(not IsNullGuid(Info.Id)));
        Obs.Observe('packageNotNull', Format(not IsNullGuid(Info.PackageId)));
        Obs.Observe('packageDiffersFromId', Format(Info.PackageId <> Info.Id));
        Obs.Observe('dataVersionIsAppVersion', Format(Format(Info.DataVersion) = Format(Info.AppVersion)));
        Deps := Info.Dependencies();
        Obs.Observe('hasDependencies', Format(Deps.Count() > 0));
        Obs.Observe('selfLookup', Format(TryGetModule(Info.Id, Other)));
        Obs.Observe('selfSameName', Format(Other.Name() = Info.Name()));
        Obs.Observe('nullLookup', Format(TryGetModule(NullId, Other)));
        Obs.Observe('nullLookupErr', GetLastErrorText());
        ClearLastError();
        Evaluate(Unknown, '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Observe('unknownLookup', Format(TryGetModule(Unknown, Other)));
        Obs.Observe('unknownLookupErr', GetLastErrorText());
        ClearLastError();
        Obs.Expect('idNotNull', 'Yes');
        Obs.Expect('packageNotNull', 'Yes');
        Obs.Expect('packageDiffersFromId', 'Yes');
        Obs.Expect('dataVersionIsAppVersion', 'Yes');
        Obs.Expect('hasDependencies', 'Yes');
        Obs.Expect('selfLookup', 'Yes');
        Obs.Expect('selfSameName', 'Yes');
        Obs.Expect('nullLookup', 'Yes');
        Obs.Expect('nullLookupErr', '');
        Obs.Expect('unknownLookup', 'No');
        Obs.Expect('unknownLookupErr', 'GetModuleInfo returned false');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryTransfer(What: Integer)
    var
        DT: DataTransfer;
    begin
        DT.SetTables(Database::"LT PnB Row", Database::"LT PnB Row");
        case What of
            1:
                DT.AddFieldValue(2, 2);
            2:
                DT.AddConstantValue('x', 2);
            3:
                DT.AddSourceFilter(1, '1');
            4:
                DT.CopyFields();
            5:
                DT.CopyRows();
            6:
                DT.UpdateAuditFields(true);
            7:
                DT.AddJoin(1, 1);
        end;
    end;

    [Test]
    procedure DataTransfer_OutsideInstall()
    var
        Obs: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 7 do begin
            Obs.Observe('op' + Format(i), Format(TryTransfer(i)));
            Obs.Observe('op' + Format(i) + '.err', GetLastErrorText());
            ClearLastError();
        end;
        Obs.Expect('op0', 'Yes');
        Obs.Expect('op0.err', '');
        Obs.Expect('op1', 'No');
        Obs.Expect('op1.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Expect('op2', 'No');
        Obs.Expect('op2.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Expect('op3', 'No');
        Obs.Expect('op3.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Expect('op4', 'No');
        Obs.Expect('op4.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Expect('op5', 'No');
        Obs.Expect('op5.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Expect('op6', 'Yes');
        Obs.Expect('op6.err', '');
        Obs.Expect('op7', 'No');
        Obs.Expect('op7.err', 'DataTransfer is only usable during upgrade and installation code.');
        Obs.Verify();
    end;

    [Test]
    procedure WebServiceActionContext_Ordinals_AndDuplicateKey()
    var
        Obs: Codeunit "Probe Observer";
        Ctx: WebServiceActionContext;
    begin
        Obs.Observe('table', Format(ObjectType::Table, 0, 2));
        Obs.Observe('report', Format(ObjectType::Report, 0, 2));
        Obs.Observe('codeunit', Format(ObjectType::Codeunit, 0, 2));
        Obs.Observe('xmlport', Format(ObjectType::XMLport, 0, 2));
        Obs.Observe('menuSuite', Format(ObjectType::MenuSuite, 0, 2));
        Obs.Observe('page', Format(ObjectType::Page, 0, 2));
        Obs.Observe('query', Format(ObjectType::Query, 0, 2));
        Obs.Observe('created', Format(WebServiceActionResultCode::Created, 0, 2));
        Obs.Observe('deleted', Format(WebServiceActionResultCode::Deleted, 0, 2));
        Obs.Observe('updated', Format(WebServiceActionResultCode::Updated, 0, 2));
        Obs.Observe('get', Format(WebServiceActionResultCode::Get, 0, 2));
        Ctx.AddEntityKey(1, 'a');
        asserterror Ctx.AddEntityKey(1, 'b');
        Obs.ObserveError('duplicateKey');
        Obs.Expect('table', '1');
        Obs.Expect('report', '3');
        Obs.Expect('codeunit', '5');
        Obs.Expect('xmlport', '6');
        Obs.Expect('menuSuite', '7');
        Obs.Expect('page', '8');
        Obs.Expect('query', '9');
        Obs.Expect('created', '201');
        Obs.Expect('deleted', '204');
        Obs.Expect('updated', '200');
        Obs.Expect('get', '200');
        Obs.Expect('duplicateKey|text', 'An invalid argument was passed to a ''WebServiceActionContext'' data type method.');
        Obs.Expect('duplicateKey|code', 'Argument');
        Obs.Verify();
    end;
}
