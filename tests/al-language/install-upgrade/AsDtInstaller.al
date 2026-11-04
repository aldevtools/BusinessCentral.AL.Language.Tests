// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: AsDtInstallTables.al (tables 79932-79937)
// Facts: DataTransfer is only usable in upgrade and install code, so the copies run here, in OnInstallAppPerCompany. Codeunit 79939 reads the
//   destination rows and the outcomes afterwards (corpus issue 644, item 15).
// Safety: an error raised from an install trigger fails the publish on every BC version. Every DataTransfer call runs inside a TryFunction, whose
//   outcome is stored in table 79937 instead of being raised. The trigger fires once per company and again on a second publish: seeding uses
//   Get before Insert, and the copies run only while the 'DONE' marker row is missing.
// BC versions: 27.5+ (scenario S4, AddDestinationFilter, needs runtime 17: BC 28+)

codeunit 79938 "LT AS DT Installer"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Obs: Record "LT AS DT Obs";
    begin
        if Obs.Get('DONE') then
            exit;
        Seed();
        Save('CTX', Format(Session.GetExecutionContext()));
        Save('S1', Outcome(TryCopyRowsFiltered()));
        Save('S2', Outcome(TryCopyFieldsJoin()));
        Save('S3', Outcome(TryCopyFieldsSameTable()));
#if BC28PLUS
        Save('S4', Outcome(TryCopyFieldsDestFilter()));
