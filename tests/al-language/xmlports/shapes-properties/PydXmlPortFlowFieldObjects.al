// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-field-element
// Scope: in-scope
// Objects for the PYD_ import tests in AyXmlPortLookupFlowField.al (writer PY-D, 2026-10-20): an import into field elements bound to Exist,
// Min, Max, Average, Lookup and Count FlowFields, as Xml, VariableText and FixedText, with OnAfterAssignField on every FlowField element.
// Uses LT AY Lk Master (80510) and LT XpFS Detail (72822). Object ids 85223-85226. Not a test codeunit file.

table 85223 "LT PYD Xp FF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; MasterCode; Code[10]) { }
        field(3; HasMaster; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT AY Lk Master" where(Code = field(MasterCode)));
        }
        field(4; MinAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("LT XpFS Detail".Amount where(ParentId = field(Id)));
        }
        field(5; MaxAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = max("LT XpFS Detail".Amount where(ParentId = field(Id)));
        }
        field(6; AvgAmt; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("LT XpFS Detail".Amount where(ParentId = field(Id)));
        }
        field(7; LkName; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT AY Lk Master".Name where(Code = field(MasterCode)));
        }
        field(8; CntD; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT XpFS Detail" where(ParentId = field(Id)));
        }
        field(9; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit(Format(Id) + '/' + MasterCode + '/' + Format(HasMaster) + '/' + Format(MinAmt) + '/' + Format(MaxAmt) + '/' + Format(AvgAmt) + '/' + LkName + '/' + Format(CntD) + '/' + Note);
    end;
}

xmlport 85224 "LT PYD Xp FF Xml"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT PYD Xp FF Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(MasterCode; Rw.MasterCode) { }
                fieldelement(HasMaster; Rw.HasMaster) { trigger OnAfterAssignField() begin Seen += 'assign HasMaster=' + Format(Rw.HasMaster) + ';'; end; }
                fieldelement(MinAmt; Rw.MinAmt) { trigger OnAfterAssignField() begin Seen += 'assign MinAmt=' + Format(Rw.MinAmt) + ';'; end; }
                fieldelement(MaxAmt; Rw.MaxAmt) { trigger OnAfterAssignField() begin Seen += 'assign MaxAmt=' + Format(Rw.MaxAmt) + ';'; end; }
                fieldelement(AvgAmt; Rw.AvgAmt) { trigger OnAfterAssignField() begin Seen += 'assign AvgAmt=' + Format(Rw.AvgAmt) + ';'; end; }
                fieldelement(LkName; Rw.LkName) { trigger OnAfterAssignField() begin Seen += 'assign LkName=' + Rw.LkName + ';'; end; }
                fieldelement(CntD; Rw.CntD) { trigger OnAfterAssignField() begin Seen += 'assign CntD=' + Format(Rw.CntD) + ';'; end; }
                fieldelement(Note; Rw.Note) { trigger OnAfterAssignField() begin Seen += 'assign Note=' + Rw.Note + ';'; end; }

                trigger OnBeforeInsertRecord()
                begin
                    Seen += 'before-insert=' + Rw.Describe() + ';';
                end;
            }
        }
    }

    var
        Seen: Text;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 85225 "LT PYD Xp FF VarText"
{
    Format = VariableText;
    FieldSeparator = ';';
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT PYD Xp FF Row")
            {
                fieldelement(Id; Rw.Id) { }
                fieldelement(MasterCode; Rw.MasterCode) { }
                fieldelement(LkName; Rw.LkName) { trigger OnAfterAssignField() begin Seen += 'assign LkName=' + Rw.LkName + ';'; end; }
                fieldelement(CntD; Rw.CntD) { trigger OnAfterAssignField() begin Seen += 'assign CntD=' + Format(Rw.CntD) + ';'; end; }
                fieldelement(MinAmt; Rw.MinAmt) { trigger OnAfterAssignField() begin Seen += 'assign MinAmt=' + Format(Rw.MinAmt) + ';'; end; }
                fieldelement(Note; Rw.Note) { trigger OnAfterAssignField() begin Seen += 'assign Note=' + Rw.Note + ';'; end; }

                trigger OnBeforeInsertRecord()
                begin
                    Seen += 'before-insert=' + Rw.Describe() + ';';
                end;
            }
        }
    }

    var
        Seen: Text;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}

xmlport 85226 "LT PYD Xp FF Fixed"
{
    Format = FixedText;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT PYD Xp FF Row")
            {
                fieldelement(Id; Rw.Id) { Width = 3; }
                fieldelement(MasterCode; Rw.MasterCode) { Width = 3; }
                fieldelement(LkName; Rw.LkName) { Width = 6; trigger OnAfterAssignField() begin Seen += 'assign LkName=' + Rw.LkName + ';'; end; }
                fieldelement(CntD; Rw.CntD) { Width = 3; trigger OnAfterAssignField() begin Seen += 'assign CntD=' + Format(Rw.CntD) + ';'; end; }
                fieldelement(Note; Rw.Note) { Width = 4; trigger OnAfterAssignField() begin Seen += 'assign Note=' + Rw.Note + ';'; end; }

                trigger OnBeforeInsertRecord()
                begin
                    Seen += 'before-insert=' + Rw.Describe() + ';';
                end;
            }
        }
    }

    var
        Seen: Text;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;
}
