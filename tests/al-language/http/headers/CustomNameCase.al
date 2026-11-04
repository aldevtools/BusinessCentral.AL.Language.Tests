// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Custom (unknown) header names added in lower, upper and mixed case: stored case in Keys, Contains and GetValues in other cases, Remove in another case
// BC versions: 29 (27 and 28 by CI)

codeunit 72967 "LT Hdr198 Custom Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure Custom(Kind: Integer; N: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := 'add=' + Helper.DoAdd(H, N, 'v');
        Res += ';keys=' + Helper.Keys(H);
        Res += ';hasLow=' + Helper.DoHas(H, N.ToLower());
        Res += ';hasUp=' + Helper.DoHas(H, N.ToUpper());
        Res += ';hasMix=' + Helper.DoHas(H, Helper.Mixed(N));
        Res += ';get=' + Helper.DoGet(H, N.ToUpper());
        Res += ';rm=' + Helper.DoRemove(H, Helper.Mixed(N));
        Res += ';keysAfter=' + Helper.Keys(H);
        exit(Res);
    end;

    [Test]
    procedure P198_Request_CustomNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lower', Custom(1, 'x-custom'));
        Observer.Observe('upper', Custom(1, 'X-CUSTOM'));
        Observer.Observe('mixed', Custom(1, 'X-Custom'));
        Observer.Observe('mixedOdd', Custom(1, 'x-CuStOm'));
        Observer.Observe('lowerNoDash', Custom(1, 'xcustom'));
        Observer.Observe('upperNoDash', Custom(1, 'XCUSTOM'));
        Observer.Observe('underscoreLower', Custom(1, 'x_custom'));
        Observer.Observe('underscoreMixed', Custom(1, 'X_Custom_Name'));
        Observer.Observe('digits', Custom(1, 'x-custom-2'));
        Observer.Observe('single', Custom(1, 'a'));
        Observer.Observe('singleUpper', Custom(1, 'A'));
        Observer.Observe('longLower', Custom(1, 'x-some-quite-long-custom-header-name'));
        Observer.Observe('longMixed', Custom(1, 'X-Some-Quite-Long-Custom-Header-Name'));
        Observer.Expect('lower', 'add=ok;keys=1:x-custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('upper', 'add=ok;keys=1:X-CUSTOM,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('mixed', 'add=ok;keys=1:X-Custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('mixedOdd', 'add=ok;keys=1:x-CuStOm,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('lowerNoDash', 'add=ok;keys=1:xcustom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('upperNoDash', 'add=ok;keys=1:XCUSTOM,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('underscoreLower', 'add=ok;keys=1:x_custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('underscoreMixed', 'add=ok;keys=1:X_Custom_Name,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('digits', 'add=ok;keys=1:x-custom-2,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('single', 'add=ok;keys=1:a,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('singleUpper', 'add=ok;keys=1:A,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('longLower', 'add=ok;keys=1:x-some-quite-long-custom-header-name,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('longMixed', 'add=ok;keys=1:X-Some-Quite-Long-Custom-Header-Name,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Content_CustomNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lower', Custom(2, 'x-custom'));
        Observer.Observe('upper', Custom(2, 'X-CUSTOM'));
        Observer.Observe('mixed', Custom(2, 'X-Custom'));
        Observer.Observe('mixedOdd', Custom(2, 'x-CuStOm'));
        Observer.Expect('lower', 'add=ok;keys=2:Content-Type,x-custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=1:Content-Type,');
        Observer.Expect('upper', 'add=ok;keys=2:Content-Type,X-CUSTOM,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=1:Content-Type,');
        Observer.Expect('mixed', 'add=ok;keys=2:Content-Type,X-Custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=1:Content-Type,');
        Observer.Expect('mixedOdd', 'add=ok;keys=2:Content-Type,x-CuStOm,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=1:Content-Type,');
        Observer.Verify();
    end;

    [Test]
    procedure P198_Response_CustomNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lower', Custom(3, 'x-custom'));
        Observer.Observe('upper', Custom(3, 'X-CUSTOM'));
        Observer.Observe('mixed', Custom(3, 'X-Custom'));
        Observer.Observe('mixedOdd', Custom(3, 'x-CuStOm'));
        Observer.Expect('lower', 'add=ok;keys=1:x-custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('upper', 'add=ok;keys=1:X-CUSTOM,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('mixed', 'add=ok;keys=1:X-Custom,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Expect('mixedOdd', 'add=ok;keys=1:x-CuStOm,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/v;rm=Yes;keysAfter=0:');
        Observer.Verify();
    end;

    [Test]
    procedure P198_SameNameThreeCases_FirstWins()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Observer.Observe('addUpper', Helper.DoAdd(H, 'X-UPPER-FIRST', 'a'));
        Observer.Observe('addLower', Helper.DoAdd(H, 'x-upper-first', 'b'));
        Observer.Observe('addMixed', Helper.DoAdd(H, 'X-Upper-First', 'c'));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('get', Helper.DoGet(H, 'x-UPPER-first'));
        Observer.Observe('removeLower', Helper.DoRemove(H, 'x-upper-first'));
        Observer.Observe('keysAfter', Helper.Keys(H));
        Observer.Observe('addLowerFirst', Helper.DoAdd(H, 'x-lower-first', 'a'));
        Observer.Observe('addUpperSecond', Helper.DoAdd(H, 'X-LOWER-FIRST', 'b'));
        Observer.Observe('keys2', Helper.Keys(H));
        Observer.Observe('rawMixed', Helper.DoRaw(H, 'X-Raw-Name', 'a'));
        Observer.Observe('rawLower', Helper.DoRaw(H, 'x-raw-name', 'b'));
        Observer.Observe('keys3', Helper.Keys(H));
        Observer.Expect('addUpper', 'ok');
        Observer.Expect('addLower', 'ok');
        Observer.Expect('addMixed', 'ok');
        Observer.Expect('keys', '1:X-UPPER-FIRST,');
        Observer.Expect('get', 'Yes/a|b|c');
        Observer.Expect('removeLower', 'Yes');
        Observer.Expect('keysAfter', '0:');
        Observer.Expect('addLowerFirst', 'ok');
        Observer.Expect('addUpperSecond', 'ok');
        Observer.Expect('keys2', '1:x-lower-first,');
        Observer.Expect('rawMixed', 'ok');
        Observer.Expect('rawLower', 'ok');
        Observer.Expect('keys3', '2:x-lower-first,X-Raw-Name,');
        Observer.Verify();
    end;

    [Test]
    procedure P198_KeysOrderAcrossCases()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Helper.DoAdd(H, 'zeta', 'a');
        Helper.DoAdd(H, 'ALPHA', 'a');
        Helper.DoAdd(H, 'Mid', 'a');
        Helper.DoAdd(H, 'accept', 'text/html');
        Helper.DoAdd(H, 'USER-AGENT', 'test');
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('hasAlpha', Helper.DoHas(H, 'alpha'));
        Observer.Observe('hasZeta', Helper.DoHas(H, 'ZETA'));
        Observer.Observe('hasUa', Helper.DoHas(H, 'User-Agent'));
        Observer.Expect('keys', '5:zeta,ALPHA,Mid,Accept,User-Agent,');
        Observer.Expect('hasAlpha', 'Yes');
        Observer.Expect('hasZeta', 'Yes');
        Observer.Expect('hasUa', 'Yes');
        Observer.Verify();
    end;
}
