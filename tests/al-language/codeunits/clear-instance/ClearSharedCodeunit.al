// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects 75580, 75581, 75582
// Probe: written against BC 29.0 on Linux (al-runner issue 8912), observed first, then asserted.
// Facts: Clear and ClearAll of a non-SingleInstance codeunit variable X whose instance an interface, a second codeunit
//   variable (Y := X) or a value parameter shares. X is either unused before the share or used once
//   (X.Get()). After the clear the test writes 5 through the alias and reads X and the alias.
//   Also the same shares without a clear, and a second codeunit variable of the same codeunit.
//   Measured on BC 29.0 (Linux):
//   - Clear(X) gives X a fresh instance, whether X was unused or used once: X.Get() reads 0 afterwards. The
//     interface, the codeunit alias or the value parameter keeps the old instance: it reads the 5 written after
//     the clear, or the 3 it wrote before. The same when X is cleared through a var parameter.
//   - An unused X shares its instance on assignment: after I := X or Y := X a write through either side is
//     seen through the other (both 5). A value parameter shares the instance too.
//   - ClearAll on the codeunit that owns X does not detach X: it resets the globals of X's instance in place.
//     An alias that wrote 3 before reads 0 afterwards, and a write after the ClearAll is seen through X (5).
//     Without an alias, ClearAll resets X (0) and the owner's Integer global (0).
//   - A second codeunit variable Z of the same codeunit has its own instance: Z.Set(7) leaves X at 0.
// BC versions: 27, 28, 29

interface "CLX IStore"
{
    procedure Set(V: Integer);
    procedure Get(): Integer;
}

codeunit 75580 "CLX Store" implements "CLX IStore"
{
    var
        N: Integer;

    procedure Set(V: Integer)
    begin
        N := V;
    end;

    procedure Get(): Integer
    begin
        exit(N);
    end;
}

codeunit 75581 "CLX Holder"
{
    var
        X: Codeunit "CLX Store";
        Count: Integer;

    procedure SetX(V: Integer)
    begin
        X.Set(V);
    end;

    procedure SetCount(V: Integer)
    begin
        Count := V;
    end;

    procedure GetCount(): Integer
    begin
        exit(Count);
    end;

    procedure UseX()
    begin
        X.Get();
    end;

    procedure ShareIface(var I: Interface "CLX IStore")
    begin
        I := X;
    end;

    procedure ShareAlias(var Y: Codeunit "CLX Store")
    begin
        Y := X;
    end;

    procedure ClearX()
    begin
        Clear(X);
    end;

    procedure ClearAllGlobals()
    begin
        ClearAll();
    end;

    procedure ClearXViaVar()
    begin
        ClearVar(X);
    end;

    procedure GetX(): Integer
    begin
        exit(X.Get());
    end;

    procedure ValueParam(UseClearAll: Boolean): Integer
    begin
        exit(ClearThenSet(X, UseClearAll));
    end;

    local procedure ClearThenSet(P: Codeunit "CLX Store"; UseClearAll: Boolean): Integer
    begin
        if UseClearAll then
            ClearAll()
        else
            Clear(X);
        P.Set(5);
        exit(P.Get());
    end;

    local procedure ClearVar(var P: Codeunit "CLX Store")
    begin
        Clear(P);
    end;
}

