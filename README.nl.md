# Vibe Code voor Home Assistant

[Nederlands](README.nl.md) | [English](README.md)

Draai de [Mistral Vibe Code](https://github.com/mistralai/mistral-vibe) CLI — Mistral's open-source AI-codingagent — direct binnen je Home Assistant-installatie. Een volwaardige AI-assistent in je browser die je Home Assistant-configuratie kan lezen en bewerken, automations kan maken, problemen kan debuggen en je smart home kan beheren.

Geïnspireerd door de [Claude Code-add-on](https://github.com/robsonfelix/robsonfelix-hass-addons) van Robson Felix.

## Functies

- **Volledige Vibe Code CLI** in een webterminal (ttyd), bereikbaar via de Home Assistant-zijbalk via Ingress
- **Smart home bewust** — de werkmap is je Home Assistant-configuratie (`/homeassistant`), zodat Vibe je `configuration.yaml`, automations, dashboards en scripts kan lezen en bewerken
- **Home Assistant MCP-integratie** — Vibe kan entiteiten, states en automaties opvragen en services aanroepen via de `hass-mcp` MCP-server
- **Inloggen met abonnement** — log in met je Mistral-account via `vibe-login`, geen handmatige API-keys nodig
- **Automatische modelontdekking** — nieuwe door Mistral gehoste modellen (zoals Z.ai GLM 5.3) worden bij elke start automatisch geregistreerd, of kies zelf via het `models`-menu
- **Tokenverbruik en kosten** — het ingebouwde `vibe-stats`-commando aggregeert tokenverbruik en geschatte kosten over al je sessies
- **Persistente inloggegevens** — je API-key en Vibe-configuratie staan in `/homeassistant/.vibe` en overleven herstarts, rebuilds en herinstallaties (en zitten in HA-backups)
- **Sessie-persistentie** — terminalsessies draaien in tmux, dus je Vibe-sessie overleeft een browserverversing of gesloten tabblad
- **Configureerbaar** — terminalthema, lettergrootte, werkmap en auto-update-opties
- **Multi-arch** — builds voor amd64, aarch64, armv7, armhf en i386

## Installatie

### Stap 1: Repository toevoegen

1. Ga in Home Assistant naar **Instellingen → Add-ons → Add-on Store**
2. Klik op het **⋮**-menu (rechtsboven) → **Repositories**
3. Voeg toe: `https://github.com/FireStarter75/hass-vibe-addon`
4. Ververs de add-on store

### Stap 2: De add-on installeren

1. Zoek **Vibe Code** in de store en klik erop
2. Klik op **Installeren** (de image wordt gebouwd op HA's build-infrastructuur; dit kan enkele minuten duren)
3. **Start** de add-on
4. Schakel **In zijbalk weergeven** in voor snelle toegang

### Stap 3: Inloggen

Zie [Inloggen](#inloggen) hieronder voor de twee manieren om in te loggen (abonnement of API-key).

## Inloggen

Er zijn twee manieren om te authenticeren. Beide slaan de key op in `/homeassistant/.vibe/.env`, wat blijft bestaan bij herstarts en in HA-backups zit. Dit hoef je maar één keer te doen.

### Optie A: Inloggen met je Mistral-abonnement (aanbevolen)

Gebruik dit om in te loggen met je Mistral-account — het abonnement dat je al betaalt, net als bij de Claude Code-add-on.

1. Open de web-UI van de add-on via de zijbalk
2. Typ `login` (of `vibe-login`) in de terminal
3. Het script print een inlog-URL — selecteer deze in de terminal en kopieer met **Ctrl+Shift+C**
4. Open de URL in een willekeurige browser (op je telefoon of PC), log in met je Mistral-account en keur de Vibe CLI-toegang goed
5. In de add-on-terminal merkt het script vanzelf dat de login is afgerond en slaat de key op

> **Waarom niet `vibe --setup`?** De ingebouwde browser-login van `vibe --setup` kan niet werken in een container (er is geen browser). `vibe-login` draait exact dezelfde Mistral-loginflow, maar print de URL als kopieerbare tekst in plaats van een browser te openen.

### Optie B: Een API-key gebruiken

Werkt met een abonnement, de gratis tier of pay-as-you-go. Haal een key op via **[console.mistral.ai](https://console.mistral.ai)**.

- **Via de add-on-configuratie (gemakkelijkst):** plak de key in de optie `mistral_api_key` (Instellingen → Add-ons → Vibe Code → Configuratie) en herstart. De add-on slaat hem op in `/homeassistant/.vibe/.env` met beperkte rechten (`chmod 600`).
- **Via de terminal:** draai `vibe --setup` en kies de API-key-optie (niet de browserlink). Plakken in een webterminal gaat met **Ctrl+Shift+V** (of rechtermuisklik), niet Ctrl+V.

## Modellen

### Automatische modelontdekking (standaard)

Met de optie `auto_models` aan (standaard: `true`) haalt de add-on bij elke start de actuele modellenlijst op van de Mistral API en registreert nieuwe coding-/agentmodellen automatisch. Voegt Mistral een nieuw model toe (zoals Z.ai GLM 5.3), dan verschijnt het na de eerstvolgende herstart in je `/model`-keuzemenu — zonder handmatige stappen.

### Het `models`-menu (handmatige keuze)

Wil je volledige controle? Draai `models` (of `vibe-models`) in de add-on-terminal:

```
$ models
============================================================
MISTRAL MODELS
============================================================

Al geregistreerd (beschikbaar via /model):
  zai-glm-5-3 *
  mistral-vibe-cli-latest

Beschikbaar op de API maar nog niet geregistreerd:
   1. devstral-small-latest *
   2. magistral-medium-latest
   ...

  * = aanbevolen coding-/agentmodel

Nummers om toe te voegen (komma-gescheiden, 'a' = alles, Enter = stoppen): 1
```

Kies nummers (bijv. `1,3`), `a` voor alles, of Enter om te stoppen. Geregistreerde modellen verschijnen direct in het `/model`-menu van de CLI (draai `/reload` in een actieve sessie).

Overige modi:

- `vibe-models --list` — toon alle modellen die de API momenteel aanbiedt
- `vibe-models --sync` — non-interactief: registreer alle nieuwe aanbevolen codingmodellen

### Het actieve model kiezen

- **Per sessie:** draai `/model` binnen de Vibe CLI en kies uit de lijst
- **Bij het opstarten:** zet de optie `active_model` in de add-on-configuratie op een model-alias (bijv. `glm-5.3`)

### Modellen registreren met volledige details (`extra_models`)

De optie `extra_models` registreert modellen met expliciete instellingen — handig voor prijzen (houdt `vibe-stats` accuraat) of custom providers:

```json
{
  "active_model": "glm-5.3",
  "extra_models": [
    {
      "name": "zai-glm-5-3",
      "alias": "glm-5.3",
      "input_price": 1.4,
      "output_price": 4.4,
      "thinking": "high"
    }
  ]
}
```

- `name` — de model-ID op de provider-API (`zai-glm-5-3` voor door Mistral gehoste GLM 5.3)
- `alias` — de korte naam waarmee je het model kiest
- `input_price` / `output_price` — per miljoen tokens, voor kostenramingen
- `thinking` — reasoning-inspanning: `off`, `low`, `medium`, `high` of `max`
- `provider` — standaard `mistral`; elke OpenAI-compatibele provider werkt

Herstart de add-on na het wijzigen van modelopties.

## Add-on-configuratie

| Optie | Standaard | Omschrijving |
|---|---|---|
| `mistral_api_key` | `""` | Mistral API-key; wordt bij het opstarten opgeslagen in `/homeassistant/.vibe/.env`. Laat leeg als je hebt ingelogd met `vibe-login`. |
| `enable_mcp` | `true` | Registreer de `homeassistant` MCP-server bij Vibe zodat deze entiteiten, states en automations kan opvragen |
| `auto_models` | `true` | Registreer bij het opstarten automatisch nieuwe door Mistral gehoste codingmodellen |
| `active_model` | `""` | Model-alias om bij het opstarten te activeren (bijv. `glm-5.3`). Leeg = CLI-standaard |
| `extra_models` | `[]` | Extra te registreren modellen met expliciete instellingen (zie [Modellen](#modellen)) |
| `terminal_font_size` | `14` | Lettergrootte van de webterminal (10–24) |
| `terminal_theme` | `dark` | `dark` of `light` kleurenschema |
| `working_directory` | `/homeassistant` | Map waar Vibe start |
| `session_persistence` | `true` | Houd de terminalsessie in tmux in stand bij browserverversing |
| `auto_update_vibe` | `false` | Werk de Vibe CLI bij naar de nieuwste release bij het opstarten (de build-versie is geverifieerd, updates niet) |

## Gebruik

Open **Vibe Code** via de zijbalk. Je krijgt een volledige terminal met de Vibe CLI klaar voor gebruik.

### Voorbeelden

Vraag Vibe om je met je smart home te helpen, direct vanuit de terminal:

```text
vibe
> Bekijk mijn configuration.yaml en stel voor hoe ik mijn automations herstructureer
> Maak een automation die alle lichten uitzet als niemand thuis is
> Waarom werkt mijn binary_sensor.front_door niet? Bekijk de logs.
```

Met de MCP-integratie aan kan Vibe ook je draaiende Home Assistant-instance inspecteren: entiteiten tonen, states uitlezen, automations bekijken en historie opvragen.

Handige shell-aliasen zijn voorgeconfigureerd:

| Alias | Commando | Omschrijving |
|---|---|---|
| `v` | `vibe` | Vibe starten (of hervatten) |
| `login` | `vibe-login` | Inloggen met je Mistral-abonnement |
| `models` | `vibe-models` | Interactief modellen kiezen |
| `stats` | `vibe-stats` | Tokenverbruik en kostenoverzicht |
| `ha-config` | `cd /homeassistant` | Naar de HA-configuratiemap |
| `ha-logs` | `ha core logs \| tail -100` | Recente Home Assistant-logs tonen |

### Tokenverbruik en kosten

Draai `stats` (of `vibe-stats`) in de add-on-terminal voor het gecumuleerde tokenverbruik en geschatte kosten over al je Vibe-sessies:

```
================================================================
VIBE CODE - TOKEN USAGE
================================================================
Sessions logged : 2
Input tokens    : 20,000
Output tokens   : 5,000
Total tokens    : 25,000
Est. total cost : $0.0750 (worst-case estimate)
----------------------------------------------------------------
Session                                      Tokens        Cost
----------------------------------------------------------------
Fix automations                              15,000     $0.0450
Debug sensor                                 10,000     $0.0300
----------------------------------------------------------------
Note: costs are worst-case estimates per session (no prompt-cache
discount). Account balance/credits: https://console.mistral.ai
```

De Vibe CLI logt per sessie de tokenaantallen en een worst-case kostenraming naar `~/.vibe/logs/session/*/metadata.json`. Kosten zijn ramingen op basis van lijstprijzen zonder prompt-cache-kortingen. Je werkelijke saldo, abonnementsverbruik en resterende credits zijn alleen zichtbaar in de [Mistral console](https://console.mistral.ai).

## Pad-mapping

Binnen de add-on-container wijken paden af van Home Assistant Core:

| Pad | Omschrijving | Toegang |
|------|-------------|--------|
| `/homeassistant` | HA-configuratiemap (= `/config` in HA Core) | lezen-schrijven |
| `/share` | Gedeelde map tussen add-ons | lezen-schrijven |
| `/media` | Mediabestanden | lezen-schrijven |
| `/ssl` | SSL-certificaten | alleen lezen |
| `/backup` | Backups | alleen lezen |
| `/data` | Eigen configuratie van deze add-on (opties) | lezen-schrijven |

Als prompts `/config/...` noemen, vertaal dit naar `/homeassistant/...`.

## Bestandsstructuur

```
hass-vibe-addon/
├── repository.yaml          # Manifest van de add-on store repository
├── README.md                # Engelse documentatie
├── README.nl.md             # Nederlandse documentatie
└── vibecode/                # De Vibe Code add-on
    ├── config.yaml          # Add-on-manifest (opties, schema, ingress)
    ├── build.yaml           # Build-images per architectuur
    ├── Dockerfile           # Alpine + Python + Vibe CLI + ttyd + tmux + hass-mcp
    ├── run.sh               # Startscript: env, API-key, modellen, MCP, ttyd
    ├── vibe-stats           # Tokenverbruik / kostenaggregatie-commando
    ├── vibe-login           # Inloggen met abonnement
    ├── vibe-models          # Interactief modellen kiezen / synchroniseren
    ├── CHANGELOG.md
    └── rootfs/root/         # Shell- en tmux-configuratie
```

## Problemen oplossen

**Inloggen en authenticatie**

- **`vibe` vraagt bij elke herstart om inloggen** — zorg dat je óf `login` hebt gedraaid, óf `mistral_api_key` in de add-on-configuratie hebt gezet, óf `vibe --setup` hebt afgerond. Alle drie schrijven naar `/homeassistant/.vibe`, wat blijft bestaan na herstarts.
- **De browserlink in `vibe --setup` werkt niet** — verwacht in een container; gebruik `login`, die de URL als kopieerbare tekst print.
- **`login` print een URL maar er gebeurt niets** — de URL is slechts enkele minuten geldig. Kopieer met Ctrl+Shift+C, open in een browser, rond de login af en wacht tot het script dit bevestigt.
- **Kan niet plakken in de terminal** — gebruik **Ctrl+Shift+V** of rechtermuisklik → Plakken. Ctrl+V werkt niet in webterminals.

**Modellen**

- **Een nieuw Mistral-model ontbreekt** — herstart de add-on met `auto_models: true`, of draai `models` om het handmatig te kiezen. Check `vibe-models --list` voor alles wat de API aanbiedt.
- **Modelkosten tonen $0.0000 in `stats`** — de prijs van dat model is de add-on niet bekend. Voeg het toe aan `extra_models` met `input_price`/`output_price`.
- **Model wisselen binnen een sessie** — gebruik het `/model`-commando van de CLI; draai `/reload` na het registreren van nieuwe modellen.

**Algemeen**

- **`ha`-commando niet gevonden** — de HA CLI bestaat alleen voor amd64 en aarch64; op andere architecturen is hij niet beschikbaar.
- **MCP werkt niet** — check de add-on-logs bij het opstarten; de MCP-server staat geregistreerd in `~/.vibe/config.toml`. Verifieer met `cat ~/.vibe/config.toml`.
- **`vibe` crasht met een TOML-fout** — de add-on houdt een backup bij van de laatste geldige config op `~/.vibe/config.toml.bak` en herstelt die automatisch bij het opstarten. Een corrupt bestand wordt quarantined als `~/.vibe/config.toml.corrupt` voor inspectie.
- **Add-on-logs** — Instellingen → Add-ons → Vibe Code → Log, of `ha-logs` in de terminal voor HA-core-logs.

## Ondersteuning

- [Mistral Vibe CLI documentatie](https://github.com/mistralai/mistral-vibe)
- [Vibe Code documentatie](https://docs.mistral.ai/vibe/code/cli/install-setup)
- [Home Assistant add-on ontwikkeldocumentatie](https://developers.home-assistant.io/docs/add-ons/)

Bugs en feature requests: open een issue op [deze repository](https://github.com/FireStarter75/hass-vibe-addon/issues).

## Disclaimer

Vibe Code is een AI-agent die je configuratie kan lezen, bestanden kan schrijven en shell-commando's kan draaien binnen de add-on-container. Houd Home Assistant-backups altijd aan voordat je een AI-agent je configuratie laat wijzigen. De auteurs aanvaarden geen aansprakelijkheid voor kapotte configuraties.

## Licentie

[MIT](LICENSE)
