// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96230-96231 (LT WF3 Flag, LT WF3 Bool Filter)
// Probe: from al-runner issue 7195: a Boolean filter under GlobalLanguage 1031 (and 1033, 1036 as controls). SetRange(Bool, false / true) then
//   GetFilter; SetFilter(Bool, <that text>) and Count; SetFilter with the words Ja, ja, Nein, Yes, no, true, False, 1, 0 (accepted or not, the
//   error text of a rejected one); Format of a Boolean; and the Base Application round trip of Sales Line.FilterLinesWithItemToPlan, which
//   runs SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter")) after Item-Check Avail set Item.SetRange("Drop Shipment Filter", false).
// Facts: see the assertions below.
// BC versions: 27+ (tested by the corpus CI matrix)

table 96230 "LT WF3 Flag"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Active; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 96231 "LT WF3 Bool Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(var Flag: Record "LT WF3 Flag"; Word: Text)
    begin
        Flag.SetFilter(Flag.Active, Word);
    end;

    local procedure Seed()
    var
        Flag: Record "LT WF3 Flag";
    begin
        Flag.DeleteAll();
        Flag."No." := 1;
        Flag.Active := false;
        Flag.Insert();
        Flag."No." := 2;
        Flag.Active := true;
        Flag.Insert();
    end;

    local procedure Words(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Flag: Record "LT WF3 Flag";
        Word: Text;
        WordList: List of [Text];
        Result: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        WordList.AddRange('Ja', 'ja', 'Nein', 'Yes', 'no', 'true', 'False', '1', '0', 'Oui', 'Non');
        foreach Word in WordList do begin
            Flag.Reset();
            ClearLastError();
            if TrySetFilter(Flag, Word) then
                Result := 'ok|' + Flag.GetFilter(Flag.Active) + '|count=' + Format(Flag.Count())
            else
                Result := 'err|' + GetLastErrorText();
            Observer.Observe('word ' + Word, Result);
        end;
        GlobalLanguage(1033);
    end;

    local procedure RoundTrip(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Flag: Record "LT WF3 Flag";
        Back: Record "LT WF3 Flag";
        B: Boolean;
        Text1: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        Flag.SetRange(Flag.Active, false);
        Text1 := Flag.GetFilter(Flag.Active);
        Observer.Observe('GetFilter of SetRange false', Text1);
        ClearLastError();
        if TrySetFilter(Back, Text1) then
            Observer.Observe('SetFilter of that text', 'ok|' + Back.GetFilter(Back.Active) + '|count=' + Format(Back.Count()))
        else
            Observer.Observe('SetFilter of that text', 'err|' + GetLastErrorText());
        Flag.Reset();
        Flag.SetRange(Flag.Active, true);
        Text1 := Flag.GetFilter(Flag.Active);
        Observer.Observe('GetFilter of SetRange true', Text1);
        Clear(Back);
        ClearLastError();
        if TrySetFilter(Back, Text1) then
            Observer.Observe('SetFilter of that true text', 'ok|' + Back.GetFilter(Back.Active) + '|count=' + Format(Back.Count()))
        else
            Observer.Observe('SetFilter of that true text', 'err|' + GetLastErrorText());
        Flag.Reset();
        Flag.SetFilter(Flag.Active, '%1', false);
        Observer.Observe('GetFilter of SetFilter %1 false', Flag.GetFilter(Flag.Active));
        Observer.Observe('Format false', Format(B));
        Observer.Observe('Format true', Format(true));
        GlobalLanguage(1033);
    end;

    [TryFunction]
    local procedure TryItemToPlan(var Item: Record Item; var SalesLine: Record "Sales Line"; var Exists: Boolean)
    begin
        Exists := SalesLine.LinesWithItemToPlanExist(Item, Enum::"Sales Document Type"::Order);
    end;

    local procedure BaseApp(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Exists: Boolean;
    begin
        GlobalLanguage(Lang);
        Item."No." := 'WF3-NONE';
        Item.SetRange("No.", 'WF3-NONE');
        Item.SetRange("Drop Shipment Filter", false);
        Observer.Observe('Item GetFilter Drop Shipment Filter', Item.GetFilter("Drop Shipment Filter"));
        ClearLastError();
        if TryItemToPlan(Item, SalesLine, Exists) then
            Observer.Observe('LinesWithItemToPlanExist', 'ok|' + Format(Exists) + '|' + SalesLine.GetFilter("Drop Shipment"))
        else
            Observer.Observe('LinesWithItemToPlanExist', 'err|' + GetLastErrorText());
        GlobalLanguage(1033);
    end;

    [Test]
    procedure WF3_Words_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Words(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Words_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Words(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Words_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Words(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_RoundTrip_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_RoundTrip_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_RoundTrip_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_BaseApp_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_BaseApp_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_BaseApp_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1036);
        Observer.Finish();
    end;
}
