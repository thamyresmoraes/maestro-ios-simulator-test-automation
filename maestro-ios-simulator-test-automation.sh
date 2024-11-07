#!/bin/bash

# Configuração de tentativas e tempo limite de inicialização do Maestro Driver
MAX_ATTEMPTS=3
export MAESTRO_DRIVER_STARTUP_TIMEOUT=60000

# Caminho para o diretório do projeto e IDs dos simuladores
PROJECT_DIR="/path/to/your/project"  # Substitua pelo caminho do projeto
APP_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PROJECT_DIR/ios/Runner/Info.plist")
SHARDS=4
SIMULATOR_IDS=(
  "SIMULATOR_ID_1" # iPhone 11 Pro Max
  "SIMULATOR_ID_2" # iPhone 12 Pro
  "SIMULATOR_ID_3" # iPhone 13 Pro
  "SIMULATOR_ID_4" # iPhone 14 Pro
)
RETRY_LIMIT=3  # Número máximo de tentativas para inicializar cada simulador

# Cores para os logs
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Iniciar o cronômetro
SECONDS=0

# Variáveis de controle de status
BUILD_FINISHED=false
SIMULATORS_READY=false

# Função para verificar se todos os simuladores estão "Booted"
check_simulator_status() {
  echo -e "${CYAN}🔍 Verificando status dos simuladores...${RESET}"
  for SIMULATOR_ID in "${SIMULATOR_IDS[@]}"; do
    attempts=0
    while [[ $(xcrun simctl list | grep "$SIMULATOR_ID" | grep -c "(Booted)") -eq 0 ]]; do
      echo -e "${YELLOW}⌛ Aguardando inicialização do simulador $SIMULATOR_ID... (Tentativa $((attempts + 1))/$RETRY_LIMIT)${RESET}"
      sleep 10
      attempts=$((attempts + 1))
      if [[ $attempts -ge $RETRY_LIMIT ]]; then
        echo -e "${RED}⚠️  Falha ao inicializar o simulador $SIMULATOR_ID após $RETRY_LIMIT tentativas. Reiniciando...${RESET}"
        xcrun simctl shutdown "$SIMULATOR_ID" 2>/dev/null
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null
        attempts=0
        sleep 20
      fi
    done
    echo -e "${GREEN}✅ Simulador $SIMULATOR_ID inicializado com sucesso!${RESET}"
  done
  SIMULATORS_READY=true
}

# Limpar simuladores e inicializar
initialize_simulators() {
  echo -e "${CYAN}🧹 Desligando e limpando todos os simuladores...${RESET}"
  for SIMULATOR_ID in "${SIMULATOR_IDS[@]}"; do
    xcrun simctl shutdown "$SIMULATOR_ID" 2>/dev/null || true
    xcrun simctl erase "$SIMULATOR_ID"
  done

  echo -e "${CYAN}🚀 Inicializando os simuladores...${RESET}"
  for SIMULATOR_ID in "${SIMULATOR_IDS[@]}"; do
    xcrun simctl boot "$SIMULATOR_ID"
  done
  open -a "Simulator"
  sleep 10
  check_simulator_status  # Executa a verificação de status dos simuladores
}

# Verificar atualizações no repositório e realizar build do app
check_for_updates_and_build() {
  cd "$PROJECT_DIR" || exit
  echo -e "${CYAN}🔄 Ignorando alterações locais e atualizando o repositório...${RESET}"

  git reset --hard
  git clean -fd
  git pull origin develop  # Substitua "develop" pela branch desejada, se necessário

  echo -e "${CYAN}🔨 Iniciando o build do app com Flutter...${RESET}"
  flutter build ios --debug --simulator --flavor dev --dart-define="ENABLE_CLEVERTAP=false" -t lib/app/env/dev/develop_main.dart

  if [ ! -d "$PROJECT_DIR/build/ios/iphonesimulator/Runner.app" ]; then
    echo -e "${RED}❌ Erro: O app não foi encontrado no caminho esperado.${RESET}"
    exit 1
  fi
  echo -e "${GREEN}✅ Build do app concluído com sucesso!${RESET}"
  BUILD_FINISHED=true
}

# Instalar o app nos simuladores quando o build e os simuladores estiverem prontos
install_app_if_ready() {
  while [[ $BUILD_FINISHED == false || $SIMULATORS_READY == false ]]; do
    echo -e "${YELLOW}⏳ Aguardando a conclusão do build e a inicialização dos simuladores...${RESET}"
    sleep 5
  done

  echo -e "${CYAN}📲 Instalando o app em todos os simuladores...${RESET}"
  for SIMULATOR_ID in "${SIMULATOR_IDS[@]}"; do
    xcrun simctl install "$SIMULATOR_ID" "$PROJECT_DIR/build/ios/iphonesimulator/Runner.app"
  done
  echo -e "${GREEN}✅ Instalação concluída em todos os simuladores!${RESET}"
}

# Executar testes com Maestro após a instalação
run_tests() {
  for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo -e "${CYAN}🔍 Executando testes com Maestro (Tentativa $attempt)...${RESET}"
    maestro test "$PROJECT_DIR/e2e_test/flows" --shards "$SHARDS"
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ Testes executados com sucesso na tentativa $attempt.${RESET}"
      return 0
    else
      echo -e "${YELLOW}⚠️  Erro na execução dos testes. Tentando novamente em 10 segundos...${RESET}"
      sleep 10
    fi
  done
  echo -e "${RED}❌ Falha na execução dos testes após $MAX_ATTEMPTS tentativas.${RESET}"
}

# Configuração para finalizar o cronômetro e encerrar o script com Ctrl+C
trap cleanup SIGINT SIGTERM

cleanup() {
  echo -e "\n${CYAN}🧹 Finalizando o script...${RESET}"
  ELAPSED_TIME=$(printf "%02d minutos e %02d segundos" $((SECONDS / 60)) $((SECONDS % 60)))
  echo -e "${GREEN}⏱️  Tempo total de execução: $ELAPSED_TIME${RESET}"
  pkill -f "cron-simulator-e2e-mobile.sh" 2>/dev/null
  exit 0
}

# Execução do script em sequência
initialize_simulators  # Inicia a inicialização dos simuladores
check_for_updates_and_build  # Inicia o update e build do app

# Verifica se o build e os simuladores estão prontos para instalar o app
install_app_if_ready

# Executa os testes após a instalação do app
run_tests

# Finalizar o cronômetro e encerrar
cleanup
