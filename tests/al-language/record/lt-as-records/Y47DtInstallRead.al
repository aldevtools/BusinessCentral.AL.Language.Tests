// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Y47DtInstall.al (tables 92909-92912, install codeunit 92912)
// Facts: what DataTransfer did in OnInstallAppPerCompany (al-runner issue 6586): the outcome of each call, the rows afterwards, and the trigger
//   log (empty = no table trigger ran). Seed: Entry 1 (alpha, ''), 2 (beta, keep), 3 ('', ''), 4 (delta, ''), Status 'seed'; Src A 10, B 20, C 30.
// Writer Y57 (corpus issue 996), Y57_DtExt_*: S4-S7 on tables with a table extension (Y57DtExtTables.al) all succeed. Extension fields
//   work as source, destination, source filter and join target; on CopyRows an unmapped extension field gets its InitValue ('ext init');
//   no trigger of the base table or of a table extension runs. Measured: SaaS sandbox BC 29 and the Linux CI containers BC 27.5, 28.5, 29.0.
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
        Observer.Expect('s4', 'ok');
        Observer.Expect('s5', 'ok');
        Observer.Expect('s6', 'ok');
        Observer.Expect('s7', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y57_DtExt_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dest', Y57DestRows());
        Observer.Observe('src', Y57SrcRows());
        Observer.Observe('triggerLog', Y57TriggerLog());
        Observer.Expect('dest', 'A|1|la|99|ext init;B|20|lb|20|k5;C|30|lc|3|k5;');
        Observer.Expect('src', 'A|10|la|99;B|20|lb|2;C|30|lc|3;');
        Observer.Expect('triggerLog', '');
        Observer.Verify();
    end;

    // Writer Y65 (al-runner issue 6668): S8 and S9 on Base Application's "Item Attribute" with this app's table extension
    // (Y65DtItemAttributeExt.al). Counts, so the result does not depend on the demo data: rows where the copy did not happen.
    [Test]
    procedure Y65_DtItemAttribute_Outcomes()
    var
        Observer: Codeunit "Probe Observer";
        ItemAttribute: Record "Item Attribute";
        NotCopied: Integer;
        NotTagged: Integer;
        WronglyTagged: Integer;
    begin
        Observer.Observe('s8', ObsText('S8'));
        Observer.Observe('s9', ObsText('S9'));
        if ItemAttribute.FindSet() then
            repeat
                if ItemAttribute."LT Y65 Display Name" <> ItemAttribute.Name then
                    NotCopied += 1;
                if (not ItemAttribute.Blocked) and (ItemAttribute."LT Y65 Tag" <> 'y65') then
                    NotTagged += 1;
                if ItemAttribute.Blocked and (ItemAttribute."LT Y65 Tag" <> '') then
                    WronglyTagged += 1;
            until ItemAttribute.Next() = 0;
        Observer.Observe('not copied', Format(NotCopied));
        Observer.Observe('not tagged', Format(NotTagged));
        Observer.Observe('blocked but tagged', Format(WronglyTagged));
        Observer.Expect('s8', 'ok');
        Observer.Expect('s9', 'ok');
        Observer.Expect('not copied', '0');
        Observer.Expect('not tagged', '0');
        Observer.Expect('blocked but tagged', '0');
        Observer.Verify();
    end;
}
