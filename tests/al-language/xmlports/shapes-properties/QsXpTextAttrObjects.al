// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-occurrence-property
// Scope: in-scope
// Fixtures used: own table 87360, xmlport 87361, runner codeunit 87362 (writer QS); the temporary blob table 87279 (QrXpContainerOccurs.al);
//   tests QS_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on the corpus CI matrix; every literal asserted in the QS_* tests is what the BC service tier produced.
// Objects: an XmlPort whose root text element has an Optional and a Required text attribute, an optional container text element with
//   an Optional text attribute, and inside it a temporary table element with a field attribute, an Optional and a Required text attribute.
//   Export takes the attribute values from the runner (root, container) and from the row fields (row attributes); Import logs each
//   OnAfterAssignVariable and each OnBeforeInsertRecord, and the runner reads the attribute variables after the import.
// BC versions: 27, 28, 29

table 87360 "LT QS XP Attr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Ref; Text[30]) { }
        field(3; Must; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

xmlport 87361 "LT QS XP Text Attributes"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(envelope)
        {
            MaxOccurs = Once;
            textattribute(instattr)
            {
                XmlName = 'cache_instance_id';
                Occurrence = Optional;

                trigger OnBeforePassVariable()
                begin
                    instattr := InstanceText;
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'instance=' + instattr + ';';
                end;
            }
            textattribute(verattr)
            {
                XmlName = 'version';
                Occurrence = Required;

                trigger OnBeforePassVariable()
                begin
                    verattr := VersionText;
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'version=' + verattr + ';';
                end;
            }
            textelement(body)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;
                textattribute(tokenattr)
                {
                    XmlName = 'token';
                    Occurrence = Optional;

                    trigger OnBeforePassVariable()
                    begin
                        tokenattr := TokenText;
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'token=' + tokenattr + ';';
                    end;
                }
                tableelement(row; "LT QS XP Attr Row")
                {
                    UseTemporary = true;
                    MinOccurs = Zero;
                    MaxOccurs = Unbounded;
                    fieldattribute(no; row."No.") { }
                    textattribute(refattr)
                    {
                        XmlName = 'ref';
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            refattr := row.Ref;
                        end;
                    }
                    textattribute(mustattr)
                    {
                        XmlName = 'must';
                        Occurrence = Required;

                        trigger OnBeforePassVariable()
                        begin
                            mustattr := row.Must;
                        end;
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log += 'row ' + row."No." + ' ref=' + refattr + ' must=' + mustattr + ';';
                        row.Ref := refattr;
                        row.Must := mustattr;
                    end;
                }
            }
        }
    }

    var
        InstanceText: Text;
        VersionText: Text;
        TokenText: Text;
        Log: Text;

    procedure SetValues(NewInstance: Text; NewVersion: Text; NewToken: Text)
    begin
        InstanceText := NewInstance;
        VersionText := NewVersion;
        TokenText := NewToken;
    end;

    procedure AddRow(No: Code[10]; NewRef: Text[30]; NewMust: Text[30])
    begin
        row.Init();
        row."No." := No;
        row.Ref := NewRef;
        row.Must := NewMust;
        row.Insert();
    end;

    procedure Values(): Text
    begin
        exit('instance=' + instattr + ' version=' + verattr + ' token=' + tokenattr + ' ref=' + refattr + ' must=' + mustattr);
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Ref + '/' + row.Must + ';';
            until row.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 87362 "LT QS XP Attr Runner"
{
    var
        Input: Text;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Port: XmlPort "LT QS XP Text Attributes";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
        Outcome := 'log=' + Port.GetLog() + ' values: ' + Port.Values() + ' rows=' + Port.Rows();
    end;

    procedure SetInput(NewInput: Text)
    begin
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}
