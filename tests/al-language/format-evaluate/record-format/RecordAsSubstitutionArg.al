// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-strsubstno-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Shape 20 (table 50020); local tables 95200-95203
// local object: the tests format every field of the record, so the field list and the key of each table is what they check
// Probe: written against BC 29.0.54011.55816 on the corpus CI (al-runner issue 6922); every literal asserted below is what BC produced.
// Facts: a Record, a RecordRef and a FieldRef passed as a %n argument of StrSubstNo, Message and Error (literal template, Text
// variable template, Label template, a Variant holding the record, a #n field of StrSubstNo), side by side with Format of the same
// record: records with a composite key, a key on the last field, no keys section, two text fields, Option, Date and Enum fields,
// each filled and empty; a temporary record and a filtered record.
// BC versions: 27.5, 28.5, 29.0 (corpus CI)

table 95200 "FMT RecArg Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Invoice no."; Code[10]) { }
        field(2; "Line no."; Integer) { }
        field(3; Description; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; Posted; Boolean) { }
    }

    keys
    {
        key(PK; "Invoice no.", "Line no.") { Clustered = true; }
    }
}

table 95201 "FMT RecArg KeyLast"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Text[30]) { }
        field(2; Qty; Integer) { }
        field(3; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 95202 "FMT RecArg NoKey"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Txt; Text[20]) { }
        field(2; Num; Integer) { }
    }
}

