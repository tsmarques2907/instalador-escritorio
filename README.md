# Automação de Instalação e Padronização de Estações de Trabalho

Este repositório contém uma solução de automação em **PowerShell** e **Batch Script** projetada para otimizar o processo de provisionamento e padronização de computadores corporativos. 

O script realiza a verificação de softwares pré-existentes, realiza instalações silenciosas em segundo plano via `winget` e instaladores locais, aplica configurações no Registro do Windows e padroniza a identidade visual da máquina.

---

## Tecnologias e Linguagens Utilizadas

- **Windows PowerShell (`.ps1`)**: Lógica principal da automação, manipulação de registros, interface de menu, funções de verificação e geração de logs.
- **Batch Script (`.bat`)**: Lançador e inicializador responsável por elevar privilégios de Administrador e contornar restrições de execução (`ExecutionPolicy Bypass`).
- **Windows Package Manager (`winget`)**: Gerenciador de pacotes para download e instalação silenciosa de softwares.

---

## Softwares e Configurações Gerenciadas

1. **Papel de Parede & Tela de Bloqueio**: Aplicação da imagem institucional via API nativa (`user32.dll`) e chaves de registro.
2. **Google Chrome**: Download silencioso, definição como navegador padrão e implantação forçada da extensão *Loy Trust*.
3. **Microsoft Edge**: Configuração de políticas de grupo e implantação forçada da extensão *Loy Trust*.
4. **AnyDesk**: Instalação e validação via pacote `winget`.
5. **Google Drive**: Instalação silenciosa do cliente desktop.
6. **Microsoft 365 (Office)**: Instalação via `winget` com *fallback* automático para o instalador Web corporativo (`setup.exe` + `configuration.xml` dinâmico).
7. **OpenVPN Connect**: Instalação do cliente de VPN.
8. **Bitdefender**: Localização dinâmica e execução do instalador corporativo a partir do diretório local/pendrive (por ser um instalador de terceiros, não o coloquei neste repositório).
9. **Windows Update**: Configuração de repositórios, instalação do módulo `PSWindowsUpdate` e varredura/aplicação de atualizações de sistema.

---

## Requisitos do Sistema

- **Windows 10 ou Windows 11** (arquitetura x64).
- **Privilégios de Administrador** no sistema operacional.
- Conexão ativa com a **Internet** (para downloads via Winget e Windows Update).
- **Winget (Windows Package Manager)** instalado e atualizado.

---

## Como Utilizar

### Método Recomendado (Via Lançador Batch)
1. Baixe a versão mais recente do repositório ou clone o projeto em uma pasta local (ou pendrive de suporte):
   ```bash
   git clone [https://github.com/tsmarques2907/instalador-escritorio.git](https://github.com/tsmarques2907/instalador-escritorio.git)
