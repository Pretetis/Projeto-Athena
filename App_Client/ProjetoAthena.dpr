program ProjetoAthena;

uses
  System.StartUpCopy,
  FMX.Forms,
  uLogin in 'Units\uLogin.pas' {fLogin},
  FMX.frame.PopUpToast in 'Auxiliares\FMX.frame.PopUpToast.pas' {FramePopUp: TFrame},
  uLoading in 'Auxiliares\uLoading.pas',
  uConnection in 'Modulos\uConnection.pas',
  uParametros in 'Modulos\uParametros.pas',
  uRequests in 'Modulos\uRequests.pas',
  uMenu in 'Units\uMenu.pas' {fMenu},
  uTelaUtils in 'Modulos\uTelaUtils.pas',
  uFormConfig in 'Modulos\uFormConfig.pas',
  frame.Menu_Dashboard in 'Frames\frame.Menu_Dashboard.pas' {FrameMenuDashboard: TFrame},
  frame.Menu_LinhaTabelaAlerta in 'Frames\frame.Menu_LinhaTabelaAlerta.pas' {FrameLinhaPlanilhaAlerta: TFrame},
  uDesignSystem in 'Modulos\uDesignSystem.pas',
  frame.Documentos in 'Frames\frame.Documentos.pas' {FrameDocumentos: TFrame},
  frame.Documentos_LinhaTabelaDocumentos in 'Frames\frame.Documentos_LinhaTabelaDocumentos.pas' {FrameLinhaPlanilhaDocumento: TFrame},
  modal.AdicionarDocumento in 'Modais\modal.AdicionarDocumento.pas' {FrameModalEnivarDocumento: TFrame},
  uCatalogos in 'Modulos\uCatalogos.pas',
  modal.VisualizarDocumento in 'Modais\modal.VisualizarDocumento.pas' {FrameVisualizarDocumento: TFrame},
  modal.AlterarDocumento in 'Modais\modal.AlterarDocumento.pas' {FrameAlterarDocumento: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfLogin, fLogin);
  Application.CreateForm(TfMenu, fMenu);
  Application.Run;
end.
