// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74135, tables 74136 and 74137, pages 74138 to 74140, test codeunit 74141
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a list part with SourceTableView where(Type = const(B)) and SubPageLink "Document No." = field("No."). The link field is declared before Type,
//   its TableRelation filters the header on Type (where(Type = field(Type))), and its OnValidate stores the Type it sees in Seen.
//   What the blank line of the part holds after New() (before typing), and what the stored line holds after a field is typed, for an existing
//   header (OpenEdit) and a new header (OpenNew). A second part without SourceTableView is the contrast.
//   Not pinned: New() on a part whose host header has Type B (HB) aborts the page with FormAbortException (the Document No. relation is validated
//   before Type is stamped: "cannot be found in the related table"); the exception is not catchable, so no test can assert it.
// Writer QO (al-runtime-rs assumption new-line-stamps-all-before-validating, Microsoft's shape: Service Order / Service Order Subform):
//   a host Card with SourceTableView where(Type = const(B)) (page 87101) holding the B part above and a copy of it with DelayedInsert = true
//   (page 87100), for a new header (OpenNew): the blank line the part shows, the line after the header No. is set, what the OnValidate
//   of "Document No." saw, the stored rows. QO_ tests in codeunit 74141.
//   Not pinned (uncatchable, same on 27.5, 28.5 and 29.0): on that host opened OpenEdit on a header of type B (HB), typing into the blank
//   line of either part (DelayedInsert or not, with or without New() first) ends the test with "Unexpected CLR exception thrown.:
//   Microsoft.Dynamics.Framework.UI.FormAbortException: Page LT QO NL Host B - HB has to close." caused by
//   NavCSideValidateTableRelationException "The field Document No. of table LT NL Line contains a value (HB) that cannot be found in the
//   related table (LT NL Header)." So the blank line validates Document No. while its Type is still A, even with DelayedInsert and a host
//   view of Type = B; no test can assert it.
// Writer QP (al-runtime-rs ask, Microsoft's Service Line shape): a header keyed on "Document Type" (Option Quote,Order) and "No." (87148)
//   and lines keyed on "Document Type", "Document No.", "Line No." whose two key fields each have an OnValidate that appends the OTHER
//   field's value to Seen (87149 without TableRelation; 87150 with Service Line's relation on "Document No."). A host Card (87154) holds
//   three parts: SubPageLink "Document Type" = field("Document Type"), "Document No." = field("No.") (87151, table 87149), the same link
//   written in the other order (87152), and the first link over the table with the relation (87153). QP_ tests in codeunit 74141: the
//   blank line after New(), the stored line after a field is typed, and Seen (which value the record held when each key field validated).
// Writer SF (al-runtime-rs assumption new-line-stamps-all-before-validating, the probe-wanted shape): line key (Type, Document No.,
//   Line No.), part view where(Type = const(B)), SubPageLink "Document No." = field("No."); tables 89068-89070, pages 89071-89074, SF_ tests.
// BC versions: 27, 28, 29 by CI

enum 74135 "LT NL Type"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
}

table 74136 "LT NL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Type; Enum "LT NL Type") { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 74137 "LT NL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[10])
        {
            TableRelation = "LT NL Header"."No." where (Type = field(Type));

            trigger OnValidate()
            begin
                Seen := Format(Type);
            end;
        }
        field(2; "Line No."; Integer) { }
        field(3; Type; Enum "LT NL Type") { }
        field(4; Seen; Text[20]) { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; "Document No.", "Line No.") { Clustered = true; } }
}

