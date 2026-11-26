// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 88410..88415 (XEB Row, XEB Row Ext, XEB Log, XEB Cfg,
//   XEB Subscriber, XEB Tests)
// local object: the table, its table extension triggers and the event subscribers are what is under test.
// Probe (al-runner issue 8986, al-runner pull request 9035): what xRec holds in a table's own OnInsert and OnDelete when a
//   table extension's OnBeforeInsert / OnBeforeDelete trigger (or an OnBeforeInsertEvent / OnBeforeDeleteEvent subscriber)
//   changed Rec first. Each trigger logs its view under a short prefix: 'SB' the OnBefore...Event subscriber, 'EB' the table
//   extension's OnBefore... trigger (before it changes Rec), 'T' the table's own OnInsert / OnDelete, 'EI' / 'ED' the table
//   extension's OnInsert / OnDelete, 'EA' its OnAfterInsert / OnAfterDelete. The order of the prefixes is the trigger order.
//   'T' logs xRec.Name, xRec.Tag, Rec.Name, Rec.Tag, Format(xRec), whether Format(xRec) = Format(Rec), and the filters and
//   current key of xRec and Rec. Before the Insert(true) the record holds Id A, Name N0, Tag T0; the stored row of a Delete
//   holds the same values.
// Cells (each with a control where nothing changes Rec):
//   - Insert(true): the extension's OnBeforeInsert sets Name (a field no trigger reads), or Tag (a field the table's
//     OnInsert copies into Copy); the same after the record variable read another row (Get) before Init;
//   - Insert(true): an OnBeforeInsertEvent subscriber sets Name or Tag instead of the extension;
//   - Insert(true): the extension changes only filters (SetRange) or the current key (SetCurrentKey) of Rec;
//   - Delete(true) with the buffer equal to the stored row or with Name changed in the buffer: the extension's
//     OnBeforeDelete sets Name or Tag, or SetRange; an OnBeforeDeleteEvent subscriber sets Name.
// Probe: written against BC 27.5, 28.5 and 29.0 (corpus CI).
table 88410 "XEB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Tag; Code[20]) { }
        field(4; Copy; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    trigger OnInsert()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Full('T', Rec, xRec);
        Copy := Tag;
    end;

    trigger OnDelete()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Full('T', Rec, xRec);
    end;
}

tableextension 88411 "XEB Row Ext" extends "XEB Row"
{
    trigger OnBeforeInsert()
    var
        Log: Codeunit "XEB Log";
        Cfg: Codeunit "XEB Cfg";
    begin
        Log.Short('EB', Rec, xRec);
        Cfg.ApplyExt(Rec);
    end;

    trigger OnInsert()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Short('EI', Rec, xRec);
    end;

    trigger OnAfterInsert()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Short('EA', Rec, xRec);
    end;

    trigger OnBeforeDelete()
    var
        Log: Codeunit "XEB Log";
        Cfg: Codeunit "XEB Cfg";
    begin
        Log.Short('EB', Rec, xRec);
        Cfg.ApplyExt(Rec);
    end;

    trigger OnDelete()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Short('ED', Rec, xRec);
    end;

    trigger OnAfterDelete()
    var
        Log: Codeunit "XEB Log";
    begin
        Log.Short('EA', Rec, xRec);
    end;
}

