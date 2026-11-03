// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 67573 and 67576, pages 67577 and 67578, log codeunit 67579, test codeunit 67582; pages 85183-85190 (writer PY-B); pages 86760-86766 and codeunit 86767 (writer QH)
// Probe: a document page (header "No." is the key) with a lines ListPart linked by SourceTableLink. A line is entered while the header key is still blank, then the key is typed. Which table triggers run (header and line: OnInsert, OnValidate), in which order, which page triggers run, what the card and the part show afterwards and what is stored. The same with the key typed first, for comparison (issue 581 item 2).
// BC versions: 27+ (the key-typed-after-a-line test: 28+; BC 27 raises an uncatchable NullReferenceException there)

table 67573 "LT DL Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('H.OnValidate(No.):' + "No.");
            end;
        }
        field(2; Name; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('H.OnValidate(Name):' + Name + ' key=' + "No.");
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('H.OnInsert:' + "No.");
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('H.OnModify:' + "No.");
    end;
}

table 67576 "LT DL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "LT DL Header";

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Document No.):' + "Document No.");
            end;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Description; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Description):' + Description + ' key=' + "Document No." + '/' + Format("Line No."));
            end;
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "LT DL Log";
            begin
                Log.Add('L.OnValidate(Quantity):' + Format(Quantity) + ' key=' + "Document No." + '/' + Format("Line No."));
            end;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('L.OnInsert:' + "Document No." + '/' + Format("Line No."));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('L.OnModify:' + "Document No." + '/' + Format("Line No."));
    end;
}

codeunit 67579 "LT DL Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 67578 "LT DL Lines"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('LP.OnNewRecord:' + Rec."Document No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('LP.OnInsertRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
        exit(true);
    end;
}

page 67577 "LT DL Document"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('HP.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('HP.OnInsertRecord:' + Rec."No.");
        exit(true);
    end;
}

// Writer PY-B (2026-10-20): page shapes for the count of a part's OnNewRecord at host OpenNew and New (pages 85183-85190, all log into
// "LT DL Log" and are used by test codeunit 67582 only).
page 85183 "LT PYB DL Lines NoSplit"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('NP.OnNewRecord:' + Rec."Document No." + ' below=' + Format(BelowxRec));
    end;
}

page 85184 "LT PYB DL Lines B"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('BP.OnNewRecord:' + Rec."Document No." + ' below=' + Format(BelowxRec));
    end;
}

page 85185 "LT PYB DL Doc NoTrigger"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85186 "LT PYB DL Doc Unlinked"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
            }
        }
    }
}

page 85187 "LT PYB DL Doc NoSplit"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT PYB DL Lines NoSplit")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85188 "LT PYB DL Doc Two"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(LinesB; "LT PYB DL Lines B")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85189 "LT PYB DL Card"
{
    PageType = Card;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 85190 "LT PYB DL Doc Const"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = const('D9');
            }
        }
    }
}

// Writer QH (2026-10-21): pages 86760-86766 and manual subscriber codeunit 86767 for the part trigger probes of al-runtime-rs PR 384
// (OnAfterGetCurrRecord among the three OnNewRecord runs, OpenView on a host with no row, the const-link relation error, the host
// insert at Close). All log into "LT DL Log" and are used by test codeunit 67582 only. Measured on BC 27.5, 28.5 and 29.0 (same values):
// - An empty part of an editable host (OpenNew, OpenEdit, host Next, host key typed) runs OnAfterGetCurrRecord right after EACH of its
//   three OnNewRecord runs: validate, new, curr, new, curr, validate, new, curr. A part with only OnAfterGetCurrRecord runs it 3 times.
//   A part with rows runs OnAfterGetRecord 4 times (first, second, first, first) and OnAfterGetCurrRecord once.
// - OpenView on a host that shows no row (empty table, or a filter that removes the row) runs the part's OnNewRecord once and then its
//   OnAfterGetCurrRecord once, without validation; the host runs no OnNewRecord and nothing is inserted.
// - A const() link whose value the relation rejects: the part runs OnOpenPage, OnNewRecord and OnAfterGetCurrRecord once, then OpenNew or
//   OpenEdit fails (TestWrapped) before any OnBeforeValidate event of the link field. When the related row exists, the const link
//   validates like a field link (OnBeforeValidate event, OnValidate, OnAfterValidate event, then the new/curr runs).
// - The host insert is not done by Close: the FIRST read or move in a part (a part control's Value, Lines.First) on a new, unsaved host
//   inserts the host (page OnInsertRecord, table OnInsert) whether the part shows rows or not, then relinks the part. Reading a host
//   control, Close, OK, host New() and a host OnNewRecord that sets a field insert nothing. (PYB_OpenNew_LinkedPart_BlankKeyRowsExist
//   reads a part control before Close, which is why its close log shows the insert.)
page 86760 "LT QH DL Lines Cur"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('CP.OnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('CP.OnNewRecord:' + Rec."Document No." + ' below=' + Format(BelowxRec));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('CP.OnAfterGetRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('CP.OnAfterGetCurrRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('CP.OnInsertRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
        exit(true);
    end;
}

page 86761 "LT QH DL Lines CurOnly"
{
    PageType = ListPart;
    SourceTable = "LT DL Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('OP.OnAfterGetCurrRecord:' + Rec."Document No." + '/' + Format(Rec."Line No."));
    end;
}

page 86762 "LT QH DL Doc Cur"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT QH DL Lines Cur")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 86763 "LT QH DL Doc Trace"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT QH DL Lines Cur")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnNewRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnAfterGetRecord:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnAfterGetCurrRecord:' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnInsertRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnModifyRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('TH.OnClosePage');
    end;
}