page 74138 "LT NL Lines B"
{
    PageType = ListPart;
    SourceTable = "LT NL Line";
    SourceTableView = where(Type = const(B));
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74139 "LT NL Lines Plain"
{
    PageType = ListPart;
    SourceTable = "LT NL Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74140 "LT NL Host"
{
    PageType = Card;
    SourceTable = "LT NL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Type; Rec.Type) { ApplicationArea = All; }
            part(LinesB; "LT NL Lines B")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(LinesPlain; "LT NL Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

codeunit 74141 "LT New Line Stamps Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed(HeaderNo: Code[10]; HeaderType: Enum "LT NL Type")
    var
        H: Record "LT NL Header";
        L: Record "LT NL Line";
    begin
        L.DeleteAll();
        H.DeleteAll();
        if HeaderNo = '' then
            exit;
        H."No." := HeaderNo;
        H.Type := HeaderType;
        H.Insert();
    end;

    local procedure ObserveLines(Prefix: Text)
    var
        L: Record "LT NL Line";
    begin
        Obs.Observe(Prefix + '.count', Format(L.Count()));
        if L.FindFirst() then
            Obs.Observe(Prefix + '.first', L."Document No." + '|' + Format(L.Type) + '|' + L.Seen + '|' + L.Descr);
    end;

    [TryFunction]
    local procedure TryNewB(var Host: TestPage "LT NL Host")
    begin
        Host.LinesB.New();
    end;

    [TryFunction]
    local procedure TryNewPlain(var Host: TestPage "LT NL Host")
    begin
        Host.LinesPlain.New();
    end;

    [TryFunction]
    local procedure TryReadB(var Host: TestPage "LT NL Host"; var Result: Text)
    begin
        Result := Host.LinesB."Document No.".Value() + '|' + Host.LinesB.Type.Value() + '|' + Host.LinesB.Seen.Value();
    end;

    [TryFunction]
    local procedure TryReadPlain(var Host: TestPage "LT NL Host"; var Result: Text)
    begin
        Result := Host.LinesPlain."Document No.".Value() + '|' + Host.LinesPlain.Type.Value() + '|' + Host.LinesPlain.Seen.Value();
    end;

    [TryFunction]
    local procedure TryTypeB(var Host: TestPage "LT NL Host")
    begin
        Host.LinesB.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure TryTypePlain(var Host: TestPage "LT NL Host")
    begin
        Host.LinesPlain.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT NL Host")
    begin
        Host.Close();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure PartB_ExistingHeaderTypeA_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HA', "LT NL Type"::A);
        Host.OpenEdit();
        Step('new', TryNewB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypeB(Host));
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'HA|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HA|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PartPlain_ExistingHeaderTypeA_NewLine()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('HA', "LT NL Type"::A);
        Host.OpenEdit();
        Step('new', TryNewPlain(Host));
        if TryReadPlain(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', TryTypePlain(Host));
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'HA|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HA|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PartB_OpenNewHeader_TypeThenNo()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Host.Type.SetValue('B');
        Host."No.".SetValue('HN');
        Step('type', TryTypeB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read', false);
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', '|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', '|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PartB_OpenNewHeader_NoThenType()
    var
        Host: TestPage "LT NL Host";
        Result: Text;
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Host."No.".SetValue('HN');
        Host.Type.SetValue('B');
        Step('type', TryTypeB(Host));
        if TryReadB(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read', false);
        Step('close', TryClose(Host));
        ObserveLines('db');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'HN|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'HN|A|A|x');
        Obs.Verify();
    end;

    // Writer PY-B (2026-10-20): why the line keeps a blank link when Type is typed before No. on a new header: what the header table
    // holds after each step, what the card shows, and the link filter of each part.
    // Rule seen: typing Type first inserts the header with a blank No.; No. typed afterwards is lost (card shows blank, no rename, part
    // filters stay ''), so the line gets the blank link. No. typed first: nothing stored until Type is typed, then the header is inserted
    // as HN and the parts filter on HN. Header Type B itself plays no part (Type A first behaves the same).
    local procedure Headers(): Text
    var
        H: Record "LT NL Header";
        Rows: Text;
    begin
        if H.FindSet() then
            repeat
                Rows += '[' + H."No." + '|' + Format(H.Type) + ']';
            until H.Next() = 0;
        exit(Format(H.Count()) + ' ' + Rows);
    end;

    local procedure Snapshot(Prefix: Text; var Host: TestPage "LT NL Host")
    begin
        Obs.Observe(Prefix + '.headers', Headers());
        Obs.Observe(Prefix + '.card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        Obs.Observe(Prefix + '.filter_b', '[' + Host.LinesB.Filter.GetFilter("Document No.") + ']');
        Obs.Observe(Prefix + '.filter_plain', '[' + Host.LinesPlain.Filter.GetFilter("Document No.") + ']');
    end;

    [TryFunction]
    local procedure TryHostNo(var Host: TestPage "LT NL Host"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryHostType(var Host: TestPage "LT NL Host"; Value: Text)
    begin
        Host.Type.SetValue(Value);
    end;

    [Test]
    procedure PYB_OpenNew_TypeThenNo_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Snapshot('open', Host);
        Step('set_type', TryHostType(Host, 'B'));
        Snapshot('after_type', Host);
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('line', TryTypePlain(Host));
        ObserveLines('after_line');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('after_close');
        Obs.Expect('open.headers', '0 ');
        Obs.Expect('open.card', '[|A]');
        Obs.Expect('open.filter_b', '['''']');
        Obs.Expect('open.filter_plain', '['''']');
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [|A]');
        Obs.Expect('after_type.card', '[|B]');
        Obs.Expect('after_type.filter_b', '['''']');
        Obs.Expect('after_type.filter_plain', '['''']');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.card', '[|B]');
        Obs.Expect('after_no.filter_b', '['''']');
        Obs.Expect('after_no.filter_plain', '['''']');
        Obs.Expect('line', 'ok');
        Obs.Expect('after_line.count', '0');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|B]');
        Obs.Expect('after_close.count', '1');
        Obs.Expect('after_close.first', '|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_NoThenType_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('set_type', TryHostType(Host, 'B'));
        Snapshot('after_type', Host);
        Step('line', TryTypePlain(Host));
        ObserveLines('after_line');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('after_close');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '0 ');
        Obs.Expect('after_no.card', '[HN|A]');
        Obs.Expect('after_no.filter_b', '[HN]');
        Obs.Expect('after_no.filter_plain', '[HN]');
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [HN|A]');
        Obs.Expect('after_type.card', '[HN|B]');
        Obs.Expect('after_type.filter_b', '[HN]');
        Obs.Expect('after_type.filter_plain', '[HN]');
        Obs.Expect('line', 'ok');
        Obs.Expect('after_line.count', '0');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [HN|B]');
        Obs.Expect('after_close.count', '1');
        Obs.Expect('after_close.first', 'HN|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TypeA_ThenNo_Steps()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_type', TryHostType(Host, 'A'));
        Snapshot('after_type', Host);
        Step('set_no', TryHostNo(Host, 'HN'));
        Snapshot('after_no', Host);
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        Obs.Expect('set_type', 'ok');
        Obs.Expect('after_type.headers', '1 [|A]');
        Obs.Expect('after_type.card', '[|A]');
        Obs.Expect('after_type.filter_b', '['''']');
        Obs.Expect('after_type.filter_plain', '['''']');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.card', '[|A]');
        Obs.Expect('after_no.filter_b', '['''']');
        Obs.Expect('after_no.filter_plain', '['''']');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|A]');
        Obs.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TypeThenNo_ThenNext()
    var
        Host: TestPage "LT NL Host";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Step('set_type', TryHostType(Host, 'B'));
        Step('set_no', TryHostNo(Host, 'HN'));
        Obs.Observe('next', Format(Host.Next()));
        Obs.Observe('after_next.headers', Headers());
        Obs.Observe('after_next.card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        Step('close', TryClose(Host));
        Obs.Observe('after_close.headers', Headers());
        Obs.Expect('set_type', 'ok');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('next', 'No');
        Obs.Expect('after_next.headers', '1 [|B]');
        Obs.Expect('after_next.card', '[|B]');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|B]');
        Obs.Verify();
    end;

    // Writer QO: host page 87101 (header view Type = B) with the part LinesB (74138) and LinesBD (87100, DelayedInsert).
    [TryFunction]
    local procedure QoRead(var Host: TestPage "LT QO NL Host B"; Delayed: Boolean; var Result: Text)
    begin
        if Delayed then
            Result := Host.LinesBD."Document No.".Value() + '|' + Host.LinesBD.Type.Value() + '|' + Host.LinesBD.Seen.Value()
        else
            Result := Host.LinesB."Document No.".Value() + '|' + Host.LinesB.Type.Value() + '|' + Host.LinesB.Seen.Value();
    end;

    [TryFunction]
    local procedure QoType(var Host: TestPage "LT QO NL Host B"; Delayed: Boolean)
    begin
        if Delayed then
            Host.LinesBD.Descr.SetValue('x')
        else
            Host.LinesB.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure QoClose(var Host: TestPage "LT QO NL Host B")
    begin
        Host.Close();
    end;

    [TryFunction]
    local procedure QoHostNo(var Host: TestPage "LT QO NL Host B"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    local procedure QoDraft(Name: Text; var Host: TestPage "LT QO NL Host B"; Delayed: Boolean)
    var
        Result: Text;
    begin
        if QoRead(Host, Delayed, Result) then
            Obs.Observe(Name, Result)
        else
            Obs.ObserveError(Name);
    end;

    [Test]
    procedure QO_HostB_OpenNew_DelayedPart_NoThenType()
    var
        Host: TestPage "LT QO NL Host B";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Obs.Observe('card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        QoDraft('blank', Host, true);
        Step('set_no', QoHostNo(Host, 'HN'));
        Obs.Observe('after_no.headers', Headers());
        QoDraft('after_no.blank', Host, true);
        Step('type', QoType(Host, true));
        QoDraft('typed', Host, true);
        Step('close', QoClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('db');
        Obs.Expect('card', '[|A]');
        Obs.Expect('blank', '|A|A');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.blank', '|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', '|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|A]');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', '|A|A|x');
        Obs.Verify();
    end;

    [Test]
    procedure QO_HostB_OpenNew_PartB_NoThenType()
    var
        Host: TestPage "LT QO NL Host B";
    begin
        Seed('', "LT NL Type"::A);
        Host.OpenNew();
        Obs.Observe('card', '[' + Host."No.".Value() + '|' + Host.Type.Value() + ']');
        QoDraft('blank', Host, false);
        Step('set_no', QoHostNo(Host, 'HN'));
        Obs.Observe('after_no.headers', Headers());
        QoDraft('after_no.blank', Host, false);
        Step('type', QoType(Host, false));
        QoDraft('typed', Host, false);
        Step('close', QoClose(Host));
        Obs.Observe('after_close.headers', Headers());
        ObserveLines('db');
        Obs.Expect('card', '[|A]');
        Obs.Expect('blank', '|A|A');
        Obs.Expect('set_no', 'ok');
        Obs.Expect('after_no.headers', '1 [|A]');
        Obs.Expect('after_no.blank', '|A|A');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', '|A|A');
        Obs.Expect('close', 'ok');
        Obs.Expect('after_close.headers', '1 [|A]');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', '|A|A|x');
        Obs.Verify();
    end;

    local procedure QP_Seed()
    var
        H: Record "LT QP TK Header";
        L: Record "LT QP TK Line";
        LR: Record "LT QP TK Line Rel";
    begin
        L.DeleteAll();
        LR.DeleteAll();
        H.DeleteAll();
        H."Document Type" := H."Document Type"::Quote;
        H."No." := 'H1';
        H.Insert();
        H."Document Type" := H."Document Type"::Order;
        H."No." := 'H1';
        H.Insert();
    end;

    local procedure QP_ObserveLines(Prefix: Text)
    var
        L: Record "LT QP TK Line";
    begin
        Obs.Observe(Prefix + '.count', Format(L.Count()));
        if L.FindFirst() then
            Obs.Observe(Prefix + '.first', Format(L."Document Type") + '|' + L."Document No." + '|' + Format(L."Line No.") + '|' + L.Seen + '|' + L.Descr);
    end;

    local procedure QP_ObserveRelLines(Prefix: Text)
    var
        L: Record "LT QP TK Line Rel";
    begin
        Obs.Observe(Prefix + '.count', Format(L.Count()));
        if L.FindFirst() then
            Obs.Observe(Prefix + '.first', Format(L."Document Type") + '|' + L."Document No." + '|' + Format(L."Line No.") + '|' + L.Seen + '|' + L.Descr);
    end;

    [TryFunction]
    local procedure QP_TryNew(var Host: TestPage "LT QP TK Host"; Which: Integer)
    begin
        case Which of
            1:
                Host.LinesTypeFirst.New();
            2:
                Host.LinesNoFirst.New();
            3:
                Host.LinesRel.New();
        end;
    end;

    [TryFunction]
    local procedure QP_TryRead(var Host: TestPage "LT QP TK Host"; Which: Integer; var Result: Text)
    begin
        case Which of
            1:
                Result := Host.LinesTypeFirst."Document Type".Value() + '|' + Host.LinesTypeFirst."Document No.".Value() + '|' + Host.LinesTypeFirst.Seen.Value();
            2:
                Result := Host.LinesNoFirst."Document Type".Value() + '|' + Host.LinesNoFirst."Document No.".Value() + '|' + Host.LinesNoFirst.Seen.Value();
            3:
                Result := Host.LinesRel."Document Type".Value() + '|' + Host.LinesRel."Document No.".Value() + '|' + Host.LinesRel.Seen.Value();
        end;
    end;

    [TryFunction]
    local procedure QP_TryType(var Host: TestPage "LT QP TK Host"; Which: Integer)
    begin
        case Which of
            1:
                Host.LinesTypeFirst.Descr.SetValue('x');
            2:
                Host.LinesNoFirst.Descr.SetValue('x');
            3:
                Host.LinesRel.Descr.SetValue('x');
        end;
    end;

    [TryFunction]
    local procedure QP_TryClose(var Host: TestPage "LT QP TK Host")
    begin
        Host.Close();
    end;

    local procedure QP_Run(Which: Integer; WithNew: Boolean)
    var
        H: Record "LT QP TK Header";
        Host: TestPage "LT QP TK Host";
        Result: Text;
    begin
        QP_Seed();
        Host.OpenEdit();
        Host.GoToKey(H."Document Type"::Order, 'H1');
        if WithNew then
            Step('new', QP_TryNew(Host, Which));
        if QP_TryRead(Host, Which, Result) then
            Obs.Observe('draft', Result)
        else
            Step('read', false);
        Step('type', QP_TryType(Host, Which));
        if QP_TryRead(Host, Which, Result) then
            Obs.Observe('typed', Result)
        else
            Step('read_typed', false);
        Step('close', QP_TryClose(Host));
        if Which = 3 then
            QP_ObserveRelLines('db')
        else
            QP_ObserveLines('db');
    end;

    [Test]
    procedure QP_TwoKeyLink_TypeFirst_NewLine()
    begin
        QP_Run(1, true);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'Order|H1|20000|type:no=[H1];no:type=[Order];|x');
        Obs.Verify();
    end;

    [Test]
    procedure QP_TwoKeyLink_TypeFirst_BlankLine()
    begin
        QP_Run(1, false);
        Obs.Expect('draft', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'Order|H1|10000|type:no=[H1];no:type=[Order];|x');
        Obs.Verify();
    end;

    [Test]
    procedure QP_TwoKeyLink_NoFirst_NewLine()
    begin
        QP_Run(2, true);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'Order|H1|20000|type:no=[H1];no:type=[Order];|x');
        Obs.Verify();
    end;

    [Test]
    procedure QP_TwoKeyLink_WithRelation_NewLine()
    begin
        QP_Run(3, true);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'Order|H1|type:no=[H1];no:type=[Order];');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'Order|H1|20000|type:no=[H1];no:type=[Order];|x');
        Obs.Verify();
    end;

    // ---- writer SF (al-runtime-rs assumption new-line-stamps-all-before-validating): the line key is (Type, Document No., Line No.),
    //      the part's view is where(Type = const(B)) and its SubPageLink "Document No." = field("No."), so the blank line takes two key
    //      values. Each key field's OnValidate notes the other one in Seen (T:<Document No.> for Type, D:<Type> for Document No.). ----

    local procedure SfSeed(HeaderNo: Code[10]; HeaderType: Enum "LT NL Type")
    var
        H: Record "LT SF NL Header";
        L: Record "LT SF NL Line";
        R: Record "LT SF NL Rel Line";
    begin
        L.DeleteAll();
        R.DeleteAll();
        H.DeleteAll();
        H."No." := HeaderNo;
        H.Type := HeaderType;
        H.Insert();
    end;

    local procedure SfObserveLines(Prefix: Text)
    var
        L: Record "LT SF NL Line";
    begin
        Obs.Observe(Prefix + '.count', Format(L.Count()));
        if L.FindFirst() then
            Obs.Observe(Prefix + '.first', Format(L.Type) + '|' + L."Document No." + '|' + Format(L."Line No.") + '|' + L.Seen + '|' + L.Descr);
    end;

    local procedure SfObserveRelLines(Prefix: Text)
    var
        R: Record "LT SF NL Rel Line";
    begin
        Obs.Observe(Prefix + '.count', Format(R.Count()));
        if R.FindFirst() then
            Obs.Observe(Prefix + '.first', Format(R.Type) + '|' + R."Document No." + '|' + Format(R."Line No.") + '|' + R.Seen + '|' + R.Descr);
    end;

    [TryFunction]
    local procedure SfTryNew(var Host: TestPage "LT SF NL Host")
    begin
        Host.Lines.New();
    end;

    [TryFunction]
    local procedure SfTryRead(var Host: TestPage "LT SF NL Host"; var Result: Text)
    begin
        Result := Host.Lines.Type.Value() + '|' + Host.Lines."Document No.".Value() + '|' + Host.Lines.Seen.Value();
    end;

    [TryFunction]
    local procedure SfTryType(var Host: TestPage "LT SF NL Host")
    begin
        Host.Lines.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure SfTryClose(var Host: TestPage "LT SF NL Host")
    begin
        Host.Close();
    end;

    local procedure SfRun(HeaderType: Enum "LT NL Type"; WithNew: Boolean)
    var
        Host: TestPage "LT SF NL Host";
        Result: Text;
    begin
        SfSeed('H1', HeaderType);
        Host.OpenEdit();
        if WithNew then
            Step('new', SfTryNew(Host));
        if SfTryRead(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('draft', false);
        Step('type', SfTryType(Host));
        if SfTryRead(Host, Result) then
            Obs.Observe('typed', Result)
        else
            Step('typed', false);
        Step('close', SfTryClose(Host));
        SfObserveLines('db');
    end;

    [Test]
    procedure SF_TwoKeyValues_HeaderTypeB_NewLine()
    begin
        SfRun("LT NL Type"::B, true);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'B|H1|T:H1;D:B;');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'B|H1|T:H1;D:B;');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'B|H1|0|T:H1;D:B;|x');
        Obs.Verify();
    end;

    [Test]
    procedure SF_TwoKeyValues_HeaderTypeA_NewLine()
    begin
        SfRun("LT NL Type"::A, true);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'B|H1|T:H1;D:B;');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'B|H1|T:H1;D:B;');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'B|H1|0|T:H1;D:B;|x');
        Obs.Verify();
    end;

    [Test]
    procedure SF_TwoKeyValues_HeaderTypeB_BlankLine()
    begin
        SfRun("LT NL Type"::B, false);
        Obs.Expect('draft', 'B|H1|T:H1;D:B;');
        Obs.Expect('type', 'ok');
        Obs.Expect('typed', 'B|H1|T:H1;D:B;');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'B|H1|0|T:H1;D:B;|x');
        Obs.Verify();
    end;

    // The same with the relation of Service Line: "Document No." relates to the header where(Type = field(Type)). A header of Type B
    // can be validated only when Type is already B on the line. Its own host page, so an abort here does not touch the tests above.
    [TryFunction]
    local procedure SfTryNewRel(var Host: TestPage "LT SF NL Rel Host")
    begin
        Host.Lines.New();
    end;

    [TryFunction]
    local procedure SfTryReadRel(var Host: TestPage "LT SF NL Rel Host"; var Result: Text)
    begin
        Result := Host.Lines.Type.Value() + '|' + Host.Lines."Document No.".Value() + '|' + Host.Lines.Seen.Value();
    end;

    [TryFunction]
    local procedure SfTryTypeRel(var Host: TestPage "LT SF NL Rel Host")
    begin
        Host.Lines.Descr.SetValue('x');
    end;

    [TryFunction]
    local procedure SfTryCloseRel(var Host: TestPage "LT SF NL Rel Host")
    begin
        Host.Close();
    end;

    local procedure SfRunRel(HeaderType: Enum "LT NL Type")
    var
        Host: TestPage "LT SF NL Rel Host";
        Result: Text;
    begin
        SfSeed('H1', HeaderType);
        Host.OpenEdit();
        Step('new', SfTryNewRel(Host));
        if SfTryReadRel(Host, Result) then
            Obs.Observe('draft', Result)
        else
            Step('draft', false);
        Step('type', SfTryTypeRel(Host));
        Step('close', SfTryCloseRel(Host));
        SfObserveRelLines('db');
    end;

    [Test]
    procedure SF_TwoKeyValues_Relation_HeaderTypeB_NewLine()
    begin
        SfRunRel("LT NL Type"::B);
        Obs.Expect('new', 'ok');
        Obs.Expect('draft', 'B|H1|T:H1;D:B;');
        Obs.Expect('type', 'ok');
        Obs.Expect('close', 'ok');
        Obs.Expect('db.count', '1');
        Obs.Expect('db.first', 'B|H1|0|T:H1;D:B;|x');
        Obs.Verify();
    end;

    // Not pinned: the same on a header of Type A (the line takes Type B from the view, so the header H1 is not in the related set) ends
    // the test with the uncatchable "Unexpected CLR exception thrown.: Microsoft.Dynamics.Framework.UI.FormAbortException: Page LT SF NL
    // Rel Host - H1 has to close." caused by NavCSideValidateTableRelationException "The field Document No. of table LT SF NL Rel Line
    // contains a value (H1) that cannot be found in the related table (LT SF NL Header)." (corpus CI 27.5, 28.5, 29.0).

}

