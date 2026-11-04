// Fixtures of pages/lt-y45-save-before-action (tables, log, subscribers, RunObject codeunit). The facts are in Y45SaveBeforeAction.al.
table 92880 "LT Y45 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            trigger OnValidate()
            begin
                Log.Add('vCode ' + Rec."Code");
            end;
        }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            begin
                Log.Add('vName ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
            end;
        }
        field(3; Qty; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('vQty ' + Format(Rec.Qty));
                if Rec.Qty < 0 then
                    Error('Qty must not be negative.');
            end;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('tI ' + Rec."Code" + ' ' + Rec.Name + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    trigger OnModify()
    begin
        Log.Add('tM ' + Rec.Name + '/' + xRec.Name + ' db=' + Log.HeadDb(Rec."Code"));
        if Rec.Name = 'boom' then
            Error('Modify refused for boom.');
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

table 92881 "LT Y45 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Doc; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Desc; Text[50])
        {
            trigger OnValidate()
            begin
                Log.Add('vDesc ' + Rec.Desc + '/' + xRec.Desc);
            end;
        }
    }

    keys
    {
        key(PK; Doc, "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('lI ' + Rec.Doc + ' ' + Format(Rec."Line No.") + ' ' + Rec.Desc + ' head=' + Log.HeadDb(Rec.Doc));
    end;

    trigger OnModify()
    begin
        Log.Add('lM ' + Format(Rec."Line No.") + ' ' + Rec.Desc + '/' + xRec.Desc + ' db=' + Log.LineDb(Rec.Doc, Rec."Line No."));
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

codeunit 92880 "LT Y45 Log"
{
    SingleInstance = true;

    var
        Buf: Text;

    procedure Add(Entry: Text)
    begin
        if Buf <> '' then
            Buf += ';';
        Buf += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buf;
        Buf := '';
        exit(Result);
    end;

    procedure HeadDb(HeadCode: Code[20]): Text
    var
        Head: Record "LT Y45 Head";
    begin
        if Head.Get(HeadCode) then
            exit(Head.Name + '/' + Format(Head.Qty));
        exit('none');
    end;

    procedure LineDb(DocCode: Code[20]; LineNo: Integer): Text
    var
        Line: Record "LT Y45 Line";
    begin
        if Line.Get(DocCode, LineNo) then
            exit(Line.Desc);
        exit('none');
    end;

    procedure Act(Tag: Text; Head: Record "LT Y45 Head")
    begin
        Add(Tag + ' ' + Head."Code" + ' rec=' + Head.Name + '/' + Format(Head.Qty) + ' db=' + HeadDb(Head."Code") + ' l1=' + LineDb(Head."Code", 10000));
    end;

    procedure LineAct(Tag: Text; Line: Record "LT Y45 Line")
    begin
        Add(Tag + ' ' + Format(Line."Line No.") + ' rec=' + Line.Desc + ' db=' + LineDb(Line.Doc, Line."Line No.") + ' head=' + HeadDb(Line.Doc));
    end;
}

codeunit 92881 "LT Y45 Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT Y45 Head", 'OnBeforeModifyEvent', '', false, false)]
    local procedure HeadBeforeModify(var Rec: Record "LT Y45 Head"; var xRec: Record "LT Y45 Head"; RunTrigger: Boolean)
    begin
        Log.Add('eBM ' + Rec.Name + ' t=' + Format(RunTrigger) + ' db=' + Log.HeadDb(Rec."Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y45 Head", 'OnAfterModifyEvent', '', false, false)]
    local procedure HeadAfterModify(var Rec: Record "LT Y45 Head"; var xRec: Record "LT Y45 Head"; RunTrigger: Boolean)
    begin
        Log.Add('eAM db=' + Log.HeadDb(Rec."Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y45 Head", 'OnBeforeInsertEvent', '', false, false)]
    local procedure HeadBeforeInsert(var Rec: Record "LT Y45 Head"; RunTrigger: Boolean)
    begin
        Log.Add('eBI ' + Rec."Code" + ' t=' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y45 Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure LineBeforeModify(var Rec: Record "LT Y45 Line"; var xRec: Record "LT Y45 Line"; RunTrigger: Boolean)
    begin
        Log.Add('eBML ' + Rec.Desc);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y45 Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure LineBeforeInsert(var Rec: Record "LT Y45 Line"; RunTrigger: Boolean)
    begin
        Log.Add('eBIL ' + Rec.Desc);
    end;

    var
        Log: Codeunit "LT Y45 Log";
}

codeunit 92882 "LT Y45 RunObj"
{
    TableNo = "LT Y45 Head";

    trigger OnRun()
    var
        Log: Codeunit "LT Y45 Log";
    begin
        Log.Act('cu', Rec);
    end;
}
