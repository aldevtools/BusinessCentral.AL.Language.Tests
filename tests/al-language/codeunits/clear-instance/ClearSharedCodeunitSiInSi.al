// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); "CKK Row" (table 86270) of ClearSharedCodeunitGlobalKinds.al; self-contained objects 86660 to 86686
// Probe: SingleInstance codeunits nested in SingleInstance codeunits, reached from a register whose owner calls ClearAll (al-runner issue 8964), observed first, then asserted.
// singleinstance-shared-on-purpose: the subject is a SingleInstance codeunit held by a SingleInstance codeunit nested in a register that ClearAll resets.
// BC versions: 27, 28, 29
codeunit 86660 "CSS a L0"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS a L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86661 "CSS a L1"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86662 "CSS a Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS a L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86663 "CSS a Own1"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSS a Reg";
        After: Text;
        AskAfter: Text;

    trigger OnRun()
    begin
        ClearAll();
        After := Reg.State();
        AskAfter := Reg.Ask();
        Reg.Register();
    end;

    procedure SetReg(var R: Codeunit "CSS a Reg")
    begin
        Reg := R;
    end;

    procedure ObservePost(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('owner.after', After);
        Observer.Observe('owner.ask', AskAfter);
    end;
}

codeunit 86664 "CSS a Own2"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSS a Reg";
        After: Text;
        AskAfter: Text;

    trigger OnRun()
    begin
        ClearAll();
        After := Reg.State();
        AskAfter := Reg.Ask();
        Reg.Register();
    end;

    procedure SetReg(var R: Codeunit "CSS a Reg")
    begin
        Reg := R;
    end;

    procedure ObservePost(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('owner.after', After);
        Observer.Observe('owner.ask', AskAfter);
    end;
}

codeunit 86665 "CSS b L0"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS b L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86666 "CSS b L1"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86667 "CSS b Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS b L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86668 "CSS c L0"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS c L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86669 "CSS c L1"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86670 "CSS c Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS c L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86671 "CSS d L0"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS d L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86672 "CSS d L1"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS d L2";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86673 "CSS d L2"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86674 "CSS d Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS d L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86675 "CSS d Own1"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSS d Reg";
        After: Text;
        AskAfter: Text;

    trigger OnRun()
    begin
        ClearAll();
        After := Reg.State();
        AskAfter := Reg.Ask();
        Reg.Register();
    end;

    procedure SetReg(var R: Codeunit "CSS d Reg")
    begin
        Reg := R;
    end;

    procedure ObservePost(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('owner.after', After);
        Observer.Observe('owner.ask', AskAfter);
    end;
}