page 86764 "LT QH DL Doc CurOnly"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT QH DL Lines CurOnly")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}

page 86765 "LT QH DL Doc Const"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "LT QH DL Lines Cur")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = const('D9');
            }
        }
    }
}

page 86766 "LT QH DL Doc SetName"
{
    PageType = Document;
    SourceTable = "LT DL Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "LT DL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Rec.Name := 'init';
        Log.Add('SH.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('SH.OnInsertRecord:' + Rec."No." + '|' + Rec.Name);
        exit(true);
    end;
}

codeunit 86767 "LT QH DL Validate Events"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT DL Line", 'OnBeforeValidateEvent', 'Document No.', false, false)]
    local procedure OnBeforeValidateDocumentNo(var Rec: Record "LT DL Line"; var xRec: Record "LT DL Line"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('E.OnBeforeValidate(Document No.):' + Rec."Document No." + ' x=' + xRec."Document No." + ' curr=' + Format(CurrFieldNo));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT DL Line", 'OnAfterValidateEvent', 'Document No.', false, false)]
    local procedure OnAfterValidateDocumentNo(var Rec: Record "LT DL Line"; var xRec: Record "LT DL Line"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT DL Log";
    begin
        Log.Add('E.OnAfterValidate(Document No.):' + Rec."Document No.");
    end;
}

codeunit 67582 "LT DL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Log: Codeunit "LT DL Log";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenNew(var Host: TestPage "LT DL Document")
    begin
        Host.OpenNew();
    end;

    [TryFunction]
    local procedure TryNewLine(var Host: TestPage "LT DL Document")
    begin
        Host.Lines.New();
    end;

    [TryFunction]
    local procedure TryDescription(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Lines.Description.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryQuantity(var Host: TestPage "LT DL Document"; Value: Decimal)
    begin
        Host.Lines.Quantity.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryKey(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryName(var Host: TestPage "LT DL Document"; Value: Text)
    begin
        Host.Name.SetValue(Value);
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    var
        Log: Codeunit "LT DL Log";
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + '_error');
        Observer.Observe(Name + '_log', PortableLog(Log.Dump()));
        Log.Reset();
    end;

    // Corpus issue 688 (owner OK 2026-10-22): while the client shows a blank draft line in a part, how often the part's OnNewRecord fires
    // depends on the service tier (handlers/TestPagePartOnNewRecordCount.al: six firings on one tier, three on another), and the entries
    // that come with each firing repeat with it: the line's L.OnValidate(Document No.) and its OnBefore/OnAfterValidate events, and the
    // part's OnAfterGetCurrRecord on the draft line (Line No. 0). A log with two or more part OnNewRecord entries is therefore observed
    // without those entries, which keeps the exact order of every other trigger, followed by the list of the removed kinds, each of which
    // fired at least once. A log with at most one part OnNewRecord entry (a single new line, a stable +1) is observed exactly.
    local procedure PortableLog(Dump: Text): Text
    var
        Entries: List of [Text];
        Entry: Text;
        Kind: Text;
        Kept: Text;
        Seen: Text;
        Kinds: List of [Text];
        Present: List of [Text];
        PartNewRecords: Integer;
    begin
        if (StrLen(Dump) < 2) or (Dump = '[]') then
            exit(Dump);
        Entries := CopyStr(Dump, 2, StrLen(Dump) - 2).Split(' | ');
        foreach Entry in Entries do
            if Entry.StartsWith('LP.OnNewRecord:') or Entry.StartsWith('NP.OnNewRecord:') or Entry.StartsWith('BP.OnNewRecord:') or Entry.StartsWith('CP.OnNewRecord:') then
                PartNewRecords += 1;
        if PartNewRecords < 2 then
            exit(Dump);
        foreach Entry in Entries do begin
            Kind := DraftKind(Entry);
            if Kind = '' then begin
                if Kept <> '' then
                    Kept += ' | ';
                Kept += Entry;
            end else
                if not Present.Contains(Kind) then
                    Present.Add(Kind);
        end;
        Kinds.AddRange('LP.OnNewRecord', 'NP.OnNewRecord', 'BP.OnNewRecord', 'CP.OnNewRecord', 'L.OnValidate(Document No.)', 'E.OnBeforeValidate(Document No.)', 'E.OnAfterValidate(Document No.)', 'CP.OnAfterGetCurrRecord(draft)', 'OP.OnAfterGetCurrRecord(draft)');
        foreach Kind in Kinds do
            if Present.Contains(Kind) then begin
                if Seen <> '' then
                    Seen += ', ';
                Seen += Kind;
            end;
        exit('[' + Kept + '] fired at least once: ' + Seen);
    end;

    local procedure DraftKind(Entry: Text): Text
    var
        Prefix: Text;
    begin
        foreach Prefix in 'LP.,NP.,BP.,CP.'.Split(',') do
            if Entry.StartsWith(Prefix + 'OnNewRecord:') then
                exit(Prefix + 'OnNewRecord');
        if Entry.StartsWith('L.OnValidate(Document No.):') then
            exit('L.OnValidate(Document No.)');
        if Entry.StartsWith('E.OnBeforeValidate(Document No.):') then
            exit('E.OnBeforeValidate(Document No.)');
        if Entry.StartsWith('E.OnAfterValidate(Document No.):') then
            exit('E.OnAfterValidate(Document No.)');
        foreach Prefix in 'CP.,OP.'.Split(',') do
            if Entry.StartsWith(Prefix + 'OnAfterGetCurrRecord:') and Entry.EndsWith('/0') then
                exit(Prefix + 'OnAfterGetCurrRecord(draft)');
        exit('');
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Header: Record "LT DL Header";
        Line: Record "LT DL Line";
        Rows: Text;
    begin
        Observer.Observe(Name + '_headers', Format(Header.Count()));
        if Header.FindSet() then
            repeat
                Rows += '[' + Header."No." + '|' + Header.Name + ']';
            until Header.Next() = 0;
        Observer.Observe(Name + '_header_rows', Rows);
        Rows := '';
        Observer.Observe(Name + '_lines', Format(Line.Count()));
        if Line.FindSet() then
            repeat
                Rows += '[' + Line."Document No." + '|' + Format(Line."Line No.") + '|' + Line.Description + '|' + Format(Line.Quantity) + ']';
            until Line.Next() = 0;
        Observer.Observe(Name + '_line_rows', Rows);
    end;

    local procedure Card(var Observer: Codeunit "Probe Observer"; Name: Text; var Host: TestPage "LT DL Document")
    begin
        Observer.Observe(Name + '_card_no', '[' + Host."No.".Value() + ']');
        Observer.Observe(Name + '_card_name', '[' + Host.Name.Value() + ']');
        Observer.Observe(Name + '_part_description', '[' + Host.Lines.Description.Value() + ']');
        Observer.Observe(Name + '_part_quantity', '[' + Host.Lines.Quantity.Value() + ']');
    end;

#if BC28PLUS // BC 27 raises an uncatchable CLR exception when the key is typed after a line was entered (a NullReferenceException that neither a TryFunction nor asserterror catches, so BC 27 cannot be pinned here)
    [Test]
    procedure PartLine_EnteredBeforeHostKey_ThenKeyTyped()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description_before_key', TryDescription(Host, 'first'));
        Step(Observer, 'quantity_before_key', TryQuantity(Host, 3));
        Stored(Observer, 'before_key');
        Step(Observer, 'type_key', TryKey(Host, 'D1'));
        Card(Observer, 'after_key', Host);
        Stored(Observer, 'after_key');
        Step(Observer, 'type_name', TryName(Host, 'Doc one'));
        Stored(Observer, 'after_name');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[HP.OnInsertRecord: | H.OnInsert:] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('description_before_key', 'Yes');
        Observer.Expect('description_before_key_log', '[L.OnValidate(Description):first key=/0]');
        Observer.Expect('quantity_before_key', 'Yes');
        Observer.Expect('quantity_before_key_log', '[LP.OnInsertRecord:/20000 | L.OnInsert:/20000 | L.OnValidate(Quantity):3 key=/20000]');
        Observer.Expect('before_key_headers', '1');
        Observer.Expect('before_key_header_rows', '[|]');
        Observer.Expect('before_key_lines', '1');
        Observer.Expect('before_key_line_rows', '[|20000|first|0]');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[L.OnModify:/20000 | H.OnValidate(No.):D1]');
        Observer.Expect('after_key_card_no', '[]');
        Observer.Expect('after_key_card_name', '[]');
        Observer.Expect('after_key_part_description', '[first]');
        Observer.Expect('after_key_part_quantity', '[3.00]');
        Observer.Expect('after_key_headers', '1');
        Observer.Expect('after_key_header_rows', '[|]');
        Observer.Expect('after_key_lines', '1');
        Observer.Expect('after_key_line_rows', '[|20000|first|3]');
        Observer.Expect('type_name', 'Yes');
        Observer.Expect('type_name_log', '[H.OnValidate(Name):Doc one key=]');
        Observer.Expect('after_name_headers', '1');
        Observer.Expect('after_name_header_rows', '[|]');
        Observer.Expect('after_name_lines', '1');
        Observer.Expect('after_name_line_rows', '[|20000|first|3]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[H.OnModify:]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|Doc one]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|20000|first|3]');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure PartLine_EnteredAfterHostKey_Baseline()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'type_key', TryKey(Host, 'D2'));
        Stored(Observer, 'after_key');
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description', TryDescription(Host, 'second'));
        Step(Observer, 'quantity', TryQuantity(Host, 4));
        Card(Observer, 'after_line', Host);
        Stored(Observer, 'after_line');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[H.OnValidate(No.):D2] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('after_key_headers', '0');
        Observer.Expect('after_key_header_rows', '');
        Observer.Expect('after_key_lines', '0');
        Observer.Expect('after_key_line_rows', '');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[HP.OnInsertRecord:D2 | H.OnInsert:D2] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('description', 'Yes');
        Observer.Expect('description_log', '[L.OnValidate(Description):second key=D2/0]');
        Observer.Expect('quantity', 'Yes');
        Observer.Expect('quantity_log', '[LP.OnInsertRecord:D2/20000 | L.OnInsert:D2/20000 | L.OnValidate(Quantity):4 key=D2/20000]');
        Observer.Expect('after_line_card_no', '[D2]');
        Observer.Expect('after_line_card_name', '[]');
        Observer.Expect('after_line_part_description', '[second]');
        Observer.Expect('after_line_part_quantity', '[4.00]');
        Observer.Expect('after_line_headers', '1');
        Observer.Expect('after_line_header_rows', '[D2|]');
        Observer.Expect('after_line_lines', '1');
        Observer.Expect('after_line_line_rows', '[D2|20000|second|0]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[L.OnModify:D2/20000]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[D2|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[D2|20000|second|4]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClose(var Host: TestPage "LT DL Document")
    begin
        Host.Close();
    end;

    // Writer PY-B (2026-10-20): how often a part's OnNewRecord runs while its host opens new, by page shape (BC 29 local, then the CI legs).
    // Rule seen: an EDITABLE host (OpenNew, OpenEdit) whose part shows no row runs the part's OnNewRecord 3 times, each pair of runs after
    // a validation of the SubPageLink field (validate, new, new, validate, new); an unlinked part gives the 3 runs without validations; a
    // second linked part repeats the pattern after the first; host OnNewRecord, AutoSplitKey and page type (Card or Document) change
    // nothing. A part that shows rows (unlinked with rows, or linked rows of the blank key) runs none. OpenView runs it once, without
    // validation. Host New() runs only the host's OnNewRecord, never the part's. A const() link to a missing header: OpenNew fails
    // TestWrapped with the relation text after one part OnNewRecord.
    local procedure SeedLine(DocNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT DL Line";
    begin
        Line."Document No." := DocNo;
        Line."Line No." := LineNo;
        Line.Description := 'seeded';
        Line.Insert();
    end;

    local procedure TakeLog(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Log: Codeunit "LT DL Log";
    begin
        Observer.Observe(Name, PortableLog(Log.Dump()));
        Log.Reset();
    end;

    [Test]
    procedure PYB_OpenNew_Document_LogOnly()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_HostWithoutOnNewRecord()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoTrigger";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_UnlinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[] fired at least once: LP.OnNewRecord');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_UnlinkedPart_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        SeedLine('X1', 10000);
        SeedLine('X1', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_PartWithoutAutoSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoSplit";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[] fired at least once: NP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_TwoLinkedParts()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Two";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[] fired at least once: LP.OnNewRecord, BP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_CardHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Card";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_ConstLinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Const";
    begin
        Seed();
        Observer.Observe('open_new', Format(TryOpenConst(Host)));
        Observer.ObserveError('open_new_error');
        TakeLog(Observer, 'open_new_log');
        Observer.Expect('open_new', 'No');
        Observer.Expect('open_new_error|text', 'The field Document No. of table LT DL Line contains a value (D9) that cannot be found in the related table (LT DL Header).');
        Observer.Expect('open_new_error|code', 'TestWrapped');
        Observer.Expect('open_new_log', '[LP.OnNewRecord:D9]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryOpenConst(var Host: TestPage "LT PYB DL Doc Const")
    begin
        Host.OpenNew();
    end;

    [Test]
    procedure PYB_OpenEdit_HostWithoutLines()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D8';
        Header.Insert();
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('host_new', '[HP.OnNewRecord]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_ThenHostNew()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('host_new', '[HP.OnNewRecord]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenNew_LinkedPart_BlankKeyRowsExist()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        SeedLine('', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_first_description', Host.Lines.Description.Value());
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('part_first_description', 'seeded');
        Observer.Expect('close', '[HP.OnInsertRecord: | H.OnInsert:]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenEdit_ThenHostNew()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D5';
        Header.Insert();
        SeedLine('D5', 10000);
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.New();
        TakeLog(Observer, 'host_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[]');
        Observer.Expect('host_new', '[HP.OnNewRecord]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OpenView_ExistingHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Header: Record "LT DL Header";
    begin
        Seed();
        Header."No." := 'D6';
        Header.Insert();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[LP.OnNewRecord:D6]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    // A non-key field typed first inserts the host with a blank key; the key typed later runs its OnValidate but is lost (no rename, the
    // card shows blank), and the line is stored under the blank key at Close.
    procedure PYB_OpenNew_NameTypedFirst_ThenKey_ThenLine()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Step(Observer, 'open_new', TryOpenNew(Host));
        Step(Observer, 'type_name', TryName(Host, 'N1'));
        Stored(Observer, 'after_name');
        Step(Observer, 'type_key', TryKey(Host, 'D7'));
        Observer.Observe('after_key_card_no', '[' + Host."No.".Value() + ']');
        Stored(Observer, 'after_key');
        Step(Observer, 'new_line', TryNewLine(Host));
        Step(Observer, 'description', TryDescription(Host, 'x'));
        Stored(Observer, 'after_line');
        Step(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('type_name', 'Yes');
        Observer.Expect('type_name_log', '[HP.OnInsertRecord: | H.OnInsert: | H.OnValidate(Name):N1 key=] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('after_name_headers', '1');
        Observer.Expect('after_name_header_rows', '[|]');
        Observer.Expect('after_name_lines', '0');
        Observer.Expect('after_name_line_rows', '');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[H.OnValidate(No.):D7]');
        Observer.Expect('after_key_card_no', '[]');
        Observer.Expect('after_key_headers', '1');
        Observer.Expect('after_key_header_rows', '[|]');
        Observer.Expect('after_key_lines', '0');
        Observer.Expect('after_key_line_rows', '');
        Observer.Expect('new_line', 'Yes');
        Observer.Expect('new_line_log', '[L.OnValidate(Document No.): | LP.OnNewRecord:]');
        Observer.Expect('description', 'Yes');
        Observer.Expect('description_log', '[L.OnValidate(Description):x key=/0]');
        Observer.Expect('after_line_headers', '1');
        Observer.Expect('after_line_header_rows', '[|]');
        Observer.Expect('after_line_lines', '0');
        Observer.Expect('after_line_line_rows', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[LP.OnInsertRecord:/20000 | L.OnInsert:/20000]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|20000|x|0]');
        Observer.Verify();
    end;

    // Writer QH (2026-10-21): probes for al-runtime-rs PR 384 "needs probe" (see the QH objects above). Observe-only first; Finish() is
    // replaced by the asserted values after the CI matrix.
    local procedure QhSeedHeader(No: Code[20])
    var
        Header: Record "LT DL Header";
    begin
        Header."No." := No;
        Header.Insert();
    end;

    [TryFunction]
    local procedure QhTryOpenNewConst(var Host: TestPage "LT QH DL Doc Const")
    begin
        Host.OpenNew();
    end;

    [TryFunction]
    local procedure QhTryOpenEditConst(var Host: TestPage "LT QH DL Doc Const")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure QhTryKeyCur(var Host: TestPage "LT QH DL Doc Cur"; Value: Text)
    begin
        Host."No.".SetValue(Value);
    end;

    [TryFunction]
    local procedure QhTryHostNew(var Host: TestPage "LT DL Document")
    begin
        Host.New();
    end;

    [TryFunction]
    local procedure QhTryOk(var Host: TestPage "LT DL Document")
    begin
        Host.OK().Invoke();
    end;

    [TryFunction]
    local procedure QhTryCloseTrace(var Host: TestPage "LT QH DL Doc Trace")
    begin
        Host.Close();
    end;

    [TryFunction]
    local procedure QhTryCloseSetName(var Host: TestPage "LT QH DL Doc SetName")
    begin
        Host.Close();
    end;

    [TryFunction]
    local procedure QhTryFilterAway(var Host: TestPage "LT QH DL Doc Trace")
    begin
        Host.Filter.SetFilter("No.", 'ZZ');
    end;

    local procedure QhResult(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + '_error');
        TakeLog(Observer, Name + '_log');
    end;

    // Item 1: the part's OnAfterGetCurrRecord among the three OnNewRecord runs of an empty part on an editable host.
    [Test]
    procedure QH_EmptyPart_OpenNew_CurrRecordOrder()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Cur";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[CP.OnOpenPage] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenNew_TraceHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[TH.OnOpenPage | CP.OnOpenPage | TH.OnNewRecord | TH.OnAfterGetCurrRecord:] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenEdit_CurrRecordOrder()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Cur";
    begin
        Seed();
        QhSeedHeader('D8');
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[CP.OnOpenPage] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenEdit_TraceHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        QhSeedHeader('D8');
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[TH.OnOpenPage | CP.OnOpenPage | TH.OnAfterGetRecord:D8 | TH.OnAfterGetCurrRecord:D8] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenNew_KeyTyped()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Cur";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'type_key', QhTryKeyCur(Host, 'Q1'));
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[CP.OnOpenPage] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('type_key', 'Yes');
        Observer.Expect('type_key_log', '[H.OnValidate(No.):Q1] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[H.OnInsert:Q1]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[Q1|]');
        Observer.Expect('after_close_lines', '0');
        Observer.Expect('after_close_line_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenNew_CurrRecordOnlyPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc CurOnly";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_new', '[L.OnValidate(Document No.): | OP.OnAfterGetCurrRecord:/0 | OP.OnAfterGetCurrRecord:/0 | L.OnValidate(Document No.): | OP.OnAfterGetCurrRecord:/0]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenEdit_CurrRecordOnlyPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc CurOnly";
    begin
        Seed();
        QhSeedHeader('D8');
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[L.OnValidate(Document No.):D8 | OP.OnAfterGetCurrRecord:D8/0 | OP.OnAfterGetCurrRecord:D8/0 | L.OnValidate(Document No.):D8 | OP.OnAfterGetCurrRecord:D8/0]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_PartWithRows_OpenEdit_CurrRecordOrder()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Cur";
    begin
        Seed();
        QhSeedHeader('D8');
        SeedLine('D8', 10000);
        SeedLine('D8', 20000);
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[CP.OnOpenPage | CP.OnAfterGetRecord:D8/10000 | CP.OnAfterGetRecord:D8/20000 | CP.OnAfterGetRecord:D8/10000 | CP.OnAfterGetRecord:D8/10000 | CP.OnAfterGetCurrRecord:D8/10000]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_EmptyPart_OpenEdit_HostNext()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Cur";
    begin
        Seed();
        QhSeedHeader('D1');
        QhSeedHeader('D2');
        Host.OpenEdit();
        TakeLog(Observer, 'open_edit');
        Observer.Observe('next', Format(Host.Next()));
        TakeLog(Observer, 'next_log');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_edit', '[CP.OnOpenPage] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '[] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    // Item 2: OpenView on a host that shows no row.
    [Test]
    procedure QH_OpenView_NoRow_Document()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Observer.Observe('card_no', '[' + Host."No.".Value() + ']');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        TakeLog(Observer, 'read_log');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_view', '[LP.OnNewRecord:]');
        Observer.Expect('card_no', '[]');
        Observer.Expect('part_description', '[]');
        Observer.Expect('read_log', '[]');
        Observer.Expect('close', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '0');
        Observer.Expect('after_close_line_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OpenView_NoRow_TraceHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[TH.OnOpenPage | CP.OnOpenPage | CP.OnNewRecord: below=Yes | CP.OnAfterGetCurrRecord:/0]');
        Observer.Expect('close', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OpenView_NoRow_CurrRecordOnlyPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc CurOnly";
    begin
        Seed();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[OP.OnAfterGetCurrRecord:/0]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OpenView_NoRow_UnlinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[LP.OnNewRecord:]');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OpenView_NoRow_BlankKeyLinesExist()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_view', '[TH.OnOpenPage | CP.OnOpenPage | CP.OnNewRecord: below=Yes | CP.OnAfterGetCurrRecord:/0]');
        Observer.Expect('part_description', '[]');
        Observer.Expect('close', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OpenView_RowFilteredAway()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        QhSeedHeader('D6');
        Host.OpenView();
        TakeLog(Observer, 'open_view');
        QhResult(Observer, 'filter_away', QhTryFilterAway(Host));
        Observer.Observe('card_no', '[' + Host."No.".Value() + ']');
        Host.Close();
        TakeLog(Observer, 'close');
        Observer.Expect('open_view', '[TH.OnOpenPage | CP.OnOpenPage | TH.OnAfterGetRecord:D6 | TH.OnAfterGetCurrRecord:D6 | CP.OnNewRecord:D6 below=Yes | CP.OnAfterGetCurrRecord:D6/0]');
        Observer.Expect('filter_away', 'Yes');
        Observer.Expect('filter_away_log', '[CP.OnNewRecord: below=Yes | CP.OnAfterGetCurrRecord:/0]');
        Observer.Expect('card_no', '[]');
        Observer.Expect('close', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Verify();
    end;

    // Item 3: a const-linked part whose relation rejects the link value; where the error comes among the part's triggers.
    [Test]
    procedure QH_ConstLink_Missing_OpenNew_Trace()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT QH DL Validate Events";
        Host: TestPage "LT QH DL Doc Const";
    begin
        Seed();
        BindSubscription(Events);
        QhResult(Observer, 'open_new', QhTryOpenNewConst(Host));
        UnbindSubscription(Events);
        Stored(Observer, 'after');
        Observer.Expect('open_new', 'No');
        Observer.Expect('open_new_error|text', 'The field Document No. of table LT DL Line contains a value (D9) that cannot be found in the related table (LT DL Header).');
        Observer.Expect('open_new_error|code', 'TestWrapped');
        Observer.Expect('open_new_log', '[CP.OnOpenPage | CP.OnNewRecord:D9 below=Yes | CP.OnAfterGetCurrRecord:D9/0]');
        Observer.Expect('after_headers', '0');
        Observer.Expect('after_header_rows', '');
        Observer.Expect('after_lines', '0');
        Observer.Expect('after_line_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure QH_ConstLink_Missing_OpenNew_Events()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT QH DL Validate Events";
        Host: TestPage "LT PYB DL Doc Const";
    begin
        Seed();
        BindSubscription(Events);
        QhResult(Observer, 'open_new', TryOpenConst(Host));
        UnbindSubscription(Events);
        Observer.Expect('open_new', 'No');
        Observer.Expect('open_new_error|text', 'The field Document No. of table LT DL Line contains a value (D9) that cannot be found in the related table (LT DL Header).');
        Observer.Expect('open_new_error|code', 'TestWrapped');
        Observer.Expect('open_new_log', '[LP.OnNewRecord:D9]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_ConstLink_Missing_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT QH DL Validate Events";
        Host: TestPage "LT QH DL Doc Const";
    begin
        Seed();
        QhSeedHeader('D1');
        BindSubscription(Events);
        QhResult(Observer, 'open_edit', QhTryOpenEditConst(Host));
        UnbindSubscription(Events);
        Observer.Expect('open_edit', 'No');
        Observer.Expect('open_edit_error|text', 'The field Document No. of table LT DL Line contains a value (D9) that cannot be found in the related table (LT DL Header).');
        Observer.Expect('open_edit_error|code', 'TestWrapped');
        Observer.Expect('open_edit_log', '[CP.OnOpenPage | CP.OnNewRecord:D9 below=Yes | CP.OnAfterGetCurrRecord:D9/0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_ConstLink_Exists_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT QH DL Validate Events";
        Host: TestPage "LT QH DL Doc Const";
    begin
        Seed();
        QhSeedHeader('D9');
        BindSubscription(Events);
        QhResult(Observer, 'open_new', QhTryOpenNewConst(Host));
        Host.Close();
        TakeLog(Observer, 'close');
        UnbindSubscription(Events);
        Observer.Expect('open_new', 'Yes');
        Observer.Expect('open_new_log', '[CP.OnOpenPage] fired at least once: CP.OnNewRecord, L.OnValidate(Document No.), E.OnBeforeValidate(Document No.), E.OnAfterValidate(Document No.), CP.OnAfterGetCurrRecord(draft)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_FieldLink_OpenNew_Events()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT QH DL Validate Events";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        BindSubscription(Events);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        UnbindSubscription(Events);
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.), E.OnBeforeValidate(Document No.), E.OnAfterValidate(Document No.)');
        Observer.Expect('close', '[]');
        Observer.Verify();
    end;

    // Item 4: a new host whose field-linked part shows rows of the blank key; what Close does and what is stored.
    [Test]
    procedure QH_BlankRows_OpenNew_CloseOnly()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        SeedLine('', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '2');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0][|20000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_ReadPart_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        SeedLine('', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_first_description', Host.Lines.Description.Value());
        TakeLog(Observer, 'read_log');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('part_first_description', 'seeded');
        Observer.Expect('read_log', '[HP.OnInsertRecord: | H.OnInsert:]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '2');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0][|20000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_HostWithoutTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoTrigger";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_TraceHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        SeedLine('', 10000);
        SeedLine('', 20000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', QhTryCloseTrace(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[TH.OnOpenPage | CP.OnOpenPage | TH.OnNewRecord | TH.OnAfterGetCurrRecord: | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetRecord:/20000 | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetCurrRecord:/10000]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '2');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0][|20000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_CardHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Card";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_PartWithoutAutoSplitKey()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc NoSplit";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_UnlinkedPart()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PYB DL Doc Unlinked";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Host.Close();
        TakeLog(Observer, 'close');
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[]');
        Observer.Expect('close', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_BlankHeaderExists()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        QhSeedHeader('');
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_HostNew_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'host_new', QhTryHostNew(Host));
        Stored(Observer, 'after_new');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('host_new', 'Yes');
        Observer.Expect('host_new_log', '[HP.OnNewRecord]');
        Observer.Expect('after_new_headers', '0');
        Observer.Expect('after_new_header_rows', '');
        Observer.Expect('after_new_lines', '1');
        Observer.Expect('after_new_line_rows', '[|10000|seeded|0]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_OkInvoke()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'ok', QhTryOk(Host));
        Stored(Observer, 'after_ok');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok_log', '[]');
        Observer.Expect('after_ok_headers', '0');
        Observer.Expect('after_ok_header_rows', '');
        Observer.Expect('after_ok_lines', '1');
        Observer.Expect('after_ok_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_HostOnNewRecordSetsName()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc SetName";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', QhTryCloseSetName(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[SH.OnNewRecord]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_NoRows_HostOnNewRecordSetsName()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc SetName";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', QhTryCloseSetName(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[SH.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '0');
        Observer.Expect('after_close_line_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OtherKeyRows_OpenNew_Close()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('X1', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[X1|10000|seeded|0]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure QhTryPartFirst(var Host: TestPage "LT DL Document"; var Found: Boolean)
    begin
        Found := Host.Lines.First();
    end;

    [Test]
    procedure QH_NoRows_ReadPartControl()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        TakeLog(Observer, 'read_log');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('part_description', '[]');
        Observer.Expect('read_log', '[HP.OnInsertRecord: | H.OnInsert:] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '0');
        Observer.Expect('after_close_line_rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure QH_OtherKeyRows_ReadPartControl()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('X1', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        TakeLog(Observer, 'read_log');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('part_description', '[]');
        Observer.Expect('read_log', '[HP.OnInsertRecord: | H.OnInsert:] fired at least once: LP.OnNewRecord, L.OnValidate(Document No.)');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[X1|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_PartFirst()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
        Found: Boolean;
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        QhResult(Observer, 'part_first', QhTryPartFirst(Host, Found));
        Observer.Observe('part_first_found', Format(Found));
        Stored(Observer, 'after_first');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('part_first', 'Yes');
        Observer.Expect('part_first_log', '[HP.OnInsertRecord: | H.OnInsert:]');
        Observer.Expect('part_first_found', 'Yes');
        Observer.Expect('after_first_headers', '1');
        Observer.Expect('after_first_header_rows', '[|]');
        Observer.Expect('after_first_lines', '1');
        Observer.Expect('after_first_line_rows', '[|10000|seeded|0]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_ReadHostControl()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT DL Document";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('card_name', '[' + Host.Name.Value() + ']');
        TakeLog(Observer, 'read_log');
        QhResult(Observer, 'close', TryClose(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[HP.OnNewRecord]');
        Observer.Expect('card_name', '[]');
        Observer.Expect('read_log', '[]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[]');
        Observer.Expect('after_close_headers', '0');
        Observer.Expect('after_close_header_rows', '');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;

    [Test]
    procedure QH_BlankRows_ReadPartControlTwice_TraceHost()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT QH DL Doc Trace";
    begin
        Seed();
        SeedLine('', 10000);
        Host.OpenNew();
        TakeLog(Observer, 'open_new');
        Observer.Observe('part_description', '[' + Host.Lines.Description.Value() + ']');
        TakeLog(Observer, 'read_log');
        Observer.Observe('part_description_again', '[' + Host.Lines.Description.Value() + ']');
        TakeLog(Observer, 'read_again_log');
        QhResult(Observer, 'close', QhTryCloseTrace(Host));
        Stored(Observer, 'after_close');
        Observer.Expect('open_new', '[TH.OnOpenPage | CP.OnOpenPage | TH.OnNewRecord | TH.OnAfterGetCurrRecord: | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetCurrRecord:/10000]');
        Observer.Expect('part_description', '[seeded]');
        Observer.Expect('read_log', '[TH.OnInsertRecord: | H.OnInsert: | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetRecord:/10000 | CP.OnAfterGetCurrRecord:/10000]');
        Observer.Expect('part_description_again', '[seeded]');
        Observer.Expect('read_again_log', '[]');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close_log', '[TH.OnQueryClosePage | TH.OnClosePage]');
        Observer.Expect('after_close_headers', '1');
        Observer.Expect('after_close_header_rows', '[|]');
        Observer.Expect('after_close_lines', '1');
        Observer.Expect('after_close_line_rows', '[|10000|seeded|0]');
        Observer.Verify();
    end;
}
