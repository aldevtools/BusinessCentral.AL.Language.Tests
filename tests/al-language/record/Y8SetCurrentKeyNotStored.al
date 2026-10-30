// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: Record.SetCurrentKey on a field that is not stored or cannot be sorted (al-runtime-rs docs/probes-needed.md, "SetCurrentKey", error text
// unknown): a FlowField, a FlowFilter, a Blob and a Media field, alone and after a normal field. For each: does it raise (text and code), and
// what CurrentKey() answers afterwards. A normal non-key field is the control (TestRecordNavContracts.al:180-195).
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).

table 91413 "LT Y8 SCK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y8 SCK Row" where(Id = field(Id)));
        }
        field(4; IdFilter; Integer) { FieldClass = FlowFilter; }
        field(5; Data; Blob) { }
        field(6; Picture; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91413 "LT Y8 SetCurrentKey Not Stored"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFlowField(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(Total);
    end;

    [TryFunction]
    local procedure TryFlowFilter(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(IdFilter);
    end;

    [TryFunction]
    local procedure TryBlob(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(Data);
    end;

    [TryFunction]
    local procedure TryMedia(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(Picture);
    end;

    [TryFunction]
    local procedure TryNameThenFlowField(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(Name, Total);
    end;

    [TryFunction]
    local procedure TryName(var R: Record "LT Y8 SCK Row")
    begin
        R.SetCurrentKey(Name);
    end;

    local procedure Outcome(Ok: Boolean; var R: Record "LT Y8 SCK Row"): Text
    begin
        if Ok then
            exit('ok key=' + R.CurrentKey());
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode() + ' key=' + R.CurrentKey());
    end;

    [Test]
    procedure Y8_SetCurrentKey_NotStoredFields()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 SCK Row";
    begin
        Observer.Observe('name', Outcome(TryName(R), R));
        Clear(R);
        Observer.Observe('flowfield', Outcome(TryFlowField(R), R));
        Clear(R);
        Observer.Observe('flowfilter', Outcome(TryFlowFilter(R), R));
        Clear(R);
        Observer.Observe('blob', Outcome(TryBlob(R), R));
        Clear(R);
        Observer.Observe('media', Outcome(TryMedia(R), R));
        Clear(R);
        Observer.Observe('name_then_flowfield', Outcome(TryNameThenFlowField(R), R));
        Observer.Expect('name', 'ok key=Name');
        Observer.Expect('flowfield', 'ok key=Total');
        Observer.Expect('flowfilter', 'ERR:Sorting cannot be done based on the IdFilter field(s) in the LT Y8 SCK Row table./DB:Ok key=Id');
        Observer.Expect('blob', 'ERR:Sorting cannot be done based on the Data field(s) in the LT Y8 SCK Row table./DB:Ok key=Id');
        Observer.Expect('media', 'ok key=Picture');
        Observer.Expect('name_then_flowfield', 'ok key=Name,Total');
        Observer.Verify();
    end;
}
