program ProjetoAthena;

{$R *.dres}

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
  uCatalogos in 'Modulos\uCatalogos.pas',
  card.Colaborador in 'Cards\card.Colaborador.pas' {FrameCardFuncionario: TFrame},
  card.Maquina in 'Cards\card.Maquina.pas' {FrameCardMaquina: TFrame},
  uGemini in 'Modulos\uGemini.pas',
  uMenuMobile in 'Units\uMenuMobile.pas' {fMenuMobile},
  uDesignSystem in 'Modulos\uDesignSystem.pas' {DesignSystem: TDataModule},
  frame.Menu_Dashboard in 'Frames\Dashboard\frame.Menu_Dashboard.pas' {FrameMenuDashboard: TFrame},
  frame.Menu_LinhaTabelaAlerta in 'Frames\Dashboard\frame.Menu_LinhaTabelaAlerta.pas' {FrameLinhaPlanilhaAlerta: TFrame},
  frame.Documentos in 'Frames\Documentos\frame.Documentos.pas' {FrameDocumentos: TFrame},
  frame.Documentos_LinhaTabelaDocumentos in 'Frames\Documentos\frame.Documentos_LinhaTabelaDocumentos.pas' {FrameLinhaPlanilhaDocumento: TFrame},
  frame.Maquina in 'Frames\Maquinas\frame.Maquina.pas' {FrameMaquinas: TFrame},
  frame.TelaFuncionario in 'Frames\Perfil\frame.TelaFuncionario.pas' {fTelaFuncionario: TFrame},
  frame.TelaFuncionario_LinhaTabelaFuncionario in 'Frames\Perfil\frame.TelaFuncionario_LinhaTabelaFuncionario.pas' {fLinhaTelaFuncionario: TFrame},
  modal.ColaboradorAdicionar in 'Modais\Colaborador\modal.ColaboradorAdicionar.pas' {FrameModalAdicionarFuncionario: TFrame},
  modal.ColaboradorAlterar in 'Modais\Colaborador\modal.ColaboradorAlterar.pas' {FrameAlterarFuncionario: TFrame},
  modal.ColaboradorConfiguracoes in 'Modais\Colaborador\modal.ColaboradorConfiguracoes.pas' {FrameModalConfiguracoesFuncionario: TFrame},
  modal.AdicionarDocumento in 'Modais\Documento\modal.AdicionarDocumento.pas' {FrameModalEnivarDocumento: TFrame},
  modal.AlterarDocumento in 'Modais\Documento\modal.AlterarDocumento.pas' {FrameAlterarDocumento: TFrame},
  modal.VisualizarDocumento in 'Modais\Documento\modal.VisualizarDocumento.pas' {FrameVisualizarDocumento: TFrame},
  modal.ConsentimentoLGPD in 'Modais\LGPD\modal.ConsentimentoLGPD.pas' {FrameModalConsentimentoLGPD: TFrame},
  modal.AdicionarMaquina in 'Modais\Maquina\modal.AdicionarMaquina.pas' {FrameModalAdicionarMaquina: TFrame},
  modal.AlterarMaquina in 'Modais\Maquina\modal.AlterarMaquina.pas' {FrameModalAlterarMaquina: TFrame},
  frame.Colaborador in 'Frames\Colaborador\frame.Colaborador.pas' {FrameColaborador: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfLogin, fLogin);
  Application.CreateForm(TfMenu, fMenu);
  Application.CreateForm(TfMenuMobile, fMenuMobile);
  Application.CreateForm(TDesignSystem, DesignSystem);
  Application.Run;
end.
