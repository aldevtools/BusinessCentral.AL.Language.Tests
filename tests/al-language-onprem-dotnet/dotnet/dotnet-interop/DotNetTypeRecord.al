// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61440
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): GetDotNetType(Record) and a Variant holding a Record
//
// GetDotNetType of a Record variable, a temporary Record and a Variant holding a Record (issue 154 item 1). Own table 61439.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; RcType) { }
    }
}

table 61439 "LT DotNetType Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 61440 "LT DotNetType Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRecord(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        Rec: Record "LT DotNetType Rec";
        T: DotNet RcType;
    begin
        T := GetDotNetType(Rec);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryTemporary(var FullName: Text; var Shown: Text)
    var
        Rec: Record "LT DotNetType Rec" temporary;
        T: DotNet RcType;
    begin
        Rec.Id := 1;
        Rec.Insert();
        T := GetDotNetType(Rec);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryVariantRecord(var FullName: Text; var Shown: Text)
    var
        Rec: Record "LT DotNetType Rec";
        V: Variant;
        T: DotNet RcType;
    begin
        V := Rec;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryRecordRef(var FullName: Text; var Shown: Text)
    var
        Ref: RecordRef;
        T: DotNet RcType;
    begin
        Ref.Open(61439);
        T := GetDotNetType(Ref);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryEqualsOther(var Result: Text)
    var
        Rec: Record "LT DotNetType Rec";
        Other: Record "LT DotNetType Rec";
        TA: DotNet RcType;
        TB: DotNet RcType;
    begin
        TA := GetDotNetType(Rec);
        TB := GetDotNetType(Other);
        Result := Format(TA.Equals(TB));
    end;

    // The runtime class name in the message is not asserted: a local BC 29 container names Microsoft.Dynamics.Nav.Runtime.StubNavRecord, the CI
    // container of BC 27.5 names Microsoft.Dynamics.Nav.BusinessApplication.Record<table id>. The text before it and the code are asserted.
    local procedure ErrorShape(): Text
    var
        Prefix: Text;
        Msg: Text;
    begin
        Prefix := 'GetDotNetType() does not support the type ';
        Msg := GetLastErrorText();
        if Msg.StartsWith(Prefix) and Msg.EndsWith('.') then
            exit(Prefix + '<record class>.|' + GetLastErrorCode());
        exit(Msg + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetDotNetType_Record_FullNameNameFormat()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DotNetType Rec";
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        Rec.DeleteAll();
        ClearLastError();
        if TryRecord(FullName, ShortName, Shown) then begin
            Observer.Observe('record_fullname', FullName);
            Observer.Observe('record_name', ShortName);
            Observer.Observe('record_format', Shown);
        end else
            Observer.Observe('record_error', ErrorShape());
        ClearLastError();
        if TryTemporary(FullName, Shown) then begin
            Observer.Observe('temporary_fullname', FullName);
            Observer.Observe('temporary_format', Shown);
        end else
            Observer.Observe('temporary_error', ErrorShape());
        Observer.Expect('record_error', 'GetDotNetType() does not support the type <record class>.|NotSupportedType');
        Observer.Expect('temporary_error', 'GetDotNetType() does not support the type <record class>.|NotSupportedType');
        Observer.Verify();
    end;

    [Test]
    procedure GetDotNetType_VariantAndRecordRef_FullNameAndFormat()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DotNetType Rec";
        FullName: Text;
        Shown: Text;
    begin
        Rec.DeleteAll();
        ClearLastError();
        if TryVariantRecord(FullName, Shown) then begin
            Observer.Observe('variant_record_fullname', FullName);
            Observer.Observe('variant_record_format', Shown);
        end else
            Observer.Observe('variant_record_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryRecordRef(FullName, Shown) then begin
            Observer.Observe('recordref_fullname', FullName);
            Observer.Observe('recordref_format', Shown);
        end else
            Observer.Observe('recordref_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('variant_record_error', 'GetDotNetType() does not support the type Microsoft.Dynamics.Nav.Runtime.NavVariant.|NotSupportedType');
        Observer.Expect('recordref_error', 'GetDotNetType() does not support the type Microsoft.Dynamics.Nav.Runtime.NavRecordRef.|NotSupportedType');
        Observer.Verify();
    end;

    [Test]
    procedure GetDotNetType_TwoRecordVariablesOfOneTable_EqualsResult()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DotNetType Rec";
        Result: Text;
    begin
        Rec.DeleteAll();
        ClearLastError();
        if TryEqualsOther(Result) then
            Observer.Observe('equals_other_variable', Result)
        else
            Observer.Observe('equals_other_variable_error', ErrorShape());
        Observer.Expect('equals_other_variable_error', 'GetDotNetType() does not support the type <record class>.|NotSupportedType');
        Observer.Verify();
    end;
}