table 95203 "FMT RecArg Kinds"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option)
        {
            OptionMembers = " ",Alpha,Beta;
            OptionCaption = ' ,Alpha cap,Beta cap';
        }
        field(3; Posting; Date) { }
        field(4; Status; Enum "ALT Status") { }
        field(5; Big; BigInteger) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95204 "FMT Record Subst Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        MessageText: Text;
        LineLbl: Label 'Line %1 is wrong';

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
        MessageText := Msg;
    end;

    local procedure FillLine(var Line: Record "FMT RecArg Line")
    begin
        Line."Invoice no." := 'INV1';
        Line."Line no." := 10;
        Line.Description := 'Gear';
        Line.Amount := 12.5;
        Line.Posted := true;
    end;

    local procedure ObserveLine(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Line: Record "FMT RecArg Line")
    var
        Template: Text;
        V: Variant;
    begin
        Observer.Observe(Prefix + ' format', '[' + Format(Line) + ']');
        Observer.Observe(Prefix + ' strsubstno', StrSubstNo('[%1]', Line));
        Observer.Observe(Prefix + ' strsubstno label', StrSubstNo(LineLbl, Line));
        MessageText := '';
        Message('[%1]', Line);
        Observer.Observe(Prefix + ' message', MessageText);
        asserterror Error('[%1]', Line);
        Observer.ObserveError(Prefix + ' error');
        Template := '[%1]';
        asserterror Error(Template, Line);
        Observer.ObserveError(Prefix + ' error text template');
        MessageText := '';
        Message(Template, Line);
        Observer.Observe(Prefix + ' message text template', MessageText);
        V := Line;
        Observer.Observe(Prefix + ' strsubstno variant', StrSubstNo('[%1]', V));
    end;

    local procedure ObserveOther(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Other: Record "ALT Shape 20")
    begin
        Observer.Observe(Prefix + ' format', '[' + Format(Other) + ']');
        Observer.Observe(Prefix + ' strsubstno', StrSubstNo('[%1]', Other));
        MessageText := '';
        Message('[%1]', Other);
        Observer.Observe(Prefix + ' message', MessageText);
        asserterror Error('[%1]', Other);
        Observer.ObserveError(Prefix + ' error');
    end;

    local procedure ObserveKeyLast(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Rec: Record "FMT RecArg KeyLast")
    begin
        Observer.Observe(Prefix + ' format', '[' + Format(Rec) + ']');
        Observer.Observe(Prefix + ' strsubstno', StrSubstNo('[%1]', Rec));
        MessageText := '';
        Message('[%1]', Rec);
        Observer.Observe(Prefix + ' message', MessageText);
        asserterror Error('[%1]', Rec);
        Observer.ObserveError(Prefix + ' error');
    end;

    local procedure ObserveNoKey(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Rec: Record "FMT RecArg NoKey")
    begin
        Observer.Observe(Prefix + ' format', '[' + Format(Rec) + ']');
        Observer.Observe(Prefix + ' strsubstno', StrSubstNo('[%1]', Rec));
        MessageText := '';
        Message('[%1]', Rec);
        Observer.Observe(Prefix + ' message', MessageText);
        asserterror Error('[%1]', Rec);
        Observer.ObserveError(Prefix + ' error');
    end;

    local procedure ObserveKinds(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Rec: Record "FMT RecArg Kinds")
    begin
        Observer.Observe(Prefix + ' format', '[' + Format(Rec) + ']');
        Observer.Observe(Prefix + ' strsubstno', StrSubstNo('[%1]', Rec));
        MessageText := '';
        Message('[%1]', Rec);
        Observer.Observe(Prefix + ' message', MessageText);
        asserterror Error('[%1]', Rec);
        Observer.ObserveError(Prefix + ' error');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_CompositeKey_Filled()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "FMT RecArg Line";
    begin
        FillLine(Line);
        ObserveLine(Observer, 'filled', Line);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_CompositeKey_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "FMT RecArg Line";
    begin
        ObserveLine(Observer, 'empty', Line);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_TwoTextFields_EmptyAndFilled()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "ALT Shape 20";
    begin
        ObserveOther(Observer, 'empty', Other);
        Other.Code := 'C1';
        Other.Name := 'Name one';
        ObserveOther(Observer, 'filled', Other);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_KeyOnLastField_EmptyAndFilled()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FMT RecArg KeyLast";
    begin
        ObserveKeyLast(Observer, 'empty', Rec);
        Rec.Name := 'Last';
        Rec.Qty := 3;
        Rec.Id := 7;
        ObserveKeyLast(Observer, 'filled', Rec);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_NoKeysSection_EmptyAndFilled()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FMT RecArg NoKey";
    begin
        ObserveNoKey(Observer, 'empty', Rec);
        Rec.Txt := 'Free';
        Rec.Num := -4;
        ObserveNoKey(Observer, 'filled', Rec);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_OptionDateEnum_EmptyAndFilled()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FMT RecArg Kinds";
    begin
        ObserveKinds(Observer, 'empty', Rec);
        Rec.Id := 1;
        Rec.Kind := Rec.Kind::Beta;
        Rec.Posting := DMY2Date(15, 3, 2026);
        Rec.Status := "ALT Status"::Active;
        Rec.Big := 1234567890123L;
        ObserveKinds(Observer, 'filled', Rec);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_RecordRefAndFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "FMT RecArg Line";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        FillLine(Line);
        RecRef.GetTable(Line);
        FldRef := RecRef.Field(3);
        Observer.Observe('recref format', '[' + Format(RecRef) + ']');
        Observer.Observe('recref strsubstno', StrSubstNo('[%1]', RecRef));
        MessageText := '';
        Message('[%1]', RecRef);
        Observer.Observe('recref message', MessageText);
        asserterror Error('[%1]', RecRef);
        Observer.ObserveError('recref error');
        Observer.Observe('fieldref format', '[' + Format(FldRef) + ']');
        Observer.Observe('fieldref strsubstno', StrSubstNo('[%1]', FldRef));
        asserterror Error('[%1]', FldRef);
        Observer.ObserveError('fieldref error');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RecordArg_TwoRecordsAndHashField()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "FMT RecArg Line";
        Other: Record "ALT Shape 20";
    begin
        FillLine(Line);
        Other.Code := 'C1';
        Observer.Observe('two records', StrSubstNo('%1|%2', Line, Other));
        Observer.Observe('record and number', StrSubstNo('%2 / %1', Line, 5));
        Observer.Observe('hash field long', StrSubstNo('[#1##########]', Line));
        Observer.Observe('hash field short', StrSubstNo('[#1##########]', Other));
        MessageText := '';
        Message('%2 then %1', Line, Other);
        Observer.Observe('message second', MessageText);
        asserterror Error('%1 and %2', Other, Line);
        Observer.ObserveError('error two records');
        Observer.Finish();
    end;

    [Test]
    procedure RecordArg_TemporaryAndFilteredRecord()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "FMT RecArg Line";
        TempLine: Record "FMT RecArg Line" temporary;
    begin
        Line.DeleteAll();
        FillLine(TempLine);
        TempLine.Insert();
        Observer.Observe('temporary strsubstno', StrSubstNo('[%1]', TempLine));
        asserterror Error('[%1]', TempLine);
        Observer.ObserveError('temporary error');
        FillLine(Line);
        Line.Insert();
        Line.SetRange("Invoice no.", 'INV1');
        Line.SetFilter(Amount, '>%1', 1);
        Line.FindFirst();
        Observer.Observe('filtered format', '[' + Format(Line) + ']');
        Observer.Observe('filtered strsubstno', StrSubstNo('[%1]', Line));
        Observer.Finish();
    end;
}