codeunit 86676 "CSS e L0"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS e L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86677 "CSS e L1"
{

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS e L2";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86678 "CSS e L2"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86679 "CSS e Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS e L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86680 "CSS e Own1"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSS e Reg";
        After: Text;
        AskAfter: Text;

    trigger OnRun()
    begin
        ClearAll();
        After := Reg.State();
        AskAfter := Reg.Ask();
        Reg.Register();
    end;

    procedure SetReg(var R: Codeunit "CSS e Reg")
    begin
        Reg := R;
    end;

    procedure ObservePost(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('owner.after', After);
        Observer.Observe('owner.ask', AskAfter);
    end;
}

codeunit 86681 "CSS f L0"
{

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS f L1";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86682 "CSS f L1"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;
        Child: Codeunit "CSS f L2";

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
        Child.Prime(V + 1);
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState() + ' | ' + Child.State());
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86683 "CSS f L2"
{
    SingleInstance = true;

    var
        N: Integer;
        T: Text;
        Rec: Record "CKK Row";
        L: List of [Text];
        D: Dictionary of [Text, Integer];
        Flag: Boolean;

    procedure Prime(V: Integer)
    begin
        N := V;
        T := 't' + Format(V);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := V;
        Rec.Txt := 'ROW' + Format(V);
        Rec.Insert();
        Rec.SetRange("No.", V, V + 5);
        Rec.FindFirst();
        L.Add('a' + Format(V));
        D.Add('k', V);
        Flag := true;
    end;

    procedure SetN(V: Integer)
    begin
        N := V;
    end;

    procedure OwnState(): Text
    begin
        exit(StrSubstNo('n=%1 t=%2 filt=%3 row=%4 list=%5 dict=%6 flag=%7', N, T, Rec.GetFilters(), Rec.Txt, L.Count(), D.Count(), Flag));
    end;

    procedure State(): Text
    begin
        exit(OwnState());
    end;

    procedure Ask(): Text
    begin
        exit(Format(Flag));
    end;

    procedure ClearMe()
    begin
        ClearAll();
    end;
}

codeunit 86684 "CSS f Reg"
{
    TableNo = "CKK Row";

    var
        Child: Codeunit "CSS f L0";
        Entry: Integer;
        Tag: Text;

    trigger OnRun()
    begin
        Entry := Rec."No.";
    end;

    procedure Prime(V: Integer)
    begin
        Entry := 5;
        Tag := 'reg';
        Child.Prime(V);
    end;

    procedure Register()
    begin
        Entry += 1;
    end;

    procedure State(): Text
    begin
        exit(StrSubstNo('entry=%1 tag=%2 :: %3', Entry, Tag, Child.State()));
    end;

    procedure Ask(): Text
    begin
        exit(Child.Ask());
    end;

    procedure ClearChild()
    begin
        Child.ClearMe();
    end;
}

codeunit 86685 "CSS f Own1"
{
    TableNo = "CKK Row";

    var
        Reg: Codeunit "CSS f Reg";
        After: Text;
        AskAfter: Text;

    trigger OnRun()
    begin
        ClearAll();
        After := Reg.State();
        AskAfter := Reg.Ask();
        Reg.Register();
    end;

    procedure SetReg(var R: Codeunit "CSS f Reg")
    begin
        Reg := R;
    end;

    procedure ObservePost(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('owner.after', After);
        Observer.Observe('owner.ask', AskAfter);
    end;
}

codeunit 86686 "CSS Nested SI SI Test"
{
    Subtype = Test;

    [Test]
    procedure Si2_OwnerClearAll_ThenSecondOwner()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS a Reg";
        V0: Codeunit "CSS a L0";
        V1: Codeunit "CSS a L1";
        Own1: Codeunit "CSS a Own1";
        Own2: Codeunit "CSS a Own2";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Observer.Observe('prime', Reg.State());
        Observer.Observe('ask.before', Reg.Ask());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        Observer.Observe('ask.caller', Reg.Ask());
        Own2.SetReg(Reg);
        Own2.Run(Row);
        Observer.Observe('second.after', Reg.State());
        Observer.Observe('second.L0', V0.OwnState());
        Observer.Observe('second.L1', V1.OwnState());
        Observer.Observe('second.ask', Reg.Ask());
        Reg.Register();
        Observer.Observe('caller.next', Reg.State());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure Si3_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS d Reg";
        V0: Codeunit "CSS d L0";
        V1: Codeunit "CSS d L1";
        V2: Codeunit "CSS d L2";
        Own1: Codeunit "CSS d Own1";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Observer.Observe('prime', Reg.State());
        Observer.Observe('ask.before', Reg.Ask());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        Observer.Observe('direct.L2', V2.OwnState());
        Observer.Observe('ask.caller', Reg.Ask());
        Reg.Register();
        Observer.Observe('caller.next', Reg.State());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        V2.SetN(902);
        Observer.Observe('link.L2', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure SiPlainSi_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS e Reg";
        V0: Codeunit "CSS e L0";
        V1: Codeunit "CSS e L1";
        V2: Codeunit "CSS e L2";
        Own1: Codeunit "CSS e Own1";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Observer.Observe('prime', Reg.State());
        Observer.Observe('ask.before', Reg.Ask());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        Observer.Observe('direct.L2', V2.OwnState());
        Observer.Observe('ask.caller', Reg.Ask());
        Reg.Register();
        Observer.Observe('caller.next', Reg.State());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        V2.SetN(902);
        Observer.Observe('link.L2', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure PlainSiSi_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS f Reg";
        V0: Codeunit "CSS f L0";
        V1: Codeunit "CSS f L1";
        V2: Codeunit "CSS f L2";
        Own1: Codeunit "CSS f Own1";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Observer.Observe('prime', Reg.State());
        Observer.Observe('ask.before', Reg.Ask());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        Observer.Observe('direct.L2', V2.OwnState());
        Observer.Observe('ask.caller', Reg.Ask());
        Reg.Register();
        Observer.Observe('caller.next', Reg.State());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        V2.SetN(902);
        Observer.Observe('link.L2', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure Si2_OwnerClearAll_Unprimed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS a Reg";
        V0: Codeunit "CSS a L0";
        V1: Codeunit "CSS a L1";
        Own1: Codeunit "CSS a Own1";
        Own2: Codeunit "CSS a Own2";
    begin
        Row."No." := 7;
        Observer.Observe('prime', Reg.State());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure Si2_WrittenByDirectLeaf_OwnerClearAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS a Reg";
        V0: Codeunit "CSS a L0";
        V1: Codeunit "CSS a L1";
        Own1: Codeunit "CSS a Own1";
        Own2: Codeunit "CSS a Own2";
    begin
        Row."No." := 7;
        V1.Prime(20);
        Observer.Observe('pre.reg', Reg.State());
        Own1.SetReg(Reg);
        Own1.Run(Row);
        Own1.ObservePost(Observer);
        Observer.Observe('caller.after', Reg.State());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure Si2_ClearRegisterVar()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS b Reg";
        V0: Codeunit "CSS b L0";
        V1: Codeunit "CSS b L1";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Clear(Reg);
        Observer.Observe('clear.reg', Reg.State());
        Observer.Observe('clear.ask', Reg.Ask());
        Observer.Observe('direct.L0', V0.OwnState());
        Observer.Observe('direct.L1', V1.OwnState());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        Observer.Finish();
    end;

    [Test]
    procedure Si2_ClearAllInsideSi()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CKK Row";
        Reg: Codeunit "CSS c Reg";
        V0: Codeunit "CSS c L0";
        V1: Codeunit "CSS c L1";
    begin
        Row."No." := 7;
        Reg.Prime(10);
        Reg.ClearChild();
        Observer.Observe('mid.clearall.reg', Reg.State());
        Observer.Observe('direct1.L0', V0.OwnState());
        Observer.Observe('direct1.L1', V1.OwnState());
        Observer.Observe('ask.1', Reg.Ask());
        Reg.Prime(30);
        V1.ClearMe();
        Observer.Observe('leaf.clearall.reg', Reg.State());
        Observer.Observe('direct2.L0', V0.OwnState());
        Observer.Observe('direct2.L1', V1.OwnState());
        Observer.Observe('ask.2', Reg.Ask());
        V0.SetN(900);
        Observer.Observe('link.L0', Reg.State());
        V1.SetN(901);
        Observer.Observe('link.L1', Reg.State());
        Observer.Finish();
    end;
}
