# AMX Resultado

Plugin de AMX Mod X para Counter-Strike 1.5 / 1.6 que administra de forma semi-automática los **cerrados** (partidas clán). Lleva el conteo de rondas, hace el cambio de equipos automático al terminar la primera mitad, y finaliza el partido al alcanzar 16 rondas.

Creado originalmente en 2008 para los servidores del clan **Insides**.

## Características

- Contador de rondas ganadas por CT y TT
- Cambio automático de equipos al finalizar la primera mitad (15 rondas)
- Bloqueo de cambio de equipos durante el cerrado
- Sistema de `/ready` para que los jugadores confirmen estar listos
- Inicio automático del cerrado cuando todos están listos (opcional)
- Bloqueo de chat `/say` durante el partido (solo `pausa`)
- Muestra el resultado con `say /resultado`
- Muestra el password con `say /pass`
- Comandos para ejecutar configuraciones (cerrado, público, práctica, poss)
- Muestra el jugador con más frags de cada mitad al finalizar

## Cvars

| Cvar | Default | Descripción |
|------|---------|-------------|
| `amx_resultado` | 0 | 1 = activa el plugin, 0 = desactivado |
| `amx_ready` | 0 | 1 = activa sistema de ready automático |
| `amx_nosay` | 0 | 1 = bloquea el chat durante el cerrado |

## Comandos

### Jugadores

| Comando | Descripción |
|---------|-------------|
| `say /ready` | Indica que estás listo |
| `say /noready` | Indica que no estás listo |
| `say /resultado` | Muestra el resultado actual |
| `say /pass` | Muestra el password del servidor |
| `say pausa` | Pide pausar el juego |

### Admin (flag ADMIN_CFG o ADMIN_CVAR)

| Comando | Descripción |
|---------|-------------|
| `amx_vale` / `say /vale` | Inicia el cerrado, resetea contadores |
| `amx_nuevo` | Limpia todos los contadores |
| `say /cerrado` | Ejecuta `cerrado.cfg` |
| `say /publico` | Ejecuta `publico.cfg` |
| `say /practica` | Ejecuta `practica.cfg` |
| `say /rr` | Restart round |
| `say /poss` | Ejecuta `poss.cfg` |
| `say /nopass` | Quita el password del servidor |

## Compilación

Compilar con `amxxpc`:

```
amxxpc amx_resultado.sma
```

## Historia

Este plugin nació en 2008 para los servidores de Counter-Strike 1.5 y 1.6 del clan **Insides**, una comunidad argentina de principios de los 2000. En esa época los cerrados se administraban medio a mano con vales, cfg sueltas y mucho confianza. El plugin automatizaba todo el flujo: conteo de rondas, cambio de equipos en la mitad, bloqueo de cambios y chat, y mostraba los resultados en HUD. Llegó a usarse en varios servers de la escena argentina de CS 1.6.

## Créditos

- **!ns - Linux** — código original
- DAM, [Lo]Phreak^n^c, JON, V3x — contribuciones y testing
- Comunidad Insides
