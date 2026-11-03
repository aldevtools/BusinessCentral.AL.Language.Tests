// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: TGL Row (69670), TGL Log (69671), TGL Row Ext (69672), TGL Row Card (69673),
//                TGL Holder (69674), TGL Subscribers (69675), TGL Row List (69676), TGL Runner (69680)
//
// Fixtures for the table-globals probes (tableglobals/). A table's `var` section holds its
// global variables. "TGL Row" keeps a counter and a tag in them, plus a record variable of its
// own table, and exposes them through procedures so a test can see whether state set by one
// trigger or procedure call is still there at the next call on the same record variable.
// "TGL Log" collects what triggers and event subscribers observed, in order.

table 69670 "TGL Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Payload; Integer)
        {
            trigger OnValidate()
            begin
                Counter += 1;
                Tag := 'V' + Format(Payload);
                XCounterInValidate := xRec.GetCounter();
                XTagInValidate := xRec.GetTag();
            end;
        }
        field(3; Seen; Text[100]) { }
        field(4; XSeen; Text[100]) { }
        field(5; Probe; Integer)
        {
            trigger OnValidate()
            begin
                Counter += 10;
            end;
        }
        field(6; RecSeen; Text[100]) { }
        field(7; ModSeq; Integer) { }
        field(8; Probe2; Integer)
        {
            trigger OnValidate()
            var
                LogRec: Record "TGL Log";
            begin
                LogRec.Add(StrSubstNo('P2:%1|%2', Counter, Tag));
                Counter += 1;
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    var
        Counter: Integer;
        Tag: Text[50];
        XCounterInValidate: Integer;
        XTagInValidate: Text[50];
        Child: Record "TGL Row";
        ModRuns: Integer;

    trigger OnInsert()
    begin
        Seen := StrSubstNo('%1|%2', Counter, Tag);
        RecSeen := StrSubstNo('%1|%2', Rec.GetCounter(), Rec.GetTag());
    end;

    trigger OnModify()
    begin
        ModRuns += 1;
        ModSeq := ModRuns;
        Seen := StrSubstNo('%1|%2', Counter, Tag);
        XSeen := StrSubstNo('%1|%2', xRec.GetCounter(), xRec.GetTag());
        RecSeen := StrSubstNo('%1|%2', Rec.GetCounter(), Rec.GetTag());
    end;

    trigger OnDelete()
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('D:%1|%2', Counter, Tag));
        Counter += 1;
    end;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure SetTag(NewTag: Text[50])
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text[50]
    begin
        exit(Tag);
    end;

    procedure GetXCounterInValidate(): Integer
    begin
        exit(XCounterInValidate);
    end;

    procedure GetXTagInValidate(): Text[50]
    begin
        exit(XTagInValidate);
    end;

    procedure ResetSelf()
    begin
        Rec.Reset();
    end;

    procedure ChildBump(): Integer
    begin
        exit(Child.Bump());
    end;

    procedure ChildCounter(): Integer
    begin
        exit(Child.GetCounter());
    end;

    procedure TakeFrom(var Other: Record "TGL Row")
    begin
        Rec := Other;
    end;

    procedure CopyFromRow(var Other: Record "TGL Row")
    begin
        Rec.Copy(Other);
    end;

    procedure TransferFromRow(var Other: Record "TGL Row")
    begin
        Rec.TransferFields(Other);
    end;

    procedure ByVar(var R: Record "TGL Row"): Integer
    begin
        exit(R.Bump());
    end;

    procedure ByValue(R: Record "TGL Row"): Integer
    begin
        exit(R.Bump());
    end;

    procedure SelfByValue(): Integer
    begin
        exit(ByValue(Rec));
    end;

    procedure Make() Result: Record "TGL Row"
    begin
        Result.Bump();
        Result.Bump();
    end;

    procedure Echo(R: Record "TGL Row") Result: Record "TGL Row"
    begin
        Result := R;
    end;
}

table 69671 "TGL Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Note; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Add(NewNote: Text[100])
    var
        LogRec: Record "TGL Log";
    begin
        if LogRec.FindLast() then
            LogRec."Entry No." += 1
        else
            LogRec."Entry No." := 1;
        LogRec.Note := NewNote;
        LogRec.Insert();
    end;
}

