// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 74956 and 74957, log 74958, xmlports 74959 and 74960, test codeunit 74961
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order in which an XmlPort runs its triggers on Export and on Import with a parent and a nested child table element and a text element: OnPreXmlPort, OnPreXmlItem, OnAfterGetRecord, the element triggers, OnPostXmlPort, and the counts the data items answer when read inside OnPreXmlPort, OnAfterGetRecord and OnPostXmlPort. Import inserts new rows and modifies existing ones (AutoSave, AutoReplace).
// BC versions: 29 (27 and 28 by CI)

table 74956 "LT XT Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74957 "LT XT Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74958 "LT XT Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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

xmlport 74959 "LT XT Export"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Hdr)
            {
                trigger OnBeforePassVariable()
                begin
                    L.Add('Hdr.BeforePassVariable');
                    Hdr := 'h';
                end;
            }
            tableelement(Par; "LT XT Parent")
            {
                XmlName = 'Par';

                fieldelement(Id; Par.Id)
                {
                    trigger OnBeforePassField()
                    begin
                        L.Add('Par.Id.BeforePassField=' + Format(Par.Id));
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XT Child")
                {
                    XmlName = 'Chi';
                    LinkFields = ParentId = field(Id);
                    LinkTable = Par;
                    MinOccurs = Zero;

                    fieldelement(CId; Chi.Id)
                    {
                        trigger OnBeforePassField()
                        begin
                            L.Add('Chi.Id.BeforePassField=' + Format(Chi.Id));
                        end;
                    }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnPreXmlItem()
                    begin
                        L.Add('Chi.PreXmlItem count=' + Format(Chi.Count()));
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        L.Add('Chi.AfterGetRecord=' + Format(Chi.Id));
                    end;

                }

                trigger OnPreXmlItem()
                begin
                    L.Add('Par.PreXmlItem count=' + Format(Par.Count()));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('Par.AfterGetRecord=' + Format(Par.Id));
                end;

            }
        }
    }

    trigger OnPreXmlPort()
    begin
        L.Add('PreXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    trigger OnPostXmlPort()
    begin
        L.Add('PostXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    var
        L: Codeunit "LT XT Log";
}

xmlport 74960 "LT XT Import"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Hdr)
            {
                trigger OnAfterAssignVariable()
                begin
                    L.Add('Hdr.AfterAssignVariable=' + Hdr);
                end;
            }
            tableelement(Par; "LT XT Parent")
            {
                XmlName = 'Par';
                AutoSave = true;
                AutoReplace = true;

                fieldelement(Id; Par.Id)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('Par.Id.AfterAssignField=' + Format(Par.Id));
                    end;
                }
                fieldelement(Name; Par.Name) { }
                tableelement(Chi; "LT XT Child")
                {
                    XmlName = 'Chi';
                    LinkFields = ParentId = field(Id);
                    LinkTable = Par;
                    MinOccurs = Zero;
                    AutoSave = true;
                    AutoReplace = true;

                    fieldelement(CId; Chi.Id)
                    {
                        trigger OnAfterAssignField()
                        begin
                            L.Add('Chi.Id.AfterAssignField=' + Format(Chi.Id));
                        end;
                    }
                    fieldelement(Note; Chi.Note) { }

                    trigger OnPreXmlItem()
                    begin
                        L.Add('Chi.PreXmlItem');
                    end;

                    trigger OnAfterInitRecord()
                    begin
                        L.Add('Chi.AfterInitRecord');
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        L.Add('Chi.BeforeInsertRecord=' + Format(Chi.Id) + '/' + Format(Chi.ParentId));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        L.Add('Chi.AfterInsertRecord=' + Format(Chi.Id));
                    end;

                    trigger OnBeforeModifyRecord()
                    begin
                        L.Add('Chi.BeforeModifyRecord=' + Format(Chi.Id));
                    end;

                    trigger OnAfterModifyRecord()
                    begin
                        L.Add('Chi.AfterModifyRecord=' + Format(Chi.Id));
                    end;

                }

                trigger OnPreXmlItem()
                begin
                    L.Add('Par.PreXmlItem');
                end;

                trigger OnAfterInitRecord()
                begin
                    L.Add('Par.AfterInitRecord');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    L.Add('Par.BeforeInsertRecord=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterInsertRecord()
                begin
                    L.Add('Par.AfterInsertRecord=' + Format(Par.Id));
                end;

                trigger OnBeforeModifyRecord()
                begin
                    L.Add('Par.BeforeModifyRecord=' + Format(Par.Id) + '/' + Par.Name);
                end;

                trigger OnAfterModifyRecord()
                begin
                    L.Add('Par.AfterModifyRecord=' + Format(Par.Id));
                end;

            }
        }
    }

    trigger OnPreXmlPort()
    begin
        L.Add('PreXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    trigger OnPostXmlPort()
    begin
        L.Add('PostXmlPort par=' + Format(Par.Count()) + ' chi=' + Format(Chi.Count()));
    end;

    var
        L: Codeunit "LT XT Log";
}

