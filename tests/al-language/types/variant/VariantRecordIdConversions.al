// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Universal (table 60000)
// Probe: observe form, measured by the corpus CI matrix (BC 27.5, 28.5, 29.0).
// Facts: a Variant holding a RecordId, a Record, a RecordRef, a Guid, a Code, a Text or an Integer, assigned to a Code[20], a
//   Text, an Integer, a Guid, a RecordId, a Record and a RecordRef: the value it gives or the error (text and code). And an
//   unassigned Variant used as a condition, in Format, and assigned to an Integer, a Text and a Boolean. Repros of
//   aldevtools/BusinessCentral.AL.Runner#7779, #7760 (item 1) and #7764 (item 1).
// BC versions: 27.5, 28.5, 29.0

codeunit 77120 "TYP Variant RecId Conv Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInto(V: Variant; Target: Text; var Result: Text)
    var
        C: Code[20];
        T: Text;
        I: Integer;
        G: Guid;
        RId: RecordId;
        Rec: Record "ALT Universal";
        RRef: RecordRef;
    begin
        case Target of
            'code':
                begin
                    C := V;
                    Result := C;
                end;
            'text':
                begin
                    T := V;
                    Result := T;
                end;
            'integer':
                begin
                    I := V;
                    Result := Format(I);
                end;
            'guid':
                begin
                    G := V;
                    if IsNullGuid(G) then
                        Result := 'null guid'
                    else
                        Result := 'a guid';
                end;
            'recordid':
                begin
                    RId := V;
                    Result := Format(RId);
                end;
            'record':
                begin
                    Rec := V;
                    Result := Format(Rec."Entry No.");
                end;
            'recordref':
                begin
                    RRef := V;
                    Result := Format(RRef.Number()) + ':' + Format(RRef.RecordId());
                end;
        end;
    end;

    local procedure ObserveInto(var Observer: Codeunit "Probe Observer"; Prefix: Text; V: Variant; Target: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryInto(V, Target, Result) then
            Observer.Observe(Prefix + '_to_' + Target, 'ok:' + Result)
        else
            Observer.Observe(Prefix + '_to_' + Target, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveTargets(var Observer: Codeunit "Probe Observer"; Prefix: Text; V: Variant)
    begin
        ObserveInto(Observer, Prefix, V, 'code');
        ObserveInto(Observer, Prefix, V, 'text');
        ObserveInto(Observer, Prefix, V, 'integer');
        ObserveInto(Observer, Prefix, V, 'guid');
        ObserveInto(Observer, Prefix, V, 'recordid');
        ObserveInto(Observer, Prefix, V, 'record');
        ObserveInto(Observer, Prefix, V, 'recordref');
    end;

    local procedure StoredRow(var Row: Record "ALT Universal")
    begin
        Row.DeleteAll();
        Row."Entry No." := 7;
        Row."Code Field" := 'X1';
        Row.Insert();
    end;

    [Test]
    procedure VariantRecordId_EveryTarget()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        V: Variant;
    begin
        StoredRow(Row);
        V := Row.RecordId();
        ObserveTargets(Observer, 'recordid', V);
        Observer.Finish();
    end;

    [Test]
    procedure VariantRecord_EveryTarget()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        V: Variant;
    begin
        StoredRow(Row);
        V := Row;
        ObserveTargets(Observer, 'record', V);
        Observer.Finish();
    end;

    [Test]
    procedure VariantRecordRef_EveryTarget()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        RRef: RecordRef;
        V: Variant;
    begin
        StoredRow(Row);
        RRef.GetTable(Row);
        V := RRef;
        ObserveTargets(Observer, 'recordref', V);
        Observer.Finish();
    end;

    [Test]
    procedure VariantGuid_EveryTarget()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := CreateGuid();
        ObserveTargets(Observer, 'guid', V);
        Observer.Finish();
    end;

    [Test]
    procedure VariantScalars_ToRecordTypes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        V: Variant;
        C: Code[20];
        T: Text;
    begin
        StoredRow(Row);
        C := 'ALT UNIVERSAL: 7';
        V := C;
        ObserveInto(Observer, 'code', V, 'recordid');
        ObserveInto(Observer, 'code', V, 'record');
        ObserveInto(Observer, 'code', V, 'recordref');
        T := Format(Row.RecordId());
        V := T;
        ObserveInto(Observer, 'text', V, 'recordid');
        ObserveInto(Observer, 'text', V, 'record');
        ObserveInto(Observer, 'text', V, 'recordref');
        V := 7;
        ObserveInto(Observer, 'integer', V, 'recordid');
        ObserveInto(Observer, 'integer', V, 'record');
        ObserveInto(Observer, 'integer', V, 'recordref');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCondition(V: Variant; var Result: Text)
    begin
        if V then
            Result := 'then'
        else
            Result := 'else';
    end;

    local procedure ObserveCondition(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryCondition(V, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure VariantAsCondition()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Unassigned: Variant;
    begin
        ObserveCondition(Observer, 'unassigned', Unassigned);
        V := true;
        ObserveCondition(Observer, 'true', V);
        V := 1;
        ObserveCondition(Observer, 'integer1', V);
        V := 0;
        ObserveCondition(Observer, 'integer0', V);
        V := 'true';
        ObserveCondition(Observer, 'texttrue', V);
        V := '';
        ObserveCondition(Observer, 'textempty', V);
        Observer.Observe('unassigned_isboolean', Format(Unassigned.IsBoolean()));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryUnassignedInto(V: Variant; Target: Text; var Result: Text)
    var
        I: Integer;
        T: Text;
        B: Boolean;
    begin
        case Target of
            'integer':
                begin
                    I := V;
                    Result := Format(I);
                end;
            'text':
                begin
                    T := V;
                    Result := '[' + T + ']';
                end;
            'boolean':
                begin
                    B := V;
                    Result := Format(B);
                end;
            'format':
                Result := '[' + Format(V) + ']';
        end;
    end;

    [Test]
    procedure UnassignedVariant_Uses()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Result: Text;
        Targets: List of [Text];
        Target: Text;
    begin
        Targets.Add('integer');
        Targets.Add('text');
        Targets.Add('boolean');
        Targets.Add('format');
        foreach Target in Targets do begin
            ClearLastError();
            if TryUnassignedInto(V, Target, Result) then
                Observer.Observe(Target, 'ok:' + Result)
            else
                Observer.Observe(Target, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Finish();
    end;
}