tableextension 69672 "TGL Row Ext" extends "TGL Row"
{
    fields
    {
        field(69672; ExtPayload; Integer)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ExtCounter += 1;
                ExtTag := 'E' + Format(ExtPayload);
            end;
        }
    }

    var
        ExtCounter: Integer;
        ExtTag: Text[50];

    procedure ExtBump(): Integer
    begin
        ExtCounter += 1;
        exit(ExtCounter);
    end;

    procedure ExtGetCounter(): Integer
    begin
        exit(ExtCounter);
    end;

    procedure ExtGetTag(): Text[50]
    begin
        exit(ExtTag);
    end;
}

codeunit 69674 "TGL Holder"
{
    var
        Row: Record "TGL Row";

    procedure BumpRow(): Integer
    begin
        exit(Row.Bump());
    end;

    procedure RowCounter(): Integer
    begin
        exit(Row.GetCounter());
    end;

    procedure ValidateRow(NewPayload: Integer)
    begin
        Row.Validate(Payload, NewPayload);
    end;

    procedure RowTag(): Text[50]
    begin
        exit(Row.GetTag());
    end;

    procedure ResetRow()
    begin
        Row.Reset();
    end;

    procedure LocalBump(): Integer
    var
        LocalRow: Record "TGL Row";
    begin
        exit(LocalRow.Bump());
    end;

    procedure SetRowFrom(var Other: Record "TGL Row")
    begin
        Row := Other;
    end;
}

codeunit 69675 "TGL Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "TGL Row"; RunTrigger: Boolean)
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('BI:%1|%2', Rec.GetCounter(), Rec.GetTag()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "TGL Row"; RunTrigger: Boolean)
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('AI:%1|%2', Rec.GetCounter(), Rec.GetTag()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "TGL Row"; var xRec: Record "TGL Row"; RunTrigger: Boolean)
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('BM:%1|%2/%3|%4', Rec.GetCounter(), Rec.GetTag(), xRec.GetCounter(), xRec.GetTag()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "TGL Row"; var xRec: Record "TGL Row"; RunTrigger: Boolean)
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('AM:%1|%2/%3|%4', Rec.GetCounter(), Rec.GetTag(), xRec.GetCounter(), xRec.GetTag()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnBeforeValidateEvent', 'Probe', false, false)]
    local procedure BeforeValidateProbe(var Rec: Record "TGL Row"; var xRec: Record "TGL Row"; CurrFieldNo: Integer)
    var
        LogRec: Record "TGL Log";
    begin
        Rec.Bump();
        LogRec.Add(StrSubstNo('BV:%1/%2', Rec.GetCounter(), xRec.GetCounter()));
        xRec.Bump();
    end;

    [EventSubscriber(ObjectType::Table, Database::"TGL Row", 'OnAfterValidateEvent', 'Probe', false, false)]
    local procedure AfterValidateProbe(var Rec: Record "TGL Row"; var xRec: Record "TGL Row"; CurrFieldNo: Integer)
    var
        LogRec: Record "TGL Log";
    begin
        LogRec.Add(StrSubstNo('AV:%1/%2', Rec.GetCounter(), xRec.GetCounter()));
    end;
}

page 69673 "TGL Row Card"
{
    PageType = Card;
    SourceTable = "TGL Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Payload; Rec.Payload) { ApplicationArea = All; }
                field(Probe2; Rec.Probe2) { ApplicationArea = All; }
                field(LastCount; LastCount) { ApplicationArea = All; }
                field(AfterGetCount; AfterGetCount) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BumpRec)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    LastCount := Rec.Bump();
                end;
            }
            action(ReadRec)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    LastCount := Rec.GetCounter();
                end;
            }
            action(ReadSeen)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    LastCount := StrLen(Rec.GetTag());
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCount := Rec.GetCounter();
    end;

    var
        LastCount: Integer;
        AfterGetCount: Integer;
}

page 69676 "TGL Row List"
{
    PageType = List;
    SourceTable = "TGL Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Payload; Rec.Payload) { ApplicationArea = All; }
                field(LastCount; LastCount) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BumpRec)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    LastCount := Rec.Bump();
                end;
            }
        }
    }

    var
        LastCount: Integer;
}

codeunit 69680 "TGL Runner"
{
    TableNo = "TGL Row";

    trigger OnRun()
    begin
        Rec.Bump();
        Rec.SetTag('ran');
    end;
}
