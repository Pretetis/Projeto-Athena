import re
import sys

def formatar_path_delphi(path_data):
    """
    Formata o conteúdo de um único 'd' com os espaços e zeros
    necessários para o TPath do Delphi FMX.
    """
    padrao = r'[a-zA-Z]|[-+]?\d*\.\d+|[-+]?\d+'
    tokens = re.findall(padrao, path_data)
    
    tokens_corrigidos = []
    for token in tokens:
        if not token.isalpha():
            # Corrige decimais sem zero
            if token.startswith('.'):
                token = '0' + token
            elif token.startswith('-.'):
                token = '-0.' + token[2:]
        tokens_corrigidos.append(token)
    
    return ' '.join(tokens_corrigidos)

def main():
    print("--- Conversor de SVG Completo para Delphi FMX ---")
    print("Cole todo o código <svg> ... </svg> abaixo.")
    print("Quando terminar de colar, pressione Enter, depois Ctrl+Z (no Windows) ou Ctrl+D (Mac/Linux) e Enter para converter:\n")
    
    # Lê tudo o que for colado no terminal até receber o sinal de fim de arquivo (EOF)
    svg_completo = sys.stdin.read()
    
    if not svg_completo.strip():
        print("\nNenhum código foi inserido.")
        return

    # Regex para encontrar tudo que está dentro do atributo d="..." nas tags path
    # O re.IGNORECASE e re.DOTALL ajudam caso o SVG esteja em várias linhas
    paths_extraidos = re.findall(r'<path[^>]*?d\s*=\s*["\'](.*?)["\']', svg_completo, re.IGNORECASE | re.DOTALL)
    
    if not paths_extraidos:
        print("\n[ERRO] Nenhuma tag <path> com o atributo 'd' foi encontrada.")
        return

    # Formata cada path encontrado e junta todos em uma única string gigante
    paths_formatados = [formatar_path_delphi(p) for p in paths_extraidos]
    resultado_final = ' '.join(paths_formatados)
    
    print("\n" + "="*60)
    print("CÓDIGO PRONTO PARA O DELPHI (Cole na propriedade Data):")
    print("="*60 + "\n")
    print(resultado_final)
    print("\n" + "="*60)

if __name__ == "__main__":
    main()