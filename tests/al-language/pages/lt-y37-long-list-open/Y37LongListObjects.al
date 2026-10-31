// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: own objects 92615 - 92619 (writer Y37, gap cycle 3 C3-12); tests in Y37LongListTests.al (codeunit 92620)
// Probe: observed on BC; every literal asserted is what the BC service tier produced.
// Objects: a table of rows Id 1..N (Name = 'N' + Id with three digits), a List page on it whose OnOpenPage moves Rec (Get(n) or FindLast,
//   as the log codeunit's mode says), a List page on a temporary source whose OnOpenPage fills Rec by Insert (the order the log codeunit
//   says) and can set Flag on the last row without Modify, and a copy of that temporary list without OnAfterGetRecord and
//   OnAfterGetCurrRecord. No page declares OnFindRecord or OnNextRecord.
//   Log: O:<id> = Rec when OnOpenPage ends, R:<id> = OnAfterGetRecord, C:<id> = OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

table 92615 "LT Y37 Long Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92616 "LT Y37 Long Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        GetId: Integer;
        FindLastMode: Boolean;
        InsertOrder: List of [Integer];
        SetFlag: Boolean;

    procedure Reset()
    begin
        Entries := '';
        GetId := 0;
        FindLastMode := false;
        Clear(InsertOrder);
        SetFlag := false;
    end;

    procedure SetGet(Id: Integer)
    begin
        GetId := Id;
    end;

    procedure SetFindLast()
    begin
        FindLastMode := true;
    end;

    procedure AddInsert(FromId: Integer; ToId: Integer)
    var
        i: Integer;
    begin
        for i := FromId to ToId do
            InsertOrder.Add(i);
    end;

    procedure SetFlagAfterFill()
    begin
        SetFlag := true;
    end;

    procedure Move(var Row: Record "LT Y37 Long Row")
    begin
        if GetId <> 0 then
            Row.Get(GetId);
        if FindLastMode then
            Row.FindLast();
    end;

    procedure Fill(var Row: Record "LT Y37 Long Row")
    var
        Id: Integer;
    begin
        foreach Id in InsertOrder do begin
            Row.Init();
            Row.Id := Id;
            Row.Name := RowName(Id);
            Row.Insert();
        end;
        if SetFlag then
            Row.Flag := true;
    end;

    procedure RowName(Id: Integer): Code[20]
    begin
        exit('N' + Format(Id, 0, '<Integer,3><Filler Character,0>'));
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 92617 "LT Y37 Long List"
{
    PageType = List;
    SourceTable = "LT Y37 Long Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Move(Rec);
        Log.Add('O:' + Format(Rec.Id));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y37 Long Log";
}

page 92618 "LT Y37 Long Temp List"
{
    PageType = List;
    SourceTable = "LT Y37 Long Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(FlagCtl; Rec.Flag) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Add('O:' + Format(Rec.Id));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y37 Long Log";
}

page 92619 "LT Y37 Long Temp List NoTrg"
{
    PageType = List;
    SourceTable = "LT Y37 Long Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
    end;

    var
        Log: Codeunit "LT Y37 Long Log";
}
