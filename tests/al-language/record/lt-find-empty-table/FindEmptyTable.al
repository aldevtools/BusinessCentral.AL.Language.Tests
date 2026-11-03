// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67072
// Probe: Record.Find on an empty table with no filter, the result not used, and with the result used, for the search strings '=', '-', '+', '>', '<' and
// '=><', and Find() with no argument. Does a call with an unused result raise an error, and what does it return. Object ids 67072 - 67073.
// Writer TV (2026-10-29, TV_* tests): the same unused Find on a table that has rows when no row meets the search, and on an empty table with a key
// value other than the default.

table 67072 "LT FE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67073 "LT FE Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFindUnused(Mode: Text)
    var
        Row: Record "LT FE Row";
    begin
        if Mode = '' then
            Row.Find()
        else
            Row.Find(Mode);
    end;

    local procedure Unused(Mode: Text): Text
    begin
        ClearLastError();
        if TryFindUnused(Mode) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Used(Mode: Text): Text
    var
        Row: Record "LT FE Row";
    begin
        if Mode = '' then
            exit(Format(Row.Find()));
        exit(Format(Row.Find(Mode)));
    end;

    [Test]
    procedure Find_EmptyTable()
    var
        Row: Record "LT FE Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('unused_default', Unused(''));
        Observer.Observe('unused_equals', Unused('='));
        Observer.Observe('unused_first', Unused('-'));
        Observer.Observe('unused_last', Unused('+'));
        Observer.Observe('unused_next', Unused('>'));
        Observer.Observe('unused_previous', Unused('<'));
        Observer.Observe('unused_all_directions', Unused('=><'));
        Observer.Observe('used_default', Used(''));
        Observer.Observe('used_equals', Used('='));
        Observer.Observe('used_first', Used('-'));
        Observer.Observe('used_last', Used('+'));
        Observer.Observe('used_next', Used('>'));
        Observer.Observe('used_previous', Used('<'));
        Observer.Observe('used_all_directions', Used('=><'));
        Observer.Expect('unused_default', 'error:The LT FE Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_equals', 'error:The LT FE Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_first', 'error:The LT FE Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused_last', 'error:The LT FE Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused_next', 'error:The LT FE Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_previous', 'error:The LT FE Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_all_directions', 'error:The LT FE Row does not exist. =><\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('used_default', 'No');
        Observer.Expect('used_equals', 'No');
        Observer.Expect('used_first', 'No');
        Observer.Expect('used_last', 'No');
        Observer.Expect('used_next', 'No');
        Observer.Expect('used_previous', 'No');
        Observer.Expect('used_all_directions', 'No');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): Find with the result not used and no filter when no row meets the search: on a table that has rows
    // (key not present, past the last row, before the first row) and on an empty table with a key value other than the default. ----

    [TryFunction]
    local procedure TvTryFindUnused(KeyValue: Integer; Mode: Text)
    var
        Row: Record "LT FE Row";
    begin
        Row.Id := KeyValue;
        if Mode = '' then
            Row.Find()
        else
            Row.Find(Mode);
    end;

    local procedure TvUnused(KeyValue: Integer; Mode: Text): Text
    begin
        ClearLastError();
        if TvTryFindUnused(KeyValue, Mode) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TvSeed()
    var
        Row: Record "LT FE Row";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Name := 'ten';
        Row.Insert();
        Row.Id := 20;
        Row.Name := 'twenty';
        Row.Insert();
    end;

    [Test]
    procedure TV_Find_TableWithRows_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TvSeed();
        Observer.Observe('default 15', TvUnused(15, ''));
        Observer.Observe('equals 15', TvUnused(15, '='));
        Observer.Observe('next from 20', TvUnused(20, '>'));
        Observer.Observe('next from 25', TvUnused(25, '>'));
        Observer.Observe('previous from 10', TvUnused(10, '<'));
        Observer.Observe('previous from 5', TvUnused(5, '<'));
        Observer.Observe('equals or next from 25', TvUnused(25, '=>'));
        Observer.Observe('equals or previous from 5', TvUnused(5, '=<'));
        Observer.Observe('default 0', TvUnused(0, ''));
        Observer.Expect('default 15', 'error:The LT FE Row does not exist. Identification fields and values: Id=''15''|DB:RecordNotFound');
        Observer.Expect('equals 15', 'error:The LT FE Row does not exist. Identification fields and values: Id=''15''|DB:RecordNotFound');
        Observer.Expect('next from 20', 'error:The LT FE Row does not exist. >\\Identification fields and values:\\Id=''20''|DB:RecordNotFound');
        Observer.Expect('next from 25', 'error:The LT FE Row does not exist. >\\Identification fields and values:\\Id=''25''|DB:RecordNotFound');
        Observer.Expect('previous from 10', 'error:The LT FE Row does not exist. <\\Identification fields and values:\\Id=''10''|DB:RecordNotFound');
        Observer.Expect('previous from 5', 'error:The LT FE Row does not exist. <\\Identification fields and values:\\Id=''5''|DB:RecordNotFound');
        Observer.Expect('equals or next from 25', 'error:The LT FE Row does not exist. =>\\Identification fields and values:\\Id=''25''|DB:RecordNotFound');
        Observer.Expect('equals or previous from 5', 'error:The LT FE Row does not exist. =<\\Identification fields and values:\\Id=''5''|DB:RecordNotFound');
        Observer.Expect('default 0', 'error:The LT FE Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure TV_Find_EmptyTable_KeyNotDefault()
    var
        Row: Record "LT FE Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('default 7', TvUnused(7, ''));
        Observer.Observe('equals 7', TvUnused(7, '='));
        Observer.Observe('next 7', TvUnused(7, '>'));
        Observer.Observe('previous 7', TvUnused(7, '<'));
        Observer.Observe('all directions 7', TvUnused(7, '=><'));
        Observer.Observe('equals or next 7', TvUnused(7, '=>'));
        Observer.Observe('first 7', TvUnused(7, '-'));
        Observer.Expect('default 7', 'error:The LT FE Row does not exist. Identification fields and values: Id=''7''|DB:RecordNotFound');
        Observer.Expect('equals 7', 'error:The LT FE Row does not exist. Identification fields and values: Id=''7''|DB:RecordNotFound');
        Observer.Expect('next 7', 'error:The LT FE Row does not exist. >\\Identification fields and values:\\Id=''7''|DB:RecordNotFound');
        Observer.Expect('previous 7', 'error:The LT FE Row does not exist. <\\Identification fields and values:\\Id=''7''|DB:RecordNotFound');
        Observer.Expect('all directions 7', 'error:The LT FE Row does not exist. =><\\Identification fields and values:\\Id=''7''|DB:RecordNotFound');
        Observer.Expect('equals or next 7', 'error:The LT FE Row does not exist. =>\\Identification fields and values:\\Id=''7''|DB:RecordNotFound');
        Observer.Expect('first 7', 'error:The LT FE Row table is empty.|DB:TableIsEmpty');
        Observer.Verify();
    end;
}
