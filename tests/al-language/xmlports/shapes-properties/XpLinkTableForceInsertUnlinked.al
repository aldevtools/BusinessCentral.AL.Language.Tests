// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktableforceinsert-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables "LT Y68 XP Parent" (93656) and "LT Y68 XP Child" (93657), log codeunit "LT Y68 XP Log" (93661)
//   and xmlport "LT Y68 XP Link NoForce" (93658, the control) from Y68XmlPortShapes.al; own xmlports 75073-75079, test codeunit 75080
// local object: the schemas of the ports are what is under test
// Probe (observe only): al-runner issue 7441. Y68XmlPortShapes.al pins LinkTableForceInsert = true on a linked table element. This probe asks what the
//   property does where no LinkTable is set:
//     Root Force       a table element below the root text element with LinkTableForceInsert = true and no LinkTable; its child table element has
//                      LinkTable, LinkFields and LinkTableForceInsert = true (the reported shape)
//     Root Force Plain the same parent; the child has LinkTable and LinkFields only
//     Child Unlinked   a nested table element with LinkTableForceInsert = true and neither LinkTable nor LinkFields
//     Root Force Only  a table element with LinkTableForceInsert = true and no child table element
//     Force False      LinkTableForceInsert = false on the parent (no LinkTable) and on the linked child
//     Text Force       Format = VariableText, the table element with LinkTableForceInsert = true
//   Import (two parents with children, a parent without children, a parent that exists already, an empty root) and export, each next to the control port without
//   the property on the parent. The insert triggers log whether the parent row is in the database when the child is inserted.
// BC versions: 27, 28, 29

