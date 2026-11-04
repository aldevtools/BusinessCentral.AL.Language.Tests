// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-triggers
// Scope: in-scope
// Fixtures used: LT XT Log (codeunit 74958, used only by test codeunit 74961 in XmlPortTriggerFlow.al, which holds the tests of these objects)
// Probe: observe probe; every literal asserted in codeunit 74961 for these objects is what the corpus CI service tiers produced.
// Facts: the objects of the nested-import tests in XmlPortTriggerFlow.al (codeunit 74961, tests NoAutoReplace_*, ThreeLevels_*, TempChild_*):
//   Xml import of a parent table element WITHOUT AutoReplace / AutoUpdate (AutoSave left at its default) holding a linked nested table
//   element with MinOccurs = Zero; three levels of nested linked table elements; a nested element with UseTemporary = true and
//   AutoReplace = true. The tables log their OnInsert / OnModify triggers and the xmlports log OnAfterInitRecord, OnBefore/AfterInsertRecord,
//   OnBefore/AfterModifyRecord and OnAfterGetRecord, so the tests read the order BC runs them in.
//   BC (CI 29.0): without AutoReplace a parent row that got at least one child row is modified again after its children
//   (OnBeforeModifyRecord, table OnModify, OnAfterModifyRecord), as with AutoReplace; a parent without child rows is not. A parent row that
//   already exists is still inserted (OnBeforeInsertRecord, table OnInsert, OnAfterInsertRecord run), its child rows are inserted, and the
//   import then fails with "already exists" before the parent's second OnBeforeModifyRecord; nothing is stored. With three levels each
//   row with child rows is modified after its own children (grandchildren, then the child, then the next child, then the parent). The
//   second and later child rows of one parent get ParentId 0 (LinkFields fill only the first). A temporary child with AutoReplace runs no
//   table triggers; a row whose key is already in the temporary table is modified (OnBefore/AfterModifyRecord), also under another parent;
//   the real child table stays empty. OnAfterGetRecord does not run during an import, on any level.
// BC versions: 27, 28, 29 (corpus CI)

table 87860 "LT RC Par"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        L.Add('tP+' + Format(Id) + '/' + Name);
    end;

    trigger OnModify()
    begin
        L.Add('tP~' + Format(Id) + '/' + Name);
    end;

    var
        L: Codeunit "LT XT Log";
}

table 87861 "LT RC Chi"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        L.Add('tC+' + Format(Id) + '/' + Format(ParentId) + '/' + Note);
    end;

    trigger OnModify()
    begin
        L.Add('tC~' + Format(Id) + '/' + Format(ParentId) + '/' + Note);
    end;

    var
        L: Codeunit "LT XT Log";
}

table 87862 "LT RC GChi"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ChildId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        L.Add('tG+' + Format(Id) + '/' + Format(ChildId) + '/' + Note);
    end;

    trigger OnModify()
    begin
        L.Add('tG~' + Format(Id) + '/' + Format(ChildId) + '/' + Note);
    end;

    var
        L: Codeunit "LT XT Log";
}

