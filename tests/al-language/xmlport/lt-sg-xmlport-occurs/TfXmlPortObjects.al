// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: table 89360 "LT SG XP Row" (SgXmlPortObjects.al); own xmlports 89815-89818 (writer TF); tests in SgXmlPortOccurs.al (codeunit 89365)
// Probe: the objects of the TF_ tests of codeunit 89365.
//  - 89815: a temporary table element with an explicit MinOccurs = Once and no MaxOccurs, below the root.
//  - 89816: the same with MinOccurs = Once and MaxOccurs = Once.
//  - 89817: a table element on a real table with MinOccurs = Once and MaxOccurs = Once.
//  - 89818: UseDefaultNamespace = true without DefaultNamespace, with a text attribute on the root, a field attribute on a table element and a
//    text attribute and a field attribute on a text element below it.
// BC versions: 27, 28, 29

xmlport 89815 "LT TF XP Min Once"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT SG XP Row")
            {
                MinOccurs = Once;
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldelement(Note; Row.Note)
                {
                    MinOccurs = Zero;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'Insert ' + Format(Row.Id) + ';';
                end;
            }
        }
    }

    var
        Log: Text;

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

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 89816 "LT TF XP Min Max Once"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT SG XP Row")
            {
                MinOccurs = Once;
                MaxOccurs = Once;
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldelement(Note; Row.Note)
                {
                    MinOccurs = Zero;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'Insert ' + Format(Row.Id) + ';';
                end;
            }
        }
    }

    var
        Log: Text;

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

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 89817 "LT TF XP Min Max Once Real"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT SG XP Row")
            {
                MinOccurs = Once;
                MaxOccurs = Once;

                fieldelement(Id; T.Id) { }
                fieldelement(Note; T.Note) { }
            }
        }
    }
}

xmlport 89818 "LT TF XP Ns Attr"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Both;
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(Ver)
            {
                Occurrence = Optional;

                trigger OnBeforePassVariable()
                begin
                    Ver := 'v1';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Ver=' + Ver + ';';
                end;
            }
            tableelement(Row; "LT SG XP Row")
            {
                MinOccurs = Zero;
                UseTemporary = true;

                fieldattribute(Id; Row.Id)
                {
                    Occurrence = Required;
                }
                fieldattribute(Note; Row.Note)
                {
                    Occurrence = Optional;
                }
                textelement(Item)
                {
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
                    fieldattribute(EntryNo; Row.EntryNo)
                    {
                        Occurrence = Optional;
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
