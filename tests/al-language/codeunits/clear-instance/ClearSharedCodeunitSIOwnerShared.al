// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CLB Store" (codeunit 75587) of ClearSharedCodeunitTempRef.al;
//   self-contained objects 75713 to 75715
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// singleinstance-shared-on-purpose: the subject is what a SingleInstance codeunit's non-SingleInstance codeunit
//   global holds when a second test codeunit reads it after a first one wrote it.
// Facts: two test codeunits run the same body on one SingleInstance owner S that holds a global X of "CLB Store"
//   (temporary record, array of RecordRef, array of Integer). Each reads a marker in S, then writes its own marker
//   and value through S. The order of the two test codeunits differs between test runners, so each test asserts a
//   relation that holds in both orders: the marker is 0 or the other codeunit's, and X shows exactly what the
//   marker says (fresh state when 0, the other codeunit's write otherwise, compared with a reference store that
//   made the same write).
//   Measured on BC 29.0 (Linux): every relation holds; the reading test codeunit sees the other's marker and X's
//   temporary row, RecordRef and Integer, or a fresh X when it runs first.
// BC versions: 27, 28, 29

codeunit 75713 "CLS SI Owner Shared"
{
    SingleInstance = true;

    var
        X: Codeunit "CLB Store";
        Cnt: Integer;

    procedure Touch()
    begin
        X.IntAt(1);
        X.RowCount();
    end;

    procedure WriteX(V: Integer)
    begin
        X.Write(V);
    end;

    procedure StateX(): Text
    begin
        exit(X.State());
    end;

    procedure ShareAlias(var Y: Codeunit "CLB Store")
    begin
        Y := X;
    end;

    procedure ShareIface(var I: Interface "CLB IStore")
    begin
        I := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure SetCnt(V: Integer)
    begin
        Cnt := V;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;
}

codeunit 75714 "CLS SI Shared Tests P"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SharedOwner_CarryOver_P()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner Shared";
        Ref: Codeunit "CLB Store";
        Seen: Integer;
    begin
        Seen := S.GetCnt();
        if Seen <> 0 then
            Ref.Write(2);
        Observer.Observe('seen is 0 or the other', Format((Seen = 0) or (Seen = 2)));
        Observer.Observe('x equals what the marker says', Format(S.StateX() = Ref.State()));
        S.SetCnt(1);
        S.WriteX(1);
        Ref.Write(1);
        Observer.Observe('x after own write equals reference', Format(S.StateX() = Ref.State()));
        Observer.Expect('seen is 0 or the other', 'Yes');
        Observer.Expect('x equals what the marker says', 'Yes');
        Observer.Expect('x after own write equals reference', 'Yes');
        Observer.Verify();
    end;
}

codeunit 75715 "CLS SI Shared Tests Q"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SharedOwner_CarryOver_Q()
    var
        Observer: Codeunit "Probe Observer";
        S: Codeunit "CLS SI Owner Shared";
        Ref: Codeunit "CLB Store";
        Seen: Integer;
    begin
        Seen := S.GetCnt();
        if Seen <> 0 then
            Ref.Write(1);
        Observer.Observe('seen is 0 or the other', Format((Seen = 0) or (Seen = 1)));
        Observer.Observe('x equals what the marker says', Format(S.StateX() = Ref.State()));
        S.SetCnt(2);
        S.WriteX(2);
        Ref.Write(2);
        Observer.Observe('x after own write equals reference', Format(S.StateX() = Ref.State()));
        Observer.Expect('seen is 0 or the other', 'Yes');
        Observer.Expect('x equals what the marker says', 'Yes');
        Observer.Expect('x after own write equals reference', 'Yes');
        Observer.Verify();
    end;
}
