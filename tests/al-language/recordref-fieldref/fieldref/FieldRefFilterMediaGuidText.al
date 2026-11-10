// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 66305 and test codeunit 66306
// local object: the table needs a Media and a MediaSet field with one row that holds content.
// Probe (al-runner issue 7461: FieldRef.SetFilter with the text of a Guid on a MediaSet field): observation form, the values are read from
//   the corpus CI matrix.
// Area: a Guid text as the filter of a Media and of a MediaSet field through FieldRef.SetFilter and FieldRef.SetRange. Filter values: a fixed
//   Guid that no row holds (with braces, without braces, in lower case), the id the row holds (the Media id, the MediaSet id and the id of
//   the item inside the set), and the empty Guid. Forms: G, =G, <>G, >G, <G, G|H, G..H, <>G&<>H, %1 and <>%1 with a text argument and with a
//   Guid argument, SetRange with a Guid, with a text and with two Guids. Each cell records GetFilter and the row numbers a
//   FindSet returns, or the error text and code. The id of the stored content is new on every run, so the cell shows it as <id>.
// Existing pins: recordref-fieldref/fieldref/FieldRefFilterMatrix.al Filter_Media_* and Filter_MediaSet_* pin the texts that are not a Guid
//   (empty, quotes, wildcards, a number); its Guid cells use CreateGuid() and are observed without being asserted.
// BC versions: 27, 28, 29 by CI