codeunit 74961 "LT XmlPort Trigger Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Par.Id := 1; Par.Name := 'one'; Par.Insert();
        Par.Id := 2; Par.Name := 'two'; Par.Insert();
        Chi.Id := 10; Chi.ParentId := 1; Chi.Note := 'c10'; Chi.Insert();
        Chi.Id := 11; Chi.ParentId := 1; Chi.Note := 'c11'; Chi.Insert();
        Chi.Id := 20; Chi.ParentId := 2; Chi.Note := 'c20'; Chi.Insert();
    end;

    local procedure ExportText(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xmlport.Export(Xmlport::"LT XT Export", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Txt += Line;
        end;
        exit(Txt);
    end;

    local procedure ImportText(Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XT Import", InS);
    end;

    [Test]
    procedure Export_TriggerOrder_ParentWithNestedChild()
    var
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Observer.Observe('xml', ExportText());
        Observer.Observe('trace', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Hdr>h</Hdr>  <Par>    <Id>1</Id>    <Name>one</Name>    <Chi>      <CId>10</CId>      <Note>c10</Note>    </Chi>    <Chi>      <CId>11</CId>      <Note>c11</Note>    </Chi>  </Par>  <Par>    <Id>2</Id>    <Name>two</Name>    <Chi>      <CId>20</CId>      <Note>c20</Note>    </Chi>  </Par></Root>');
        Observer.Expect('trace', 'PreXmlPort par=2 chi=3;Hdr.BeforePassVariable;Par.PreXmlItem count=2;Par.AfterGetRecord=1;Par.Id.BeforePassField=1;Chi.PreXmlItem count=2;Chi.AfterGetRecord=10;Chi.Id.BeforePassField=10;Chi.AfterGetRecord=11;Chi.Id.BeforePassField=11;Par.AfterGetRecord=2;Par.Id.BeforePassField=2;Chi.PreXmlItem count=1;Chi.AfterGetRecord=20;Chi.Id.BeforePassField=20;PostXmlPort par=2 chi=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TriggerOrder_EmptyTables()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Log.Take();
        Observer.Observe('xml', ExportText());
        Observer.Observe('trace', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Hdr>h</Hdr>  <Par>    <Id>0</Id>    <Name />  </Par></Root>');
        Observer.Expect('trace', 'PreXmlPort par=0 chi=0;Hdr.BeforePassVariable;Par.PreXmlItem count=0;Par.Id.BeforePassField=0;Chi.PreXmlItem count=0;PostXmlPort par=0 chi=0;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TriggerOrder_NewRows()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        Log.Take();
        ImportText('<Root><Hdr>h</Hdr><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>c10</Note></Chi><Chi><CId>11</CId><Note>c11</Note></Chi></Par><Par><Id>2</Id><Name>two</Name></Par></Root>');
        Observer.Observe('trace', Log.Take());
        Observer.Observe('par_after', Format(Par.Count()));
        Observer.Observe('chi_after', Format(Chi.Count()));
        Observer.Expect('trace', 'PreXmlPort par=0 chi=0;Hdr.AfterAssignVariable=h;Par.AfterInitRecord;Par.Id.AfterAssignField=1;Par.BeforeInsertRecord=1/one;Par.AfterInsertRecord=1;Chi.AfterInitRecord;Chi.Id.AfterAssignField=10;Chi.BeforeInsertRecord=10/1;Chi.AfterInsertRecord=10;Chi.AfterInitRecord;Chi.Id.AfterAssignField=11;Chi.BeforeInsertRecord=11/0;Chi.AfterInsertRecord=11;Par.BeforeModifyRecord=1/one;Par.AfterModifyRecord=1;Par.AfterInitRecord;Par.Id.AfterAssignField=2;Par.BeforeInsertRecord=2/two;Par.AfterInsertRecord=2;PostXmlPort par=2 chi=2;');
        Observer.Expect('par_after', '2');
        Observer.Expect('chi_after', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TriggerOrder_ExistingRows()
    var
        Par: Record "LT XT Parent";
        Chi: Record "LT XT Child";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        ImportText('<Root><Hdr>h</Hdr><Par><Id>1</Id><Name>changed</Name><Chi><CId>10</CId><Note>n10</Note></Chi></Par></Root>');
        Observer.Observe('trace', Log.Take());
        Par.Get(1);
        Observer.Observe('par1_name', Par.Name);
        Chi.Get(10);
        Observer.Observe('chi10_note', Chi.Note);
        Observer.Observe('par_after', Format(Par.Count()));
        Observer.Observe('chi_after', Format(Chi.Count()));
        Observer.Expect('trace', 'PreXmlPort par=2 chi=3;Hdr.AfterAssignVariable=h;Par.AfterInitRecord;Par.Id.AfterAssignField=1;Par.BeforeModifyRecord=1/changed;Par.AfterModifyRecord=1;Chi.AfterInitRecord;Chi.Id.AfterAssignField=10;Chi.BeforeModifyRecord=10;Chi.AfterModifyRecord=10;Par.BeforeModifyRecord=1/changed;Par.AfterModifyRecord=1;PostXmlPort par=2 chi=3;');
        Observer.Expect('par1_name', 'changed');
        Observer.Expect('chi10_note', 'n10');
        Observer.Expect('par_after', '2');
        Observer.Expect('chi_after', '3');
        Observer.Verify();
    end;

    // Tests of the nested-import objects in RcXmlPortNestedImport.al (tables 87860-87862, xmlports 87863-87865, runner 87866).
    local procedure RcWipe()
    var
        Par: Record "LT RC Par";
        Chi: Record "LT RC Chi";
        GChi: Record "LT RC GChi";
        Log: Codeunit "LT XT Log";
    begin
        Par.DeleteAll();
        Chi.DeleteAll();
        GChi.DeleteAll();
        Commit();
        Log.Take();
    end;

    local procedure RcRun(XmlportId: Integer; Xml: Text): Text
    var
        Runner: Codeunit "LT RC Import Runner";
    begin
        Commit();
        Runner.SetArgs(XmlportId, Xml);
        if Runner.Run() then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RcRows(): Text
    var
        Par: Record "LT RC Par";
        Chi: Record "LT RC Chi";
        GChi: Record "LT RC GChi";
        Txt: Text;
    begin
        if Par.FindSet() then
            repeat
                Txt += 'P' + Format(Par.Id) + '/' + Par.Name + ';';
            until Par.Next() = 0;
        if Chi.FindSet() then
            repeat
                Txt += 'C' + Format(Chi.Id) + '/' + Format(Chi.ParentId) + '/' + Chi.Note + ';';
            until Chi.Next() = 0;
        if GChi.FindSet() then
            repeat
                Txt += 'G' + Format(GChi.Id) + '/' + Format(GChi.ChildId) + '/' + GChi.Note + ';';
            until GChi.Next() = 0;
        exit(Txt);
    end;

    [Test]
    procedure NoAutoReplace_NewParentTwoChildren()
    var
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp NoAR", '<Root><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>a</Note></Chi><Chi><CId>11</CId><Note>b</Note></Chi></Par><Par><Id>2</Id><Name>two</Name></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'ok');
        Observer.Expect('trace', 'P.init;P.bi=1/one;tP+1/one;P.ai=1;C.init;C.bi=10/1;tC+10/1/a;C.ai=10;C.init;C.bi=11/0;tC+11/0/b;C.ai=11;P.bm=1/one;tP~1/one;P.am=1;P.init;P.bi=2/two;tP+2/two;P.ai=2;');
        Observer.Expect('rows', 'P1/one;P2/two;C10/1/a;C11/0/b;');
        Observer.Verify();
    end;

    [Test]
    procedure NoAutoReplace_ExistingParentWithChild()
    var
        Par: Record "LT RC Par";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Par.Id := 1;
        Par.Name := 'old';
        Par.Insert();
        Commit();
        Log.Take();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp NoAR", '<Root><Par><Id>1</Id><Name>new</Name><Chi><CId>10</CId><Note>a</Note></Chi></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'error:The record in table LT RC Par already exists. Identification fields and values: Id=''1''|DB:RecordExists');
        Observer.Expect('trace', 'P.init;P.bi=1/new;tP+1/new;P.ai=1;C.init;C.bi=10/1;tC+10/1/a;C.ai=10;');
        Observer.Expect('rows', 'P1/old;');
        Observer.Verify();
    end;

    [Test]
    procedure NoAutoReplace_ExistingParentNoChild()
    var
        Par: Record "LT RC Par";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Par.Id := 1;
        Par.Name := 'old';
        Par.Insert();
        Commit();
        Log.Take();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp NoAR", '<Root><Par><Id>1</Id><Name>new</Name></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'error:The record in table LT RC Par already exists. Identification fields and values: Id=''1''|DB:RecordExists');
        Observer.Expect('trace', 'P.init;P.bi=1/new;tP+1/new;P.ai=1;');
        Observer.Expect('rows', 'P1/old;');
        Observer.Verify();
    end;

    [Test]
    procedure NoAutoReplace_ExistingChildUnderNewParent()
    var
        Chi: Record "LT RC Chi";
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Chi.Id := 10;
        Chi.ParentId := 9;
        Chi.Note := 'old';
        Chi.Insert();
        Commit();
        Log.Take();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp NoAR", '<Root><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>a</Note></Chi></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'error:The record in table LT RC Chi already exists. Identification fields and values: Id=''10''|DB:RecordExists');
        Observer.Expect('trace', 'P.init;P.bi=1/one;tP+1/one;P.ai=1;C.init;C.bi=10/1;tC+10/1/a;C.ai=10;P.bm=1/one;tP~1/one;P.am=1;');
        Observer.Expect('rows', 'C10/9/old;');
        Observer.Verify();
    end;

    [Test]
    procedure ThreeLevels_NoAutoReplace()
    var
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp Three", '<Root><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>a</Note><G><GId>100</GId><GNote>x</GNote></G><G><GId>101</GId><GNote>y</GNote></G></Chi><Chi><CId>11</CId><Note>b</Note></Chi></Par><Par><Id>2</Id><Name>two</Name><Chi><CId>20</CId><Note>c</Note><G><GId>200</GId><GNote>z</GNote></G></Chi></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'ok');
        Observer.Expect('trace', 'P.bi=1/one;tP+1/one;P.ai=1;C.bi=10/1;tC+10/1/a;C.ai=10;G.bi=100/10;tG+100/10/x;G.ai=100;G.bi=101/0;tG+101/0/y;G.ai=101;C.bm=10;tC~10/1/a;C.am=10;C.bi=11/0;tC+11/0/b;C.ai=11;P.bm=1/one;tP~1/one;P.am=1;P.bi=2/two;tP+2/two;P.ai=2;C.bi=20/2;tC+20/2/c;C.ai=20;G.bi=200/20;tG+200/20/z;G.ai=200;C.bm=20;tC~20/2/c;C.am=20;P.bm=2/two;tP~2/two;P.am=2;');
        Observer.Expect('rows', 'P1/one;P2/two;C10/1/a;C11/0/b;C20/2/c;G100/10/x;G101/0/y;G200/20/z;');
        Observer.Verify();
    end;

    [Test]
    procedure TempChild_AutoReplace()
    var
        Log: Codeunit "LT XT Log";
        Observer: Codeunit "Probe Observer";
    begin
        RcWipe();
        Observer.Observe('result', RcRun(Xmlport::"LT RC Imp TempChi", '<Root><Par><Id>1</Id><Name>one</Name><Chi><CId>10</CId><Note>a</Note></Chi><Chi><CId>10</CId><Note>b</Note></Chi><Chi><CId>11</CId><Note>c</Note></Chi></Par><Par><Id>2</Id><Name>two</Name><Chi><CId>11</CId><Note>d</Note></Chi></Par></Root>'));
        Observer.Observe('trace', Log.Take());
        Observer.Observe('rows', RcRows());
        Observer.Expect('result', 'ok');
        Observer.Expect('trace', 'P.bi=1/one;tP+1/one;P.ai=1;C.bi=10/1/a;C.ai=10/1/a;C.bm=10/b;C.am=10/b;C.bi=11/0/c;C.ai=11/0/c;P.bm=1/one;tP~1/one;P.am=1;P.bi=2/two;tP+2/two;P.ai=2;C.bm=11/d;C.am=11/d;P.bm=2/two;tP~2/two;P.am=2;post filter=;tmp=10/0/b;tmp=11/2/d;');
        Observer.Expect('rows', 'P1/one;P2/two;');
        Observer.Verify();
    end;
}
