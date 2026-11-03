// Faithful to the issue #1674 repro: the failing Insert happened inside a
// Subtype=Install trigger (MutableRecordBuffer.MarkAllFieldsAsChanged on the
// install path), so the whole bundle EXEC-FAILed before a single test ran.
codeunit 60894 "BEI Installer"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        BeiSetup: Record "BEI Setup";
    begin
        // Reinstall re-runs the repro insert: drop the blank-key row a previous install left behind.
        if BeiSetup.Get('') then
            BeiSetup.Delete();

        BeiSetup.Init();
        BeiSetup.Insert(false);
    end;
}

// Writer UR (tests/al-language/install/lt-ur-block-order/UrBlockOrderTests.al): an install codeunit in id block 1 (90515 = 65536 + 24979); it only logs, with `if Insert() then;`.
codeunit 90515 "LT UR Install High"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('I90515', 'company');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('I90515', 'database');
    end;
}
