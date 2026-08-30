# Navegación social de un robot móvil evitando zonas proxémicas mediante A* con replanificación dinámica

Este documento describe, con nivel de detalle apto para la sección de métodos de un artículo científico, el diseño e implementación del módulo de navegación de un robot en un entorno con personas (`Experimento_01.m`), incluyendo las decisiones de diseño, los parámetros usados y su justificación, y las limitaciones verificadas empíricamente.

## 1. Motivación y planteamiento del problema

Un robot que se desplaza en un espacio compartido con personas debe evitar invadir su espacio personal (proxemia), tanto a nivel individual como cuando las personas están agrupadas en formaciones conversacionales. Este trabajo formaliza dicho requisito como un problema de planificación de trayectorias sobre un mapa de ocupación derivado de un modelo proxémico gaussiano, resuelto mediante el algoritmo A*, con:

- una velocidad de desplazamiento del robot acorde a valores reportados para navegación social,
- replanificación periódica para adaptarse a personas en movimiento, y
- una etapa de posprocesamiento geométrico (simplificación y suavizado) que produce trayectorias más realistas que la salida cruda de A* sobre una grilla.

El robot se representa únicamente como un punto para efectos de planificación; su representación gráfica (`Robot_model.m`) es ilustrativa y no participa en los cálculos.

## 2. Modelo proxémico

### 2.1 Zona individual

Cada persona se modela con una densidad gaussiana asimétrica orientada según su dirección de marcha (Vega et al., 2017), ya implementada en el proyecto (`MODELOS/Individual_model.m`, reutilizada dentro de `Individual_Human_Model.m`):

```
g(x, y) = exp( -( dx_local^2 / (2 σ_s^2) + dy_local^2 / (2 σ_h^2) ) )
```

donde `(dx_local, dy_local)` es el desplazamiento respecto al centro de la persona expresado en su marco de referencia local (rotado según su orientación θ), y:

- **σ_h = 0.9 m** (varianza frontal, eje hacia el que mira la persona)
- **σ_s = 0.6 m** (varianza lateral)

Estos valores provienen de la literatura proxémica ya citada en el código base (Vega et al., 2017) y no fueron modificados para este trabajo.

### 2.2 Zona grupal

Cuando `Group_Detector_Distan` (función preexistente, basada en un umbral de distancia entre personas) detecta un grupo, su zona proxémica conjunta se calcula con `Aracelly_model.m` (seleccionado como opción 4 del dispensador `Modelo.m`): una mezcla de gaussianas individuales orientadas hacia el centro geométrico del grupo, consistente con una formación conversacional tipo *O-space* (Kendon), tal como está documentado en el propio archivo del modelo.

### 2.3 Definición del "borde" de una zona proxémica

Para que la restricción de planificación ("no cruzar una zona proxémica") sea consistente con lo que efectivamente se visualiza en la figura, se usaron los **mismos niveles de contorno que ya se dibujan**:

| Tipo de zona | Umbral usado | Coincide con |
|---|---|---|
| Individual | `g > 0.75` | Contorno magenta dibujado por `Individual_Human_Model.m` |
| Grupal | `z > 0.4` | Contorno rojo dibujado en `Experimento_01.m` vía `Modelo`/`Aracelly_model` |

Es decir, una celda del entorno se considera "dentro de una zona proxémica" si y solo si cae dentro de la curva de nivel que ya se muestra gráficamente para esa zona.

## 3. Representación del entorno para la planificación

Se discretiza el dominio `[0, li] × [0, li]` (con `li = 10 m`, el mismo límite del experimento) en una grilla regular de paso **`cellSize = 0.25 m`** (≈ 41×41 nodos). Para cada replanificación se construye una **grilla de ocupación booleana**:

1. Para cada persona `k`, se evalúa la gaussiana individual en cada nodo de la grilla, transformando el desplazamiento al marco local de la persona:

   ```
   dx_local =  dx·cos(θ) + dy·sin(θ)
   dy_local = -dx·sin(θ) + dy·cos(θ)
   ```

   (con `dx = X_grilla - x_persona`, `dy = Y_grilla - y_persona`). Esta transformación fue **derivada y validada numéricamente** contra la salida real de `rotar_gaussiana.m` (la función que usa el resto del proyecto para orientar la gaussiana), confirmando que ambos cálculos coinciden salvo error de interpolación. Se marca la celda como ocupada si el valor supera 0.75.

2. Para cada grupo detectado, se evalúa `Modelo(xin, yin, mo)` sobre su propia malla y se interpola sobre la grilla común mediante `griddata` (necesario porque cada modelo grupal genera su propia malla, de tamaño y extensión distintos a la grilla de planificación). Se marca la celda como ocupada si el valor interpolado supera 0.4.