// Parent without AutoReplace / AutoUpdate, nested child with MinOccurs = Zero (both AutoSave left at the default).
xmlport 87863 "LT RC Imp NoAR"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT RC Par")
            {
                XmlName = 'Par';

                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT RC Chi")
                {
                    XmlName = 'Chi';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnAfterInitRecord()
                    begin
                        L.Add('C.init');
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('C.agr=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        L.Add('C.bi=' + Format(Chi.Id) + '/' + Format(Chi.ParentId));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        L.Add('C.ai=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeModifyRecord()
                    begin
                        L.Add('C.bm=' + Format(Chi.Id));
                    end;

                    trigger OnAfterModifyRecord()
                    begin
                        L.Add('C.am=' + Format(Chi.Id));
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    L.Add('P.init');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('P.agr=' + Format(Par.Id));
                end;

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('P.bi=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterInsertRecord()
                begin
                    L.Add('P.ai=' + Format(Par.Id));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('P.bm=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('P.am=' + Format(Par.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XT Log";
}

// Three levels, no AutoReplace anywhere: Par > Chi (MinOccurs = Zero) > GChi (MinOccurs = Zero).
xmlport 87864 "LT RC Imp Three"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT RC Par")
            {
                XmlName = 'Par';

                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT RC Chi")
                {
                    XmlName = 'Chi';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id) { }
                    fieldelement(Note; Chi.Note) { }
                    tableelement(GChi; "LT RC GChi")
                    {
                        XmlName = 'G';
                        LinkTable = Chi;
                        LinkFields = ChildId = field(Id);
                        MinOccurs = Zero;

                        fieldelement(GId; GChi.Id) { }
                        fieldelement(GNote; GChi.Note) { }

                        trigger OnAfterGetRecord()
                        begin
                            L.Add('G.agr=' + Format(GChi.Id));
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            L.Add('G.bi=' + Format(GChi.Id) + '/' + Format(GChi.ChildId));
                        end;

                        trigger OnAfterInsertRecord()
                        begin
                            L.Add('G.ai=' + Format(GChi.Id));
                        end;

                        trigger OnBeforeModifyRecord()
                        begin
                            L.Add('G.bm=' + Format(GChi.Id));
                        end;

                        trigger OnAfterModifyRecord()
                        begin
                            L.Add('G.am=' + Format(GChi.Id));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('C.agr=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        L.Add('C.bi=' + Format(Chi.Id) + '/' + Format(Chi.ParentId));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        L.Add('C.ai=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeModifyRecord()
                    begin
                        L.Add('C.bm=' + Format(Chi.Id));
                    end;

                    trigger OnAfterModifyRecord()
                    begin
                        L.Add('C.am=' + Format(Chi.Id));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    L.Add('P.agr=' + Format(Par.Id));
                end;

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('P.bi=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterInsertRecord()
                begin
                    L.Add('P.ai=' + Format(Par.Id));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('P.bm=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('P.am=' + Format(Par.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "LT XT Log";
}

// Parent without AutoReplace, nested child with UseTemporary = true and AutoReplace = true.
xmlport 87865 "LT RC Imp TempChi"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT RC Par")
            {
                XmlName = 'Par';

                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT RC Chi")
                {
                    XmlName = 'Chi';
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;
                    UseTemporary = true;
                    AutoReplace = true;

                    fieldelement(CId; Chi.Id) { }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('C.agr=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        L.Add('C.bi=' + Format(Chi.Id) + '/' + Format(Chi.ParentId) + '/' + Chi.Note);
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        L.Add('C.ai=' + Format(Chi.Id) + '/' + Format(Chi.ParentId) + '/' + Chi.Note);
                    end;

                    trigger OnBeforeModifyRecord()
                    begin
                        L.Add('C.bm=' + Format(Chi.Id) + '/' + Chi.Note);
                    end;

                    trigger OnAfterModifyRecord()
                    begin
                        L.Add('C.am=' + Format(Chi.Id) + '/' + Chi.Note);
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('P.bi=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterInsertRecord()
                begin
                    L.Add('P.ai=' + Format(Par.Id));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('P.bm=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('P.am=' + Format(Par.Id));
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        L.Add('post filter=' + Chi.GetFilters());
        Chi.Reset();
        if Chi.FindSet() then
            repeat
                L.Add('tmp=' + Format(Chi.Id) + '/' + Format(Chi.ParentId) + '/' + Chi.Note);
            until Chi.Next() = 0;
    end;

    var
        L: Codeunit "LT XT Log";
}

// Runs one import inside Codeunit.Run, so an error (also one raised at the commit that ends the run) does not end the test.
codeunit 87866 "LT RC Import Runner"
{
    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(XmlTxt);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlportId, InS);
    end;

    procedure SetArgs(NewXmlportId: Integer; NewXmlTxt: Text)
    begin
        XmlportId := NewXmlportId;
        XmlTxt := NewXmlTxt;
    end;

    var
        XmlportId: Integer;
        XmlTxt: Text;
}