page 87100 "LT QO NL Lines BD"
{
    PageType = ListPart;
    SourceTable = "LT NL Line";
    SourceTableView = where(Type = const(B));
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 87101 "LT QO NL Host B"
{
    PageType = Card;
    SourceTable = "LT NL Header";
    SourceTableView = where(Type = const(B));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Type; Rec.Type) { ApplicationArea = All; }
            part(LinesB; "LT NL Lines B")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(LinesBD; "LT QO NL Lines BD")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

table 87148 "LT QP TK Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = Quote,Order; }
        field(2; "No."; Code[10]) { }
    }

    keys { key(PK; "Document Type", "No.") { Clustered = true; } }
}

table 87149 "LT QP TK Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionMembers = Quote,Order;

            trigger OnValidate()
            begin
                Seen += 'type:no=[' + "Document No." + '];';
            end;
        }
        field(3; "Document No."; Code[10])
        {

            trigger OnValidate()
            begin
                Seen += 'no:type=[' + Format("Document Type") + '];';
            end;
        }
        field(4; "Line No."; Integer) { }
        field(5; Seen; Text[100]) { }
        field(6; Descr; Text[30]) { }
    }

    keys { key(PK; "Document Type", "Document No.", "Line No.") { Clustered = true; } }
}

table 87150 "LT QP TK Line Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionMembers = Quote,Order;

            trigger OnValidate()
            begin
                Seen += 'type:no=[' + "Document No." + '];';
            end;
        }
        field(3; "Document No."; Code[10])
        {
            TableRelation = "LT QP TK Header"."No." where("Document Type" = field("Document Type"));

            trigger OnValidate()
            begin
                Seen += 'no:type=[' + Format("Document Type") + '];';
            end;
        }
        field(4; "Line No."; Integer) { }
        field(5; Seen; Text[100]) { }
        field(6; Descr; Text[30]) { }
    }

    keys { key(PK; "Document Type", "Document No.", "Line No.") { Clustered = true; } }
}