xmlport 75073 "LT XLF Root Force"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;
                LinkTableForceInsert = true;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");
                    LinkTableForceInsert = true;

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No.") + ' parent in db=' + Format(ParentExists(P."No.")));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('child air ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75074 "LT XLF Root Force Plain"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;
                LinkTableForceInsert = true;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No.") + ' parent in db=' + Format(ParentExists(P."No.")));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('child air ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75075 "LT XLF Child Unlinked"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTableForceInsert = true;

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No.") + ' parent in db=' + Format(ParentExists(P."No.")));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('child air ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75076 "LT XLF Root Force Only"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;
                LinkTableForceInsert = true;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75077 "LT XLF Force False"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;
                LinkTableForceInsert = false;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");
                    LinkTableForceInsert = false;

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No.") + ' parent in db=' + Format(ParentExists(P."No.")));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('child air ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75078 "LT XLF Control"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                XmlName = 'P';
                MinOccurs = Zero;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { MinOccurs = Zero; }
                tableelement(C; "LT Y68 XP Child")
                {
                    XmlName = 'C';
                    MinOccurs = Zero;
                    LinkTable = P;
                    LinkFields = "Parent No." = field("No.");

                    fieldelement(Line; C."Line No.") { }
                    fieldelement(Amount; C.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('child bir ' + C."Parent No." + '/' + Format(C."Line No.") + ' parent in db=' + Format(ParentExists(P."No.")));
                    end;

                    trigger OnAfterInsertRecord()
                    begin
                        Log.Add('child air ' + C."Parent No." + '/' + Format(C."Line No."));
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No." + ' in db=' + Format(ParentExists(P."No.")));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure ParentExists(No: Code[10]): Boolean
    var
        Stored: Record "LT Y68 XP Parent";
    begin
        exit(Stored.Get(No));
    end;
}

xmlport 75079 "LT XLF Text Force"
{
    Direction = Both;
    Format = VariableText;
    TextEncoding = UTF16;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(P; "LT Y68 XP Parent")
            {
                LinkTableForceInsert = true;

                fieldelement(No; P."No.") { }
                fieldelement(Name; P.Name) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('parent bir ' + P."No.");
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('parent air ' + P."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y68 XP Log";
}

codeunit 75080 "LT XLF Force Insert Unlinked"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y68 XP Log";

    local procedure Clean()
    var
        P: Record "LT Y68 XP Parent";
        C: Record "LT Y68 XP Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        Log.Take();
        ClearLastError();
    end;

    local procedure AddParent(No: Code[10]; Name: Text[30])
    var
        P: Record "LT Y68 XP Parent";
    begin
        P."No." := No;
        P.Name := Name;
        P.Insert();
    end;

    local procedure AddChild(ParentNo: Code[10]; LineNo: Integer; Amount: Decimal)
    var
        C: Record "LT Y68 XP Child";
    begin
        C."Parent No." := ParentNo;
        C."Line No." := LineNo;
        C.Amount := Amount;
        C.Insert();
    end;

    local procedure ParentRows() Result: Text
    var
        P: Record "LT Y68 XP Parent";
    begin
        if P.FindSet() then
            repeat
                Result += '[' + P."No." + '|' + P.Name + ']';
            until P.Next() = 0;
    end;

    local procedure ChildRows() Result: Text
    var
        C: Record "LT Y68 XP Child";
    begin
        if C.FindSet() then
            repeat
                Result += '[' + C."Parent No." + '/' + Format(C."Line No.") + '/' + Format(C.Amount, 0, 9) + ']';
            until C.Next() = 0;
    end;

    [TryFunction]
    local procedure TryExport(XmlportId: Integer; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
    end;

    [TryFunction]
    local procedure TryImport(XmlportId: Integer; Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        if XmlportId = Xmlport::"LT XLF Text Force" then begin
            TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
            OutS.WriteText(Content);
            TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        end else begin
            TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
            OutS.WriteText(Content);
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        end;
        Xmlport.Import(XmlportId, InS);
    end;

    local procedure ObserveImport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; Content: Text; ExistingParent: Code[10])
    begin
        Clean();
        if ExistingParent <> '' then
            AddParent(ExistingParent, 'stored');
        if TryImport(XmlportId, Content) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' parents', ParentRows());
        Observer.Observe(Name + ' children', ChildRows());
    end;

    local procedure ObserveImports(var Observer: Codeunit "Probe Observer"; XmlportId: Integer; Part: Integer)
    begin
        if Part = 1 then begin
            ObserveImport(Observer, 'two parents', XmlportId,
                '<Root><P><No>P1</No><Name>one</Name><C><Line>1</Line><Amount>5</Amount></C><C><Line>2</Line><Amount>6</Amount></C></P><P><No>P2</No><Name>two</Name><C><Line>1</Line><Amount>7</Amount></C></P></Root>', '');
            ObserveImport(Observer, 'no children', XmlportId, '<Root><P><No>P1</No><Name>one</Name></P></Root>', '');
        end else begin
            ObserveImport(Observer, 'parent exists', XmlportId, '<Root><P><No>P1</No><Name>one</Name><C><Line>1</Line><Amount>5</Amount></C></P></Root>', 'P1');
            ObserveImport(Observer, 'empty root', XmlportId, '<Root />', '');
        end;
    end;

    local procedure ObserveExport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer)
    var
        Result: Text;
    begin
        Clean();
        AddParent('P1', 'one');
        AddParent('P2', 'two');
        AddChild('P1', 10, 1.5);
        AddChild('P1', 20, 2);
        AddChild('P9', 10, 9);
        if TryExport(XmlportId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure ForceOnUnlinkedParent_LinkedForcedChild_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Root Force", 1);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedParent_LinkedForcedChild_Import_ParentExists_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Root Force", 2);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedParent_LinkedChild_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Root Force Plain", 1);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedParent_LinkedChild_Import_ParentExists_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Root Force Plain", 2);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedNestedChild_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Child Unlinked", 1);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedNestedChild_Import_ParentExists_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Child Unlinked", 2);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinkedParent_NoChildTable_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'two parents', Xmlport::"LT XLF Root Force Only", '<Root><P><No>P1</No><Name>one</Name></P><P><No>P2</No></P></Root>', '');
        ObserveImport(Observer, 'parent exists already', Xmlport::"LT XLF Root Force Only", '<Root><P><No>P1</No><Name>one</Name></P></Root>', 'P1');
        Observer.Finish();
    end;

    [Test]
    procedure ForceFalse_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Force False", 1);
        Observer.Finish();
    end;

    [Test]
    procedure ForceFalse_Import_ParentExists_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Force False", 2);
        Observer.Finish();
    end;

    [Test]
    procedure NoForce_Import_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Control", 1);
        Observer.Finish();
    end;

    [Test]
    procedure NoForce_Import_Control_ParentExists_EmptyRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImports(Observer, Xmlport::"LT XLF Control", 2);
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinked_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExport(Observer, 'root force', Xmlport::"LT XLF Root Force");
        ObserveExport(Observer, 'root force plain child', Xmlport::"LT XLF Root Force Plain");
        ObserveExport(Observer, 'child unlinked', Xmlport::"LT XLF Child Unlinked");
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnUnlinked_Export_OtherPorts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveExport(Observer, 'root force only', Xmlport::"LT XLF Root Force Only");
        ObserveExport(Observer, 'force false', Xmlport::"LT XLF Force False");
        ObserveExport(Observer, 'control', Xmlport::"LT XLF Control");
        Observer.Finish();
    end;

    [Test]
    procedure ForceOnTableElement_VariableText()
    var
        Observer: Codeunit "Probe Observer";
        CrLf: Text[2];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        ObserveImport(Observer, 'text import', Xmlport::"LT XLF Text Force", '"P1","one"' + CrLf + '"P2","two"' + CrLf, '');
        ObserveImport(Observer, 'text import parent exists', Xmlport::"LT XLF Text Force", '"P1","one"' + CrLf, 'P1');
        ObserveExport(Observer, 'text export', Xmlport::"LT XLF Text Force");
        Observer.Finish();
    end;
}
