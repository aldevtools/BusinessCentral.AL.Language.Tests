// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Y47DtInstall.al (tables 92909-92912, install codeunit 92912)
// Facts: what DataTransfer did in OnInstallAppPerCompany (al-runner issue 6586): the outcome of each call, the rows afterwards, and the trigger
//   log (empty = no table trigger ran). Seed: Entry 1 (alpha, ''), 2 (beta, keep), 3 ('', ''), 4 (delta, ''), Status 'seed'; Src A 10, B 20, C 30.
// BC versions: 27.5+

codeunit 92913 "LT Y47 DT Install Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObsText(ObsCode: Code[20]): Text
    var
        Obs: Record "LT Y47 DT Log";
    begin
        if Obs.Get(ObsCode) then
            exit(Obs.Outcome);
        exit('<missing>');
    end;

    local procedure EntryRows() Result: Text
    var
        Entry: Record "LT Y47 DT Entry";
    begin
        if Entry.FindSet() then
            repeat
                Result += Format(Entry."Entry No.") + '|' + Entry.Name + '|' + Entry."Display Name" + '|' + Entry.Status + ';';
            until Entry.Next() = 0;
    end;

    local procedure DestRows() Result: Text
    var
        Dest: Record "LT Y47 DT Dest";
    begin
        if Dest.FindSet() then
            repeat
                Result += Dest."Code" + '|' + Format(Dest.Amount) + '|' + Dest.Note + '|' + Dest.Unmapped + ';';
            until Dest.Next() = 0;
    end;

    local procedure TriggerLog() Result: Text
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.SetFilter("Code", 'L*');
        if Log.FindSet() then
            repeat
                Result += Log.Outcome + ';';
            until Log.Next() = 0;
    end;

    [Test]
    procedure Y47_DtInstall_Outcomes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ctx', ObsText('CTX'));
        Observer.Observe('done', ObsText('DONE'));
        Observer.Observe('s1', ObsText('S1'));
        Observer.Observe('s2', ObsText('S2'));
        Observer.Observe('s3', ObsText('S3'));
        Observer.Expect('ctx', 'Install');
        Observer.Expect('done', 'ok');
        Observer.Expect('s1', 'ok');
        Observer.Expect('s2', 'ok');
        Observer.Expect('s3', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_DtInstall_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('entry', EntryRows());
        Observer.Observe('dest', DestRows());
        Observer.Expect('entry', '1|alpha|alpha|const;2|beta|keep|const;3|||seed;4|delta|delta|const;');
        Observer.Expect('dest', 'B|20|rows|init;C|30|rows|init;');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_DtInstall_NoTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('triggerLog', TriggerLog());
        Observer.Expect('triggerLog', '');
        Observer.Verify();
    end;

    // Writer Y57: S4-S7 on tables with a table extension (Y57DtExtTables.al). Seed: Src A 10 la Qty 1, B 20 lb Qty 2, C 30 lc Qty 3.
    local procedure Y57DestRows() Result: Text
    var
        Dest: Record "LT Y57 DT Dest";
    begin
        if Dest.FindSet() then
            repeat
                Result += Dest."Code" + '|' + Format(Dest.Amount) + '|' + Dest.Note + '|' + Format(Dest."Ext Amount") + '|' + Dest."Ext Note" + ';';
            until Dest.Next() = 0;
    end;

    local procedure Y57SrcRows() Result: Text
    var
        Src: Record "LT Y57 DT Src";
    begin
        if Src.FindSet() then
            repeat
                Result += Src."Code" + '|' + Format(Src.Amount) + '|' + Src.Label + '|' + Format(Src."Ext Qty") + ';';
            until Src.Next() = 0;
    end;

    local procedure Y57TriggerLog() Result: Text
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.SetFilter("Code", 'X*');
        if Log.FindSet() then
            repeat
                Result += Log.Outcome + ';';
            until Log.Next() = 0;
    end;

    [Test]
    procedure Y57_DtExt_Outcomes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s4', ObsText('S4'));
        Observer.Observe('s5', ObsText('S5'));
        Observer.Observe('s6', ObsText('S6'));
        Observer.Observe('s7', ObsText('S7'));
        Observer.Finish();
    end;

    [Test]
    procedure Y57_DtExt_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dest', Y57DestRows());
        Observer.Observe('src', Y57SrcRows());
        Observer.Observe('triggerLog', Y57TriggerLog());
        Observer.Finish();
    end;
}
