// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 78305, subscriber codeunit 78306, test codeunit 78307
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: AreFieldsLoaded on Rec and xRec inside OnBeforeModify and OnAfterModify subscribers when the record was read with SetLoadFields and then changed with
// Modify(true) and Modify(false); whether Modify loads more fields into the caller's record; the same after a Get that loads only the primary key.
// BC versions: 27, 28, 29

table 78305 "LT AF Mod"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Text[30]) { }
        field(3; B; Integer) { }
        field(4; C; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 78306 "LT AF Mod Subscribers"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    local procedure Loaded(var R: Record "LT AF Mod"): Text
    begin
        exit(
            'A=' + Format(R.AreFieldsLoaded(R.A)) +
            ' B=' + Format(R.AreFieldsLoaded(R.B)) +
            ' C=' + Format(R.AreFieldsLoaded(R.C)) +
            ' AB=' + Format(R.AreFieldsLoaded(R.A, R.B)));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT AF Mod", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT AF Mod"; var xRec: Record "LT AF Mod"; RunTrigger: Boolean)
    begin
        Log += 'before rec ' + Loaded(Rec) + '; before xrec ' + Loaded(xRec) + '; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT AF Mod", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModify(var Rec: Record "LT AF Mod"; var xRec: Record "LT AF Mod"; RunTrigger: Boolean)
    begin
        Log += 'after rec ' + Loaded(Rec) + '; after xrec ' + Loaded(xRec) + '; ';
    end;
}

