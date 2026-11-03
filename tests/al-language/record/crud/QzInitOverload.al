// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "LT RcB Init" (RcBInit.al): tables 87688 and 87709.
// Facts: a table procedure Init(A; B) next to the built-in Init(): which one a qualified Rec.Init() and Rec.Init(1, 'x') call from outside,
//   and which one a bare Init() and Init(1, 'x') call from code of the table itself.
//   Table 87709 declares Init() with the built-in's own signature: which one Row.Init(), a bare Init() and Rec.Init() inside the table call.

table 87688 "LT QZ Init Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Num; Integer) { InitValue = 7; }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Init(A: Integer; B: Text)
    begin
        Rec.Init();
        Rec.Num := A;
        Rec.Name := CopyStr('own ' + B, 1, MaxStrLen(Rec.Name));
    end;

    procedure CallBareInit()
    begin
        Init();
    end;

    procedure CallBareInitWithArguments()
    begin
        Init(5, 'inner');
    end;
}

// A table procedure Init() with the built-in's exact signature (the compiler accepts it).
table 87709 "LT QZ Init Hide"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Num; Integer) { InitValue = 7; }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure Init()
    begin
        Name := 'own Init()';
    end;

    procedure CallBareInit()
    begin
        Init();
    end;

    procedure CallRecInit()
    begin
        Rec.Init();
    end;
}