table 66305 "RRF MediaGuid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 66306 "RRF MediaGuid Tests"
{
    Subtype = Test;

    var
        MediaId: Text;
        SetId: Text;
        ItemId: Text;
        FixedG: Label '{11F319D9-C18B-449D-A6BC-6E725A266949}', Locked = true;
        FixedH: Label '{F1F319D9-C18B-449D-A6BC-6E725A266949}', Locked = true;
        EmptyG: Label '{00000000-0000-0000-0000-000000000000}', Locked = true;

    local procedure Initialize()
    var
        R: Record "RRF MediaGuid Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 1;
        R.Insert();
        R.Init();
        R."No." := 2;
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', OutS);
        TempBlob.CreateInStream(InS);
        R.Pic.ImportStream(InS, 'probe', 'image/png');
        TempBlob.CreateInStream(InS);
        R.Pics.ImportStream(InS, 'probe', 'image/png');
        R.Insert();
        R.Init();
        R."No." := 3;
        R.Insert();
        R.Get(2);
        MediaId := Format(R.Pic.MediaId());
        SetId := Format(R.Pics.MediaId());
        if R.Pics.Count() > 0 then
            ItemId := Format(R.Pics.Item(1))
        else
            ItemId := '';
    end;

    local procedure Scrub(Value: Text): Text
    begin
        if MediaId <> '' then
            Value := Value.Replace(MediaId, '<media id>').Replace(MediaId.ToLower(), '<media id lower>').Replace(DelChr(MediaId, '=', '{}'), '<media id bare>');
        if SetId <> '' then
            Value := Value.Replace(SetId, '<set id>').Replace(SetId.ToLower(), '<set id lower>').Replace(DelChr(SetId, '=', '{}'), '<set id bare>');
        if ItemId <> '' then
            Value := Value.Replace(ItemId, '<item id>').Replace(ItemId.ToLower(), '<item id lower>').Replace(DelChr(ItemId, '=', '{}'), '<item id bare>');
        exit(Value);
    end;

    local procedure Rows(var Ref: RecordRef) Result: Text
    begin
        if Ref.FindSet() then
            repeat
                Result += Format(Ref.Field(1).Value()) + ' ';
            until Ref.Next() = 0;
    end;

    [TryFunction]
    local procedure TrySet(var Fld: FieldRef; FilterText: Text)
    begin
        Fld.SetFilter(FilterText);
    end;

    [TryFunction]
    local procedure TrySetArg(var Fld: FieldRef; FilterText: Text; Arg: Variant)
    begin
        Fld.SetFilter(FilterText, Arg);
    end;

    [TryFunction]
    local procedure TryRange(var Fld: FieldRef; Arg: Variant)
    begin
        Fld.SetRange(Arg);
    end;

    [TryFunction]
    local procedure TryRange2(var Fld: FieldRef; Arg1: Variant; Arg2: Variant)
    begin
        Fld.SetRange(Arg1, Arg2);
    end;

    [TryFunction]
    local procedure TryRows(var Ref: RecordRef; var Result: Text)
    begin
        Result := Rows(Ref);
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; Name: Text; var Ref: RecordRef; var Fld: FieldRef; Ok: Boolean)
    var
        Found: Text;
    begin
        if not Ok then begin
            Observer.Observe(Name, Scrub('E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']'));
            ClearLastError();
            exit;
        end;
        if not TryRows(Ref, Found) then begin
            Found := Scrub('read E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
        Observer.Observe(Name, Scrub(Fld.GetFilter()) + ' | ' + Found);
    end;

    // Kind: 'f' SetFilter(Value), 't' SetFilter(Form, text argument), 'g' SetFilter(Form, Guid argument), 'r' SetRange(Guid),
    // 'rt' SetRange(text), 'r2' SetRange(Guid, Guid of Value2).
    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Kind: Text; Form: Text; Value: Text; Value2: Text)
    var
        Ref: RecordRef;
        Fld: FieldRef;
        G: Guid;
        G2: Guid;
        Ok: Boolean;
    begin
        Ref.Open(Database::"RRF MediaGuid Row");
        Fld := Ref.Field(FieldNo);
        if Kind in ['g', 'r', 'r2'] then begin
            Evaluate(G, Value);
            if Value2 <> '' then
                Evaluate(G2, Value2);
        end;
        case Kind of
            'f':
                Ok := TrySet(Fld, Form.Replace('{G}', Value).Replace('{H}', Value2));
            't':
                Ok := TrySetArg(Fld, Form, Value);
            'g':
                Ok := TrySetArg(Fld, Form, G);
            'r':
                Ok := TryRange(Fld, G);
            'rt':
                Ok := TryRange(Fld, Value);
            'r2':
                Ok := TryRange2(Fld, G, G2);
        end;
        Outcome(Observer, Name, Ref, Fld, Ok);
        Ref.Close();
    end;

    local procedure FixedForms(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    begin
        Cell(Observer, 'eq', FieldNo, 'f', '{G}', FixedG, '');
        Cell(Observer, 'eq bare', FieldNo, 'f', '{G}', DelChr(FixedG, '=', '{}'), '');
        Cell(Observer, 'eq lower', FieldNo, 'f', '{G}', LowerCase(FixedG), '');
        Cell(Observer, 'eq quoted', FieldNo, 'f', '''{G}''', FixedG, '');
        Cell(Observer, 'eqsign', FieldNo, 'f', '={G}', FixedG, '');
        Cell(Observer, 'ne', FieldNo, 'f', '<>{G}', FixedG, '');
        Cell(Observer, 'gt', FieldNo, 'f', '>{G}', FixedG, '');
        Cell(Observer, 'lt', FieldNo, 'f', '<{G}', FixedG, '');
        Cell(Observer, 'or', FieldNo, 'f', '{G}|{H}', FixedG, FixedH);
        Cell(Observer, 'range', FieldNo, 'f', '{G}..{H}', FixedG, FixedH);
        Cell(Observer, 'ne and ne', FieldNo, 'f', '<>{G}&<>{H}', FixedG, FixedH);
        Cell(Observer, 'empty guid', FieldNo, 'f', '{G}', EmptyG, '');
        Cell(Observer, 'ne empty guid', FieldNo, 'f', '<>{G}', EmptyG, '');
    end;

    local procedure ArgForms(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    begin
        Cell(Observer, 'text arg eq', FieldNo, 't', '%1', FixedG, '');
        Cell(Observer, 'text arg ne', FieldNo, 't', '<>%1', FixedG, '');
        Cell(Observer, 'guid arg eq', FieldNo, 'g', '%1', FixedG, '');
        Cell(Observer, 'guid arg ne', FieldNo, 'g', '<>%1', FixedG, '');
        Cell(Observer, 'guid arg ge', FieldNo, 'g', '>=%1', FixedG, '');
        Cell(Observer, 'empty guid arg eq', FieldNo, 'g', '%1', EmptyG, '');
        Cell(Observer, 'empty guid arg ne', FieldNo, 'g', '<>%1', EmptyG, '');
        Cell(Observer, 'range guid', FieldNo, 'r', '', FixedG, '');
        Cell(Observer, 'range text', FieldNo, 'rt', '', FixedG, '');
        Cell(Observer, 'range two guids', FieldNo, 'r2', '', FixedG, FixedH);
        Cell(Observer, 'range empty guid', FieldNo, 'r', '', EmptyG, '');
    end;

    local procedure StoredForms(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Id: Text; Name: Text)
    begin
        if Id = '' then begin
            Observer.Observe(Name, 'no id');
            exit;
        end;
        Cell(Observer, Name + ' eq', FieldNo, 'f', '{G}', Id, '');
        Cell(Observer, Name + ' eq bare', FieldNo, 'f', '{G}', DelChr(Id, '=', '{}'), '');
        Cell(Observer, Name + ' eq lower', FieldNo, 'f', '{G}', LowerCase(Id), '');
        Cell(Observer, Name + ' ne', FieldNo, 'f', '<>{G}', Id, '');
        Cell(Observer, Name + ' or fixed', FieldNo, 'f', '{G}|{H}', Id, FixedG);
        Cell(Observer, Name + ' text arg eq', FieldNo, 't', '%1', Id, '');
        Cell(Observer, Name + ' text arg ne', FieldNo, 't', '<>%1', Id, '');
        Cell(Observer, Name + ' guid arg eq', FieldNo, 'g', '%1', Id, '');
        Cell(Observer, Name + ' guid arg ne', FieldNo, 'g', '<>%1', Id, '');
        Cell(Observer, Name + ' range guid', FieldNo, 'r', '', Id, '');
        Cell(Observer, Name + ' range text', FieldNo, 'rt', '', Id, '');
    end;

    [Test]
    procedure MediaSet_SetFilter_FixedGuidText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        FixedForms(Observer, 3);
        Observer.Expect('eq', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq bare', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq lower', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq quoted', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eqsign', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('gt', '>{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('lt', '<{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('or', '{11F319D9-C18B-449D-A6BC-6E725A266949}|{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('range', '{11F319D9-C18B-449D-A6BC-6E725A266949}..{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne and ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949}&<>{F1F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('empty guid', '{00000000-0000-0000-0000-000000000000} | 1 3 ');
        Observer.Expect('ne empty guid', '<>{00000000-0000-0000-0000-000000000000} | 2 ');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_SetFilterAndSetRange_FixedGuidArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ArgForms(Observer, 3);
#if BC28PLUS
        Observer.Expect('text arg eq', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('text arg ne', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('guid arg eq', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('guid arg ne', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('guid arg ge', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('empty guid arg eq', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('empty guid arg ne', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('range guid', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('range text', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('range two guids', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('range empty guid', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Verify();
#else
        Observer.Expect('text arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('text arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('guid arg ge', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('empty guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('empty guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('range guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('range text', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('range two guids', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('range empty guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure MediaSet_Filter_IdOfTheStoredSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('set id is empty', Format(SetId = EmptyG));
        Observer.Observe('item id equals set id', Format(ItemId = SetId));
        StoredForms(Observer, 3, SetId, 'set');
#if BC28PLUS
        Observer.Expect('set id is empty', 'No');
        Observer.Expect('item id equals set id', 'No');
        Observer.Expect('set eq', '<set id> | 2 ');
        Observer.Expect('set eq bare', '<set id> | 2 ');
        Observer.Expect('set eq lower', '<set id> | 2 ');
        Observer.Expect('set ne', '<><set id> | 1 3 ');
        Observer.Expect('set or fixed', '<set id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | 2 ');
        Observer.Expect('set text arg eq', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('set text arg ne', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('set guid arg eq', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('set guid arg ne', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('set range guid', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('set range text', 'E: The value "<set id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Verify();
#else
        Observer.Expect('set id is empty', 'No');
        Observer.Expect('item id equals set id', 'No');
        Observer.Expect('set eq', '<set id> | 2 ');
        Observer.Expect('set eq bare', '<set id> | 2 ');
        Observer.Expect('set eq lower', '<set id> | 2 ');
        Observer.Expect('set ne', '<><set id> | 1 3 ');
        Observer.Expect('set or fixed', '<set id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | 2 ');
        Observer.Expect('set text arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('set text arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('set guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('set guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('set range guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('set range text', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure MediaSet_Filter_IdOfTheItemInTheSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        StoredForms(Observer, 3, ItemId, 'item');
#if BC28PLUS
        Observer.Expect('item eq', '<item id> | ');
        Observer.Expect('item eq bare', '<item id> | ');
        Observer.Expect('item eq lower', '<item id> | ');
        Observer.Expect('item ne', '<><item id> | 1 2 3 ');
        Observer.Expect('item or fixed', '<item id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('item text arg eq', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('item text arg ne', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('item guid arg eq', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('item guid arg ne', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('item range guid', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Expect('item range text', 'E: The value "<item id>" can''t be evaluated into type MediaSet. [Evaluate:Argument]');
        Observer.Verify();
#else
        Observer.Expect('item eq', '<item id> | ');
        Observer.Expect('item eq bare', '<item id> | ');
        Observer.Expect('item eq lower', '<item id> | ');
        Observer.Expect('item ne', '<><item id> | 1 2 3 ');
        Observer.Expect('item or fixed', '<item id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('item text arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('item text arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('item guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('item guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('item range guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Expect('item range text', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMediaSet. [Argument]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Media_SetFilter_FixedGuidText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        FixedForms(Observer, 2);
#if BC29PLUS
        Observer.Expect('eq', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq bare', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq lower', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq quoted', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eqsign', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('gt', '>{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('lt', '<{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('or', '{11F319D9-C18B-449D-A6BC-6E725A266949}|{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('range', '{11F319D9-C18B-449D-A6BC-6E725A266949}..{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne and ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949}&<>{F1F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('empty guid', '{00000000-0000-0000-0000-000000000000} | 1 3 ');
        Observer.Expect('ne empty guid', '<>{00000000-0000-0000-0000-000000000000} | 2 ');
        Observer.Verify();
#else
        Observer.Expect('eq', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq bare', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq lower', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eq quoted', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('eqsign', '{11F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('gt', '>{11F319D9-C18B-449D-A6BC-6E725A266949} | 2 ');
        Observer.Expect('lt', '<{11F319D9-C18B-449D-A6BC-6E725A266949} | 1 3 ');
        Observer.Expect('or', '{11F319D9-C18B-449D-A6BC-6E725A266949}|{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('range', '{11F319D9-C18B-449D-A6BC-6E725A266949}..{F1F319D9-C18B-449D-A6BC-6E725A266949} | ');
        Observer.Expect('ne and ne', '<>{11F319D9-C18B-449D-A6BC-6E725A266949}&<>{F1F319D9-C18B-449D-A6BC-6E725A266949} | 1 2 3 ');
        Observer.Expect('empty guid', '{00000000-0000-0000-0000-000000000000} | 1 3 ');
        Observer.Expect('ne empty guid', '<>{00000000-0000-0000-0000-000000000000} | 2 ');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Media_SetFilterAndSetRange_FixedGuidArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        ArgForms(Observer, 2);
#if BC28PLUS
        Observer.Expect('text arg eq', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('text arg ne', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('guid arg eq', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('guid arg ne', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('guid arg ge', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('empty guid arg eq', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('empty guid arg ne', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('range guid', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('range text', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('range two guids', 'E: The value "{11F319D9-C18B-449D-A6BC-6E725A266949}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('range empty guid', 'E: The value "{00000000-0000-0000-0000-000000000000}" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Verify();
#else
        Observer.Expect('text arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('text arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('guid arg ge', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('empty guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('empty guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('range guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('range text', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('range two guids', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('range empty guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Media_Filter_IdOfTheStoredMedia()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('media id is empty', Format(MediaId = EmptyG));
        StoredForms(Observer, 2, MediaId, 'media');
#if BC28PLUS
        Observer.Expect('media id is empty', 'No');
        Observer.Expect('media eq', '<media id> | 2 ');
        Observer.Expect('media eq bare', '<media id> | 2 ');
        Observer.Expect('media eq lower', '<media id> | 2 ');
        Observer.Expect('media ne', '<><media id> | 1 3 ');
        Observer.Expect('media or fixed', '<media id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | 2 ');
        Observer.Expect('media text arg eq', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('media text arg ne', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('media guid arg eq', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('media guid arg ne', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('media range guid', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Expect('media range text', 'E: The value "<media id>" can''t be evaluated into type Media. [Evaluate:Argument]');
        Observer.Verify();
#else
        Observer.Expect('media id is empty', 'No');
        Observer.Expect('media eq', '<media id> | 2 ');
        Observer.Expect('media eq bare', '<media id> | 2 ');
        Observer.Expect('media eq lower', '<media id> | 2 ');
        Observer.Expect('media ne', '<><media id> | 1 3 ');
        Observer.Expect('media or fixed', '<media id>|{11F319D9-C18B-449D-A6BC-6E725A266949} | 2 ');
        Observer.Expect('media text arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('media text arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('media guid arg eq', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('media guid arg ne', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('media range guid', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Expect('media range text', 'E: Invalid Conversion. Source: NavVariant, Destination: NavMedia. [Argument]');
        Observer.Verify();
#endif
    end;
}