codeunit 78307 "LT AF Modify LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Subscribers: Codeunit "LT AF Mod Subscribers";

    local procedure Seed()
    var
        Row: Record "LT AF Mod";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.A := 'one';
        Row.B := 10;
        Row.C := 1.5;
        Row.Insert();
        Subscribers.Take();
    end;

    local procedure Loaded(var R: Record "LT AF Mod"): Text
    begin
        exit(
            'A=' + Format(R.AreFieldsLoaded(R.A)) +
            ' B=' + Format(R.AreFieldsLoaded(R.B)) +
            ' C=' + Format(R.AreFieldsLoaded(R.C)));
    end;

    [Test]
    procedure AF_Modify_True_After_SetLoadFields_A()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AF Mod";
    begin
        Seed();
        Row.SetLoadFields(A);
        Row.Get(1);
        Observer.Observe('after get', Loaded(Row));
        Row.A := 'two';
        Row.Modify(true);
        Observer.Observe('subscribers modify(true)', Subscribers.Take());
        Observer.Observe('caller after modify(true)', Loaded(Row));
        Observer.Expect('after get', 'A=Yes B=No C=No');
        Observer.Expect('subscribers modify(true)', 'before rec A=Yes B=Yes C=Yes AB=Yes; before xrec A=Yes B=Yes C=Yes AB=Yes; after rec A=Yes B=Yes C=Yes AB=Yes; after xrec A=Yes B=Yes C=Yes AB=Yes; ');
        Observer.Expect('caller after modify(true)', 'A=Yes B=Yes C=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Modify_False_After_SetLoadFields_A()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AF Mod";
    begin
        Seed();
        Row.SetLoadFields(A);
        Row.Get(1);
        Row.A := 'two';
        Row.Modify(false);
        Observer.Observe('subscribers modify(false)', Subscribers.Take());
        Observer.Observe('caller after modify(false)', Loaded(Row));
        Observer.Expect('subscribers modify(false)', 'before rec A=Yes B=Yes C=Yes AB=Yes; before xrec A=Yes B=Yes C=Yes AB=Yes; after rec A=Yes B=Yes C=Yes AB=Yes; after xrec A=Yes B=Yes C=Yes AB=Yes; ');
        Observer.Expect('caller after modify(false)', 'A=Yes B=Yes C=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Modify_True_After_SetLoadFields_A_B()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AF Mod";
    begin
        Seed();
        Row.SetLoadFields(A, B);
        Row.FindFirst();
        Row.B := 11;
        Row.Modify(true);
        Observer.Observe('subscribers modify(true) A,B', Subscribers.Take());
        Observer.Observe('caller after modify(true) A,B', Loaded(Row));
        Observer.Expect('subscribers modify(true) A,B', 'before rec A=Yes B=Yes C=Yes AB=Yes; before xrec A=Yes B=Yes C=Yes AB=Yes; after rec A=Yes B=Yes C=Yes AB=Yes; after xrec A=Yes B=Yes C=Yes AB=Yes; ');
        Observer.Expect('caller after modify(true) A,B', 'A=Yes B=Yes C=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AF_Modify_True_Without_SetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AF Mod";
    begin
        Seed();
        Row.Get(1);
        Row.A := 'two';
        Row.Modify(true);
        Observer.Observe('subscribers modify(true) full', Subscribers.Take());
        Observer.Observe('caller after modify(true) full', Loaded(Row));
        Observer.Expect('subscribers modify(true) full', 'before rec A=Yes B=Yes C=Yes AB=Yes; before xrec A=Yes B=Yes C=Yes AB=Yes; after rec A=Yes B=Yes C=Yes AB=Yes; after xrec A=Yes B=Yes C=Yes AB=Yes; ');
        Observer.Expect('caller after modify(true) full', 'A=Yes B=Yes C=Yes');
        Observer.Verify();
    end;

    // Corpus issue 668 item 38 (writer br): what an OnBeforeModify / OnAfterModify subscriber reads from xRec fields the caller never loaded.
    [Test]
    procedure BR_Modify_True_After_SetLoadFields_A_SubscriberReadsXRecValues()
    var
        Observer: Codeunit "Probe Observer";
        BrSubscribers: Codeunit "LT BR AF Mod Subscribers";
        Row: Record "LT BR AF Mod";
    begin
        BrSeed();
        BrSubscribers.SetReload(false);
        Row.SetLoadFields(A);
        Row.Get(1);
        Row.B := 11;
        Row.Modify(true);
        Observer.Observe('subscribers', BrSubscribers.Take());
        Observer.Observe('caller c', Format(Row.C, 0, 9));
        Row.Get(1);
        Observer.Observe('stored', Format(Row.B) + '|' + Format(Row.C, 0, 9));
        Observer.Expect('subscribers', 'before xrec loadedC=Yes B=11 C=1.5; before rec loadedC=Yes B=11 C=1.5; after xrec loadedC=Yes B=11 C=1.5; after rec loadedC=Yes B=11 C=1.5; ');
        Observer.Expect('caller c', '1.5');
        Observer.Expect('stored', '11|1.5');
        Observer.Verify();
    end;

    [Test]
    procedure BR_Modify_True_After_SetLoadFields_A_SubscriberReloadsXRec()
    var
        Observer: Codeunit "Probe Observer";
        BrSubscribers: Codeunit "LT BR AF Mod Subscribers";
        Row: Record "LT BR AF Mod";
    begin
        BrSeed();
        BrSubscribers.SetReload(true);
        Row.SetLoadFields(A);
        Row.Get(1);
        Row.B := 12;
        Row.Modify(true);
        BrSubscribers.SetReload(false);
        Observer.Observe('subscribers', BrSubscribers.Take());
        Row.Get(1);
        Observer.Observe('stored', Format(Row.B) + '|' + Format(Row.C, 0, 9));
        Observer.Expect('subscribers', 'reload find=Yes; before xrec loadedC=Yes B=10 C=1.5; before rec loadedC=Yes B=12 C=1.5; after xrec loadedC=Yes B=10 C=1.5; after rec loadedC=Yes B=12 C=1.5; ');
        Observer.Expect('stored', '12|1.5');
        Observer.Verify();
    end;

    local procedure BrSeed()
    var
        Row: Record "LT BR AF Mod";
        BrSubscribers: Codeunit "LT BR AF Mod Subscribers";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.A := 'one';
        Row.B := 10;
        Row.C := 1.5;
        Row.Insert();
        BrSubscribers.Take();
    end;
}

table 82950 "LT BR AF Mod"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Text[30]) { }
        field(3; B; Integer) { }
        field(4; C; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 82951 "LT BR AF Mod Subscribers"
{
    SingleInstance = true;

    var
        Log: Text;
        Reload: Boolean;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure SetReload(NewReload: Boolean)
    begin
        Reload := NewReload;
    end;

    local procedure Values(var R: Record "LT BR AF Mod"): Text
    begin
        exit('loadedC=' + Format(R.AreFieldsLoaded(R.C)) + ' B=' + Format(R.B) + ' C=' + Format(R.C, 0, 9));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BR AF Mod", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT BR AF Mod"; var xRec: Record "LT BR AF Mod"; RunTrigger: Boolean)
    begin
        if Reload then begin
            xRec.AddLoadFields(C);
            Log += 'reload find=' + Format(xRec.Find('=')) + '; ';
        end;
        Log += 'before xrec ' + Values(xRec) + '; before rec ' + Values(Rec) + '; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BR AF Mod", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModify(var Rec: Record "LT BR AF Mod"; var xRec: Record "LT BR AF Mod"; RunTrigger: Boolean)
    begin
        Log += 'after xrec ' + Values(xRec) + '; after rec ' + Values(Rec) + '; ';
    end;
}
