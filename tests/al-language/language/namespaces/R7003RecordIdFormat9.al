// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 95680-95687 and 95689 (R7003RecordIdNsTables.al, R7003RecordIdPlainTables.al);
//   Base Application tables Contact and Item (read into a record variable, never written)
// Probe: al-runner issue 7003. Format(RecordId, 0, 9) and Format(RecordId) of tables with and without a namespace whose names have no
// space, a space, an underscore, a hyphen, a dot or a slash, and of Base Application's Contact and Item (namespaced, one-word names),
// through a Record and through a RecordRef. Nothing is inserted: the RecordId of a record variable holds its key values.
// BC versions: 29 (27 and 28 by CI)

namespace LT.R7003.Tests;

using LT.R7003.Data;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;

codeunit 95688 "R7003 RecordId Format 9"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(var Observer: Codeunit "Probe Observer"; Name: Text; Id: RecordId)
    begin
        Observer.Observe(Name + ' 9', Format(Id, 0, 9));
        Observer.Observe(Name + ' 0', Format(Id));
    end;

    [Test]
    procedure Format9_NamespacedOwnTables()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7003Row";
        Under: Record "R7003_Under";
        Hyphen: Record "R7003-Hyphen";
        Dot: Record "R7003.Dot";
        Slash: Record "R7003/Slash";
        Words: Record "R7003 Ns Words";
    begin
        Row.Id := 7;
        Under.Id := 7;
        Hyphen.Id := 7;
        Dot.Id := 7;
        Slash.Id := 7;
        Words.Id := 7;
        Forms(Observer, 'one word', Row.RecordId);
        Forms(Observer, 'underscore', Under.RecordId);
        Forms(Observer, 'hyphen', Hyphen.RecordId);
        Forms(Observer, 'dot', Dot.RecordId);
        Forms(Observer, 'slash', Slash.RecordId);
        Forms(Observer, 'words', Words.RecordId);
        Observer.Finish();
    end;

    [Test]
    procedure Format9_TablesWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "R7003Plain";
        Words: Record "R7003 Plain Words";
        Hyphen: Record "R7003-PlainHyphen";
    begin
        Plain.Id := 7;
        Words.Id := 7;
        Hyphen.Id := 7;
        Forms(Observer, 'one word', Plain.RecordId);
        Forms(Observer, 'words', Words.RecordId);
        Forms(Observer, 'hyphen', Hyphen.RecordId);
        Observer.Finish();
    end;

    [Test]
    procedure Format9_BaseAppContactAndItem()
    var
        Observer: Codeunit "Probe Observer";
        Cont: Record Contact;
        It: Record Item;
    begin
        Cont."No." := 'CT7003';
        It."No." := 'IT7003';
        Forms(Observer, 'contact', Cont.RecordId);
        Forms(Observer, 'item', It.RecordId);
        Observer.Finish();
    end;

    [Test]
    procedure Format9_ThroughRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Cont: Record Contact;
        Row: Record "R7003Row";
        RecRef: RecordRef;
    begin
        Cont."No." := 'CT7003';
        RecRef.GetTable(Cont);
        Observer.Observe('contact', Format(RecRef.RecordId, 0, 9));
        Row.Id := 7;
        RecRef.GetTable(Row);
        Observer.Observe('own one word', Format(RecRef.RecordId, 0, 9));
        Observer.Finish();
    end;
}