codeunit 88412 "XEB Log"
{
    SingleInstance = true;

    var
        Names: List of [Text];
        Values: List of [Text];

    procedure Reset()
    begin
        Clear(Names);
        Clear(Values);
    end;

    procedure Add(Name: Text; Value: Text)
    begin
        Names.Add(Name);
        Values.Add(Value);
    end;

    procedure Short(Prefix: Text; var Rec: Record "XEB Row"; var xRec: Record "XEB Row")
    begin
        Add(Prefix + '.xName', xRec.Name);
        Add(Prefix + '.xTag', xRec.Tag);
        Add(Prefix + '.Name', Rec.Name);
    end;

    procedure Full(Prefix: Text; var Rec: Record "XEB Row"; var xRec: Record "XEB Row")
    begin
        Add(Prefix + '.xId', xRec.Id);
        Add(Prefix + '.xName', xRec.Name);
        Add(Prefix + '.xTag', xRec.Tag);
        Add(Prefix + '.Name', Rec.Name);
        Add(Prefix + '.Tag', Rec.Tag);
        Add(Prefix + '.xFmt', Format(xRec));
        Add(Prefix + '.fmtEq', Format(Format(xRec) = Format(Rec)));
        Add(Prefix + '.xFilt', xRec.GetFilters());
        Add(Prefix + '.xKey', xRec.CurrentKey());
        Add(Prefix + '.filt', Rec.GetFilters());
        Add(Prefix + '.key', Rec.CurrentKey());
    end;

    procedure Flush(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('log.count', Format(Names.Count()));
        for i := 1 to Names.Count() do
            Observer.Observe(Format(i) + ' ' + Names.Get(i), Values.Get(i));
        Reset();
    end;
}

codeunit 88413 "XEB Cfg"
{
    SingleInstance = true;

    var
        ExtMode: Integer;
        SubMode: Integer;

    procedure Set(NewExtMode: Integer; NewSubMode: Integer)
    begin
        ExtMode := NewExtMode;
        SubMode := NewSubMode;
    end;

    // 0 nothing, 1 Name := 'EXT', 2 Tag := 'EXTTAG', 3 SetRange(Name, 'N0'), 4 SetCurrentKey(Name)
    procedure ApplyExt(var Rec: Record "XEB Row")
    begin
        Apply(Rec, ExtMode, 'EXT');
    end;

    procedure ApplySub(var Rec: Record "XEB Row")
    begin
        Apply(Rec, SubMode, 'SUB');
    end;

    local procedure Apply(var Rec: Record "XEB Row"; Mode: Integer; Value: Text)
    begin
        case Mode of
            1:
                Rec.Name := Value;
            2:
                Rec.Tag := Value + 'TAG';
            3:
                Rec.SetRange(Name, 'N0');
            4:
                Rec.SetCurrentKey(Name);
        end;
    end;
}

codeunit 88414 "XEB Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"XEB Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "XEB Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "XEB Log";
        Cfg: Codeunit "XEB Cfg";
    begin
        Log.Add('SB.Name', Rec.Name);
        Cfg.ApplySub(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"XEB Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "XEB Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "XEB Log";
        Cfg: Codeunit "XEB Cfg";
    begin
        Log.Add('SB.Name', Rec.Name);
        Cfg.ApplySub(Rec);
    end;
}

codeunit 88415 "XEB Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "XEB Log";
        Cfg: Codeunit "XEB Cfg";

    local procedure Start()
    var
        Row: Record "XEB Row";
    begin
        Row.DeleteAll();
        Log.Reset();
        Cfg.Set(0, 0);
    end;

    local procedure RunInsert(var Observer: Codeunit "Probe Observer"; ExtMode: Integer; SubMode: Integer; ReadOtherFirst: Boolean)
    var
        Row: Record "XEB Row";
    begin
        Start();
        if ReadOtherFirst then begin
            Row.Id := 'B';
            Row.Name := 'OTHER';
            Row.Tag := 'OTAG';
            Row.Insert();
            Row.Get('B');
            Row.Init();
        end;
        Row.Id := 'A';
        Row.Name := 'N0';
        Row.Tag := 'T0';
        Cfg.Set(ExtMode, SubMode);
        Row.Insert(true);
        Cfg.Set(0, 0);
        Log.Flush(Observer);
        Observer.Observe('caller.Name', Row.Name);
        Observer.Observe('caller.Tag', Row.Tag);
        Observer.Observe('caller.Copy', Row.Copy);
        Observer.Observe('caller.filt', Row.GetFilters());
        Observer.Observe('caller.key', Row.CurrentKey());
        Row.Reset();
        Row.Get('A');
        Observer.Observe('stored', Row.Name + '/' + Row.Tag + '/' + Row.Copy);
    end;

    local procedure RunDelete(var Observer: Codeunit "Probe Observer"; ExtMode: Integer; SubMode: Integer; ChangeBuffer: Boolean)
    var
        Row: Record "XEB Row";
    begin
        Start();
        Row.Id := 'A';
        Row.Name := 'N0';
        Row.Tag := 'T0';
        Row.Insert();
        Clear(Row);
        Row.Get('A');
        if ChangeBuffer then
            Row.Name := 'BUF';
        Cfg.Set(ExtMode, SubMode);
        Row.Delete(true);
        Cfg.Set(0, 0);
        Log.Flush(Observer);
        Observer.Observe('caller.Name', Row.Name);
        Observer.Observe('caller.filt', Row.GetFilters());
        Row.Reset();
        Observer.Observe('stored.count', Format(Row.Count()));
    end;

    [Test]
    procedure Insert_NothingChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 0, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ExtSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 1, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ExtSetsTagReadByOnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 2, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterGet_NothingChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 0, 0, true);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_AfterGet_ExtSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 1, 0, true);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_SubscriberSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 0, 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_SubscriberSetsTagReadByOnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 0, 2, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_SubscriberAndExtSetName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 1, 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ExtSetRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 3, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_ExtSetCurrentKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInsert(Observer, 4, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_NothingChanges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 0, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_BufferChanged_NothingElse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 0, 0, true);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_ExtSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 1, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_BufferChanged_ExtSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 1, 0, true);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_ExtSetsTag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 2, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_ExtSetRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 3, 0, false);
        Observer.Finish();
    end;

    [Test]
    procedure Delete_SubscriberSetsName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDelete(Observer, 0, 1, false);
        Observer.Finish();
    end;
}