#endif
        Save('DONE', 'ok');
    end;

    local procedure Seed()
    var
        Fields: Record "LT AS DT Fields";
        SelfRec: Record "LT AS DT Self";
        DestF: Record "LT AS DT DestF";
    begin
        AddSrc('A', 10, 'alpha', 1.5, 1);
        AddSrc('B', 20, 'beta', 2.5, 2);
        AddSrc('C', 30, 'gamma', 3.5, 1);
        AddSrc('D', 0, 'delta', 0, 2);

        if not Fields.Get('A') then
            AddFields('A');
        if not Fields.Get('B') then
            AddFields('B');
        if not Fields.Get('E') then
            AddFields('E');

        if not SelfRec.Get('X') then
            AddSelf('X', 5);
        if not SelfRec.Get('Y') then
            AddSelf('Y', 15);
        if not SelfRec.Get('Z') then
            AddSelf('Z', 25);

        if not DestF.Get('A') then
            AddDestF('A', 1);
        if not DestF.Get('B') then
            AddDestF('B', 2);
        if not DestF.Get('C') then
            AddDestF('C', 1);
    end;

    local procedure AddSrc(NewCode: Code[20]; NewAmount: Integer; NewName: Text[30]; NewQty: Decimal; NewKind: Integer)
    var
        Src: Record "LT AS DT Src";
    begin
        if Src.Get(NewCode) then
            exit;
        Src.Init();
        Src."Code" := NewCode;
        Src.Amount := NewAmount;
        Src.Name := NewName;
        Src.Qty := NewQty;
        Src.Kind := NewKind;
        Src.Insert();
    end;

    local procedure AddFields(NewCode: Code[20])
    var
        Fields: Record "LT AS DT Fields";
    begin
        Fields.Init();
        Fields."Code" := NewCode;
        Fields.Name := 'old';
        Fields.Amount := -1;
        Fields.Note := 'seed';
        Fields.Insert();
    end;

    local procedure AddSelf(NewCode: Code[20]; NewAmount: Integer)
    var
        SelfRec: Record "LT AS DT Self";
    begin
        SelfRec.Init();
        SelfRec."Code" := NewCode;
        SelfRec.Amount := NewAmount;
        SelfRec."Copy" := -1;
        SelfRec.Note := 'seed';
        SelfRec.Insert();
    end;

    local procedure AddDestF(NewCode: Code[20]; NewKind: Integer)
    var
        DestF: Record "LT AS DT DestF";
    begin
        DestF.Init();
        DestF."Code" := NewCode;
        DestF.Name := 'old';
        DestF.Kind := NewKind;
        DestF.Insert();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Save(NewCode: Code[20]; Value: Text)
    var
        Obs: Record "LT AS DT Obs";
    begin
        if Obs.Get(NewCode) then
            exit;
        Obs.Init();
        Obs."Code" := NewCode;
        Obs.Outcome := CopyStr(Value, 1, MaxStrLen(Obs.Outcome));
        Obs.Insert();
    end;

    // S1: CopyRows into an empty table, source filter Amount > 10, three fields mapped, one constant.
    [TryFunction]
    local procedure TryCopyRowsFiltered()
    var
        Src: Record "LT AS DT Src";
        Dst: Record "LT AS DT Rows";
        DT: DataTransfer;
    begin
        DT.SetTables(Database::"LT AS DT Src", Database::"LT AS DT Rows");
        DT.AddSourceFilter(Src.FieldNo(Amount), '>%1', 10);
        DT.AddFieldValue(Src.FieldNo("Code"), Dst.FieldNo("Code"));
        DT.AddFieldValue(Src.FieldNo(Amount), Dst.FieldNo(Amount));
        DT.AddFieldValue(Src.FieldNo(Name), Dst.FieldNo(Name));
        DT.AddConstantValue('copied', Dst.FieldNo(Note));
        DT.CopyRows();
    end;

    // S2: CopyFields into a seeded table joined on Code, source filter Kind = 1 (source A and C; the destination has A, B, E).
    [TryFunction]
    local procedure TryCopyFieldsJoin()
    var
        Src: Record "LT AS DT Src";
        Dst: Record "LT AS DT Fields";
        DT: DataTransfer;
    begin
        DT.SetTables(Database::"LT AS DT Src", Database::"LT AS DT Fields");
        DT.AddJoin(Src.FieldNo("Code"), Dst.FieldNo("Code"));
        DT.AddSourceFilter(Src.FieldNo(Kind), '=%1', 1);
        DT.AddFieldValue(Src.FieldNo(Name), Dst.FieldNo(Name));
        DT.AddFieldValue(Src.FieldNo(Amount), Dst.FieldNo(Amount));
        DT.AddConstantValue('joined', Dst.FieldNo(Note));
        DT.CopyFields();
    end;

    // S3: CopyFields within one table, source filter Amount >= 15, Amount copied to Copy, one constant.
    [TryFunction]
    local procedure TryCopyFieldsSameTable()
    var
        SelfRec: Record "LT AS DT Self";
        DT: DataTransfer;
    begin
        DT.SetTables(Database::"LT AS DT Self", Database::"LT AS DT Self");
        DT.AddSourceFilter(SelfRec.FieldNo(Amount), '>=%1', 15);
        DT.AddFieldValue(SelfRec.FieldNo(Amount), SelfRec.FieldNo("Copy"));
        DT.AddConstantValue('self', SelfRec.FieldNo(Note));
        DT.CopyFields();
    end;

#if BC28PLUS
    // S4: CopyFields joined on Code, destination filter Kind = 1 (destination A and C; B has Kind 2).
    [TryFunction]
    local procedure TryCopyFieldsDestFilter()
    var
        Src: Record "LT AS DT Src";
        Dst: Record "LT AS DT DestF";
        DT: DataTransfer;
    begin
        DT.SetTables(Database::"LT AS DT Src", Database::"LT AS DT DestF");
        DT.AddJoin(Src.FieldNo("Code"), Dst.FieldNo("Code"));
        DT.AddDestinationFilter(Dst.FieldNo(Kind), '=%1', 1);
        DT.AddFieldValue(Src.FieldNo(Name), Dst.FieldNo(Name));
        DT.CopyFields();
    end;
#endif
}

// Probe UM (ADR-046 Q1): see install/lt-um-install-order/UmInstallOrder.al. Writes only `if Insert() then;` into a DataPerCompany = false log.
codeunit 90433 "LT UM Cu Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Cu', 'OnInstallAppPerCompany');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Cu', 'OnInstallAppPerDatabase');
    end;
}
