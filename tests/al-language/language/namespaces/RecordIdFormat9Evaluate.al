// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// local object: table 61805 has a RecordId field, and reading text into that field (through the record and through a FieldRef) is what is under test
// Fixtures used: Probe Observer (codeunit 69160); tables 95680 to 95687 and 95689 (R7003RecordIdNsTables.al, R7003RecordIdPlainTables.al);
//   Base Application tables (read into a record variable, never written); own table 61805, test codeunit 61806
// Probe (al-runner issue 7326): Evaluate into a RecordId of the text Format(RecordId, 0, 9) gives. Area: the table name shape (one word,
//   underscore, hyphen, period, slash, spaces) crossed with the table's place (own namespace, no namespace, Base Application), the call
//   (Evaluate(Id, Text), Evaluate(Id, Text, 9), the format 0 text, result used and not used), the target (a RecordId variable, a RecordId
//   field of a record, a FieldRef of that field) and bracket texts written by hand (quotes added or left out, another or no namespace,
//   other letter case, brackets left out).
//   Each round trip is observed as '<result> <table number> same' when the RecordId read back equals the one formatted, else with the
//   format 9 text of what came back.
// Next to: language/namespaces/R7003RecordIdFormat9.al (the Format side of every name shape, no Evaluate),
//   format-evaluate/P128EvalRecordId.al (Evaluate of the format 0 text and of format 9 for tables without a namespace),
//   format-evaluate/N582RecordIdText.al (key parts), format-evaluate/Y49RecordIdFormat10.al (format 10).
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

namespace LT.R7003.Tests;

using LT.R7003.Data;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Account;