3. Las celdas correspondientes a la posición de inicio y a la meta se liberan explícitamente, para que la planificación nunca falle por el solo hecho de que el robot ya se encuentre cerca de una persona en el instante de replanificar, o de que la meta quede justo en el borde de una zona.

## 4. Planificación de trayectoria: A\*

Implementado en `FUNCTIONS/AStar_Grid.m`, de forma independiente del resto del sistema (recibe una grilla de ocupación genérica y dos celdas origen/destino).

- **Conectividad:** 8 vecinos.
- **Costo de arista:** 1 (movimiento ortogonal), √2 (movimiento diagonal).
- **Heurística:** distancia euclidiana entre celdas, admisible para este esquema de costos.
- **Prevención de "corte de esquina":** un movimiento diagonal se descarta si cualquiera de las dos celdas ortogonales adyacentes al movimiento está bloqueada, evitando que la ruta "pase entre" dos obstáculos diagonales sin espacio físico real para el robot.
- **Estructura de datos:** lista abierta simple (arreglo), adecuada para el tamaño de grilla usado (~1700 nodos); no se implementó una cola de prioridad con heap por no ser necesaria a esta escala.

## 5. Posprocesamiento de la trayectoria

La salida cruda de A* es una secuencia de celdas contiguas (incluyendo movimientos en zigzag propios de la discretización). Se aplican dos etapas adicionales, en este orden:

### 5.1 Simplificación (*string pulling*) — `FUNCTIONS/SimplifyPath.m`

Elimina vértices intermedios cuando existe línea de vista libre de celdas bloqueadas entre dos puntos no consecutivos del camino (verificado muestreando la línea recta entre ambos puntos contra la grilla de ocupación). Reduce el camino a sus vértices esenciales (puntos de giro reales).

### 5.2 Suavizado de esquinas — `FUNCTIONS/SmoothPathCorners.m`

Cada vértice interior del camino simplificado se reemplaza por un **arco de Bézier cuadrática**, usando como puntos de control dos puntos ubicados a una fracción `cutFraction` de la longitud del segmento adyacente más corto, con el propio vértice como punto de control central:

```
B(t) = (1-t)^2 · A + 2(1-t)t · V + t^2 · B ,   t ∈ [0, 1]
```

donde `V` es el vértice original y `A`, `B` son los puntos de corte sobre los segmentos entrante y saliente. Esta curva queda, por construcción, contenida en el triángulo `(A, V, B)`, por lo que **nunca se aleja del camino original hacia el lado contrario al obstáculo que motivó el giro** — es una técnica estándar de suavizado de esquinas en planificación de trayectorias robóticas ("corner cutting"/"path fileting").

Como medida de seguridad adicional, cada arco se **valida contra la grilla de ocupación** muestreándolo en `samplesPerCorner` puntos; si alguno cae en una celda bloqueada, esa esquina en particular se deja sin suavizar (se conserva el vértice original), en vez de arriesgar que el redondeo invada una zona proxémica cercana.

Parámetros usados: `cutFraction = 0.3`, `samplesPerCorner = 8`.

## 6. Replanificación dinámica

Las personas del experimento se mueven de forma continua (caminata aleatoria con inercia y rebote elástico ante colisiones entre sí y con los límites del entorno — lógica preexistente del experimento, no modificada). En consecuencia, un plan calculado una sola vez puede quedar invalidado.

Se implementó una función local `PlanPath(...)` (dentro de `Experimento_01.m`) que encapsula la construcción de la grilla de ocupación y la llamada a A* + posprocesamiento, de modo que pueda invocarse repetidamente:

- **En `t = 0`**, se planifica una vez desde `start_pos = (0,0)` hasta `goal_pos = (9,9)`.
- **Cada `replanInterval = 10` cuadros** (~1 s de simulación, dado `dt_robot = 0.1 s`) se vuelve a planificar desde la posición *actual* del robot hasta la meta, usando las posiciones y grupos vigentes en ese instante.
- Si la replanificación no encuentra una ruta válida (p. ej. el robot quedó momentáneamente rodeado), se conserva la trayectoria anterior en lugar de fallar la simulación.
- Dentro de cada cuadro, el robot avanza usando siempre la trayectoria más reciente disponible (la replanificación ocurre antes del paso de avance, no después), para minimizar el retraso entre el estado del entorno y la decisión de movimiento.

## 7. Modelo cinemático y velocidad del robot

El robot no se simula con dinámica de bajo nivel (no hay modelo de ruedas, torque o restricciones no-holonómicas); se emplea **seguimiento de trayectoria por longitud de arco**: la ruta se parametriza por distancia acumulada entre waypoints, y en cada cuadro se interpola la posición correspondiente a la distancia recorrida hasta ese instante. La orientación del robot en cada instante es la dirección del segmento de trayectoria que se está recorriendo (`atan2` del vector de avance).