page 87151 "LT QP TK Lines TypeFirst"
{
    PageType = ListPart;
    SourceTable = "LT QP TK Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 87152 "LT QP TK Lines NoFirst"
{
    PageType = ListPart;
    SourceTable = "LT QP TK Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 87153 "LT QP TK Lines Rel"
{
    PageType = ListPart;
    SourceTable = "LT QP TK Line Rel";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 87154 "LT QP TK Host"
{
    PageType = Card;
    SourceTable = "LT QP TK Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(LinesTypeFirst; "LT QP TK Lines TypeFirst")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
            }
            part(LinesNoFirst; "LT QP TK Lines NoFirst")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No."), "Document Type" = field("Document Type");
            }
            part(LinesRel; "LT QP TK Lines Rel")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
            }
        }
    }
}

// Writer SF: Service Line's key shape (Type, Document No., Line No.) with the part view where(Type = const(B)).
table 89068 "LT SF NL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Type; Enum "LT NL Type") { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 89069 "LT SF NL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Type; Enum "LT NL Type")
        {
            trigger OnValidate()
            begin
                Seen += 'T:' + "Document No." + ';';
            end;
        }
        field(2; "Document No."; Code[10])
        {
            trigger OnValidate()
            begin
                Seen += 'D:' + Format(Type) + ';';
            end;
        }
        field(3; "Line No."; Integer) { }
        field(4; Seen; Text[50]) { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; Type, "Document No.", "Line No.") { Clustered = true; } }
}

table 89070 "LT SF NL Rel Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Type; Enum "LT NL Type")
        {
            trigger OnValidate()
            begin
                Seen += 'T:' + "Document No." + ';';
            end;
        }
        field(2; "Document No."; Code[10])
        {
            TableRelation = "LT SF NL Header"."No." where(Type = field(Type));

            trigger OnValidate()
            begin
                Seen += 'D:' + Format(Type) + ';';
            end;
        }
        field(3; "Line No."; Integer) { }
        field(4; Seen; Text[50]) { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; Type, "Document No.", "Line No.") { Clustered = true; } }
}

page 89071 "LT SF NL Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SF NL Line";
    SourceTableView = where(Type = const(B));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 89072 "LT SF NL Rel Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SF NL Rel Line";
    SourceTableView = where(Type = const(B));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 89073 "LT SF NL Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SF NL Header";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Type; Rec.Type) { ApplicationArea = All; }
            part(Lines; "LT SF NL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 89074 "LT SF NL Rel Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SF NL Header";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Type; Rec.Type) { ApplicationArea = All; }
            part(Lines; "LT SF NL Rel Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
