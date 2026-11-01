// Probe: TextBuilder.Append (and AppendLine, Insert, Replace) of a Guid: a Guid field, a Guid parameter, a Guid read from lower-case text,
// a Guid in a Variant; the built text then used as a filter on the Guid field.
// Gap cycle 5, spec G5-09 (writer Y49). Object ids: table 92942, codeunit 92942.
// Fixtures used: Probe Observer (codeunit 69160).

table 92942 "LT Y49 Guid Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; G; Guid) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 92942 "LT Y49 TB Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y49 Guid Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Evaluate(Row.G, '{3f2504e0-4f89-11d3-9a0c-0305e82c3301}');
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Evaluate(Row.G, '{0A1B2C3D-0000-1111-2222-333344445555}');
        Row.Insert();
    end;

    local procedure AddId(var TB: TextBuilder; Id: Guid)
    begin
        TB.Append(Id);
    end;

    local procedure Ids(var Row: Record "LT Y49 Guid Row"): Text
    var
        Res: Text;
    begin
        if Row.FindSet() then
            repeat
                Res += Format(Row.Id) + ';';
            until Row.Next() = 0;
        exit(Res);
    end;

    [Test]
    procedure TbAppendGuid_Field_Filter()
    var
        Row: Record "LT Y49 Guid Row";
        Found: Record "LT Y49 Guid Row";
        TB: TextBuilder;
        Filter: Text;
    begin
        Seed();
        Row.SetFilter(Id, '1|3');
        if Row.FindSet() then
            repeat
                TB.Append(Row.G);
                TB.Append('|');
            until Row.Next() = 0;
        Filter := TB.ToText().TrimEnd('|');
        Observer.Observe('two rows text', TB.ToText());
        Found.SetFilter(G, Filter);
        Observer.Observe('two rows filter', Found.GetFilter(G));
        Observer.Observe('two rows count', Format(Found.Count()));
        Observer.Observe('two rows ids', Ids(Found));
        Clear(TB);
        Row.Reset();
        if Row.FindSet() then
            repeat
                TB.Append(Row.G);
                TB.Append('|');
            until Row.Next() = 0;
        Observer.Observe('all rows text', TB.ToText());
        Found.Reset();
        ClearLastError();
        if TrySetFilter(Found, TB.ToText().TrimEnd('|')) then begin
            Observer.Observe('all rows count', Format(Found.Count()));
            Observer.Observe('all rows ids', Ids(Found));
        end else begin
            Observer.Observe('all rows count', 'raised');
            Observer.ObserveError('all rows filter');
        end;
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySetFilter(var Found: Record "LT Y49 Guid Row"; Filter: Text)
    begin
        Found.SetFilter(G, Filter);
    end;

    [Test]
    procedure TbAppendGuid_Parameter()
    var
        Row: Record "LT Y49 Guid Row";
        TB: TextBuilder;
        G: Guid;
    begin
        Seed();
        Row.Get(1);
        G := Row.G;
        AddId(TB, G);
        TB.Append('|');
        Row.Get(2);
        AddId(TB, Row.G);
        Observer.Observe('param', TB.ToText());
        Observer.Observe('length', Format(TB.Length()));
        Observer.Finish();
    end;

    [Test]
    procedure TbAppendLineGuid_Insert()
    var
        Row: Record "LT Y49 Guid Row";
        TB: TextBuilder;
        Lf: Text[1];
        Cr: Text[1];
    begin
        Seed();
        Row.Get(3);
        Cr[1] := 13;
        Lf[1] := 10;
        TB.AppendLine(Row.G);
        Observer.Observe('appendline', TB.ToText().Replace(Cr, '<CR>').Replace(Lf, '<LF>'));
        Clear(TB);
        TB.Append('x');
        TB.Insert(2, Row.G);
        Observer.Observe('insert', TB.ToText());
        Clear(TB);
        TB.Append('a ' + Format(Row.G) + ' b');
        TB.Replace(Format(Row.G), 'G');
        Observer.Observe('replace format', TB.ToText());
        Clear(TB);
        TB.Append('a {0A1B2C3D-0000-1111-2222-333344445555} b');
        TB.Replace(Row.G, 'G');
        Observer.Observe('replace guid as old', TB.ToText());
        Clear(TB);
        TB.Append('a-b');
        TB.Replace('-', Row.G);
        Observer.Observe('replace guid as new', TB.ToText());
        Observer.Finish();
    end;

    [Test]
    procedure TbAppendGuid_Case()
    var
        Row: Record "LT Y49 Guid Row";
        TB: TextBuilder;
        G: Guid;
    begin
        Seed();
        Row.Get(1);
        TB.Append(Row.G);
        Observer.Observe('field from lower text', TB.ToText());
        Evaluate(G, '3f2504e0-4f89-11d3-9a0c-0305e82c3301');
        Clear(TB);
        TB.Append(G);
        Observer.Observe('var from lower text no braces', TB.ToText());
        Clear(TB);
        Clear(G);
        TB.Append(G);
        Observer.Observe('empty', TB.ToText());
        Observer.Finish();
    end;

    [Test]
    procedure TbAppendGuid_Variant()
    var
        Row: Record "LT Y49 Guid Row";
        TB: TextBuilder;
        V: Variant;
    begin
        Seed();
        Row.Get(1);
        V := Row.G;
        ClearLastError();
        if TryAppendVariant(TB, V) then
            Observer.Observe('variant', '[' + TB.ToText() + ']')
        else begin
            Observer.Observe('variant', 'raised');
            Observer.ObserveError('variant');
        end;
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAppendVariant(var TB: TextBuilder; V: Variant)
    begin
        TB.Append(V);
    end;
}