| Parámetro | Valor | Justificación |
|---|---|---|
| `v_robot` | **0.6 m/s** | Velocidad de crucero "social": por debajo de la marcha humana normal (~1.2–1.4 m/s) para resultar predecible y no invasiva cerca de personas; dentro del rango típico reportado (0.3–0.8 m/s) para navegación consciente de humanos (cf. Kruse et al., 2013, *"Human-aware robot navigation: A survey"*) |
| `dt_robot` | 0.1 s | Paso de tiempo de simulación (10 Hz), valor habitual en lazos de control/simulación de robots móviles |
| `goal_tol` | 0.15 m | Tolerancia de llegada a la meta (menor a media celda de la grilla de planificación) |

## 8. Condición de término

La simulación finaliza cuando la distancia euclidiana entre el robot y `goal_pos` es menor que `goal_tol`. Como salvaguarda, se incluye un límite `maxFrames = 5000` cuadros que interrumpe la simulación con una advertencia si nunca se alcanzara la meta; en las pruebas realizadas este límite nunca se activó (el robot siempre llegó en unos pocos cientos de cuadros).

## 9. Modelo visual del robot (`Robot_model.m`)

Decisión de diseño explícita: **el robot no posee una zona proxémica propia** (no genera ninguna gaussiana ni se le asocia un umbral de exclusión). Esto refleja la asimetría planteada para este experimento: el robot debe respetar el espacio personal de las personas, pero no se modela, en esta versión, una zona recíproca que las personas deban respetar alrededor del robot. `Robot_model(x, y, theta)` solo dibuja una silueta en vista superior (chasis con esquinas achaflanadas, dos ruedas laterales, una torreta/sensor central y un indicador triangular de frente) y no participa en ningún cálculo de la planificación — el robot se trata como un punto para A*.

## 10. Integración con el experimento existente

Se preservó íntegramente la lógica original de `Experimento_01.m`:

- `n = 7` personas con posiciones iniciales fijas (`x`, `y`).
- Movimiento aleatorio con inercia (`ang0`, `spd0`, ruido gaussiano `noise_gain` por cuadro) y rebote elástico tanto entre personas como contra los límites del entorno.
- Detección de grupos por distancia (`Group_Detector_Distan`) y visualización de sus zonas grupales (contorno rojo, nivel 0.4).
- Visualización de la silueta y zona individual de cada persona (`Individual_Human_Model`, contorno magenta, nivel 0.75).

El robot y su planificación se añadieron como una **capa adicional** sobre ese experimento: en cada cuadro se dibuja primero la escena de personas (sin cambios respecto al experimento original) y luego se superponen la trayectoria planificada, los marcadores de inicio/meta y el robot.

## 11. Validación empírica y limitaciones

Para verificar el sistema no solo visualmente sino de forma cuantitativa, se instrumentó el código para registrar, en cada cuadro, el valor de la gaussiana individual y del modelo grupal evaluados exactamente en la posición del robot, comparándolos contra los umbrales de zona (0.75 y 0.4 respectivamente).

**Hallazgo:** en el escenario de referencia (7 personas, entorno de 10×10 m, `mo = 4`), el robot **cruza ocasionalmente** el umbral de zona proxémica pese a la replanificación periódica. Se identificaron las siguientes causas, verificadas experimentalmente:

1. **Ausencia de coevitación:** el modelo de movimiento de las personas es completamente independiente del robot (las personas no lo detectan ni lo evitan), a diferencia de cómo sí se evitan entre sí (colisión elástica ya implementada). Una persona puede desplazarse directamente hacia la posición del robot.
2. **Densidad del entorno:** con 7 personas y zonas de hasta ~1.5–2 m de radio efectivo en un entorno de 10×10 m, las zonas proxémicas pueden cubrir una fracción considerable del espacio libre, dejando corredores estrechos que se cierran y abren dinámicamente.
3. **Velocidades comparables:** algunas personas pueden alcanzar velocidades (hasta `max_speed` por cuadro, equivalente a ~1.0 m/s) superiores a `v_robot` (0.6 m/s), por lo que el robot no siempre puede evadir a tiempo a una persona que se aproxima.

**Se descartaron dos mitigaciones tras evaluarlas empíricamente:**

- *Replanificar en cada cuadro* (`replanInterval = 1`): no produjo una reducción sustancial de las violaciones respecto a replanificar cada 10 cuadros, lo que indica que el problema no es de latencia de replanificación sino estructural (falta de reactividad/coevitación).
- *Inflar la grilla de ocupación* como margen de seguridad (1–2 celdas adicionales bloqueadas alrededor de cada zona): en el escenario de prueba, esto eliminó por completo la existencia de una ruta viable (algunas zonas quedan demasiado próximas entre sí y a la meta), por lo que no se incluyó en la versión final.

