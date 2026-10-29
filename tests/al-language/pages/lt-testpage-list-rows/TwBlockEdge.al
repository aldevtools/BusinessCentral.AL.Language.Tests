// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: own objects 90151 - 90156 (writer TW); Assert (60021)
// Probe: al-runner issue 6117 (reporter's real-BC 29.0 run, 5/5 green), objects renamed, the two control tests moved into this codeunit
//   (one test codeunit per SingleInstance log). A List page (Editable = false, OnAfterGetRecord logs R<Id>) over a table of 45 or 80
//   rows (key Id): OpenView, GoToKey(40), Next, and GoToKey(62). Also a lookup: Page.RunModal of a plain list with a filtered record,
//   a ModalPageHandler that calls GoToRecord on row 40, reads Id and Name, then OK.
// Facts: GoToKey(40) reads the block 19..40 (the target is its last row), then rows 39 and 40 again, then the rows after them up to
//   row 60 at most (41..45 of 45 rows, 41..60 of 80); Next() reads nothing. GoToKey(62) of 80 rows then reads 59..80. The lookup
//   answers LookupOK on row 40. Controls: GoToKey(30) reads 19..40 only; the lookup on row 30.
// Neighbours: ListRowsWindow.al (GoToKey to the last row of the view), handlers/TestPageRuntimeContracts.al (GoToKey windows of 60 rows).
// BC versions: 27, 28, 29

table 90151 "LT TW Block Edge Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
        field(3; Blocked; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 90152 "LT TW Block Edge Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 90153 "LT TW Block Edge Logged List"
{
    PageType = List;
    SourceTable = "LT TW Block Edge Row";
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT TW Block Edge Log";
}

page 90154 "LT TW Block Edge Plain List"
{
    PageType = List;
    SourceTable = "LT TW Block Edge Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Blocked; Rec.Blocked) { }
            }
        }
    }
}

codeunit 90155 "LT TW Block Edge Picker"
{
    procedure PickUnblocked(): Integer
    var
        Row: Record "LT TW Block Edge Row";
    begin
        Row.SetRange(Blocked, false);
        if Page.RunModal(Page::"LT TW Block Edge Plain List", Row) = Action::LookupOK then
            exit(Row.Id);
        exit(-1);
    end;
}

codeunit 90156 "LT TW Block Edge Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "LT TW Block Edge Log";
        Target: Integer;
        SeenInLookup: Text;

    [Test]
    procedure GoToKeyLastRowOfFullBlockMoreRowsAfter()
    var
        P: TestPage "LT TW Block Edge Logged List";
        Observed: Text;
    begin
        SeedRows(45);
        P.OpenView();
        Log.Take();
        P.GoToKey(40);
        Observed := 'gotokey=' + P.Id.Value() + '/' + P.Name.Value() + ':' + Log.Take();
        P.Next();
        Observed += ' next=' + P.Id.Value() + ':' + Log.Take();
        P.Close();
        Assert.AreEqual('gotokey=40/N40:R19;R20;R21;R22;R23;R24;R25;R26;R27;R28;R29;R30;R31;R32;R33;R34;R35;R36;R37;R38;R39;R40;R39;R40;R41;R42;R43;R44;R45; next=41:', Observed, 'GoToKey onto row 40 of 45.');
    end;

    [Test]
    procedure GoToKeyLastRowOfFullBlockFullBlockAfter()
    var
        P: TestPage "LT TW Block Edge Logged List";
        Observed: Text;
    begin
        SeedRows(80);
        P.OpenView();
        Log.Take();
        P.GoToKey(40);
        Observed := 'gotokey=' + P.Id.Value() + ':' + Log.Take();
        P.Next();
        Observed += ' next=' + P.Id.Value() + ':' + Log.Take();
        P.GoToKey(62);
        Observed += ' gotokey62=' + P.Id.Value() + ':' + Log.Take();
        P.Close();
        Assert.AreEqual('gotokey=40:R19;R20;R21;R22;R23;R24;R25;R26;R27;R28;R29;R30;R31;R32;R33;R34;R35;R36;R37;R38;R39;R40;R39;R40;R41;R42;R43;R44;R45;R46;R47;R48;R49;R50;R51;R52;R53;R54;R55;R56;R57;R58;R59;R60; next=41: gotokey62=62:R59;R60;R61;R62;R63;R64;R65;R66;R67;R68;R69;R70;R71;R72;R73;R74;R75;R76;R77;R78;R79;R80;', Observed, 'GoToKey onto row 40 of 80.');
    end;

    [Test]
    [HandlerFunctions('PickHandler')]
    procedure LookupGoToRecordLastRowOfFullBlockThenOK()
    var
        Picker: Codeunit "LT TW Block Edge Picker";
        Picked: Integer;
    begin
        SeedRows(45);
        Target := 40;
        Picked := Picker.PickUnblocked();
        Assert.AreEqual('40 40/N40', Format(Picked) + ' ' + SeenInLookup, 'Lookup onto row 40 of 45.');
    end;

    [Test]
    procedure GoToKeyInsideBlockControl()
    var
        P: TestPage "LT TW Block Edge Logged List";
        Observed: Text;
    begin
        SeedRows(45);
        P.OpenView();
        Log.Take();
        P.GoToKey(30);
        Observed := 'gotokey=' + P.Id.Value() + '/' + P.Name.Value() + ':' + Log.Take();
        P.Next();
        Observed += ' next=' + P.Id.Value() + ':' + Log.Take();
        P.Close();
        Assert.AreEqual('gotokey=30/N30:R19;R20;R21;R22;R23;R24;R25;R26;R27;R28;R29;R30;R31;R32;R33;R34;R35;R36;R37;R38;R39;R40; next=31:', Observed, 'GoToKey onto row 30 of 45.');
    end;

    [Test]
    [HandlerFunctions('PickHandler')]
    procedure LookupGoToRecordInsideBlockControl()
    var
        Picker: Codeunit "LT TW Block Edge Picker";
        Picked: Integer;
    begin
        SeedRows(45);
        Target := 30;
        Picked := Picker.PickUnblocked();
        Assert.AreEqual('30 30/N30', Format(Picked) + ' ' + SeenInLookup, 'Lookup onto row 30 of 45.');
    end;

    [ModalPageHandler]
    procedure PickHandler(var Lookup: TestPage "LT TW Block Edge Plain List")
    var
        Row: Record "LT TW Block Edge Row";
    begin
        Row.Get(Target);
        Lookup.GoToRecord(Row);
        SeenInLookup := Lookup.Id.Value() + '/' + Lookup.Name.Value();
        Lookup.OK().Invoke();
    end;

    local procedure SeedRows(RowCount: Integer)
    var
        Row: Record "LT TW Block Edge Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to RowCount do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'N' + Format(i);
            Row.Insert();
        end;
        Log.Take();
        SeenInLookup := '';
    end;
}
