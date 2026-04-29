# Matrix Grey

[![Build](https://github.com/tardelli013/matrix-grey-screensaver-mac/actions/workflows/build.yml/badge.svg)](https://github.com/tardelli013/matrix-grey-screensaver-mac/actions/workflows/build.yml)

Protetor de tela para macOS no estilo Matrix, em escala de cinza.
Bundle `.saver` nativo escrito em Swift sobre o framework `ScreenSaver`,
com configurador próprio (CLI ou `.app`).

## Pré-requisitos

- macOS 13 (Ventura) ou superior, Apple Silicon
- Xcode Command Line Tools (`xcode-select --install`)

Não precisa do Xcode.app — o build usa `swiftc` direto.

## Targets do Makefile

```bash
make build        # compila o screensaver em build/MatrixGrey.saver
make install      # copia o screensaver para ~/Library/Screen Savers/
make reinstall    # clean + install
make configure    # abre o configurador como app CLI (janela GUI)
make app          # empacota MatrixGreyConfig.app em build/
make install-app  # instala MatrixGreyConfig.app em ~/Applications/
make uninstall    # remove o .saver e o .app instalados (preferências ficam)
make purge        # uninstall + apaga preferências + clean
make clean        # remove build/
```

Tanto o screensaver quanto o configurador são assinados ad-hoc
(`codesign -s -`), suficiente para rodar localmente. Não distribuível —
para isso seria preciso um Developer ID.

## Instalando o protetor de tela

```bash
make install
```

Depois:

1. **Ajustes do Sistema → Protetor de Tela**
2. Selecione **"Matrix Grey"** na lista (pode estar numa seção tipo
   "Other"/"Outros" no macOS Sonoma+)
3. Se aparecer aviso de desenvolvedor não identificado, vá em
   **Privacidade e Segurança** e clique em **Permitir**

## Configurando

> **Importante:** o macOS 26 (Tahoe) removeu o botão "Opções…" do
> painel Screen Saver para `.saver` legados de terceiros. Por isso este
> projeto inclui um configurador próprio que usa exatamente a mesma
> janela que apareceria como sheet em versões anteriores do macOS.

Há duas formas de abrir o configurador.

### Pelo terminal

```bash
make configure
```

Compila (se ainda não tiver compilado) e abre a janela. Feche-a para sair.

### Como app no Finder/Spotlight

```bash
make install-app
```

Instala `MatrixGreyConfig.app` em `~/Applications/`. Depois abra por
Spotlight (`⌘Space` → "Matrix Grey Config") ou pelo Finder. Pode
arrastar pro Dock também.

### O que o configurador expõe

| Parâmetro    | Range          | Default      | Efeito                                  |
|--------------|----------------|--------------|-----------------------------------------|
| Head color   | color picker   | white 0.95   | Cor do glifo na frente da coluna        |
| Glow color   | color picker   | white 0.72   | Cor do glifo logo atrás da cabeça       |
| Trail fade   | 0.02 – 0.20    | 0.07         | Quão rápido a trilha desaparece         |
| Font size    | 8 – 28 pt      | 16 pt        | Tamanho do glifo (afeta densidade)      |
| Frame rate   | 15 – 60 fps    | 21 fps       | Velocidade base da animação (mais baixo = letras caem mais devagar) |

Os valores são persistidos em
`~/Library/Preferences/com.tardelli.MatrixGrey.plist` via
`ScreenSaverDefaults`. **O screensaver lê os valores ao iniciar** — se
ele já estiver rodando ou em preview no momento da mudança, é preciso
desativar e reativar para puxar os novos valores.

## Troubleshooting

**O protetor não atualiza depois do `make reinstall`.**
O System Settings cacheia o `.saver`. Selecione outro protetor de tela
e volte para "Matrix Grey" para forçar reload.

**`make configure` abre uma janela em branco / não responde.**
Verifique que o build foi limpo (`make clean && make configure`). Se
persistir, execute o binário diretamente para ver o stderr:
`./build/MatrixGreyConfig`.

**"Cannot be opened because the developer cannot be verified."**
Esperado pela assinatura ad-hoc. Em **Privacidade e Segurança** vai
aparecer um botão "Permitir mesmo assim".

**Quero resetar tudo para os defaults.**
```bash
defaults delete com.tardelli.MatrixGrey
```

## Desinstalar

```bash
make uninstall   # remove o .saver e o .app instalados (mantém preferências)
make purge       # remove tudo: .saver, .app, preferências e build/
```

`make purge` é o "limpar completamente" — depois dele não sobra nenhum
vestígio do projeto na máquina (fora os arquivos-fonte do repo).

## Estrutura do projeto

```
matrix-grey/
├── Sources/
│   ├── MatrixGreyView.swift          # ScreenSaverView subclass
│   ├── MatrixColumn.swift            # estado por coluna
│   ├── Glyphs.swift                  # alfabeto de glifos
│   ├── Settings.swift                # wrapper de ScreenSaverDefaults
│   └── ConfigureWindowController.swift  # janela compartilhada (sheet + standalone)
├── Configurator/
│   └── main.swift                    # entry point do MatrixGreyConfig
├── Resources/
│   ├── Info.plist                    # bundle do .saver
│   └── Configurator-Info.plist       # bundle do .app
└── Makefile
```

`Settings.swift` e `ConfigureWindowController.swift` são compartilhados
pelos dois alvos (o `.saver` e o `MatrixGreyConfig`).
