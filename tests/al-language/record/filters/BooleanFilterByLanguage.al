// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96230-96231 (LT WF3 Flag, LT WF3 Bool Filter)
// Probe: from al-runner issue 7195: a Boolean filter under GlobalLanguage 1031 (and 1033, 1036 as controls). SetRange(Bool, false / true) then
//   GetFilter; SetFilter(Bool, <that text>) and Count; SetFilter with the words Ja, ja, Nein, Yes, no, true, False, 1, 0 (accepted or not, the
//   error text of a rejected one); Format of a Boolean; and the Base Application round trip of Sales Line.FilterLinesWithItemToPlan, which
//   runs SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter")) after Item-Check Avail set Item.SetRange("Drop Shipment Filter", false).
// Facts (BC 27.5, 28.5 and 29.0 alike): the Boolean filter reads back its own GetFilter text in every language: 1031 gives Nein / Ja, 1036 Non / Oui,
//   1033 No / Yes, and SetFilter of that text selects the same one row. Under 1031 the filter accepts Ja, ja, Nein, true, False, 1 and 0 and rejects
//   Yes, no, Oui and Non; under 1036 Oui, Non, no, true, False, 1 and 0 are accepted and Ja, ja, Nein and Yes are rejected; under 1033 Yes, no, true,
//   False, 1 and 0 are accepted and the German and French words are rejected. A rejected word raises the localized "filter ... is not valid for the
//   ... field" text with "can't be evaluated into type Boolean". Sales Line.LinesWithItemToPlanExist after Item.SetRange("Drop Shipment Filter", false)
//   runs without error in each language and the Sales Line filter reads Nein, Non or No.
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
        Observer.Expect('word Ja', 'err|The filter "Ja" is not valid for the Active field on the LT WF3 Flag table. The value "Ja" can''t be evaluated into type Boolean.');
        Observer.Expect('word ja', 'err|The filter "ja" is not valid for the Active field on the LT WF3 Flag table. The value "ja" can''t be evaluated into type Boolean.');
        Observer.Expect('word Nein', 'err|The filter "Nein" is not valid for the Active field on the LT WF3 Flag table. The value "Nein" can''t be evaluated into type Boolean.');
        Observer.Expect('word Yes', 'ok|Yes|count=1');
        Observer.Expect('word no', 'ok|No|count=1');
        Observer.Expect('word true', 'ok|Yes|count=1');
        Observer.Expect('word False', 'ok|No|count=1');
        Observer.Expect('word 1', 'ok|Yes|count=1');
        Observer.Expect('word 0', 'ok|No|count=1');
        Observer.Expect('word Oui', 'err|The filter "Oui" is not valid for the Active field on the LT WF3 Flag table. The value "Oui" can''t be evaluated into type Boolean.');
        Observer.Expect('word Non', 'err|The filter "Non" is not valid for the Active field on the LT WF3 Flag table. The value "Non" can''t be evaluated into type Boolean.');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_Words_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Words(Observer, 1031);
        Observer.Expect('word Ja', 'ok|Ja|count=1');
        Observer.Expect('word ja', 'ok|Ja|count=1');
        Observer.Expect('word Nein', 'ok|Nein|count=1');
        Observer.Expect('word Yes', 'err|Der Filter ''Yes'' ist für das Feld ''Active'' der Tabelle ''LT WF3 Flag'' nicht gültig. Der Wert „Yes“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('word no', 'err|Der Filter ''no'' ist für das Feld ''Active'' der Tabelle ''LT WF3 Flag'' nicht gültig. Der Wert „no“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('word true', 'ok|Ja|count=1');
        Observer.Expect('word False', 'ok|Nein|count=1');
        Observer.Expect('word 1', 'ok|Ja|count=1');
        Observer.Expect('word 0', 'ok|Nein|count=1');
        Observer.Expect('word Oui', 'err|Der Filter ''Oui'' ist für das Feld ''Active'' der Tabelle ''LT WF3 Flag'' nicht gültig. Der Wert „Oui“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('word Non', 'err|Der Filter ''Non'' ist für das Feld ''Active'' der Tabelle ''LT WF3 Flag'' nicht gültig. Der Wert „Non“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_Words_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Words(Observer, 1036);
        Observer.Expect('word Ja', 'err|Le filtre « Ja » n''est pas valide pour le champ Active de la table LT WF3 Flag. La valeur « Ja » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('word ja', 'err|Le filtre « ja » n''est pas valide pour le champ Active de la table LT WF3 Flag. La valeur « ja » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('word Nein', 'err|Le filtre « Nein » n''est pas valide pour le champ Active de la table LT WF3 Flag. La valeur « Nein » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('word Yes', 'err|Le filtre « Yes » n''est pas valide pour le champ Active de la table LT WF3 Flag. La valeur « Yes » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('word no', 'ok|Non|count=1');
        Observer.Expect('word true', 'ok|Oui|count=1');
        Observer.Expect('word False', 'ok|Non|count=1');
        Observer.Expect('word 1', 'ok|Oui|count=1');
        Observer.Expect('word 0', 'ok|Non|count=1');
        Observer.Expect('word Oui', 'ok|Oui|count=1');
        Observer.Expect('word Non', 'ok|Non|count=1');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_RoundTrip_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1033);
        Observer.Expect('GetFilter of SetRange false', 'No');
        Observer.Expect('SetFilter of that text', 'ok|No|count=1');
        Observer.Expect('GetFilter of SetRange true', 'Yes');
        Observer.Expect('SetFilter of that true text', 'ok|Yes|count=1');
        Observer.Expect('GetFilter of SetFilter %1 false', 'No');
        Observer.Expect('Format false', 'No');
        Observer.Expect('Format true', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_RoundTrip_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1031);
        Observer.Expect('GetFilter of SetRange false', 'Nein');
        Observer.Expect('SetFilter of that text', 'ok|Nein|count=1');
        Observer.Expect('GetFilter of SetRange true', 'Ja');
        Observer.Expect('SetFilter of that true text', 'ok|Ja|count=1');
        Observer.Expect('GetFilter of SetFilter %1 false', 'Nein');
        Observer.Expect('Format false', 'Nein');
        Observer.Expect('Format true', 'Ja');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_RoundTrip_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 1036);
        Observer.Expect('GetFilter of SetRange false', 'Non');
        Observer.Expect('SetFilter of that text', 'ok|Non|count=1');
        Observer.Expect('GetFilter of SetRange true', 'Oui');
        Observer.Expect('SetFilter of that true text', 'ok|Oui|count=1');
        Observer.Expect('GetFilter of SetFilter %1 false', 'Non');
        Observer.Expect('Format false', 'Non');
        Observer.Expect('Format true', 'Oui');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_BaseApp_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1033);
        Observer.Expect('Item GetFilter Drop Shipment Filter', 'No');
        Observer.Expect('LinesWithItemToPlanExist', 'ok|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_BaseApp_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1031);
        Observer.Expect('Item GetFilter Drop Shipment Filter', 'Nein');
        Observer.Expect('LinesWithItemToPlanExist', 'ok|Nein|Nein');
        Observer.Verify();
    end;

    [Test]
    procedure WF3_BaseApp_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BaseApp(Observer, 1036);
        Observer.Expect('Item GetFilter Drop Shipment Filter', 'Non');
        Observer.Expect('LinesWithItemToPlanExist', 'ok|Non|Non');
        Observer.Verify();
    end;
}
