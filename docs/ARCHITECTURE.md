# Arquitectura técnica

## Principios

- **Game Engine desacoplado**: `lib/game_engine/` es Dart puro. Cero imports de Flutter.
  Se puede testear, serializar y reutilizar en un servidor sin cambios.
- **Estado inmutable**: cada acción produce un nuevo `GameState` via `copyWith`.
  Riverpod detecta cambios automáticamente y la serialización para red es trivial.
- **Feature-first**: cada feature es un módulo autónomo con sus capas de datos,
  dominio y presentación. Las features no se importan entre sí.
- **Eventos desacoplados**: el engine emite `GameEvent` en un stream broadcast.
  La UI lo escucha para animaciones y sonidos sin que el engine sepa nada de Flutter.

---

## Capas y dependencias

```
┌─────────────────────────────────────────────────────┐
│  features/*/presentation  (Flutter widgets)         │
│         ↓                                           │
│  features/*/providers     (Riverpod)                │
│         ↓                                           │
│  features/*/domain/usecases                         │
│         ↓                      ↘                    │
│  game_engine/engine/GameEngine   network/            │
│         ↓                                           │
│  game_engine/rules + deck + turn                    │
│         ↓                                           │
│  game_engine/models  (entidades inmutables)         │
└─────────────────────────────────────────────────────┘
         ↑ todos dependen de ↑
         core/  (constantes, errores, utils)
```

---

## Game Engine

### Flujo de una acción

```
UI → engine.apply(TurnAction)
       │
       ├─ GameRules.validate()      → lanza InvalidActionException si inválida
       │
       └─ ActionProcessor.process()
              │
              ├─ muta GameState (inmutablemente via copyWith)
              ├─ emite GameEvent al bus
              └─ devuelve nuevo GameState
```

### `TurnAction` — sealed class

Exhaustiva: el compilador obliga a manejar todos los casos en `ActionProcessor`.

| Acción | Descripción |
|--------|-------------|
| `DrawCardAction` | Robar la carta de arriba del mazo |
| `PlayCardAction` | Jugar una carta sin objetivo |
| `PlayFavorAction` | Pedir carta aleatoria a otro jugador |
| `PlayCatPairAction` | Par de gatos → robar carta aleatoria |
| `PlayCatTrioAction` | Trío de gatos → elegir carta de la mano del objetivo |
| `DefuseBombAction` | Usar Defuse + elegir posición de reinserción |
| `NopeAction` | Cancelar (o des-cancelar) la acción pendiente |

### `GameEvent` — sealed class

El bus emite eventos que la UI consume para animaciones y sonidos sin polling.

```dart
engine.on<BombTriggeredEvent>().listen((_) => showExplosionAnimation());
engine.on<NopedEvent>().listen((e) => playNopeSound());
```

### Turno y fases

```
TurnPhase.playing
    │  (jugador juega carta)
    ▼
TurnPhase.nopeWindow     ← ventana de GameConstants.nopeWindowMs ms
    │  (se cierra o se juega Nope)
    ▼
TurnPhase.resolving      ← se aplica el efecto
    │
    ▼
TurnPhase.drawRequired   ← jugador debe robar
    │
    ▼
TurnPhase.ended          ← TurnManager.advance() rota al siguiente
```

Attack chain: `TurnModel.actionsLeft > 1` mantiene al mismo jugador.
Nope chain: `TurnModel.nopeChainCount` impar = acción cancelada.

---

## Red (Fase 5)

### Diseño cliente–servidor simétrico

El **host** levanta `WebSocketServer` en `AppConstants.localGamePort` (8765) y
también se conecta como cliente a sí mismo. Todos los jugadores (incluido el host)
usan exactamente el mismo `WebSocketClient`.

```
Host:    WebSocketServer  ←→  GameEngine  ←→  WebSocketClient (host)
Clients:                       WebSocketClient (cliente 1..N)
```

Cuando se migre a modo online, solo cambia la URL de conexión del cliente.

### Serialización

`GameStateSerializer` convierte `GameState` ↔ JSON. El estado completo se
retransmite a todos los clientes tras cada acción para garantizar consistencia.
Los eventos individuales (`GameEvent` ↔ JSON via `EventSerializer`) se usan
para triggers de animación en los clientes.

### Reconexión

`ReconnectionManager` gestiona el grace period de `GameConstants.reconnectTimeoutSeconds`
segundos. Al reconectar, el servidor envía el `GameState` completo y el cliente
restaura la UI desde él.

---

## Gestión de estado (Riverpod)

```dart
// Provider principal de partida (Fase 4)
@riverpod
class GameStateNotifier extends _$GameStateNotifier {
  late GameEngine _engine;

  @override
  GameState build() { ... }

  void apply(TurnAction action) {
    state = _engine.apply(action);
  }
}
```

Los providers de animación y audio escuchan `GameEventBus.instance.stream`
de forma independiente para no bloquear el árbol de widgets.

---

## Expansión futura

### Añadir una carta nueva

1. Añadir valor al enum `CardType` en `card_type.dart`
2. Añadir caso en `CardRules` y en `GameRules`
3. Añadir caso en el `switch` de `ActionProcessor.process()` — el compilador
   obliga a manejarlo al ser `sealed`
4. Añadir asset en `assets/cards/` y registrar en `AssetPaths`
5. Añadir test en `test/game_engine/rules/`

### Añadir una expansión

Crear un `DeckBuilder` especializado que reciba `GameConfig.includeExpansion = true`
y ajuste la composición del mazo. El engine no requiere cambios.
