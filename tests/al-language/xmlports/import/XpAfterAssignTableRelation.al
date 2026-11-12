// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlport/devenv-onafterassignfield-xmlport-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); own tables 77700-77701, xmlports 77702-77706 and 77709-77711,
//   log codeunit 77707, test codeunit 77708.
// local object: the field's TableRelation, OnValidate and the node's OnAfterAssignField trigger are what is under test.
// Probe: al-runner issue 7863. An Xml import of a field node (fieldattribute or fieldelement) that has an OnAfterAssignField trigger, into a
//   Code field with a TableRelation and an OnValidate trigger: which runs first (the TableRelation check, OnValidate, OnAfterAssignField),
//   what the trigger sees, and what is stored. Ports:
//     Attr      fieldattribute, temporary table element (the reporter's shape)
//     Elem      fieldelement, temporary table element
//     Attr NoVal  fieldattribute with FieldValidate = No
//     Attr NV   fieldattribute into a field with ValidateTableRelation = false
//     Attr Db   fieldattribute, table element not temporary (rows read back from the table)
//   The trigger logs the value it sees and, per mode, leaves it (0), sets an existing related value P2 (1) or a missing value MISS (2).
//   Each case imports one row with an existing value (P1), a missing value (MISS) or a blank value and records the result, the error,
//   the log (OnValidate, OnAfterAssignField, OnBeforeInsertRecord, OnAfterInsertRecord) and the rows.
//   BjXmlPortDefaultValidation.al (RG_*) pins the TableRelation check of a node without OnAfterAssignField.
// BC versions: 27, 28, 29

table 77700 "XP AAR Rel"
{
    // local object: the related table.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 77701 "XP AAR Row"
{
    // local object: the imported rows; "Rel Code" is validated against the related table, "Rel Code NV" is not.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Rel Code"; Code[20])
        {
            TableRelation = "XP AAR Rel";

            trigger OnValidate()
            begin
                AarLog.Add('validate:' + "Rel Code");
            end;
        }
        field(3; "Rel Code NV"; Code[20])
        {
            TableRelation = "XP AAR Rel";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                AarLog.Add('validate nv:' + "Rel Code NV");
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77702 "XP AAR Attr"
{
    // local object: fieldattribute with OnAfterAssignField, temporary table element (the reporter's shape).
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                UseTemporary = true;
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77703 "XP AAR Elem"
{
    // local object: fieldelement with OnAfterAssignField, temporary table element.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                UseTemporary = true;
                fieldattribute(Id; Row.Id) { }
                fieldelement(RelCode; Row."Rel Code")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77704 "XP AAR Attr NoVal"
{
    // local object: fieldattribute with OnAfterAssignField and FieldValidate = No.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                UseTemporary = true;
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code")
                {
                    FieldValidate = No;

                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77705 "XP AAR Attr NV"
{
    // local object: fieldattribute with OnAfterAssignField into the field with ValidateTableRelation = false.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                UseTemporary = true;
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code NV")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code NV");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code NV" := 'P2';
                            2:
                                Row."Rel Code NV" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NV");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NV");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77706 "XP AAR Attr Db"
{
    // local object: fieldattribute with OnAfterAssignField, table element not temporary.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77709 "XP AAR Elem Db"
{
    // local object: fieldelement with OnAfterAssignField, table element not temporary.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(RelCode; Row."Rel Code")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77710 "XP AAR Attr NoVal Db"
{
    // local object: fieldattribute with OnAfterAssignField and FieldValidate = No, table element not temporary.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code")
                {
                    FieldValidate = No;

                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code" := 'P2';
                            2:
                                Row."Rel Code" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77711 "XP AAR Attr NV Db"
{
    // local object: fieldattribute into the field with ValidateTableRelation = false, table element not temporary.
    Direction = Import;
    Encoding = UTF8;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP AAR Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(RelCode; Row."Rel Code NV")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code NV");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code NV" := 'P2';
                            2:
                                Row."Rel Code NV" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NV");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NV");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

codeunit 77707 "XP AAR Log"
{
    // local object: the log of the triggers and the mode of OnAfterAssignField (used by codeunit 77708 only).
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Integer;

    procedure Reset(NewMode: Integer)
    begin
        Entries := '';
        Mode := NewMode;
    end;

    procedure GetMode(): Integer
    begin
        exit(Mode);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 77708 "XP AAR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        AarLog: Codeunit "XP AAR Log";

    local procedure Seed(Mode: Integer)
    var
        Row: Record "XP AAR Row";
        Rel: Record "XP AAR Rel";
    begin
        Row.DeleteAll();
        Rel.DeleteAll();
        Rel."Code" := 'P1';
        Rel.Insert();
        Rel."Code" := 'P2';
        Rel.Insert();
        AarLog.Reset(Mode);
    end;

    [TryFunction]
    local procedure TryImport(XmlPortId: Integer; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlPortId, InS);
    end;

    local procedure DbRows(): Text
    var
        Row: Record "XP AAR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row."Rel Code" + ':' + Row."Rel Code NV" + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    // One import of one row: Ok | error text | error code | log | rows of the table (only the not temporary port writes rows there).
    local procedure ImportCase(XmlPortId: Integer; IsAttribute: Boolean; Value: Text; Mode: Integer; Name: Text)
    var
        Xml: Text;
        Ok: Boolean;
    begin
        if IsAttribute then
            Xml := '<?xml version="1.0" encoding="UTF-8"?><Root><Row Id="1" RelCode="' + Value + '" /></Root>'
        else
            Xml := '<?xml version="1.0" encoding="UTF-8"?><Root><Row Id="1"><RelCode>' + Value + '</RelCode></Row></Root>';
        Seed(Mode);
        ClearLastError();
        Ok := TryImport(XmlPortId, Xml);
        Observer.Observe(Name, Format(Ok) + ' | ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + AarLog.Take() + ' | ' + DbRows());
        ClearLastError();
    end;

    local procedure Probe(XmlPortId: Integer; IsAttribute: Boolean)
    begin
        ImportCase(XmlPortId, IsAttribute, 'P1', 0, 'existing, trigger reads');
        ImportCase(XmlPortId, IsAttribute, 'MISS', 0, 'missing, trigger reads');
        ImportCase(XmlPortId, IsAttribute, '', 0, 'blank, trigger reads');
        ImportCase(XmlPortId, IsAttribute, 'MISS', 1, 'missing, trigger sets P2');
        ImportCase(XmlPortId, IsAttribute, 'P1', 2, 'existing, trigger sets MISS');
        ImportCase(XmlPortId, IsAttribute, 'P1', 1, 'existing, trigger sets P2');
    end;

    [Test]
    procedure AAR_FieldAttribute_TableRelation_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr", true);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldElement_TableRelation_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Elem", false);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateNo_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NoVal", true);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldAttribute_ValidateTableRelationFalse_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NV", true);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldAttribute_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr Db", true);
        Observer.Finish();
    end;
    [Test]
    procedure AAR_FieldElement_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Elem Db", false);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateNo_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NoVal Db", true);
        Observer.Finish();
    end;

    [Test]
    procedure AAR_FieldAttribute_ValidateTableRelationFalse_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NV Db", true);
        Observer.Finish();
    end;
}
