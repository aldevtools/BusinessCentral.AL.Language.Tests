// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-occurrence-property
// Scope: in-scope
// Fixtures used: own table 89360, xmlports 89361-89364 (writer SG); tests in SgXmlPortOccurs.al (codeunit 89365)
// Probe: observed on the corpus CI matrix; every literal asserted in the SG_ tests is what the BC service tier produced.
// Objects:
//  - 89361: a field attribute with Occurrence = Required / Optional and a text attribute with Occurrence = Required, all inside a text element
//    that is a child of a temporary table element (the attribute's parent is the text element, not the table element).
//  - 89362: temporary table elements with MaxOccurs = Once and MinOccurs = Zero below a container text element (MaxOccurs = Once) and
//    below the root.
//  - 89363: a table element on a real table with MaxOccurs = Once and the default MinOccurs, below the root.
//  - 89364: UseDefaultNamespace = true without DefaultNamespace and without Namespaces.
// BC versions: 27, 28, 29

table 89360 "LT SG XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; EntryNo; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 89361 "LT SG XP Attr Below Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT SG XP Row")
            {
                MinOccurs = Zero;
                UseTemporary = true;

                fieldattribute(Id; Row.Id)
                {
                    Occurrence = Required;
                }
                textelement(Sched)
                {
                    fieldattribute(EntryNo; Row.EntryNo)
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(Note; Row.Note)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(Kind)
                    {
                        Occurrence = Required;

                        trigger OnBeforePassVariable()
                        begin
                            Kind := 'k' + Format(Row.Id);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'Kind=' + Kind + ';';
                        end;
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'Insert ' + Format(Row.Id) + ':' + Format(Row.EntryNo) + ':' + Row.Note + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(Id: Integer; EntryNo: Integer; Note: Text[30])
    begin
        Row.Init();
        Row.Id := Id;
        Row.EntryNo := EntryNo;
        Row.Note := Note;
        Row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        Row.Reset();
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.EntryNo) + ':' + Row.Note + ',';
            until Row.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 89362 "LT SG XP Once Temp"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Request)
            {
                MaxOccurs = Once;

                tableelement(Req; "LT SG XP Row")
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    UseTemporary = true;

                    fieldelement(ReqId; Req.Id) { }
                    fieldelement(ReqNote; Req.Note)
                    {
                        MinOccurs = Zero;
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log += 'Req ' + Format(Req.Id) + ';';
                    end;
                }
            }
            tableelement(Resp; "LT SG XP Row")
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                UseTemporary = true;

                fieldelement(RespId; Resp.Id) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'Resp ' + Format(Resp.Id) + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddReq(Id: Integer; Note: Text[30])
    begin
        Req.Init();
        Req.Id := Id;
        Req.Note := Note;
        Req.Insert();
    end;

    procedure AddResp(Id: Integer)
    begin
        Resp.Init();
        Resp.Id := Id;
        Resp.Insert();
    end;

    procedure Rows() Result: Text
    begin
        Req.Reset();
        if Req.FindSet() then
            repeat
                Result += 'req' + Format(Req.Id) + ':' + Req.Note + ',';
            until Req.Next() = 0;
        Resp.Reset();
        if Resp.FindSet() then
            repeat
                Result += 'resp' + Format(Resp.Id) + ',';
            until Resp.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 89363 "LT SG XP Once Real"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT SG XP Row")
            {
                MaxOccurs = Once;

                fieldelement(Id; T.Id) { }
                fieldelement(Note; T.Note) { }
            }
        }
    }
}

xmlport 89364 "LT SG XP Default Ns"
{
    Format = Xml;
    Direction = Both;
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT SG XP Row")
            {
                MinOccurs = Zero;
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldattribute(Note; Row.Note)
                {
                    Occurrence = Optional;
                }
            }
        }
    }

    procedure AddRow(Id: Integer; Note: Text[30])
    begin
        Row.Init();
        Row.Id := Id;
        Row.Note := Note;
        Row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        Row.Reset();
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Note + ',';
            until Row.Next() = 0;
    end;
}
