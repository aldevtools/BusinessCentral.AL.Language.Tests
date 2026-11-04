// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: own tables 73057-73059, xmlports 73060-73068, pages 73069-73070, helper codeunit 73071, no-op codeunit 73072, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Shared fixtures of the P94 probes (xmlport properties, page runs, sessions): not a test codeunit.
// BC versions: 29 (27 and 28 by CI)

table 73057 "LT P94 Item"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73058 "LT P94 Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73059 "LT P94 Blob"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// VariableText export, no property declared (defaults)
xmlport 73060 "LT P94 Csv Plain"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT P94 Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
        }
    }
}

// VariableText export with every separator property declared
xmlport 73061 "LT P94 Csv Declared"
{
    Format = VariableText;
    Direction = Export;
    FieldDelimiter = '~';
    FieldSeparator = '|';
    RecordSeparator = '<CR/LF>';
    TableSeparator = '<None>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT P94 Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
        }
    }
}

// VariableText export of two root tables, default separators
xmlport 73062 "LT P94 Csv Two"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
            tableelement(LineRow; "LT P94 Line")
            {
                fieldelement(Id; LineRow.Id) { }
                fieldelement(Note; LineRow.Note) { }
            }
        }
    }
}

// VariableText export of two root tables, TableSeparator and RecordSeparator declared
xmlport 73063 "LT P94 Csv Two Decl"
{
    Format = VariableText;
    Direction = Export;
    FieldDelimiter = '<None>';
    FieldSeparator = ';';
    RecordSeparator = '<LF>';
    TableSeparator = '#';
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
            tableelement(LineRow; "LT P94 Line")
            {
                fieldelement(Id; LineRow.Id) { }
                fieldelement(Note; LineRow.Note) { }
            }
        }
    }
}

// Xml export/import that records CurrentPath in every trigger
xmlport 73064 "LT P94 Xml Path"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                XmlName = 'Item';
                fieldattribute(Qty; ItemRow.Qty)
                {
                    trigger OnBeforePassField()
                    begin
                        Add('attrBeforePass');
                    end;

                    trigger OnAfterAssignField()
                    begin
                        Add('attrAfterAssign');
                    end;
                }
                fieldelement(Id; ItemRow.Id)
                {
                    trigger OnBeforePassField()
                    begin
                        Add('idBeforePass');
                    end;

                    trigger OnAfterAssignField()
                    begin
                        Add('idAfterAssign');
                    end;
                }
                fieldelement(Name; ItemRow.Name) { }
                trigger OnPreXmlItem()
                begin
                    Add('itemPre');
                end;

                trigger OnAfterGetRecord()
                begin
                    Add('itemGet');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Add('itemBeforeInsert');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('itemAfterInsert');
                end;
            }
        }
    }
    var
        LogText: Text;

    trigger OnPreXmlPort()
    begin
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    local procedure Add(Where: Text)
    begin
        LogText += Where + '=[' + currXMLport.CurrentPath() + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// Xml export/import whose table element breaks / breaks unbound / quits at the second row (Mode 1, 2, 3)
xmlport 73065 "LT P94 Xml Flow"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                trigger OnAfterGetRecord()
                begin
                    Hit();
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Hit();
                end;
            }
        }
    }
    var
        Mode: Integer;
        Hits: Integer;
        LogText: Text;

    trigger OnPreXmlPort()
    begin
        LogText += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        LogText += 'post;';
    end;

    local procedure Hit()
    begin
        Hits += 1;
        LogText += 'hit' + Format(Hits) + ';';
        if Hits = 2 then
            case Mode of
                1:
                    currXMLport.Break();
                2:
                    currXMLport.BreakUnbound();
                3:
                    currXMLport.Quit();
            end;
        LogText += 'after' + Format(Hits) + ';';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// Xml export/import that records Filename in OnPreXmlPort and OnPostXmlPort