**Conclusión a reportar honestamente en el artículo:** el enfoque implementado (A* sobre grilla de ocupación proxémica + replanificación periódica + suavizado geométrico) reduce sustancialmente, pero **no garantiza en el 100 % de los casos**, la ausencia de incursión en zonas proxémicas cuando las personas se mueven de forma completamente independiente del robot en espacios densamente poblados. Esta es una limitación conocida del enfoque reactivo-por-replanificación frente a escenarios verdaderamente dinámicos, y no un defecto de la implementación de A* en sí (que sí es correcta y completa frente a la configuración de obstáculos vigente en el instante en que planifica).

## 12. Trabajo futuro (propuestas, no implementadas)

- **Coevitación:** extender el modelo de colisión elástica existente entre personas para que también reaccione a la posición del robot.
- **Comportamiento reactivo local:** que el robot detecte una violación inminente y ejecute una maniobra local (detenerse, esquivar lateralmente) en vez de depender solo de la replanificación global.
- **Modelos de velocidad social adaptativa:** variar `v_robot` según la proximidad a personas, en lugar de una velocidad constante.
- **Cola de prioridad para A\*** si se requiere escalar a grillas más finas o entornos más grandes (la implementación actual usa una lista abierta simple, suficiente para la escala usada aquí).

## 13. Reproducibilidad

El experimento usa `rand`/`randn` sin fijar una semilla (`rng`), por lo que cada ejecución produce una trayectoria de personas distinta. Para figuras o videos destinados a publicación donde se requiera reproducibilidad exacta, se recomienda fijar la semilla al inicio del script, p. ej.:

```matlab
rng(<semilla>);
```

Durante el desarrollo y las pruebas de validación reportadas en la Sección 11 se usó `rng(7)` para poder comparar variantes del algoritmo sobre exactamente la misma secuencia de movimientos de las personas.

## 14. Resumen de parámetros

| Parámetro | Valor | Justificación / origen |
|---|---|---|
| σ_h (frontal, individual) | 0.9 m | Vega et al. (2017) — ya presente en el proyecto |
| σ_s (lateral, individual) | 0.6 m | Vega et al. (2017) — ya presente en el proyecto |
| Umbral zona individual | 0.75 | Coincide con el contorno visualizado (magenta) |
| Umbral zona grupal | 0.4 | Coincide con el contorno visualizado (rojo) |
| Tamaño de celda de grilla | 0.25 m | Balance resolución/costo computacional (~41×41 nodos) |
| `v_robot` | 0.6 m/s | Rango social típico 0.3–0.8 m/s (Kruse et al., 2013) |
| `dt_robot` | 0.1 s | 10 Hz, típico en simulación de robots móviles |
| `goal_tol` | 0.15 m | < media celda de la grilla |
| `replanInterval` | 10 cuadros | ≈ 1 s de simulación; evaluado también con 1 cuadro (sin mejora sustancial) |
| `cutFraction` (suavizado) | 0.3 | Recorte moderado de esquina; validado sin invadir zonas en las pruebas realizadas |
| `samplesPerCorner` | 8 | Resolución de muestreo del arco de Bézier para validación y trazado |
| `maxFrames` | 5000 | Salvaguarda; no se activó en las pruebas realizadas |

## 15. Estructura del código relevante

| Archivo | Rol |
|---|---|
| `Experimento_01.m` | Escenario completo (personas + robot); contiene la función local `PlanPath` |
| `FUNCTIONS/AStar_Grid.m` | Algoritmo A* sobre grilla con 8 vecinos |
| `FUNCTIONS/SimplifyPath.m` | Simplificación de trayectoria (*string pulling*) |
| `FUNCTIONS/SmoothPathCorners.m` | Suavizado de esquinas con Bézier cuadrática, validado contra la grilla |
| `Robot_model.m` | Silueta visual del robot (sin zona proxémica) |
| `Individual_Human_Model.m` | Silueta y gaussiana individual de cada persona |
| `MODELOS/Modelo.m`, `MODELOS/Aracelly_model.m` | Modelo grupal usado (`mo = 4`) |
| `FUNCTIONS/Group_Detector_Distan.m` | Detección de grupos por distancia (preexistente, sin modificar) |
| `FUNCTIONS/rotar_gaussiana.m` | Rotación de la malla gaussiana (preexistente, usada para validar la transformación al marco local) |

## Nota sobre las referencias bibliográficas

Las citas a Vega et al. (2017) y Kruse et al. (2013) se mantienen tal como ya aparecían documentadas en los comentarios del código base de este proyecto. Antes de incluirlas en el artículo, se recomienda verificar y completar los datos bibliográficos exactos (título completo, revista/conferencia, volumen y páginas) directamente de las fuentes originales, ya que este documento no tuvo acceso a esa información y no debe tomarse como una referencia bibliográfica verificada.
