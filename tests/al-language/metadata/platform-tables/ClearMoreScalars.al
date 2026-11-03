// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74006
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on DateFormula, RecordId, Version, Code[N], Text[N], Byte, Char, Boolean, BigInteger and others not yet pinned
// BC versions: 29
// Tag: P95

codeunit 74006 "LT P95 Clear More Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearMoreScalars()
    var
        Observer: Codeunit "Probe Observer";
        DF: DateFormula;
        Cd: Code[10];
        Tx: Text[20];
        By: Byte;
        Ch: Char;
        Ver: Version;
        Rid: RecordId;
    begin
        Evaluate(DF, '<1M>');
        Cd := 'ABC';
        Tx := 'hello';
        By := 200;
        Ch := 'x';
        Ver := Version.Create(1, 2, 3, 4);
        Observer.Observe('before', Format(DF) + '|' + Cd + '|' + Tx + '|' + Format(By) + '|' + Format(Ver));
        Clear(DF);
        Clear(Cd);
        Clear(Tx);
        Clear(By);
        Clear(Ch);
        Clear(Ver);
        Clear(Rid);
        Observer.Observe('dateformula', '[' + Format(DF) + ']');
        Observer.Observe('code', '[' + Cd + ']' + Format(StrLen(Cd)));
        Observer.Observe('text', '[' + Tx + ']' + Format(StrLen(Tx)));
        Observer.Observe('byte', Format(By));
        Observer.Observe('char', Format(Ch));
        Observer.Observe('char_int', Format(Ch));
        Observer.Observe('version', Format(Ver));
        Observer.Observe('version_major', Format(Ver.Major()));
        Observer.Observe('recordid', '[' + Format(Rid) + ']');
        Observer.Observe('recordid_table', Format(Rid.TableNo()));

        Observer.Expect('before', '1M|ABC|hello|˜|1.2.3.4');
        Observer.Expect('dateformula', '[]');
        Observer.Expect('code', '[]0');
        Observer.Expect('text', '[]0');
        Observer.Expect('byte', '\u0000');
        Observer.Expect('char', '\u0000');
        Observer.Expect('char_int', '\u0000');
        Observer.Expect('version', '0.0.0.0');
        Observer.Expect('version_major', '0');
        Observer.Expect('recordid', '[]');
        Observer.Expect('recordid_table', '0');
        Observer.Verify();
    end;

}
