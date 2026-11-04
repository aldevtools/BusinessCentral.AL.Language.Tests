// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74877, codeunits 74887 (callee) and 74886 (tests)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a temporary record passed to a parameter that is not declared temporary, by value and by var: IsTemporary() of the callee's record, the rows the callee sees,
//   whether an Insert in the callee reaches the stored table (read through a second, non-temporary variable) and whether the caller's temporary rows change afterwards.
//   Contrast: a parameter declared temporary. Settles the assumption temp-record-by-value-to-persistent-parameter.
// BC versions: all (CI)

table 74877 "LT TRV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74887 "LT TRV Callee"
{
    procedure ByValue(R: Record "LT TRV Row"; var Observer: Codeunit "Probe Observer"; NewId: Integer)
    begin
        Observer.Observe('byValue.isTemporary', Format(R.IsTemporary()));
        Observer.Observe('byValue.countSeen', Format(R.Count()));
        R.Id := NewId;
        R.Name := 'inCallee';
        R.Insert();
        Observer.Observe('byValue.countAfterInsert', Format(R.Count()));
        Observer.Observe('byValue.isTemporaryAfter', Format(R.IsTemporary()));
    end;

    procedure ByVar(var R: Record "LT TRV Row"; var Observer: Codeunit "Probe Observer"; NewId: Integer)
    begin
        Observer.Observe('byVar.isTemporary', Format(R.IsTemporary()));
        Observer.Observe('byVar.countSeen', Format(R.Count()));
        R.Id := NewId;
        R.Name := 'inCallee';
        R.Insert();
        Observer.Observe('byVar.countAfterInsert', Format(R.Count()));
    end;

    procedure ByValueTemporary(var Observer: Codeunit "Probe Observer"; NewId: Integer; var R: Record "LT TRV Row" temporary)
    begin
        Observer.Observe('byVarTemp.isTemporary', Format(R.IsTemporary()));
        Observer.Observe('byVarTemp.countSeen', Format(R.Count()));
        R.Id := NewId;
        R.Name := 'inCallee';
        R.Insert();
    end;

    procedure ByValueModify(R: Record "LT TRV Row"; var Observer: Codeunit "Probe Observer")
    begin
        R.FindFirst();
        R.Name := 'changed';
        R.Modify();
        Observer.Observe('modify.firstName', R.Name);
    end;

    procedure ByValueDeleteAll(R: Record "LT TRV Row"; var Observer: Codeunit "Probe Observer")
    begin
        R.DeleteAll();
        Observer.Observe('deleteAll.countInCallee', Format(R.Count()));
    end;
}

