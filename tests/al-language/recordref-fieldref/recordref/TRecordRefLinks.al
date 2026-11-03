// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copylinks-recordref-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 69374, test codeunit 69369
// Facts: RecordRef.CopyLinks (from a Record, a RecordRef and a Variant) with real Record Link rows: which links the target gets (url, description, count), links already on the target, a source without links,
// the Record Link table rows of source and target; RecordRef.DeleteLink with a valid id, the id of another record, an id that does not exist and 0.
// BC versions: 27.0 and later

table 69374 "LT T Link Host"
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

codeunit 69382 "LT T Delete Link"
{
    var
        TargetId: RecordId;
        TargetLink: Integer;

    procedure Set(NewTarget: RecordId; NewLink: Integer)
    begin
        TargetId := NewTarget;
        TargetLink := NewLink;
    end;

    trigger OnRun()
    var
        Ref: RecordRef;
    begin
        Ref.Get(TargetId);
        Ref.DeleteLink(TargetLink);
    end;
}

codeunit 69369 "LT T RecordRef Links Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(var Source: RecordRef; var Target: RecordRef)
    var
        Host: Record "LT T Link Host";
        RecordLink: Record "Record Link";
    begin
        if Host.FindSet() then
            repeat
                RecordLink.Reset();
                RecordLink.SetRange("Record ID", Host.RecordId());
                RecordLink.DeleteAll(false);
            until Host.Next() = 0;
        Host.DeleteAll();
        Host.Id := 1;
        Host.Name := 'source';
        Host.Insert();
        Host.Id := 2;
        Host.Name := 'target';
        Host.Insert();
        Host.Id := 3;
        Host.Name := 'empty';
        Host.Insert();
        Host.Get(1);
        Source.GetTable(Host);
        Host.Get(2);
        Target.GetTable(Host);
    end;

    local procedure DeleteResult(var Ref: RecordRef; LinkId: Integer): Text
    var
        Deleter: Codeunit "LT T Delete Link";
        Ok: Boolean;
        Result: Text;
    begin
        Deleter.Set(Ref.RecordId(), LinkId);
        Commit();
        Ok := Deleter.Run();
        Result := Format(Ok) + '|' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure LinkList(RecId: RecordId): Text
    var
        RecordLink: Record "Record Link";
        Result: Text;
    begin
        RecordLink.SetRange("Record ID", RecId);
        if RecordLink.FindSet() then
            repeat
                Result += RecordLink.URL1 + '|' + RecordLink.Description + '|' + Format(RecordLink.Type) + ';';
            until RecordLink.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure CopyLinks_FromRecordRef_CopiesAllLinks()
    var
        Source: RecordRef;
        Target: RecordRef;
        Id1: Integer;
        Id2: Integer;
    begin
        Seed(Source, Target);
        Id1 := Source.AddLink('https://example.com/a', 'first');
        Id2 := Source.AddLink('https://example.com/b', 'second');
        Observer.Observe('ids are positive and different', Format((Id1 > 0) and (Id2 > 0) and (Id1 <> Id2)));
        Observer.Observe('source has links', Format(Source.HasLinks()));
        Observer.Observe('target has links before', Format(Target.HasLinks()));
        Target.CopyLinks(Source);
        Observer.Observe('target has links after', Format(Target.HasLinks()));
        Observer.Observe('target link rows', LinkList(Target.RecordId()));
        Observer.Observe('source link rows', LinkList(Source.RecordId()));
        Observer.Expect('ids are positive and different', 'Yes');
        Observer.Expect('source has links', 'Yes');
        Observer.Expect('target has links before', 'No');
        Observer.Expect('target has links after', 'Yes');
        Observer.Expect('target link rows', 'https://example.com/a|first|Link;https://example.com/b|second|Link;');
        Observer.Expect('source link rows', 'https://example.com/a|first|Link;https://example.com/b|second|Link;');
        Observer.Verify();
    end;

    [Test]
    procedure CopyLinks_FromRecordAndVariant_CopiesAllLinks()
    var
        Source: RecordRef;
        Target: RecordRef;
        Host: Record "LT T Link Host";
        Empty: Record "LT T Link Host";
        V: Variant;
    begin
        Seed(Source, Target);
        Source.AddLink('https://example.com/a', 'first');
        Host.Get(1);
        Target.CopyLinks(Host);
        Observer.Observe('from record', LinkList(Target.RecordId()));
        Target.CopyLinks(Host);
        Observer.Observe('from record again', LinkList(Target.RecordId()));
        Empty.Get(3);
        V := Empty;
        Target.CopyLinks(V);
        Observer.Observe('from variant record without links', LinkList(Target.RecordId()));
        V := Host;
        Target.CopyLinks(V);
        Observer.Observe('from variant record', LinkList(Target.RecordId()));
        V := Source;
        Target.CopyLinks(V);
        Observer.Observe('from variant recordref', LinkList(Target.RecordId()));
        Observer.Expect('from record', 'https://example.com/a|first|Link;');
        Observer.Expect('from record again', 'https://example.com/a|first|Link;https://example.com/a|first|Link;');
        Observer.Expect('from variant record without links', 'https://example.com/a|first|Link;https://example.com/a|first|Link;');
        Observer.Expect('from variant record', 'https://example.com/a|first|Link;https://example.com/a|first|Link;https://example.com/a|first|Link;');
        Observer.Expect('from variant recordref', 'https://example.com/a|first|Link;https://example.com/a|first|Link;https://example.com/a|first|Link;https://example.com/a|first|Link;');
        Observer.Verify();
    end;

    [Test]
    procedure CopyLinks_TargetKeepsItsOwnLinks_AndSourceWithoutLinks()
    var
        Source: RecordRef;
        Target: RecordRef;
        Empty: Record "LT T Link Host";
        EmptyRef: RecordRef;
    begin
        Seed(Source, Target);
        Source.AddLink('https://example.com/a', 'first');
        Target.AddLink('https://example.com/own', 'own');
        Target.CopyLinks(Source);
        Observer.Observe('target after copy', LinkList(Target.RecordId()));
        Empty.Get(3);
        EmptyRef.GetTable(Empty);
        Target.CopyLinks(EmptyRef);
        Observer.Observe('target after copy from empty', LinkList(Target.RecordId()));
        Observer.Observe('empty has links', Format(EmptyRef.HasLinks()));
        Observer.Expect('target after copy', 'https://example.com/own|own|Link;https://example.com/a|first|Link;');
        Observer.Expect('target after copy from empty', 'https://example.com/own|own|Link;https://example.com/a|first|Link;');
        Observer.Expect('empty has links', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteLink_ValidAndMissingId()
    var
        Source: RecordRef;
        Target: RecordRef;
        Id1: Integer;
        Id2: Integer;
        Missing: Integer;
    begin
        Seed(Source, Target);
        Id1 := Source.AddLink('https://example.com/a', 'first');
        Id2 := Source.AddLink('https://example.com/b', 'second');
        Target.AddLink('https://example.com/t', 'target');
        Source.DeleteLink(Id1);
        Observer.Observe('source after delete', LinkList(Source.RecordId()));
        Observer.Observe('source still has links', Format(Source.HasLinks()));
        Observer.Observe('target untouched', LinkList(Target.RecordId()));
        Observer.Observe('delete again', DeleteResult(Source, Id1));
        Missing := Id1 + Id2 + 1000;
        Observer.Observe('delete unknown id', DeleteResult(Source, Missing));
        Observer.Observe('delete 0', DeleteResult(Source, 0));
        Observer.Observe('delete negative', DeleteResult(Source, -1));
        Observer.Observe('delete id of another record', DeleteResult(Target, Id2));
        Observer.Observe('source after errors', LinkList(Source.RecordId()));
        Observer.Observe('target after errors', LinkList(Target.RecordId()));
        Source.DeleteLink(Id2);
        Observer.Observe('source after last delete', LinkList(Source.RecordId()));
        Observer.Observe('source has links at the end', Format(Source.HasLinks()));
        Observer.Expect('source after delete', 'https://example.com/b|second|Link;');
        Observer.Expect('source still has links', 'Yes');
        Observer.Expect('target untouched', 'https://example.com/t|target|Link;');
        Observer.Expect('delete again', 'Yes||');
        Observer.Expect('delete unknown id', 'Yes||');
        Observer.Expect('delete 0', 'Yes||');
        Observer.Expect('delete negative', 'Yes||');
        Observer.Expect('delete id of another record', 'Yes||');
        Observer.Expect('source after errors', 'https://example.com/b|second|Link;');
        Observer.Expect('target after errors', 'https://example.com/t|target|Link;');
        Observer.Expect('source after last delete', '');
        Observer.Expect('source has links at the end', 'No');
        Observer.Verify();
    end;
}
