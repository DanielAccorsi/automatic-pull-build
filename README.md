# `.pulls` — pull e deploy em lote

Scripts para rodar **git pull** em vários repositórios Git dentro de uma mesma estrutura e, em seguida, **Maven `clean install`** onde existir `pom.xml`.

## Estrutura esperada

Coloque a pasta **`.pulls`** (ou outro nome que você colocou na pasta) no **mesmo nível** das pastas dos projetos (não dentro de cada repo). O script usa o **diretório pai** de `.pulls` como base:

```text
projetos/
├── .pulls/
│   ├── git-pull-and-deploy.sh
│   ├── projetos-list.sh
│   └── README.md
├── projeto 1/
├── projeto 2/
├── projeto 3/
└── ...
```

Cada nome em `projetos-list.sh` deve ser uma pasta contendo um clone Git dos projetos.

## Lista de projetos

Os nomes dos repositórios ficam no arquivo **`projetos-list.sh`** (array `PROJETOS`). Edite esse arquivo para incluir ou remover projetos; o script principal apenas importa a lista com `source`.

## Como executar

No **Linux**, **macOS** ou **Git Bash** no Windows (precisa de `bash`, `git` e `mvn` no `PATH`):

```bash
cd /caminho/para/projetos/.pulls
bash git-pull-and-deploy.sh
```

Opcionalmente, marque como executável e chame direto:

```bash
chmod +x git-pull-and-deploy.sh
./git-pull-and-deploy.sh
```

## O que o script faz

1. **Fase 1 — Git:** em cada projeto, executa `git pull origin desenvolvimento`. O projeto `ecigaintegrationmap` usa `git pull origin` (sem nome de branch). O script **não** faz `checkout` automático: o pull integra o remoto na **branch em que você estiver** naquele repositório.
2. **Fase 2 — Maven:** em pastas que tenham `pom.xml`, roda `mvn clean install` (com exceções já definidas no script para alguns projetos).

Se algum pull falhar, a execução **para** naquele projeto.

## Relatório

Ao final, o script imprime falhas de deploy (se houver), um resumo da **fase 1** (quantos projetos receberam atualização e quantos arquivos mudaram entre o commit antes e depois do pull) e os **tempos** de pull e Maven.

## Requisitos

- Bash (pode ser o GitBash integrado ao Git)
- Git
- Maven (`mvn`), para a fase 2
