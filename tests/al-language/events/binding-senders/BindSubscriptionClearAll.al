// BindSubscription and ClearAll (al-runner issue 6974). A codeunit holds a bound manual subscriber in a global variable and calls
// ClearAll: does the binding end, and is the variable afterwards the bound instance or a fresh one (rebinding it, unbinding it, and the
// Tag the subscriber adds to the hits tell them apart)? Clear of the same global, for comparison (Clear of a local variable is pinned in
// TestProbeEventContracts.al BSK_Bind_AfterClear_And_OnCopy). Once with the global in a plain codeunit, once in the test codeunit itself.
// Subscriber and publisher are in BindSubscriptionKinds.Objects.al: "LT BSK Manual" adds 'M' + its Tag to the hits of a Ping, and the
// automatic subscriber "LT BSK Static Explicit" adds 'A' to every Ping.
// local object: ClearAll resets the globals of the codeunit that calls it, so the bound variable is a global of a codeunit of its own.

codeunit 95394 "EVT BindSub ClearAll Holder"
{
    var
        Sub: Codeunit "LT BSK Manual";
        Marker: Integer;

    procedure SetTag(NewTag: Text)
    begin
        Sub.SetTag(NewTag);
    end;

    procedure SetMarker(NewMarker: Integer)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Integer
    begin
        exit(Marker);
    end;

    procedure Bind(): Text
    var
        R: Text;
    begin
        if TryBind() then
            R := 'ok'
        else
            R := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(R);
    end;

    procedure Unbind(): Text
    begin
        exit(Format(UnbindSubscription(Sub)));
    end;

    procedure DoClearAll()
    begin
        ClearAll();
    end;

    procedure DoClear()
    begin
        Clear(Sub);
    end;

    [TryFunction]
    local procedure TryBind()
    begin
        BindSubscription(Sub);
    end;
}

codeunit 95395 "EVT BindSub ClearAll Tests"
{
    Subtype = Test;

    var
        Sub: Codeunit "LT BSK Manual";

    [Test]
    procedure ClearAll_HolderWithBoundGlobal_Binding()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        Holder: Codeunit "EVT BindSub ClearAll Holder";
    begin
        Holder.SetTag('1');
        Holder.SetMarker(5);
        O.Observe('bind', Holder.Bind());
        O.Observe('hits bound', Pub.Ping());
        Holder.DoClearAll();
        O.Observe('marker after clearall', Format(Holder.GetMarker()));
        O.Observe('hits after clearall', Pub.Ping());
        Holder.SetTag('C');
        O.Observe('hits after settag', Pub.Ping());
        O.Observe('bind after clearall', Holder.Bind());
        O.Observe('hits after bind', Pub.Ping());
        O.Observe('unbind', Holder.Unbind());
        O.Observe('hits after unbind', Pub.Ping());
        O.Observe('unbind again', Holder.Unbind());
        O.Observe('hits end', Pub.Ping());
        O.Finish();
    end;

    [Test]
    procedure Clear_HolderWithBoundGlobal_Binding()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        Holder: Codeunit "EVT BindSub ClearAll Holder";
    begin
        Holder.SetTag('2');
        Holder.SetMarker(5);
        O.Observe('bind', Holder.Bind());
        O.Observe('hits bound', Pub.Ping());
        Holder.DoClear();
        O.Observe('marker after clear', Format(Holder.GetMarker()));
        O.Observe('hits after clear', Pub.Ping());
        Holder.SetTag('D');
        O.Observe('hits after settag', Pub.Ping());
        O.Observe('bind after clear', Holder.Bind());
        O.Observe('hits after bind', Pub.Ping());
        O.Observe('unbind', Holder.Unbind());
        O.Observe('hits after unbind', Pub.Ping());
        O.Observe('unbind again', Holder.Unbind());
        O.Observe('hits end', Pub.Ping());
        O.Finish();
    end;

    [Test]
    procedure ClearAll_TestCodeunitWithBoundGlobal_Binding()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
    begin
        UnbindSubscription(Sub);
        Sub.SetTag('3');
        O.Observe('bind', BindResult());
        O.Observe('hits bound', Pub.Ping());
        ClearAll();
        O.Observe('hits after clearall', Pub.Ping());
        Sub.SetTag('E');
        O.Observe('hits after settag', Pub.Ping());
        O.Observe('bind after clearall', BindResult());
        O.Observe('hits after bind', Pub.Ping());
        O.Observe('unbind', Format(UnbindSubscription(Sub)));
        O.Observe('hits after unbind', Pub.Ping());
        O.Observe('unbind again', Format(UnbindSubscription(Sub)));
        O.Observe('hits end', Pub.Ping());
        O.Finish();
    end;

    local procedure BindResult(): Text
    var
        R: Text;
    begin
        if TryBindGlobal() then
            R := 'ok'
        else
            R := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(R);
    end;

    [TryFunction]
    local procedure TryBindGlobal()
    begin
        BindSubscription(Sub);
    end;
}
