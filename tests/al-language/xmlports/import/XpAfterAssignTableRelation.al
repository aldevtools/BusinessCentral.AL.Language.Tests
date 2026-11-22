// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlport/devenv-onafterassignfield-xmlport-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); own tables 77700-77701 and 77712, xmlports 77702-77706,
//   77709-77711, 77713-77719 and 77729-77740, log codeunit 77707, test codeunit 77708.
// local object: the field's TableRelation, OnValidate and the node's OnAfterAssignField trigger are what is under test.
// Probe: al-runner issue 7863. An Xml import of a field node (fieldattribute or fieldelement) that has an OnAfterAssignField trigger, into a
//   Code field with a TableRelation and an OnValidate trigger: which runs first (the TableRelation check, OnValidate, OnAfterAssignField),
//   what the trigger sees, and what is stored. Ports:
//     Attr      fieldattribute, temporary table element (the reporter's shape)
//     Elem      fieldelement, temporary table element
//     Attr NoVal  fieldattribute with FieldValidate = No
//     Attr NV   fieldattribute into a field with ValidateTableRelation = false
//     Attr Db, Elem Db, Attr NoVal Db, Attr NV Db   the same four shapes with a table element that is not temporary (rows read back)
//   The trigger logs the value it sees and, per mode, leaves it (0), sets an existing related value P2 (1) or a missing value MISS (2).
//   Each case imports one row with an existing value (P1), a missing value (MISS) or a blank value and records the result, the error,
//   the log (OnValidate, OnAfterAssignField, OnBeforeInsertRecord, OnAfterInsertRecord) and the rows.
//   BjXmlPortDefaultValidation.al (RG_*) pins the TableRelation check of a node without OnAfterAssignField.
// Facts: on a table element that is not temporary, OnAfterAssignField runs first and sees the imported value; then the field is validated
//   with the value the trigger left: the TableRelation check (DB:PrimRecordNotFound, "The field Rel Code of table XP AAR Row contains a value
//   (MISS) that cannot be found in the related table (XP AAR Rel).", no row, OnValidate not run), then OnValidate, then OnBeforeInsertRecord.
//   A missing imported value that the trigger replaces by an existing one imports; an existing value the trigger replaces by a missing one
//   fails. FieldValidate = No: no check and no OnValidate, the value is stored. ValidateTableRelation = false: OnValidate runs, no check.
//   On a temporary table element (UseTemporary = true, the reporter's shape) the field is not validated at all: no TableRelation check and
//   no OnValidate, every case imports with the value the trigger left. A blank fieldattribute runs no OnAfterAssignField (and no
//   validation); a blank fieldelement runs OnAfterAssignField and, not temporary, OnValidate.
// Second round (al-runner issue 7863 as reported, nodes without OnAfterAssignField, FieldValidate, other field types; tests from
//   AAR_NoOnValidate_Reporter_InstanceImport on, rows shown as Id:Rel Code:Rel Code NoTrig:Rel Int:Rel Code10):
//   - A field with a TableRelation and no OnValidate (the reporter's shape) behaves as "Rel Code" without the OnValidate entry: on a
//     temporary table element nothing is checked (MISS imports, the trigger sees the imported value; through an XmlPort variable with
//     SetSource and Import too); not temporary, the TableRelation check runs after OnAfterAssignField, with the value it leaves.
//   - A node without OnAfterAssignField: on a temporary table element no TableRelation check and no OnValidate (fieldattribute and
//     fieldelement); not temporary, the check and OnValidate run (a missing value: the same error, nothing in the log, no row).
//   - Blank value without OnAfterAssignField, not temporary: a fieldattribute runs no OnValidate, a fieldelement runs OnValidate with ''.
//     A blank Code value is never checked against the related table.
//   - FieldValidate = Yes set explicitly is the same as the default: still no validation on a temporary table element.
//   - fieldelement with FieldValidate = No: no check and no OnValidate (MISS stored), OnAfterAssignField runs, also on a blank element.
//   - Integer field with a TableRelation: the same order and the same error ("... contains a value (99) that cannot be found in the
//     related table (XP AAR IntRel).", DB:PrimRecordNotFound). A blank attribute assigns nothing (0 stays; no trigger, no OnValidate);
//     the value 0 runs the trigger and OnValidate and passes the check.
//   - Code[10] field related to a Code[20] key: the same as "Rel Code". An 11-character value fails before OnAfterAssignField:
//     "The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK", StringLengthExceeded.
// BC versions: 27, 28, 29 (first round: values observed on local BC 27.5 and 28.5, identical, the five first ports also on 29.0; second
//   round: observed on local BC 27.5, 28.5 and 29.0, identical; the corpus CI run checks all three)

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
        field(4; "Rel Code NoTrig"; Code[20])
        {
            // al-runner issue 7863 as reported: a TableRelation and no OnValidate trigger.
            TableRelation = "XP AAR Rel";
        }
        field(5; "Rel Int"; Integer)
        {
            TableRelation = "XP AAR IntRel";

            trigger OnValidate()
            begin
                AarLog.Add('validate int:' + Format("Rel Int"));
            end;
        }
        field(6; "Rel Code10"; Code[10])
        {
            TableRelation = "XP AAR Rel";

            trigger OnValidate()
            begin
                AarLog.Add('validate c10:' + "Rel Code10");
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

table 77712 "XP AAR IntRel"
{
    // local object: the related table of the Integer field "Rel Int".
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
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

xmlport 77713 "XP AAR NT Attr"
{
    // local object: fieldattribute with OnAfterAssignField into a field with a TableRelation and no OnValidate, temporary table element (al-runner issue 7863 as reported; captures the value in a global).
    Direction = Import;
    Encoding = UTF8;
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
                fieldattribute(RelCode; Row."Rel Code NoTrig")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code NoTrig");
                        Captured := Row."Rel Code NoTrig";
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code NoTrig" := 'P2';
                            2:
                                Row."Rel Code NoTrig" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NoTrig");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NoTrig");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
        Captured: Code[20];

    procedure GetCaptured(): Code[20]
    begin
        exit(Captured);
    end;
}

xmlport 77714 "XP AAR NT Attr Plain"
{
    // local object: fieldattribute without OnAfterAssignField into the field with a TableRelation and no OnValidate, temporary table element.
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
                fieldattribute(RelCode; Row."Rel Code NoTrig") { }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NoTrig");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NoTrig");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77715 "XP AAR NT Attr Db"
{
    // local object: fieldattribute with OnAfterAssignField into the field with a TableRelation and no OnValidate, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Code NoTrig")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code NoTrig");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code NoTrig" := 'P2';
                            2:
                                Row."Rel Code NoTrig" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NoTrig");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NoTrig");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77716 "XP AAR NT Attr Db Plain"
{
    // local object: fieldattribute without OnAfterAssignField into the field with a TableRelation and no OnValidate, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Code NoTrig") { }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code NoTrig");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code NoTrig");
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77717 "XP AAR Attr Plain"
{
    // local object: fieldattribute without OnAfterAssignField, temporary table element.
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
                fieldattribute(RelCode; Row."Rel Code") { }

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

xmlport 77718 "XP AAR Attr Db Plain"
{
    // local object: fieldattribute without OnAfterAssignField, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Code") { }

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

xmlport 77719 "XP AAR Elem Plain"
{
    // local object: fieldelement without OnAfterAssignField, temporary table element.
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
                fieldelement(RelCode; Row."Rel Code") { }

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

xmlport 77729 "XP AAR Elem Db Plain"
{
    // local object: fieldelement without OnAfterAssignField, table element not temporary.
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
                fieldelement(RelCode; Row."Rel Code") { }

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

xmlport 77730 "XP AAR Attr FVYes"
{
    // local object: fieldattribute with OnAfterAssignField and FieldValidate = Yes, temporary table element.
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
                    FieldValidate = Yes;

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

xmlport 77731 "XP AAR Attr FVYes Db"
{
    // local object: fieldattribute with OnAfterAssignField and FieldValidate = Yes, table element not temporary.
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
                    FieldValidate = Yes;

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

xmlport 77732 "XP AAR Attr FVYes Plain"
{
    // local object: fieldattribute without OnAfterAssignField and FieldValidate = Yes, temporary table element.
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
                    FieldValidate = Yes;
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

xmlport 77733 "XP AAR Attr FVYes Db Plain"
{
    // local object: fieldattribute without OnAfterAssignField and FieldValidate = Yes, table element not temporary.
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
                    FieldValidate = Yes;
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

xmlport 77734 "XP AAR Elem NoVal"
{
    // local object: fieldelement with OnAfterAssignField and FieldValidate = No, temporary table element.
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

xmlport 77735 "XP AAR Elem NoVal Db"
{
    // local object: fieldelement with OnAfterAssignField and FieldValidate = No, table element not temporary.
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

xmlport 77736 "XP AAR Elem NoVal Db Plain"
{
    // local object: fieldelement without OnAfterAssignField and FieldValidate = No, table element not temporary.
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
                    FieldValidate = No;
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

xmlport 77737 "XP AAR Int Attr"
{
    // local object: fieldattribute with OnAfterAssignField into an Integer field with a TableRelation, temporary table element.
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
                fieldattribute(RelCode; Row."Rel Int")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Format(Row."Rel Int"));
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Int" := 2;
                            2:
                                Row."Rel Int" := 99;
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Format(Row."Rel Int"));
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Format(Row."Rel Int"));
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77738 "XP AAR Int Attr Db"
{
    // local object: fieldattribute with OnAfterAssignField into an Integer field with a TableRelation, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Int")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Format(Row."Rel Int"));
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Int" := 2;
                            2:
                                Row."Rel Int" := 99;
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Format(Row."Rel Int"));
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Format(Row."Rel Int"));
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77739 "XP AAR Int Attr Db Plain"
{
    // local object: fieldattribute without OnAfterAssignField into an Integer field with a TableRelation, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Int") { }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Format(Row."Rel Int"));
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Format(Row."Rel Int"));
                end;
            }
        }
    }

    var
        AarLog: Codeunit "XP AAR Log";
}

xmlport 77740 "XP AAR C10 Attr Db"
{
    // local object: fieldattribute with OnAfterAssignField into a Code[10] field related to a Code[20] key, table element not temporary.
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
                fieldattribute(RelCode; Row."Rel Code10")
                {
                    trigger OnAfterAssignField()
                    begin
                        AarLog.Add('after:' + Row."Rel Code10");
                        case AarLog.GetMode() of
                            1:
                                Row."Rel Code10" := 'P2';
                            2:
                                Row."Rel Code10" := 'MISS';
                        end;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    AarLog.Add('before insert:' + Row."Rel Code10");
                end;

                trigger OnAfterInsertRecord()
                begin
                    AarLog.Add('after insert:' + Row."Rel Code10");
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
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_TableRelation_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Elem", false);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | after:;before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateNo_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NoVal", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_ValidateTableRelationFalse_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NV", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr Db", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;validate:P1;before insert:P1;after insert:P1; | 1:P1:,');
        Observer.Expect('missing, trigger reads', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1::,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;validate:P2;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Expect('existing, trigger sets MISS', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:P1; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;validate:P2;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Verify();
    end;
    [Test]
    procedure AAR_FieldElement_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Elem Db", false);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;validate:P1;before insert:P1;after insert:P1; | 1:P1:,');
        Observer.Expect('missing, trigger reads', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | after:;validate:;before insert:;after insert:; | 1::,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;validate:P2;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Expect('existing, trigger sets MISS', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:P1; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;validate:P2;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateNo_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NoVal Db", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | 1:P1:,');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | 1:MISS:,');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1::,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | 1:MISS:,');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | 1:P2:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_ValidateTableRelationFalse_NotTemporary_AfterAssign()
    begin
        Probe(Xmlport::"XP AAR Attr NV Db", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;validate nv:P1;before insert:P1;after insert:P1; | 1::P1,');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;validate nv:MISS;before insert:MISS;after insert:MISS; | 1::MISS,');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1::,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;validate nv:P2;before insert:P2;after insert:P2; | 1::P2,');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;validate nv:MISS;before insert:MISS;after insert:MISS; | 1::MISS,');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;validate nv:P2;before insert:P2;after insert:P2; | 1::P2,');
        Observer.Verify();
    end;

    // Cells 2 (the second round of al-runner issue 7863): the rows of the new tests show Id:Rel Code:Rel Code NoTrig:Rel Int:Rel Code10.
    local procedure SeedAll(Mode: Integer)
    var
        IntRel: Record "XP AAR IntRel";
    begin
        Seed(Mode);
        IntRel.DeleteAll();
        IntRel.Id := 1;
        IntRel.Insert();
        IntRel.Id := 2;
        IntRel.Insert();
    end;

    local procedure DbRowsAll(): Text
    var
        Row: Record "XP AAR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row."Rel Code" + ':' + Row."Rel Code NoTrig" + ':' + Format(Row."Rel Int") + ':' + Row."Rel Code10" + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure ImportCaseAll(XmlPortId: Integer; IsAttribute: Boolean; Value: Text; Mode: Integer; Name: Text)
    var
        Xml: Text;
        Ok: Boolean;
    begin
        if IsAttribute then
            Xml := '<?xml version="1.0" encoding="UTF-8"?><Root><Row Id="1" RelCode="' + Value + '" /></Root>'
        else
            Xml := '<?xml version="1.0" encoding="UTF-8"?><Root><Row Id="1"><RelCode>' + Value + '</RelCode></Row></Root>';
        SeedAll(Mode);
        ClearLastError();
        Ok := TryImport(XmlPortId, Xml);
        Observer.Observe(Name, Format(Ok) + ' | ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + AarLog.Take() + ' | ' + DbRowsAll());
        ClearLastError();
    end;

    local procedure ProbeAll(XmlPortId: Integer; IsAttribute: Boolean)
    begin
        ImportCaseAll(XmlPortId, IsAttribute, 'P1', 0, 'existing, trigger reads');
        ImportCaseAll(XmlPortId, IsAttribute, 'MISS', 0, 'missing, trigger reads');
        ImportCaseAll(XmlPortId, IsAttribute, '', 0, 'blank, trigger reads');
        ImportCaseAll(XmlPortId, IsAttribute, 'MISS', 1, 'missing, trigger sets P2');
        ImportCaseAll(XmlPortId, IsAttribute, 'P1', 2, 'existing, trigger sets MISS');
        ImportCaseAll(XmlPortId, IsAttribute, 'P1', 1, 'existing, trigger sets P2');
    end;

    // A node without OnAfterAssignField: the imported value only.
    local procedure ProbePlain(XmlPortId: Integer; IsAttribute: Boolean)
    begin
        ImportCaseAll(XmlPortId, IsAttribute, 'P1', 0, 'existing');
        ImportCaseAll(XmlPortId, IsAttribute, 'MISS', 0, 'missing');
        ImportCaseAll(XmlPortId, IsAttribute, '', 0, 'blank');
    end;

    // Integer field related to "XP AAR IntRel" (rows 1 and 2): the trigger sets 2 (mode 1) or 99 (mode 2).
    local procedure ProbeInt(XmlPortId: Integer; WithTrigger: Boolean)
    begin
        ImportCaseAll(XmlPortId, true, '1', 0, 'existing 1');
        ImportCaseAll(XmlPortId, true, '99', 0, 'missing 99');
        ImportCaseAll(XmlPortId, true, '', 0, 'blank');
        ImportCaseAll(XmlPortId, true, '0', 0, 'zero');
        if not WithTrigger then
            exit;
        ImportCaseAll(XmlPortId, true, '99', 1, 'missing 99, trigger sets 2');
        ImportCaseAll(XmlPortId, true, '1', 2, 'existing 1, trigger sets 99');
        ImportCaseAll(XmlPortId, true, '1', 1, 'existing 1, trigger sets 2');
    end;

    // The reporter's call: an XmlPort variable, SetSource, Import, then a procedure of the port returns the value the trigger captured.
    [TryFunction]
    local procedure TryImportReporter(Xml: Text; var Captured: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        AarImport: XmlPort "XP AAR NT Attr";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS);
        AarImport.SetSource(InS);
        AarImport.Import();
        Captured := AarImport.GetCaptured();
    end;

    local procedure ReporterCase(Value: Text; Name: Text)
    var
        Captured: Code[20];
        Ok: Boolean;
    begin
        SeedAll(0);
        ClearLastError();
        Ok := TryImportReporter('<?xml version="1.0" encoding="UTF-8"?><Root><Row Id="1" RelCode="' + Value + '" /></Root>', Captured);
        Observer.Observe(Name, Format(Ok) + ' | ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | captured:' + Captured + ' | ' + AarLog.Take() + ' | ' + DbRowsAll());
        ClearLastError();
    end;

    [Test]
    procedure AAR_NoOnValidate_Reporter_InstanceImport()
    begin
        ReporterCase('P1', 'existing');
        ReporterCase('MISS', 'missing');
        ReporterCase('', 'blank');
        Observer.Expect('existing', 'Yes |  |  | captured:P1 | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing', 'Yes |  |  | captured:MISS | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank', 'Yes |  |  | captured: | before insert:;after insert:; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_NoOnValidate_Temporary_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR NT Attr", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_NoOnValidate_Temporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR NT Attr Plain", true);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | ');
        Observer.Expect('missing', 'Yes |  |  | before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_NoOnValidate_NotTemporary_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR NT Attr Db", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | 1::P1:0:,');
        Observer.Expect('missing, trigger reads', 'No | The field Rel Code NoTrig of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | 1::P2:0:,');
        Observer.Expect('existing, trigger sets MISS', 'No | The field Rel Code NoTrig of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:P1; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | 1::P2:0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_NoOnValidate_NotTemporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR NT Attr Db Plain", true);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | 1::P1:0:,');
        Observer.Expect('missing', 'No | The field Rel Code NoTrig of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_Temporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Attr Plain", true);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | ');
        Observer.Expect('missing', 'Yes |  |  | before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_NotTemporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Attr Db Plain", true);
        Observer.Expect('existing', 'Yes |  |  | validate:P1;before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_Temporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Elem Plain", false);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | ');
        Observer.Expect('missing', 'Yes |  |  | before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_NotTemporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Elem Db Plain", false);
        Observer.Expect('existing', 'Yes |  |  | validate:P1;before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('blank', 'Yes |  |  | validate:;before insert:;after insert:; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateYes_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR Attr FVYes", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateYes_NotTemporary_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR Attr FVYes Db", true);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;validate:P1;before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing, trigger reads', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;validate:P2;before insert:P2;after insert:P2; | 1:P2::0:,');
        Observer.Expect('existing, trigger sets MISS', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:P1; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;validate:P2;before insert:P2;after insert:P2; | 1:P2::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateYes_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Attr FVYes Plain", true);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | ');
        Observer.Expect('missing', 'Yes |  |  | before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldAttribute_FieldValidateYes_NotTemporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Attr FVYes Db Plain", true);
        Observer.Expect('existing', 'Yes |  |  | validate:P1;before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing', 'No | The field Rel Code of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_FieldValidateNo_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR Elem NoVal", false);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | ');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | after:;before insert:;after insert:; | ');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | ');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_FieldValidateNo_NotTemporary_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR Elem NoVal Db", false);
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing, trigger reads', 'Yes |  |  | after:MISS;before insert:MISS;after insert:MISS; | 1:MISS::0:,');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | after:;before insert:;after insert:; | 1:::0:,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;before insert:P2;after insert:P2; | 1:P2::0:,');
        Observer.Expect('existing, trigger sets MISS', 'Yes |  |  | after:P1;before insert:MISS;after insert:MISS; | 1:MISS::0:,');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;before insert:P2;after insert:P2; | 1:P2::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_FieldElement_FieldValidateNo_NotTemporary_Plain()
    begin
        ProbePlain(Xmlport::"XP AAR Elem NoVal Db Plain", false);
        Observer.Expect('existing', 'Yes |  |  | before insert:P1;after insert:P1; | 1:P1::0:,');
        Observer.Expect('missing', 'Yes |  |  | before insert:MISS;after insert:MISS; | 1:MISS::0:,');
        Observer.Expect('blank', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_IntegerRelation_AfterAssign()
    begin
        ProbeInt(Xmlport::"XP AAR Int Attr", true);
        Observer.Expect('existing 1', 'Yes |  |  | after:1;before insert:1;after insert:1; | ');
        Observer.Expect('missing 99', 'Yes |  |  | after:99;before insert:99;after insert:99; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:0;after insert:0; | ');
        Observer.Expect('zero', 'Yes |  |  | after:0;before insert:0;after insert:0; | ');
        Observer.Expect('missing 99, trigger sets 2', 'Yes |  |  | after:99;before insert:2;after insert:2; | ');
        Observer.Expect('existing 1, trigger sets 99', 'Yes |  |  | after:1;before insert:99;after insert:99; | ');
        Observer.Expect('existing 1, trigger sets 2', 'Yes |  |  | after:1;before insert:2;after insert:2; | ');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_IntegerRelation_NotTemporary_AfterAssign()
    begin
        ProbeInt(Xmlport::"XP AAR Int Attr Db", true);
        Observer.Expect('existing 1', 'Yes |  |  | after:1;validate int:1;before insert:1;after insert:1; | 1:::1:,');
        Observer.Expect('missing 99', 'No | The field Rel Int of table XP AAR Row contains a value (99) that cannot be found in the related table (XP AAR IntRel). | DB:PrimRecordNotFound | after:99; | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:0;after insert:0; | 1:::0:,');
        Observer.Expect('zero', 'Yes |  |  | after:0;validate int:0;before insert:0;after insert:0; | 1:::0:,');
        Observer.Expect('missing 99, trigger sets 2', 'Yes |  |  | after:99;validate int:2;before insert:2;after insert:2; | 1:::2:,');
        Observer.Expect('existing 1, trigger sets 99', 'No | The field Rel Int of table XP AAR Row contains a value (99) that cannot be found in the related table (XP AAR IntRel). | DB:PrimRecordNotFound | after:1; | ');
        Observer.Expect('existing 1, trigger sets 2', 'Yes |  |  | after:1;validate int:2;before insert:2;after insert:2; | 1:::2:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_IntegerRelation_NotTemporary_Plain()
    begin
        ProbeInt(Xmlport::"XP AAR Int Attr Db Plain", false);
        Observer.Expect('existing 1', 'Yes |  |  | validate int:1;before insert:1;after insert:1; | 1:::1:,');
        Observer.Expect('missing 99', 'No | The field Rel Int of table XP AAR Row contains a value (99) that cannot be found in the related table (XP AAR IntRel). | DB:PrimRecordNotFound |  | ');
        Observer.Expect('blank', 'Yes |  |  | before insert:0;after insert:0; | 1:::0:,');
        Observer.Expect('zero', 'Yes |  |  | validate int:0;before insert:0;after insert:0; | 1:::0:,');
        Observer.Verify();
    end;

    [Test]
    procedure AAR_Code10Relation_NotTemporary_AfterAssign()
    begin
        ProbeAll(Xmlport::"XP AAR C10 Attr Db", true);
        ImportCaseAll(Xmlport::"XP AAR C10 Attr Db", true, 'ABCDEFGHIJK', 0, 'eleven characters, trigger reads');
        Observer.Expect('existing, trigger reads', 'Yes |  |  | after:P1;validate c10:P1;before insert:P1;after insert:P1; | 1:::0:P1,');
        Observer.Expect('missing, trigger reads', 'No | The field Rel Code10 of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:MISS; | ');
        Observer.Expect('blank, trigger reads', 'Yes |  |  | before insert:;after insert:; | 1:::0:,');
        Observer.Expect('missing, trigger sets P2', 'Yes |  |  | after:MISS;validate c10:P2;before insert:P2;after insert:P2; | 1:::0:P2,');
        Observer.Expect('existing, trigger sets MISS', 'No | The field Rel Code10 of table XP AAR Row contains a value (MISS) that cannot be found in the related table (XP AAR Rel). | DB:PrimRecordNotFound | after:P1; | ');
        Observer.Expect('existing, trigger sets P2', 'Yes |  |  | after:P1;validate c10:P2;before insert:P2;after insert:P2; | 1:::0:P2,');
        Observer.Expect('eleven characters, trigger reads', 'No | The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK | StringLengthExceeded |  | ');
        Observer.Verify();
    end;
}
