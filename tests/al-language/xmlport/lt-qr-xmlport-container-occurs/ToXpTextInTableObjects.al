// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlport/devenv-onbeforepassvariable-xmlport-trigger
// Scope: in-scope
// Fixtures used: own table 90000, xmlports 90001-90003, runner codeunit 90004 (writer TO); the temporary blob table 87279 (QrXpContainerOccurs.al);
//   tests TO_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on BC; every literal asserted in the TO_* tests is what the BC service tier produced.
// Objects: a text element below a table element.
//   90001: the text element's only children are text attributes; its OnBeforePassVariable sets its text from the row, the attribute's
//     OnBeforePassVariable sets the attribute from the row. Every trigger logs, so the logs show the order.
//   90002: the same shape with no trigger on the text element or its attribute: export writes the variables as they are.
//   90003: the text element has content: a text attribute, a field element and a text element below it.
//   Import: the rows land in the temporary table element (OnBeforeInsertRecord copies the variables into fields), the log shows the order.
// BC versions: 27, 28, 29

table 90000 "LT TO XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Opt; Text[30]) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

xmlport 90001 "LT TO XP Attr Item Trigger"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            tableelement(row; "LT TO XP Row")
            {
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(no; row."No.")
                {
                    trigger OnAfterAssignField()
                    begin
                        Log += 'no=' + row."No." + ';';
                    end;
                }
                textelement(item)
                {
                    textattribute(optattr)
                    {
                        XmlName = 'option_value';

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass attr;';
                            optattr := row.Opt;
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'attr=' + optattr + ';';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass item;';
                        item := row.Name;
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'item=' + item + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ' + row."No." + ';';
                end;

                trigger OnAfterInitRecord()
                begin
                    Log += 'init;';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + row."No." + ' item=' + item + ' attr=' + optattr + ';';
                    row.Name := item;
                    row.Opt := optattr;
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after insert;';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(No: Code[10]; NewName: Text[30]; NewOpt: Text[30])
    begin
        row.Init();
        row."No." := No;
        row.Name := NewName;
        row.Opt := NewOpt;
        row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Name + '/' + row.Opt + ';';
            until row.Next() = 0;
    end;

    procedure Values(): Text
    begin
        exit('item=' + item + ' attr=' + optattr);
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90002 "LT TO XP Attr Item Plain"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            tableelement(row; "LT TO XP Row")
            {
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(no; row."No.") { }
                textelement(item)
                {
                    textattribute(optattr)
                    {
                        XmlName = 'option_value';
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + row."No." + ' item=' + item + ' attr=' + optattr + ';';
                    row.Name := item;
                    row.Opt := optattr;
                end;
            }
        }
    }

    var
        Log: Text;

    procedure SetVariables(NewItem: Text; NewAttr: Text)
    begin
        item := NewItem;
        optattr := NewAttr;
    end;

    procedure AddRow(No: Code[10])
    begin
        row.Init();
        row."No." := No;
        row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Name + '/' + row.Opt + ';';
            until row.Next() = 0;
    end;

    procedure Values(): Text
    begin
        exit('item=' + item + ' attr=' + optattr);
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90003 "LT TO XP Text Content"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            tableelement(row; "LT TO XP Row")
            {
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(no; row."No.")
                {
                    trigger OnAfterAssignField()
                    begin
                        Log += 'no=' + row."No." + ';';
                    end;
                }
                textelement(info)
                {
                    textattribute(kind)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass kind;';
                            kind := row.Opt;
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'kind=' + kind + ';';
                        end;
                    }
                    fieldelement(name; row.Name)
                    {
                        trigger OnBeforePassField()
                        begin
                            Log += 'pass name;';
                        end;

                        trigger OnAfterAssignField()
                        begin
                            Log += 'name=' + row.Name + ';';
                        end;
                    }
                    textelement(sub)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass sub;';
                            sub := row.Note;
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'sub=' + sub + ';';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass info;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'info=' + info + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ' + row."No." + ';';
                end;

                trigger OnAfterInitRecord()
                begin
                    Log += 'init;';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + row."No." + ' name=' + row.Name + ' kind=' + kind + ' sub=' + sub + ';';
                    row.Opt := kind;
                    row.Note := sub;
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after insert;';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(No: Code[10]; NewName: Text[30]; NewOpt: Text[30]; NewNote: Text[30])
    begin
        row.Init();
        row."No." := No;
        row.Name := NewName;
        row.Opt := NewOpt;
        row.Note := NewNote;
        row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Name + '/' + row.Opt + '/' + row.Note + ';';
            until row.Next() = 0;
    end;

    procedure Values(): Text
    begin
        exit('info=' + info + ' kind=' + kind + ' sub=' + sub);
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 90004 "LT TO XP Runner"
{
    // Imports Input into xmlport Mode (90001, 90002 or 90003) inside Codeunit.Run, so a failed import does not end the test.
    var
        Input: Text;
        Mode: Integer;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Trig: XmlPort "LT TO XP Attr Item Trigger";
        Plain: XmlPort "LT TO XP Attr Item Plain";
        Content: XmlPort "LT TO XP Text Content";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        case Mode of
            90001:
                begin
                    Trig.SetSource(InS);
                    Trig.Import();
                    Outcome := 'log=' + Trig.GetLog() + ' values: ' + Trig.Values() + ' rows=' + Trig.Rows();
                end;
            90002:
                begin
                    Plain.SetSource(InS);
                    Plain.Import();
                    Outcome := 'log=' + Plain.GetLog() + ' values: ' + Plain.Values() + ' rows=' + Plain.Rows();
                end;
            90003:
                begin
                    Content.SetSource(InS);
                    Content.Import();
                    Outcome := 'log=' + Content.GetLog() + ' values: ' + Content.Values() + ' rows=' + Content.Rows();
                end;
        end;
    end;

    procedure SetInput(NewMode: Integer; NewInput: Text)
    begin
        Mode := NewMode;
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}