codeunit 74886 "LT TRV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Temp: Record "LT TRV Row" temporary)
    var
        Stored: Record "LT TRV Row";
    begin
        Stored.DeleteAll();
        Stored.Id := 100;
        Stored.Name := 'stored';
        Stored.Insert();
        Temp.DeleteAll();
        Temp.Id := 1;
        Temp.Name := 'temp1';
        Temp.Insert();
        Temp.Id := 2;
        Temp.Name := 'temp2';
        Temp.Insert();
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; var Temp: Record "LT TRV Row" temporary)
    var
        Stored: Record "LT TRV Row";
        Names: Text;
    begin
        Observer.Observe('caller.tempCount', Format(Temp.Count()));
        Observer.Observe('caller.storedCount', Format(Stored.Count()));
        if Temp.FindSet() then
            repeat
                Names += Format(Temp.Id) + '=' + Temp.Name + ';';
            until Temp.Next() = 0;
        Observer.Observe('caller.tempRows', Names);
        Names := '';
        if Stored.FindSet() then
            repeat
                Names += Format(Stored.Id) + '=' + Stored.Name + ';';
            until Stored.Next() = 0;
        Observer.Observe('caller.storedRows', Names);
    end;

    [Test]
    procedure TempRecord_ByValue_ToPersistentParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT TRV Callee";
        Temp: Record "LT TRV Row" temporary;
    begin
        Seed(Temp);
        Callee.ByValue(Temp, Observer, 50);
        Report(Observer, Temp);
        Observer.Expect('byValue.isTemporary', 'No');
        Observer.Expect('byValue.countSeen', '1');
        Observer.Expect('byValue.countAfterInsert', '2');
        Observer.Expect('byValue.isTemporaryAfter', 'No');
        Observer.Expect('caller.tempCount', '2');
        Observer.Expect('caller.storedCount', '2');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;');
        Observer.Expect('caller.storedRows', '50=inCallee;100=stored;');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ByVar_ToPersistentParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT TRV Callee";
        Temp: Record "LT TRV Row" temporary;
    begin
        Seed(Temp);
        Callee.ByVar(Temp, Observer, 50);
        Report(Observer, Temp);
        Observer.Expect('byVar.isTemporary', 'Yes');
        Observer.Expect('byVar.countSeen', '2');
        Observer.Expect('byVar.countAfterInsert', '3');
        Observer.Expect('caller.tempCount', '3');
        Observer.Expect('caller.storedCount', '1');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;50=inCallee;');
        Observer.Expect('caller.storedRows', '100=stored;');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ToTemporaryParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT TRV Callee";
        Temp: Record "LT TRV Row" temporary;
    begin
        Seed(Temp);
        Callee.ByValueTemporary(Observer, 50, Temp);
        Report(Observer, Temp);
        Observer.Expect('byVarTemp.isTemporary', 'Yes');
        Observer.Expect('byVarTemp.countSeen', '2');
        Observer.Expect('caller.tempCount', '3');
        Observer.Expect('caller.storedCount', '1');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;50=inCallee;');
        Observer.Expect('caller.storedRows', '100=stored;');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ByValue_ModifyAndDeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT TRV Callee";
        Temp: Record "LT TRV Row" temporary;
    begin
        Seed(Temp);
        Callee.ByValueModify(Temp, Observer);
        Report(Observer, Temp);
        Callee.ByValueDeleteAll(Temp, Observer);
        Report(Observer, Temp);
        Observer.Expect('modify.firstName', 'changed');
        Observer.Expect('caller.tempCount', '2');
        Observer.Expect('caller.storedCount', '1');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;');
        Observer.Expect('caller.storedRows', '100=changed;');
        Observer.Expect('deleteAll.countInCallee', '0');
        Observer.Expect('caller.tempCount', '2');
        Observer.Expect('caller.storedCount', '0');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;');
        Observer.Expect('caller.storedRows', '');
        Observer.Verify();
    end;

    [Test]
    procedure PersistentRecord_ByValue_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT TRV Callee";
        Temp: Record "LT TRV Row" temporary;
        Stored: Record "LT TRV Row";
    begin
        Seed(Temp);
        Callee.ByValue(Stored, Observer, 60);
        Report(Observer, Temp);
        Observer.Expect('byValue.isTemporary', 'No');
        Observer.Expect('byValue.countSeen', '1');
        Observer.Expect('byValue.countAfterInsert', '2');
        Observer.Expect('byValue.isTemporaryAfter', 'No');
        Observer.Expect('caller.tempCount', '2');
        Observer.Expect('caller.storedCount', '2');
        Observer.Expect('caller.tempRows', '1=temp1;2=temp2;');
        Observer.Expect('caller.storedRows', '60=inCallee;100=stored;');
        Observer.Verify();
    end;


    // Corpus issue 668 item 36 (writer BQ): a temporary record passed by value to an event whose parameter is not declared temporary, and the
    // subscriber's view of it (microsoft/AL issue 1671). Fixtures: codeunits LT BQ TRV Pub / Sub in record/lt-bq-odd-leads/BqObjects.al.
    [Test]
    procedure TempRecord_ByValue_ToEventSubscriber_BQ()
    var
        Temp: Record "LT TRV Row" temporary;
        Pub: Codeunit "LT BQ TRV Pub";
        Sub: Codeunit "LT BQ TRV Sub";
        Log: Codeunit "LT BQ TRV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Temp);
        Log.Take();
        BindSubscription(Sub);
        Pub.Raise(Temp);
        UnbindSubscription(Sub);
        Observer.Observe('subscriber', Log.Take());
        Observer.Observe('callerTemporary', Format(Temp.IsTemporary()));
        Observer.Observe('callerRows', Format(Temp.Count()));
        Observer.Expect('subscriber', 'temp=No count=1');
        Observer.Expect('callerTemporary', 'Yes');
        Observer.Expect('callerRows', '2');
        Observer.Verify();
    end;
}
