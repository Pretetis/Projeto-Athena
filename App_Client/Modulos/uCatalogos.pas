unit uCatalogos;

// Armazena os catálogos carregados no início da sessão.
// Acesso global via arrays paralelos: Ids[i] <-> Nomes[i]

interface

var
  // Funcionários
  CatFuncionariosIds  : TArray<string>;
  CatFuncionariosNomes: TArray<string>;

  // Máquinas
  CatMaquinasIds  : TArray<string>;
  CatMaquinasNomes: TArray<string>;

  // Empresas
  CatEmpresasIds  : TArray<string>;
  CatEmpresasNomes: TArray<string>;

// Preenche os arrays a partir de um TJSONArray com objetos {_id, nome/razaoSocial}
procedure PreencherCatalogo(
  const AJSON       : string;
  const ACampoNome  : string;       // 'nome' ou 'razaoSocial'
  var   AIds, ANomes: TArray<string>
);

implementation

uses
  System.JSON, System.SysUtils;

procedure PreencherCatalogo(
  const AJSON      : string;
  const ACampoNome : string;
  var   AIds, ANomes: TArray<string>
);
var
  LArr : TJSONArray;
  LObj : TJSONObject;
  I, N : Integer;
begin
    AIds   := [];
    ANomes := [];

    LArr := TJSONObject.ParseJSONValue(AJSON) as TJSONArray;
    if not Assigned(LArr) then Exit;
    try
        N := LArr.Count;
        SetLength(AIds,   N);
        SetLength(ANomes, N);

        for I := 0 to N - 1 do
        begin
            LObj     := LArr.Items[I] as TJSONObject;
            AIds[I]  := LObj.GetValue<string>('_id');
            ANomes[I]:= LObj.GetValue<string>(ACampoNome);
        end;
    finally
        LArr.Free;
    end;
end;

end.
