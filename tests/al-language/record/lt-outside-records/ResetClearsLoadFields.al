// Does Reset (and Init, Clear) drop a SetLoadFields request, so that the next fetch loads every field?
// Real BC: Reset and Clear drop it; Init keeps it.
// The existing case record/lt-record-read/RcAMisc.al (SetLoadFields_Blank_Resets_To_All) fetches the full
// row first, so it passes either way. Here the record variable has never fetched before the Reset, unless the
// test name says otherwise. Loaded state is read with AreFieldsLoaded, which does not load anything itself.
// Source: al-runner issue 5764 (Q3_SetLoadFields_Lifetime).
table 88870 "LT RY Wide"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; Notes; Text[250]) { }
        field(4; Amount; Decimal) { }
        field(5; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 88871 "LT RY Reset Load Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Wide: Record "LT RY Wide";
        i: Integer;
    begin
        Wide.DeleteAll();
        for i := 1 to 4 do begin
            Clear(Wide);
            Wide.Code := 'W' + Format(i);
            Wide.Description := 'D' + Format(i);
            Wide.Notes := 'N' + Format(i);
            Wide.Amount := (5 - i) * 10;
            Wide.Qty := i;
            Wide.Insert();
        end;
    end;

    local procedure Loaded(var Wide: Record "LT RY Wide"): Text
    begin
        exit(StrSubstNo('%1 desc=%2 notes=%3 amount=%4 qty=%5', Wide.Code,
            Wide.AreFieldsLoaded(Wide.Description), Wide.AreFieldsLoaded(Wide.Notes),
            Wide.AreFieldsLoaded(Wide.Amount), Wide.AreFieldsLoaded(Wide.Qty)));
    end;

    [Test]
    procedure ResetThenFindFirst_NoEarlierFetch()
    var
        Wide: Record "LT RY Wide";
        Control: Record "LT RY Wide";
    begin
        Seed();
        Control.SetLoadFields(Description);
        Control.FindFirst();
        Observer.Observe('control without Reset', Loaded(Control));
        Wide.SetLoadFields(Description);
        Wide.Reset();
        Wide.FindFirst();
        Observer.Observe('after Reset', Loaded(Wide));
        Observer.Observe('notes value', Wide.Notes);
        Observer.Expect('control without Reset', 'W1 desc=Yes notes=No amount=No qty=No');
        Observer.Expect('after Reset', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Expect('notes value', 'N1');
        Observer.Verify();
    end;

    [Test]
    procedure ResetThenGet_NoEarlierFetch()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.Reset();
        Wide.Get('W2');
        Observer.Observe('after Reset', Loaded(Wide));
        Observer.Expect('after Reset', 'W2 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResetThenFindSet_NoEarlierFetch()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.Reset();
        Wide.FindSet();
        Observer.Observe('first row', Loaded(Wide));
        Wide.Next();
        Observer.Observe('second row', Loaded(Wide));
        Observer.Expect('first row', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Expect('second row', 'W2 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResetThenGet_AfterEarlierFullGet()
    var
        Wide: Record "LT RY Wide";
        Control: Record "LT RY Wide";
    begin
        Seed();
        Control.Get('W1');
        Control.SetLoadFields(Description);
        Control.Get('W2');
        Observer.Observe('control without Reset', Loaded(Control));
        Wide.Get('W1');
        Observer.Observe('full get', Loaded(Wide));
        Wide.SetLoadFields(Description);
        Wide.Reset();
        Wide.Get('W2');
        Observer.Observe('after Reset', Loaded(Wide));
        Observer.Expect('control without Reset', 'W2 desc=Yes notes=No amount=No qty=No');
        Observer.Expect('full get', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Expect('after Reset', 'W2 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResetAfterPartialFetch_KeepsBufferThenRefetchLoadsAll()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.FindFirst();
        Wide.Reset();
        Observer.Observe('after Reset, no fetch', Loaded(Wide));
        Wide.FindLast();
        Observer.Observe('FindLast after Reset', Loaded(Wide));
        Observer.Expect('after Reset, no fetch', 'W1 desc=Yes notes=No amount=No qty=No');
        Observer.Expect('FindLast after Reset', 'W4 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResetAfterAddLoadFields_NoEarlierFetch()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.AddLoadFields(Amount);
        Wide.Reset();
        Wide.FindFirst();
        Observer.Observe('after Reset', Loaded(Wide));
        Observer.Expect('after Reset', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResetWithFilters_ClearsFiltersAndLoadFields()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.SetRange(Code, 'W3');
        Wide.Reset();
        Wide.FindFirst();
        Observer.Observe('after Reset', Loaded(Wide) + ' filters=' + Wide.GetFilters());
        Observer.Expect('after Reset', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes filters=');
        Observer.Verify();
    end;

    [Test]
    procedure InitThenFindFirst_NoEarlierFetch_KeepsLoadFields()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Wide.Init();
        Wide.FindFirst();
        Observer.Observe('after Init', Loaded(Wide));
        // Init keeps the request (BC 27.5, 28.5, 29.0); only Reset and Clear drop it.
        Observer.Expect('after Init', 'W1 desc=Yes notes=No amount=No qty=No');
        Observer.Verify();
    end;

    [Test]
    procedure ClearThenFindFirst_NoEarlierFetch()
    var
        Wide: Record "LT RY Wide";
    begin
        Seed();
        Wide.SetLoadFields(Description);
        Clear(Wide);
        Wide.FindFirst();
        Observer.Observe('after Clear', Loaded(Wide));
        Observer.Expect('after Clear', 'W1 desc=Yes notes=Yes amount=Yes qty=Yes');
        Observer.Verify();
    end;
}
