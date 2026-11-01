// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope
// Fixture of SeqCarry.al (this folder): the install code that creates the number sequences the test codeunits there restart and
// delete (al-runner issue 6638, the shape of an app whose install routine calls NumberSequence.Insert).
// Install safety: only NumberSequence calls behind an Exists check of the same name; no table writes, so it cannot raise on a
// fresh database or on a reinstall. Every install starts each sequence again from 1, so a reinstall reads the same as the first.
codeunit 93600 "LT Y56 Seq Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        Fresh('Y56-I-D');
        Fresh('Y56-I-DI');
        Fresh('Y56-I-N');
        Fresh('Y56-I-R');
        Fresh('Y56-I-RS');
        Fresh('Y56-I-RN');
    end;

    local procedure Fresh(Name: Text)
    begin
        if NumberSequence.Exists(Name, false) then
            NumberSequence.Delete(Name, false);
        NumberSequence.Insert(Name, 1, 1, false);
    end;
}