codeunit 75582 "CLX Clear Shared Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_LocalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        I := X;
        Clear(X);
        I.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        Y := X;
        Clear(X);
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        Y := X;
        ClearVar(X);
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        A: Integer;
    begin
        A := ClearThenSet(X, X);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.ShareIface(I);
        H.ClearX();
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.ShareAlias(Y);
        H.ClearX();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        A: Integer;
    begin
        A := H.ValueParam(false);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.ShareIface(I);
        I.Set(3);
        H.ClearX();
        Observer.Observe('alias', Format(I.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '3');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.ShareAlias(Y);
        Y.Set(3);
        H.ClearX();
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '3');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.ShareIface(I);
        H.ClearAllGlobals();
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        A: Integer;
    begin
        A := H.ValueParam(true);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.ShareIface(I);
        I.Set(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Format(I.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '0');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUnusedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.ShareAlias(Y);
        Y.Set(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '0');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUnusedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.ShareAlias(Y);
        H.ClearXViaVar();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        I := X;
        I.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedIface_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        I := X;
        X.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedAlias_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        Y := X;
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedAlias_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        Y := X;
        X.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUnusedValueParam_WriteThroughParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
    begin
        SetThrough(X);
        Observer.Observe('x', Format(X.Get()));
        Observer.Expect('x', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_GlobalUnusedIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.ShareIface(I);
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Second_LocalUnusedX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Z: Codeunit "CLX Store";
    begin
        Z.Set(7);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('z', Format(Z.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('z', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Second_GlobalUnusedX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Z: Codeunit "CLX Store";
    begin
        Z.Set(7);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('z', Format(Z.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('z', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedIface()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        X.Get();
        I := X;
        Clear(X);
        I.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        X.Get();
        Y := X;
        Clear(X);
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        X.Get();
        Y := X;
        ClearVar(X);
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_LocalUsedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        A: Integer;
    begin
        X.Get();
        A := ClearThenSet(X, X);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.UseX();
        H.ShareIface(I);
        H.ClearX();
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.UseX();
        H.ShareAlias(Y);
        H.ClearX();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        A: Integer;
    begin
        H.UseX();
        A := H.ValueParam(false);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.UseX();
        H.ShareIface(I);
        I.Set(3);
        H.ClearX();
        Observer.Observe('alias', Format(I.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '3');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.UseX();
        H.ShareAlias(Y);
        Y.Set(3);
        H.ClearX();
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '3');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIface()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.UseX();
        H.ShareIface(I);
        H.ClearAllGlobals();
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.UseX();
        H.ShareAlias(Y);
        H.ClearAllGlobals();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedValueParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        A: Integer;
    begin
        H.UseX();
        A := H.ValueParam(true);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(A));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedIface_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.UseX();
        H.ShareIface(I);
        I.Set(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Format(I.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '0');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalUsedAlias_AliasWroteBefore()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.UseX();
        H.ShareAlias(Y);
        Y.Set(3);
        H.ClearAllGlobals();
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('alias', '0');
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalUsedAliasClearedThroughVarParam()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Y: Codeunit "CLX Store";
    begin
        H.UseX();
        H.ShareAlias(Y);
        H.ClearXViaVar();
        Y.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        X.Get();
        I := X;
        I.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedIface_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        I: Interface "CLX IStore";
    begin
        X.Get();
        I := X;
        X.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedAlias_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        X.Get();
        Y := X;
        Y.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedAlias_WriteThroughX()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Y: Codeunit "CLX Store";
    begin
        X.Get();
        Y := X;
        X.Set(5);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('alias', Format(Y.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_LocalUsedValueParam_WriteThroughParam()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
    begin
        X.Get();
        SetThrough(X);
        Observer.Observe('x', Format(X.Get()));
        Observer.Expect('x', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Share_GlobalUsedIface_WriteThroughAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        I: Interface "CLX IStore";
    begin
        H.UseX();
        H.ShareIface(I);
        I.Set(5);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('alias', Format(I.Get()));
        Observer.Expect('x', '5');
        Observer.Expect('alias', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Second_LocalUsedX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        X: Codeunit "CLX Store";
        Z: Codeunit "CLX Store";
    begin
        X.Get();
        Z.Set(7);
        Observer.Observe('x', Format(X.Get()));
        Observer.Observe('z', Format(Z.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('z', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Second_GlobalUsedX_OtherVariableWrites()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
        Z: Codeunit "CLX Store";
    begin
        H.UseX();
        Z.Set(7);
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('z', Format(Z.Get()));
        Observer.Expect('x', '0');
        Observer.Expect('z', '7');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_GlobalSetX_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
    begin
        H.SetX(3);
        H.SetCount(4);
        H.ClearAllGlobals();
        Observer.Observe('x', Format(H.GetX()));
        Observer.Observe('count', Format(H.GetCount()));
        Observer.Expect('x', '0');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_GlobalSetX_NoAlias()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "CLX Holder";
    begin
        H.SetX(3);
        H.ClearX();
        Observer.Observe('x', Format(H.GetX()));
        Observer.Expect('x', '0');
        Observer.Verify();
    end;

    local procedure ClearVar(var P: Codeunit "CLX Store")
    begin
        Clear(P);
    end;

    local procedure ClearThenSet(var P: Codeunit "CLX Store"; Q: Codeunit "CLX Store"): Integer
    begin
        Clear(P);
        Q.Set(5);
        exit(Q.Get());
    end;

    local procedure SetThrough(P: Codeunit "CLX Store")
    begin
        P.Set(5);
    end;
}