xmlport 73066 "LT P94 Xml Filename"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
            }
        }
    }
    var
        LogText: Text;

    trigger OnPreXmlPort()
    begin
        LogText += 'pre=[' + currXMLport.Filename() + '];';
    end;

    trigger OnPostXmlPort()
    begin
        LogText += 'post=[' + currXMLport.Filename() + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// VariableText export that records the separator properties in OnPreXmlPort, and changes one of them depending on Mode
xmlport 73067 "LT P94 Csv Props Trig"
{
    Format = VariableText;
    Direction = Export;
    FieldDelimiter = '~';
    FieldSeparator = '|';
    RecordSeparator = '<LF>';
    TableSeparator = '<None>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT P94 Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
        }
    }
    var
        Mode: Integer;
        LogText: Text;

    trigger OnPreXmlPort()
    begin
        LogText := 'delim=[' + currXMLport.FieldDelimiter() + '];sep=[' + currXMLport.FieldSeparator() + '];rec=[' + currXMLport.RecordSeparator() + '];table=[' + currXMLport.TableSeparator() + '];enc=' + Format(currXMLport.TextEncoding());
        case Mode of
            1:
                currXMLport.FieldSeparator(';');
            2:
                currXMLport.FieldDelimiter('"');
            3:
                currXMLport.RecordSeparator('<CR/LF>');
            4:
                currXMLport.TextEncoding(TextEncoding::UTF16);
        end;
        LogText += ';after=[' + currXMLport.FieldSeparator() + '|' + currXMLport.FieldDelimiter() + '|' + currXMLport.RecordSeparator() + '|' + Format(currXMLport.TextEncoding()) + ']';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// Plain Xml export used by the Run probes
xmlport 73068 "LT P94 Xml Marker"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P94 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
            }
        }
    }
}

page 73069 "LT P94 Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P94 Item";
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

page 73070 "LT P94 List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P94 Item";
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

codeunit 73071 "LT P94 Helper"
{
    procedure Wipe()
    var
        Item: Record "LT P94 Item";
        Line: Record "LT P94 Line";
        Blob: Record "LT P94 Blob";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Blob.DeleteAll();
    end;

    procedure Seed()
    begin
        AddItem(1, 'Alpha', 10);
        AddItem(2, 'Beta', 20);
        AddItem(3, 'Gamma', 30);
        AddLine(1, 'L1');
        AddLine(2, 'L2');
    end;

    procedure AddItem(Id: Integer; Name: Text; Qty: Integer)
    var
        Item: Record "LT P94 Item";
    begin
        Item.Id := Id;
        Item.Name := CopyStr(Name, 1, MaxStrLen(Item.Name));
        Item.Qty := Qty;
        Item.Insert();
    end;

    procedure AddLine(Id: Integer; Note: Text)
    var
        Line: Record "LT P94 Line";
    begin
        Line.Id := Id;
        Line.Note := CopyStr(Note, 1, MaxStrLen(Line.Note));
        Line.Insert();
    end;

    procedure CountItems(): Integer
    var
        Item: Record "LT P94 Item";
    begin
        exit(Item.Count());
    end;

    procedure CountLines(): Integer
    var
        Line: Record "LT P94 Line";
    begin
        exit(Line.Count());
    end;

    procedure ItemNames(): Text
    var
        Item: Record "LT P94 Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '=' + Item.Name + ';';
            until Item.Next() = 0;
        exit(Result);
    end;

    // The whole content of the blob field of Row read with the given encoding (no line splitting).
    procedure ReadBlob(var Row: Record "LT P94 Blob"; Enc: TextEncoding): Text
    var
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        Row.CalcFields(Data);
        Row.Data.CreateInStream(InS, Enc);
        Big.Read(InS);
        if Big.Length() = 0 then
            exit('');
        Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;

    procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    procedure ErrText(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}

// Harmless no-op target of StartSession; sleeps one second so a stop right after the start has something to stop.
codeunit 73072 "LT P94 NoOp"
{
    TableNo = "LT P94 Line";

    trigger OnRun()
    begin
        Sleep(1000);
    end;
}
