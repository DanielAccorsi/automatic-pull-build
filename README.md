# `.pulls` — pull e deploy em lote

Scripts para rodar **git pull** em vários repositórios Git dentro de uma mesma estrutura e, em seguida, **Maven `clean install`** onde existir `pom.xml`.

## Estrutura esperada

Coloque a pasta **`.pulls`** (ou outro nome que você colocou na pasta) no **mesmo nível** das pastas dos projetos (não dentro de cada repo). O script usa o **diretório pai** de `.pulls` como base:

```text
projetos/
├── .pulls/
│   ├── custom-maven-params.txt
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

Essa lista é padrão bash também, e precisa criar uma variável de array:

```bash
#!/bin/bash
PROJETOS=(
  projeto1
  projeto2
  projeto3
)
```

## Parâmetros Maven Customizados

Se alguns projetos exigirem argumentos específicos no build (como pular testes ou ignorar erros de documentação), você pode criar/editar um arquivo chamado **`custom-maven-params.txt`** junto do script principal. 

Cada linha deve ter o formato `projeto=parametros`:

```text
projeto1=-Dadditionalparam=-Xdoclint:none
projeto2=-DskipTests
```

Se o arquivo não existir ou o projeto não estiver listado nele, o build continuará usando o clássico `mvn clean install`.

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

1. **Fase 1 — Git:** em cada projeto, executa `git pull origin desenvolvimento`. O script **não** faz `checkout` automático: o pull integra o remoto na **branch em que você estiver** naquele repositório.
2. **Fase 2 — Maven:** em pastas que tenham `pom.xml`, roda `mvn clean install` (se o projeto tiver uma configuração customizada no arquivo `custom-maven-params.txt`, os parâmetros definidos lá complementarão ou alterarão o comando).

Se algum pull falhar, a execução **para** naquele projeto.

## Relatório

Ao final, o script imprime falhas de deploy (se houver), um resumo da **fase 1** (quantos projetos receberam atualização e quantos arquivos mudaram entre o commit antes e depois do pull) e os **tempos** de pull e Maven.

## Requisitos

- Bash (pode ser o GitBash integrado ao Git)
- Git
- Maven (`mvn`), para a fase 2
