#!/bin/bash
# Script: git pull em todos os projetos e opcionalmente deploy Maven (clean install)
# Uso: coloque o script dentro de uma pasta junto com as outras pastas dos projetos GIT
# Por Daniel Accorsi - Update: 06/03/2026 (com auxilio de IA)

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/projetos-list.sh"
# Projetos que receberam commits novos no pull (Fase 1) e quantidade de arquivos tocados
PROJETOS_ALTERADOS=()
ARQUIVOS_ALTERADOS=()

echo "=============================================="
echo "  Pull / Deploy de todos os projetos"
echo "  Por Daniel Accorsi - com auxílio de IA"
echo "=============================================="
echo ""
echo "  FASE 1: Git Pull em todos os projetos"
echo "  Diretório base: $BASE_DIR"
echo "=============================================="

PUSH_REPO="cnpjalfa"
PULL_START=$(date +%s)
for projeto in "${PROJETOS[@]}"; do
    dir="$BASE_DIR/$projeto"
    if [[ -d "$dir" ]]; then
        echo ""
        echo ">>> Entrando em: $projeto"
        if [[ $projeto == "ecigaintegrationmap" ]]; then
            branch_pull=""
        else
            branch_pull="desenvolvimento"
        fi
        echo "+ cd \"$dir\""
        echo "+ git pull origin $branch_pull"
        pushd "$dir" >/dev/null || {
            echo "*** Não foi possível entrar em: $dir. Abortando execução."
            exit 1
        }
        old_head=$(git rev-parse HEAD 2>/dev/null) || old_head=""
        if ! git pull origin $branch_pull; then
            popd >/dev/null
            echo "*** Falha no pull: $projeto. Abortando execução."
            exit 1
        fi
        new_head=$(git rev-parse HEAD)
        if [[ -n "$old_head" && "$old_head" != "$new_head" ]]; then
            num_arquivos=$(git diff --name-only "$old_head" "$new_head" 2>/dev/null | wc -l)
            num_arquivos=$(echo "$num_arquivos" | tr -d ' \t\r\n')
            PROJETOS_ALTERADOS+=("$projeto")
            ARQUIVOS_ALTERADOS+=("$num_arquivos")
        fi
        
        # Pega a branch atual e verificar se é a cnpjalfa
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ "$current_branch" == "$PUSH_REPO" ]]; then

            # Faz um pull na branch cnpjalfa para garantir que pegou os ultimos commits
            # Tem mais de um dev trabalhando com essa branch
            echo "+ git pull origin $PUSH_REPO"
            if ! git pull origin $PUSH_REPO; then
                popd >/dev/null
                echo "*** Falha no pull: $projeto para a branch $PUSH_REPO. Abortando execução."
                exit 1
            fi
            
            # Faz um push automatico para a branch se houve merge local da outra branch
            echo "+ git push origin $PUSH_REPO"
            if ! git push origin $PUSH_REPO; then
                popd >/dev/null
                echo "*** Falha no push: $projeto para a branch $PUSH_REPO. Abortando execução."
                exit 1
            fi
        fi
        popd >/dev/null
    else
        echo "*** Diretório não encontrado: $projeto ($dir). Abortando execução."
        exit 1
    fi
done
PULL_END=$(date +%s)

echo ""
echo "======================================================================"
echo "  Fase 1 (Git Pull) concluída."
echo "======================================================================"
echo ""
#read -p "Deseja entrar na fase 2 (deploy Maven clean install)? [s/N] " resposta
#resposta="${resposta:-n}"
#if [[ ! "$resposta" =~ ^[sS]$ ]]; then
#    echo "Fase 2 cancelada. Até mais."
#    exit 0
#fi

echo ""
echo "======================================================================"
echo "  FASE 2: Maven clean install em cada projeto"
echo "======================================================================"

FALHAS_DEPLOY=()
MAVEN_START=$(date +%s)
for projeto in "${PROJETOS[@]}"; do
    dir="$BASE_DIR/$projeto"
    if [[ -d "$dir" ]] && [[ -f "$dir/pom.xml" ]]; then
        echo ""
        echo ">>> Deploy: $projeto"
        PARAMETROS_CUSTOM=""
        PARAMS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/custom-maven-params.txt"
        if [[ -f "$PARAMS_FILE" ]]; then
            PARAMETROS_CUSTOM=$(grep "^$projeto=" "$PARAMS_FILE" | cut -d'=' -f2-)
        fi

        if [[ -n "$PARAMETROS_CUSTOM" ]]; then
            echo "    -> Usando parâmetros customizados: $PARAMETROS_CUSTOM"
            if ! (cd "$dir" && mvn clean install $PARAMETROS_CUSTOM); then
                echo "*** Falha no deploy: $projeto"
                FALHAS_DEPLOY+=("$projeto")
            fi
        else
            if ! (cd "$dir" && mvn clean install); then
                echo "*** Falha no deploy: $projeto"
                FALHAS_DEPLOY+=("$projeto")
            fi
        fi
    elif [[ -d "$dir" ]]; then
        echo "*** Pulando $projeto (sem pom.xml)"
    else
        echo "*** Diretório não encontrado: $projeto"
    fi
done
MAVEN_END=$(date +%s)

echo ""
echo "======================================================================"
echo "  Fase 2 (Deploy) concluída."
echo "======================================================================"
echo ""
echo "======================================================================"
echo "  RELATÓRIO - Projetos com falha no deploy"
echo "======================================================================"
if [[ ${#FALHAS_DEPLOY[@]} -eq 0 ]]; then
    echo "  Nenhum."
else
    for p in "${FALHAS_DEPLOY[@]}"; do
        echo "  - $p"
    done
fi
echo "======================================================================"
echo ""
echo "======================================================================"
echo "  RELATÓRIO - Fase 1 Git (atualizações do remoto)"
echo "======================================================================"
TOTAL_COM_ALTERACAO=${#PROJETOS_ALTERADOS[@]}
echo "  Total de projetos com alteração (novo commit após pull): $TOTAL_COM_ALTERACAO"
if [[ $TOTAL_COM_ALTERACAO -eq 0 ]]; then
    echo "  Detalhe: nenhum — repositórios já estavam alinhados com o remoto."
else
    for i in "${!PROJETOS_ALTERADOS[@]}"; do
        echo "  - ${PROJETOS_ALTERADOS[$i]}: ${ARQUIVOS_ALTERADOS[$i]} arquivo(s) alterado(s)"
    done
fi
echo "======================================================================"
echo ""
echo "======================================================================"
echo "  TEMPOS DE EXECUÇÃO"
echo "======================================================================"
PULL_DUR=$((PULL_END - PULL_START))
MAVEN_DUR=$((MAVEN_END - MAVEN_START))
PULL_MIN=$((PULL_DUR / 60))
PULL_SEC=$((PULL_DUR % 60))
MAVEN_MIN=$((MAVEN_DUR / 60))
MAVEN_SEC=$((MAVEN_DUR % 60))
printf "  Git Pull (todos): %d min %d s\n" "$PULL_MIN" "$PULL_SEC"
printf "  Maven (todos):   %d min %d s\n" "$MAVEN_MIN" "$MAVEN_SEC"
echo "======================================================================"
