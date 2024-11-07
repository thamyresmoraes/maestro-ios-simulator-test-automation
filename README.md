# maestro-ios-simulator-test-automation
# iOS Simulator Test Automation

Este repositório contém um script em Bash para automatizar a execução de testes em simuladores iOS. O script faz o seguinte:
- Inicializa simuladores iOS específicos.
- Atualiza o repositório de código.
- Executa o build do aplicativo com Flutter.
- Instala o aplicativo nos simuladores.
- Executa testes automatizados com o Maestro.

## Pré-requisitos

Antes de usar este script, você precisará garantir que os seguintes softwares estão instalados:

- **Git**: Para controle de versão e atualização do repositório.
- **Flutter**: Necessário para compilar o aplicativo iOS.
- **Xcode**: Necessário para os simuladores iOS.
- **Maestro**: Para a execução dos testes automatizados.

## Configuração

### 1. Clone o Repositório

```bash
git clone https://github.com/thamyresmoraes/ios-simulator-test-automation.git
cd ios-simulator-test-automation
```

### 2. Configure o Script
- **Edite o arquivo scripts/run_ios_tests.sh e substitua os placeholders com as informações corretas:**

PROJECT_DIR: Caminho para o diretório do projeto iOS.
SIMULATOR_IDS: IDs dos simuladores que deseja usar para os testes. Você pode encontrar os IDs dos simuladores executando xcrun simctl list.
Branch Git: Substitua a branch no comando git pull origin develop caso você esteja usando uma branch diferente.

### 3. Conceder Permissões ao Script
Dê permissão de execução ao script:

```bash
chmod +x scripts/run_ios_tests.sh
```
### Uso

Para rodar o script manualmente, execute o seguinte comando:

```bash

./scripts/run_ios_tests.sh
```