table 61805 "R7326 RecordId Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; RecordId) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61806 "R7326 RecordId Evaluate 9"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Outcome(Ok: Boolean; Back: RecordId; Wanted: RecordId): Text
    begin
        if Back = Wanted then
            exit(Format(Ok) + ' ' + Format(Back.TableNo) + ' same');
        exit(Format(Ok) + ' ' + Format(Back.TableNo) + ' [' + Format(Back, 0, 9) + ']');
    end;

    // The format 9 text read back with the default format, with format 9, and the format 0 text read back.
    local procedure RoundTrip(var Observer: Codeunit "Probe Observer"; Name: Text; Id: RecordId)
    var
        Back: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Back, Format(Id, 0, 9));
        Observer.Observe(Name + ' 9 text', Outcome(Ok, Back, Id));
        Clear(Back);
        Ok := Evaluate(Back, Format(Id, 0, 9), 9);
        Observer.Observe(Name + ' 9 text, number 9', Outcome(Ok, Back, Id));
        Clear(Back);
        Ok := Evaluate(Back, Format(Id));
        Observer.Observe(Name + ' 0 text', Outcome(Ok, Back, Id));
    end;

    // A text written by hand, with the result used.
    local procedure Read(var Observer: Codeunit "Probe Observer"; Txt: Text; Wanted: RecordId)
    var
        Back: RecordId;
        Ok: Boolean;
    begin
        Ok := Evaluate(Back, Txt);
        Observer.Observe(Txt, Outcome(Ok, Back, Wanted));
    end;

    // A text with the result not used: the error, or 'no error' with what was read.
    local procedure ReadAsStatement(var Observer: Codeunit "Probe Observer"; Txt: Text)
    var
        Back: RecordId;
    begin
        asserterror
        begin
            Evaluate(Back, Txt);
            Error('no error: %1 [%2]', Back.TableNo, Format(Back, 0, 9));
        end;
        Observer.ObserveError(Txt);
    end;

    [Test]
    procedure Evaluate9_NamespacedOwnTables()
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
        RoundTrip(Observer, 'one word', Row.RecordId);
        RoundTrip(Observer, 'underscore', Under.RecordId);
        RoundTrip(Observer, 'hyphen', Hyphen.RecordId);
        RoundTrip(Observer, 'dot', Dot.RecordId);
        RoundTrip(Observer, 'slash', Slash.RecordId);
        RoundTrip(Observer, 'words', Words.RecordId);
        Observer.Expect('one word 9 text', 'Yes 95680 same');
        Observer.Expect('one word 9 text, number 9', 'Yes 95680 same');
        Observer.Expect('one word 0 text', 'Yes 95680 same');
        Observer.Expect('underscore 9 text', 'Yes 95681 same');
        Observer.Expect('underscore 9 text, number 9', 'Yes 95681 same');
        Observer.Expect('underscore 0 text', 'Yes 95681 same');
        Observer.Expect('hyphen 9 text', 'Yes 95682 same');
        Observer.Expect('hyphen 9 text, number 9', 'Yes 95682 same');
        Observer.Expect('hyphen 0 text', 'Yes 95682 same');
        Observer.Expect('dot 9 text', 'Yes 95683 same');
        Observer.Expect('dot 9 text, number 9', 'Yes 95683 same');
        Observer.Expect('dot 0 text', 'Yes 95683 same');
        Observer.Expect('slash 9 text', 'Yes 95684 same');
        Observer.Expect('slash 9 text, number 9', 'Yes 95684 same');
        Observer.Expect('slash 0 text', 'Yes 95684 same');
        Observer.Expect('words 9 text', 'Yes 95689 same');
        Observer.Expect('words 9 text, number 9', 'Yes 95689 same');
        Observer.Expect('words 0 text', 'Yes 95689 same');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_TablesWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Record "R7003Plain";
        Words: Record "R7003 Plain Words";
        Hyphen: Record "R7003-PlainHyphen";
    begin
        Plain.Id := 7;
        Words.Id := 7;
        Hyphen.Id := 7;
        RoundTrip(Observer, 'one word', Plain.RecordId);
        RoundTrip(Observer, 'words', Words.RecordId);
        RoundTrip(Observer, 'hyphen', Hyphen.RecordId);
        Observer.Expect('one word 9 text', 'Yes 95685 same');
        Observer.Expect('one word 9 text, number 9', 'Yes 95685 same');
        Observer.Expect('one word 0 text', 'Yes 95685 same');
        Observer.Expect('words 9 text', 'Yes 95686 same');
        Observer.Expect('words 9 text, number 9', 'Yes 95686 same');
        Observer.Expect('words 0 text', 'Yes 95686 same');
        Observer.Expect('hyphen 9 text', 'Yes 95687 same');
        Observer.Expect('hyphen 9 text, number 9', 'Yes 95687 same');
        Observer.Expect('hyphen 0 text', 'Yes 95687 same');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_BaseAppTables_OneFieldKeys()
    var
        Observer: Codeunit "Probe Observer";
        Cont: Record Contact;
        It: Record Item;
        Account: Record "G/L Account";
        Entry: Record "Cust. Ledger Entry";
    begin
        Cont."No." := 'CT7326';
        It."No." := 'IT7326';
        Account."No." := 'GL7326';
        Entry."Entry No." := 7326;
        Observer.Observe('contact text', Format(Cont.RecordId, 0, 9));
        RoundTrip(Observer, 'contact', Cont.RecordId);
        Observer.Observe('item text', Format(It.RecordId, 0, 9));
        RoundTrip(Observer, 'item', It.RecordId);
        Observer.Observe('slash and space text', Format(Account.RecordId, 0, 9));
        RoundTrip(Observer, 'slash and space', Account.RecordId);
        Observer.Observe('period text', Format(Entry.RecordId, 0, 9));
        RoundTrip(Observer, 'period', Entry.RecordId);
        Observer.Expect('contact text', '[Microsoft.CRM.Contact.Contact]: CT7326');
        Observer.Expect('contact 9 text', 'Yes 5050 same');
        Observer.Expect('contact 9 text, number 9', 'Yes 5050 same');
        Observer.Expect('contact 0 text', 'Yes 5050 same');
        Observer.Expect('item text', '[Microsoft.Inventory.Item.Item]: IT7326');
        Observer.Expect('item 9 text', 'Yes 27 same');
        Observer.Expect('item 9 text, number 9', 'Yes 27 same');
        Observer.Expect('item 0 text', 'Yes 27 same');
        Observer.Expect('slash and space text', '[Microsoft.Finance.GeneralLedger.Account.G/L Account]: GL7326');
        Observer.Expect('slash and space 9 text', 'Yes 15 same');
        Observer.Expect('slash and space 9 text, number 9', 'Yes 15 same');
        Observer.Expect('slash and space 0 text', 'Yes 15 same');
        Observer.Expect('period text', '[Microsoft.Sales.Receivables."Cust. Ledger Entry"]: 7326');
        Observer.Expect('period 9 text', 'Yes 21 same');
        Observer.Expect('period 9 text, number 9', 'Yes 21 same');
        Observer.Expect('period 0 text', 'Yes 21 same');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_BaseAppTables_CompositeKeys()
    var
        Observer: Codeunit "Probe Observer";
        WhseLine: Record "Whse. Worksheet Line";
        MoveLine: Record "Internal Movement Line";
        SalesLine: Record "Sales Line";
    begin
        WhseLine."Worksheet Template Name" := 'TPL';
        WhseLine.Name := 'BATCH';
        WhseLine."Location Code" := 'LOC';
        WhseLine."Line No." := 10000;
        MoveLine."No." := 'IM7326';
        MoveLine."Line No." := 10000;
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'SO7326';
        SalesLine."Line No." := 10000;
        Observer.Observe('period, four key fields text', Format(WhseLine.RecordId, 0, 9));
        RoundTrip(Observer, 'period, four key fields', WhseLine.RecordId);
        Observer.Observe('words, two key fields text', Format(MoveLine.RecordId, 0, 9));
        RoundTrip(Observer, 'words, two key fields', MoveLine.RecordId);
        Observer.Observe('words, enum key field text', Format(SalesLine.RecordId, 0, 9));
        RoundTrip(Observer, 'words, enum key field', SalesLine.RecordId);
        Observer.Expect('period, four key fields text', '[Microsoft.Warehouse.Worksheet."Whse. Worksheet Line"]: TPL,BATCH,LOC,10000');
        Observer.Expect('period, four key fields 9 text', 'Yes 7326 same');
        Observer.Expect('period, four key fields 9 text, number 9', 'Yes 7326 same');
        Observer.Expect('period, four key fields 0 text', 'Yes 7326 same');
        Observer.Expect('words, two key fields text', '[Microsoft.Warehouse.InternalDocument.Internal Movement Line]: IM7326,10000');
        Observer.Expect('words, two key fields 9 text', 'Yes 7347 same');
        Observer.Expect('words, two key fields 9 text, number 9', 'Yes 7347 same');
        Observer.Expect('words, two key fields 0 text', 'Yes 7347 same');
        Observer.Expect('words, enum key field text', '[Microsoft.Sales.Document.Sales Line]: 1,SO7326,10000');
        Observer.Expect('words, enum key field 9 text', 'Yes 37 same');
        Observer.Expect('words, enum key field 9 text, number 9', 'Yes 37 same');
        Observer.Expect('words, enum key field 0 text', 'Yes 37 same');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_ResultNotUsed_NamespacedShapes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7003Row";
        Dot: Record "R7003.Dot";
        Words: Record "R7003 Ns Words";
        WhseLine: Record "Whse. Worksheet Line";
        It: Record Item;
    begin
        Row.Id := 7;
        Dot.Id := 7;
        Words.Id := 7;
        WhseLine."Worksheet Template Name" := 'TPL';
        WhseLine.Name := 'BATCH';
        WhseLine."Location Code" := 'LOC';
        WhseLine."Line No." := 10000;
        It."No." := 'IT7326';
        ReadAsStatement(Observer, Format(Row.RecordId, 0, 9));
        ReadAsStatement(Observer, Format(Dot.RecordId, 0, 9));
        ReadAsStatement(Observer, Format(Words.RecordId, 0, 9));
        ReadAsStatement(Observer, Format(WhseLine.RecordId, 0, 9));
        ReadAsStatement(Observer, Format(It.RecordId, 0, 9));
        Observer.Expect('[LT.R7003.Data.R7003Row]: 7|text', 'no error: 95680 [[LT.R7003.Data.R7003Row]: 7]');
        Observer.Expect('[LT.R7003.Data.R7003Row]: 7|code', 'Dialog');
        Observer.Expect('[LT.R7003.Data."R7003.Dot"]: 7|text', 'no error: 95683 [[LT.R7003.Data."R7003.Dot"]: 7]');
        Observer.Expect('[LT.R7003.Data."R7003.Dot"]: 7|code', 'Dialog');
        Observer.Expect('[LT.R7003.Data.R7003 Ns Words]: 7|text', 'no error: 95689 [[LT.R7003.Data.R7003 Ns Words]: 7]');
        Observer.Expect('[LT.R7003.Data.R7003 Ns Words]: 7|code', 'Dialog');
        Observer.Expect('[Microsoft.Warehouse.Worksheet."Whse. Worksheet Line"]: TPL,BATCH,LOC,10000|text', 'no error: 7326 [[Microsoft.Warehouse.Worksheet."Whse. Worksheet Line"]: TPL,BATCH,LOC,10000]');
        Observer.Expect('[Microsoft.Warehouse.Worksheet."Whse. Worksheet Line"]: TPL,BATCH,LOC,10000|code', 'Dialog');
        Observer.Expect('[Microsoft.Inventory.Item.Item]: IT7326|text', 'no error: 27 [[Microsoft.Inventory.Item.Item]: IT7326]');
        Observer.Expect('[Microsoft.Inventory.Item.Item]: IT7326|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_HandWritten_QuotesAddedOrLeftOut()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7003Row";
        Dot: Record "R7003.Dot";
        Words: Record "R7003 Ns Words";
    begin
        Row.Id := 7;
        Dot.Id := 7;
        Words.Id := 7;
        Read(Observer, '[LT.R7003.Data."R7003Row"]: 7', Row.RecordId);
        Read(Observer, '[LT.R7003.Data."R7003 Ns Words"]: 7', Words.RecordId);
        Read(Observer, '[LT.R7003.Data.R7003.Dot]: 7', Dot.RecordId);
        Read(Observer, '["LT.R7003.Data.R7003Row"]: 7', Row.RecordId);
        Read(Observer, '["LT.R7003.Data"."R7003Row"]: 7', Row.RecordId);
        Read(Observer, '[LT.R7003.Data."R7003.Dot"]:7', Dot.RecordId);
        Read(Observer, '[LT.R7003.Data."R7003.Dot"]', Dot.RecordId);
        Read(Observer, '[LT.R7003.Data."R7003.Dot"]: ', Dot.RecordId);
        Observer.Expect('[LT.R7003.Data."R7003Row"]: 7', 'Yes 95680 same');
        Observer.Expect('[LT.R7003.Data."R7003 Ns Words"]: 7', 'Yes 95689 same');
        Observer.Expect('[LT.R7003.Data.R7003.Dot]: 7', 'No 0 []');
        Observer.Expect('["LT.R7003.Data.R7003Row"]: 7', 'No 0 []');
        Observer.Expect('["LT.R7003.Data"."R7003Row"]: 7', 'No 0 []');
        Observer.Expect('[LT.R7003.Data."R7003.Dot"]:7', 'Yes 95683 same');
        Observer.Expect('[LT.R7003.Data."R7003.Dot"]', 'Yes 95683 [[LT.R7003.Data."R7003.Dot"]]');
        Observer.Expect('[LT.R7003.Data."R7003.Dot"]: ', 'Yes 95683 [[LT.R7003.Data."R7003.Dot"]]');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_HandWritten_NamespacePart()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7003Row";
        Dot: Record "R7003.Dot";
        Plain: Record "R7003Plain";
    begin
        Row.Id := 7;
        Dot.Id := 7;
        Plain.Id := 7;
        Read(Observer, '[R7003Row]: 7', Row.RecordId);
        Read(Observer, '["R7003.Dot"]: 7', Dot.RecordId);
        Read(Observer, '[LT.Wrong.R7003Row]: 7', Row.RecordId);
        Read(Observer, '[Data.R7003Row]: 7', Row.RecordId);
        Read(Observer, '[lt.r7003.data.r7003row]: 7', Row.RecordId);
        Read(Observer, 'LT.R7003.Data.R7003Row: 7', Row.RecordId);
        Read(Observer, '[R7003Plain]: 7', Plain.RecordId);
        Read(Observer, '[LT.R7003.Data.R7003Plain]: 7', Plain.RecordId);
        Read(Observer, '"R7003Plain": 7', Plain.RecordId);
#if BC28PLUS
        Observer.Expect('[R7003Row]: 7', 'Yes 95680 same');
        Observer.Expect('["R7003.Dot"]: 7', 'No 0 []');
        Observer.Expect('[LT.Wrong.R7003Row]: 7', 'No 0 []');
        Observer.Expect('[Data.R7003Row]: 7', 'No 0 []');
        Observer.Expect('[lt.r7003.data.r7003row]: 7', 'No 0 []');
        Observer.Expect('LT.R7003.Data.R7003Row: 7', 'No 0 []');
        Observer.Expect('[R7003Plain]: 7', 'Yes 95685 same');
        Observer.Expect('[LT.R7003.Data.R7003Plain]: 7', 'No 0 []');
        Observer.Expect('"R7003Plain": 7', 'Yes 95685 same');
        Observer.Verify();
#else
        Observer.Expect('[R7003Row]: 7', 'No 0 []');
        Observer.Expect('["R7003.Dot"]: 7', 'No 0 []');
        Observer.Expect('[LT.Wrong.R7003Row]: 7', 'No 0 []');
        Observer.Expect('[Data.R7003Row]: 7', 'No 0 []');
        Observer.Expect('[lt.r7003.data.r7003row]: 7', 'No 0 []');
        Observer.Expect('LT.R7003.Data.R7003Row: 7', 'No 0 []');
        Observer.Expect('[R7003Plain]: 7', 'No 0 []');
        Observer.Expect('[LT.R7003.Data.R7003Plain]: 7', 'No 0 []');
        Observer.Expect('"R7003Plain": 7', 'Yes 95685 same');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Evaluate9_HandWritten_ResultNotUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadAsStatement(Observer, '[LT.Wrong.R7003Row]: 7');
        ReadAsStatement(Observer, '[LT.R7003.Data.R7003.Dot]: 7');
        ReadAsStatement(Observer, '[R7003Row]: 7');
        ReadAsStatement(Observer, '[LT.R7003.Data.NoSuchTable]: 7');
#if BC28PLUS
        Observer.Expect('[LT.Wrong.R7003Row]: 7|text', 'The value "[LT.Wrong.R7003Row]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.Wrong.R7003Row]: 7|code', 'Evaluate');
        Observer.Expect('[LT.R7003.Data.R7003.Dot]: 7|text', 'The value "[LT.R7003.Data.R7003.Dot]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.R7003.Data.R7003.Dot]: 7|code', 'Evaluate');
        Observer.Expect('[R7003Row]: 7|text', 'no error: 95680 [[LT.R7003.Data.R7003Row]: 7]');
        Observer.Expect('[R7003Row]: 7|code', 'Dialog');
        Observer.Expect('[LT.R7003.Data.NoSuchTable]: 7|text', 'The value "[LT.R7003.Data.NoSuchTable]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.R7003.Data.NoSuchTable]: 7|code', 'Evaluate');
        Observer.Verify();
#else
        Observer.Expect('[LT.Wrong.R7003Row]: 7|text', 'The value "[LT.Wrong.R7003Row]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.Wrong.R7003Row]: 7|code', 'Evaluate');
        Observer.Expect('[LT.R7003.Data.R7003.Dot]: 7|text', 'The value "[LT.R7003.Data.R7003.Dot]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.R7003.Data.R7003.Dot]: 7|code', 'Evaluate');
        Observer.Expect('[R7003Row]: 7|text', 'The value "[R7003Row]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[R7003Row]: 7|code', 'Evaluate');
        Observer.Expect('[LT.R7003.Data.NoSuchTable]: 7|text', 'The value "[LT.R7003.Data.NoSuchTable]: 7" can''t be evaluated into type RecordID.');
        Observer.Expect('[LT.R7003.Data.NoSuchTable]: 7|code', 'Evaluate');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Evaluate9_IntoRecordIdField()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Record "R7326 RecordId Holder";
        Row: Record "R7003Row";
        Dot: Record "R7003.Dot";
        Words: Record "R7003 Ns Words";
        WhseLine: Record "Whse. Worksheet Line";
        Ok: Boolean;
    begin
        Row.Id := 7;
        Dot.Id := 7;
        Words.Id := 7;
        WhseLine."Worksheet Template Name" := 'TPL';
        WhseLine.Name := 'BATCH';
        WhseLine."Location Code" := 'LOC';
        WhseLine."Line No." := 10000;
        Ok := Evaluate(Holder.Ref, Format(Row.RecordId, 0, 9));
        Observer.Observe('one word', Outcome(Ok, Holder.Ref, Row.RecordId));
        Clear(Holder);
        Ok := Evaluate(Holder.Ref, Format(Dot.RecordId, 0, 9));
        Observer.Observe('dot', Outcome(Ok, Holder.Ref, Dot.RecordId));
        Clear(Holder);
        Ok := Evaluate(Holder.Ref, Format(Words.RecordId, 0, 9));
        Observer.Observe('words', Outcome(Ok, Holder.Ref, Words.RecordId));
        Clear(Holder);
        Ok := Evaluate(Holder.Ref, Format(WhseLine.RecordId, 0, 9));
        Observer.Observe('Base Application, period', Outcome(Ok, Holder.Ref, WhseLine.RecordId));
        Observer.Expect('one word', 'Yes 95680 same');
        Observer.Expect('dot', 'Yes 95683 same');
        Observer.Expect('words', 'Yes 95689 same');
        Observer.Expect('Base Application, period', 'Yes 7326 same');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate9_IntoFieldRefOfRecordIdField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R7003Row";
        Dot: Record "R7003.Dot";
        Words: Record "R7003 Ns Words";
        WhseLine: Record "Whse. Worksheet Line";
        It: Record Item;
    begin
        Row.Id := 7;
        Dot.Id := 7;
        Words.Id := 7;
        WhseLine."Worksheet Template Name" := 'TPL';
        WhseLine.Name := 'BATCH';
        WhseLine."Location Code" := 'LOC';
        WhseLine."Line No." := 10000;
        It."No." := 'IT7326';
        ThroughFieldRef(Observer, 'one word', Row.RecordId);
        ThroughFieldRef(Observer, 'dot', Dot.RecordId);
        ThroughFieldRef(Observer, 'words', Words.RecordId);
        ThroughFieldRef(Observer, 'Base Application, period', WhseLine.RecordId);
        ThroughFieldRef(Observer, 'Base Application, one word', It.RecordId);
        Observer.Expect('one word', 'Yes 95680 same');
        Observer.Expect('one word, number 9', 'Yes 95680 same');
        Observer.Expect('dot', 'Yes 95683 same');
        Observer.Expect('dot, number 9', 'Yes 95683 same');
        Observer.Expect('words', 'Yes 95689 same');
        Observer.Expect('words, number 9', 'Yes 95689 same');
        Observer.Expect('Base Application, period', 'Yes 7326 same');
        Observer.Expect('Base Application, period, number 9', 'Yes 7326 same');
        Observer.Expect('Base Application, one word', 'Yes 27 same');
        Observer.Expect('Base Application, one word, number 9', 'Yes 27 same');
        Observer.Verify();
    end;

    local procedure ThroughFieldRef(var Observer: Codeunit "Probe Observer"; Name: Text; Id: RecordId)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Back: RecordId;
        Ok: Boolean;
    begin
        RecRef.Open(Database::"R7326 RecordId Holder");
        FldRef := RecRef.Field(2);
        Ok := Evaluate(FldRef, Format(Id, 0, 9));
        Back := FldRef.Value;
        Observer.Observe(Name, Outcome(Ok, Back, Id));
        RecRef.Close();
        Clear(Back);
        RecRef.Open(Database::"R7326 RecordId Holder");
        FldRef := RecRef.Field(2);
        Ok := Evaluate(FldRef, Format(Id, 0, 9), 9);
        Back := FldRef.Value;
        Observer.Observe(Name + ', number 9', Outcome(Ok, Back, Id));
        RecRef.Close();
    end;
}
