// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-export-method
// Scope: in-scope
// Fixtures used: none.
// Writer Y66 (al-runner issue 6657): an export and an import XmlPort of app A, each with a global procedure, used through XmlPort variables of
// the main test app (tests/al-language/xmlport/lt-y66-xmlport-var-members/Y66XmlPortVarMembers.al): the reporter's XmlPort lives in a
// dependency app.

xmlport 61100 "LT Y66 XA XP Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(Flag)
            {
                trigger OnBeforePassVariable()
                begin
                    Flag := Format(MyFlag);
                end;
            }
            tableelement(I; Integer)
            {
                SourceTableView = sorting(Number);
                fieldelement(N; I.Number) { }
            }
        }
    }

    var
        MyFlag: Boolean;

    procedure MyProc(NewFlag: Boolean)
    begin
        MyFlag := NewFlag;
    end;

    procedure GetFlag(): Boolean
    begin
        exit(MyFlag);
    end;
}

xmlport 61101 "LT Y66 XA XP Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(N)
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;

                trigger OnAfterAssignVariable()
                begin
                    Got += N + ';';
                end;
            }
        }
    }

    var
        Got: Text;

    procedure GetGot(): Text
    begin
        exit(Got);
    end;
}
