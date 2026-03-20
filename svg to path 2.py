import re

def format_delphi_path(path_string):
    if not path_string:
        return ""

    pattern = re.compile(r'([a-zA-Z])|([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)')
    formatted_parts = []
    
    for match in pattern.finditer(path_string):
        command = match.group(1)
        number = match.group(2)
        
        if command:
            formatted_parts.append(command)
        elif number:
            if number.startswith('.'):
                number = '0' + number
            elif number.startswith('-.'):
                number = '-0.' + number[2:]
            elif number.startswith('+.'):
                number = '+0.' + number[2:]
            
            formatted_parts.append(number)
            
    return ' '.join(formatted_parts)

def main():
    print("==================================================")
    print("  FORMATADOR DE PATHS SVG PARA DELPHI 10.3")
    print("==================================================")
    print("Instruções:")
    print("- Cole apenas a string (ex: M0,0...)")
    print("- OU cole a tag inteira (ex: <path d=\"M0,0...\" />)")
    print("- Digite 'sair' para encerrar o programa.")
    print("==================================================\n")

    while True:
        try:
            # Aguarda você colar o código no terminal
            entrada = input("👉 Cole o SVG/Path aqui: ").strip()
            
            # Condição de parada
            if entrada.lower() == 'sair':
                print("Encerrando o formatador. Até mais!")
                break
                
            if not entrada:
                continue
                
            # Verifica se você colou a tag inteira procurando por d="..."
            match_d = re.search(r'd=["\']([^"\']+)["\']', entrada)
            
            if match_d:
                path_original = match_d.group(1)
            else:
                # Se não achar o d="", assume que você colou o path direto
                path_original = entrada
                
            # Formata o path
            path_formatado = format_delphi_path(path_original)
            
            # Imprime o resultado de forma destacada
            print("\n✅ PATH FORMATADO:")
            print("-" * 60)
            print(path_formatado)
            print("-" * 60)
            print("Pronto para o próximo! (ou digite 'sair')\n")
            
        except KeyboardInterrupt:
            # Trata o caso de você apertar Ctrl+C no terminal
            print("\nEncerrando o formatador. Até mais!")
            break
        except Exception as e:
            print(f"\n❌ Ocorreu um erro: {e}\n")

if __name__ == "__main__":
    main()