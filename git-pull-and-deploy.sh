#!/bin/bash
# Script: git pull em todos os projetos e opcionalmente deploy Maven (clean install)
# Uso: coloque o script dentro de uma pasta junto com as outras pastas dos projetos GIT
# Por Daniel Accorsi - Update: 06/03/2026 (com auxilio de IA)

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/projetos-list.sh"
BRANCH="desenvolvimento"

echo "=============================================="
echo "  Pull / Deploy de todos os projetos"
echo "  Por Daniel Accorsi - com auxílio de IA"
echo "=============================================="
echo ""
echo "  FASE 1: Git Pull em todos os projetos"
echo "  Diretório base: $BASE_DIR"
echo "=============================================="

PULL_START=$(date +%s)
for projeto in "${PROJETOS[@]}"; do
    dir="$BASE_DIR/$projeto"
    if [[ -d "$dir" ]]; then
        echo ""
        echo ">>> Entrando em: $projeto"
        if [[ $projeto == "ecigaintegrationmap" ]]; then
            BRANCH="" 
        else
            BRANCH="desenvolvimento"
        fi
        echo "+ cd \"$dir\""
        #echo "+ git checkout $BRANCH"
        echo "+ git pull origin $BRANCH"
        #if ! (cd "$dir" && git checkout $BRANCH && git pull origin $BRANCH); then
        if ! (cd "$dir" && git pull origin $BRANCH); then
            echo "*** Falha no pull: $projeto. Abortando execução."
            exit 1
        fi
    else
        echo "*** Diretório não encontrado: $projeto ($dir). Abortando execução."
        exit 1
    fi
done
PULL_END=$(date +%s)

echo ""
echo "=============================================="
echo "  Fase 1 (Git Pull) concluída."
echo "=============================================="
echo ""
#read -p "Deseja entrar na fase 2 (deploy Maven clean install)? [s/N] " resposta
#resposta="${resposta:-n}"
#if [[ ! "$resposta" =~ ^[sS]$ ]]; then
#    echo "Fase 2 cancelada. Até mais."
#    exit 0
#fi

echo ""
echo "=============================================="
echo "  FASE 2: Maven clean install em cada projeto"
echo "=============================================="

FALHAS_DEPLOY=()
MAVEN_START=$(date +%s)
for projeto in "${PROJETOS[@]}"; do
    dir="$BASE_DIR/$projeto"
    if [[ -d "$dir" ]] && [[ -f "$dir/pom.xml" ]]; then
        echo ""
        echo ">>> Deploy: $projeto"
        if [[ $projeto == "econtab" ]]; then
            if ! (cd "$dir" && mvn clean install -Dadditionalparam=-Xdoclint:none); then
                echo "*** Falha no deploy: $projeto"
                FALHAS_DEPLOY+=("$projeto")
            fi
        elif [[ $projeto == "ejuridico" || $projeto == "erestfulspring" ]]; then
            if ! (cd "$dir" && mvn clean install -DskipTests); then
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
echo "=============================================="
echo "  Fase 2 (Deploy) concluída."
echo "=============================================="
echo ""
echo "=============================================="
echo "  RELATÓRIO - Projetos com falha no deploy"
echo "=============================================="
if [[ ${#FALHAS_DEPLOY[@]} -eq 0 ]]; then
    echo "  Nenhum."
else
    for p in "${FALHAS_DEPLOY[@]}"; do
        echo "  - $p"
    done
fi
echo "=============================================="
echo ""
echo "=============================================="
echo "  TEMPOS DE EXECUÇÃO"
echo "=============================================="
PULL_DUR=$((PULL_END - PULL_START))
MAVEN_DUR=$((MAVEN_END - MAVEN_START))
PULL_MIN=$((PULL_DUR / 60))
PULL_SEC=$((PULL_DUR % 60))
MAVEN_MIN=$((MAVEN_DUR / 60))
MAVEN_SEC=$((MAVEN_DUR % 60))
printf "  Git Pull (todos): %d min %d s\n" "$PULL_MIN" "$PULL_SEC"
printf "  Maven (todos):   %d min %d s\n" "$MAVEN_MIN" "$MAVEN_SEC"
echo "=============================================="
