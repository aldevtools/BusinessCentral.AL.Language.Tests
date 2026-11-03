// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-systemid-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table BC Enum Row (80953, types/lt-bc-enum-variant/BcEnumObjects.al)
// Corpus issue 659 item 6 (from al-runtime-rs #255): the method form ErrorInfo.SystemId(Guid) / SystemId(), its value on a new ErrorInfo,
// after ErrorInfo.Create with a record, after Clear and copy, and on the ErrorInfo returned by GetCollectedErrors after a collectible Error(ErrorInfo).
// The property form (ErrInfo.SystemId := ...) is in errorinfo/lt-errnotif/EnTErrorInfoProps.al.

codeunit 80985 "BC ErrorInfo SystemId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fixed(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{6A2F1C3E-0000-4000-8000-000000000001}');
        exit(G);
    end;

    [Test]
    procedure SystemId_Method_RoundTrip_Repro()
    var
        Info: ErrorInfo;
        Value: Guid;
    begin
        // The repro of al-runtime-rs #255.
        Value := CreateGuid();
        Info := ErrorInfo.Create('Repro');
        Info.SystemId(Value);
        if Info.SystemId() <> Value then
            Error('The error SystemId did not round-trip.');
    end;

    [Test]
    procedure SystemId_Method_DefaultsAndValues()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Copy: ErrorInfo;
        Empty: Guid;
    begin
        Observer.Observe('fresh var', Format(Info.SystemId()));
        Info := ErrorInfo.Create('x');
        Observer.Observe('after create', Format(Info.SystemId()));
        Info.SystemId(Fixed());
        Observer.Observe('after set', Format(Info.SystemId()));
        Observer.Observe('property reads same', Format(Info.SystemId = Fixed()));
        Observer.Observe('tableid after set', Format(Info.TableId()));
        Observer.Observe('recordid after set', Format(Info.RecordId()));
        Copy := Info;
        Copy.SystemId(Empty);
        Observer.Observe('copy cleared', Format(Copy.SystemId()));
        Observer.Observe('original after copy cleared', Format(Info.SystemId()));
        Clear(Info);
        Observer.Observe('after clear', Format(Info.SystemId()));
        Observer.Expect('fresh var', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('after create', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('after set', '{6A2F1C3E-0000-4000-8000-000000000001}');
        Observer.Expect('property reads same', 'Yes');
        Observer.Expect('tableid after set', '0');
        Observer.Expect('recordid after set', '');
        Observer.Expect('copy cleared', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('original after copy cleared', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('after clear', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure SystemId_From_Create_With_Record()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Enum Row";
        Info: ErrorInfo;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Info := ErrorInfo.Create('x', false, Row);
        Observer.Observe('create record sysid equal', Format(Info.SystemId() = Row.SystemId));
        Observer.Observe('create record tableid', Format(Info.TableId()));
        Observer.Observe('create record recordid', Format(Info.RecordId() = Row.RecordId));
        Info := ErrorInfo.Create('x', false, Row, Row.FieldNo(Kind));
        Observer.Observe('create record field sysid equal', Format(Info.SystemId() = Row.SystemId));
        Observer.Observe('create record field fieldno', Format(Info.FieldNo()));
        Info := ErrorInfo.Create('x');
        Info.RecordId(Row.RecordId);
        Observer.Observe('recordid setter sets sysid', Format(Info.SystemId() = Row.SystemId));
        Observer.Observe('recordid setter sysid null', Format(IsNullGuid(Info.SystemId())));
        Row.DeleteAll();
        Observer.Expect('create record sysid equal', 'Yes');
        Observer.Expect('create record tableid', '80953');
        Observer.Expect('create record recordid', 'Yes');
        Observer.Expect('create record field sysid equal', 'Yes');
        Observer.Expect('create record field fieldno', '2');
        Observer.Expect('recordid setter sets sysid', 'No');
        Observer.Expect('recordid setter sysid null', 'Yes');
        Observer.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RaiseCollectible(Id: Guid)
    var
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('bc collected');
        Info.Collectible(true);
        Info.SystemId(Id);
        Error(Info);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectAndRead(var Observer: Codeunit "Probe Observer")
    var
        Errors: List of [ErrorInfo];
        Info: ErrorInfo;
    begin
        RaiseCollectible(Fixed());
        Errors := GetCollectedErrors(true);
        Observer.Observe('collected count', Format(Errors.Count()));
        if Errors.Count() > 0 then begin
            Info := Errors.Get(1);
            Observer.Observe('collected message', Info.Message());
            Observer.Observe('collected sysid', Format(Info.SystemId()));
        end;
    end;

    [Test]
    procedure SystemId_On_CollectedError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CollectAndRead(Observer);
        Observer.Expect('collected count', '1');
        Observer.Expect('collected message', 'bc collected');
        Observer.Expect('collected sysid', '{6A2F1C3E-0000-4000-8000-000000000001}');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRaise(Id: Guid)
    var
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('bc raised');
        Info.SystemId(Id);
        Error(Info);
    end;

    [Test]
    procedure SystemId_ErrorRaised_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try result', Format(TryRaise(Fixed())));
        Observer.ObserveError('last error');
        asserterror TryRaise(Fixed());
        Observer.ObserveError('asserterror');
        Observer.Expect('try result', 'No');
        Observer.Expect('last error|text', 'bc raised');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('asserterror|text', 'bc raised');
        Observer.Expect('asserterror|code', 'Dialog');
        Observer.Verify();
    end;
}
