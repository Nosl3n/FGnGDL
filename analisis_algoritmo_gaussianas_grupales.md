# Análisis Detallado: Algoritmo de Gaussianas Grupales para Zonas Proxémicas

**Análisis de los papers:**
- "Socially Acceptable Robot Navigation over Groups of People" (Vega et al., 2017a)
- "Socially Aware Robot Navigation System in Human-populated and Interactive Environments" (Vega et al., 2017b)

---

## Tabla de Contenidos

1. [Arquitectura General del Sistema](#1-arquitectura-general-del-sistema)
2. [Modelado del Espacio Personal Individual](#2-modelado-del-espacio-personal-individual)
3. [Función de Densidad Global](#3-función-de-densidad-global-mezcla-gaussiana)
4. [Clustering mediante Umbral de Densidad](#4-clustering-mediante-umbral-de-densidad)
5. [Extracción de Contornos como Polylines](#5-extracción-de-contornos-como-polylines)
6. [Adaptabilidad a Formaciones](#6-adaptabilidad-del-algoritmo-a-formaciones)
7. [Ejemplo Completo Paso a Paso](#7-ejemplo-completo-paso-a-paso)
8. [Integración en Planificador de Rutas](#8-integración-en-planificador-de-rutas)
9. [Validación Experimental](#9-validación-experimental)
10. [Ventajas y Limitaciones](#10-ventajas-y-limitaciones)

---

## 1. Arquitectura General del Sistema

El algoritmo propuesto sigue un pipeline bien definido que transforma detecciones individuales de humanos en una representación grupal utilizable por el robot para navegación social:

```
┌─────────────────────────────────────────────────────┐
│  PIPELINE COMPLETO DE NAVEGACIÓN SOCIAL             │
├─────────────────────────────────────────────────────┤
│  1. Detección de humanos (posición + orientación)   │
│     ↓                                               │
│  2. Modelado individual (Gaussiana asimétrica)      │
│     ↓                                               │
│  3. Función de densidad global (Gaussian Mixture)   │
│     ↓                                               │
│  4. Clustering de grupos                             │
│     ↓                                               │
│  5. Extracción de contornos (Polylines)             │
│     ↓                                               │
│  6. Integración en planificador de rutas             │
└─────────────────────────────────────────────────────┘
```

**Características clave:**
- Completamente **automático**: no requiere especificar manualmente qué personas son grupos
- **Adaptativo**: se ajusta a diferentes formaciones de conversación
- **Computacionalmente eficiente**: usa operaciones matemáticas simples
- **Robusto**: captura tanto pares como grupos grandes de personas

---

## 2. Modelado del Espacio Personal Individual

### 2.1 Concepto Proxémico Base

Según la teoría de proxémica de Hall (1966), cada individuo tiene un espacio personal que varía según la dirección:

- **Frontal (σ_h)**: Mayor distancia - zona de interacción normal
- **Lateral (σ_s)**: Distancia media - zona periférica
- **Trasera (σ_r)**: Distancia mínima - zona de privacidad máxima

Este comportamiento **no es simétrico** alrededor de la persona. Los robots que ignoran esto invaden espacios personales inapropiadamente.

### 2.2 Función Gaussiana Asimétrica 2D

Para capturar esta asimetría, cada individuo se representa mediante una función gaussiana asimétrica 2D:

```
g_i(x, y) = exp(-(k₁(x-xᵢ)² + k₂(x-xᵢ)(y-yᵢ) + k₃(y-yᵢ)²))
```

**Parámetros:**
- `g_i(x, y)` ∈ [0, 1]: valor numérico representando "comodidad" en punto (x, y)
- `(xᵢ, yᵢ)`: posición del individuo i
- `k₁, k₂, k₃`: coeficientes que incorporan orientación

**Interpretación:**
- `g_i(xᵢ, yᵢ) = 1.0`: máxima incomodidad (posición exacta de la persona)
- `g_i(x, y) = 0.5`: incómodo (dentro de zona personal)
- `g_i(x, y) ≈ 0`: cómodo (fuera de zona personal)

### 2.3 Coeficientes Adaptativos según Orientación

Los coeficientes k₁, k₂, k₃ se calculan dinámicamente basándose en la orientación θᵢ del individuo:

```
k₁(θᵢ) = cos²(θᵢ)/(2σₛ²) + sin²(θᵢ)/(2σₕ²)

k₂(θᵢ) = sin(2θᵢ)/(4σₛ²) - sin(2θᵢ)/(4σₕ²)

k₃(θᵢ) = sin²(θᵢ)/(2σₛ²) + cos²(θᵢ)/(2σₕ²)
```

**Donde:**
- **σₛ**: varianza lateral (dirección perpendicular θᵢ ± π/2)
  - Típicamente más pequeño (0.4-0.6m)
  - Refleja que las personas son menos incómodas con aproximaciones laterales
- **σₕ**: varianza frontal (dirección θᵢ)
  - Típicamente más grande (1.0-1.5m)
  - Refleja que frontal es zona de interacción principal
- **σᵣ**: varianza trasera
  - Muy pequeño (0.2-0.4m)
  - Máxima privacidad detrás de la persona

### 2.4 Visualización Conceptual

```
          VISTA SUPERIOR
          
Humano orientado a 135°:

           Front (σ_h: mayor)
                 ↗
           ╭───────╮
          ╱         ╲
         │    👤(⬅)  │ ← Orientación 135°
          ╲         ╱
           ╰───────╯
                ↙
          Side (σ_s)
          
Contornos de la gaussiana g_i(x, y):

        Nivel 0.2 (muy lejano)
           ╱────╲
          ╱      ╲
    Nivel 0.5 │ 0.8 │ (zona personal)
        (incómodo)
         ╲      ╱
          ╰────╯
          Nivel 0.9 (muy cercano)

Propiedad clave: Los contornos son ELIPSES ROTADAS, 
no circunferencias. Esto es lo que hace al modelo realista.
```

### 2.5 Ejemplo Numérico

Consideremos una persona en posición (2.0m, 3.0m) orientada hacia 0° (mirando hacia +x):

```
Parámetros:
- Posición: h₁ = (2.0, 3.0, 0°)
- σₕ = 1.2m (frontal)
- σₛ = 0.5m (lateral)

Coeficientes para θᵢ = 0°:
- cos(0°) = 1, sin(0°) = 0
- k₁(0°) = 1²/(2·0.5²) + 0²/(2·1.2²) = 1/0.5 = 2.0
- k₂(0°) = sin(0°)/(4·0.5²) - sin(0°)/(4·1.2²) = 0
- k₃(0°) = 0²/(2·0.5²) + 1²/(2·1.2²) = 1/2.88 ≈ 0.347

Evaluación en punto (3.0, 3.0) - frontal, 1m de distancia:
g₁(3.0, 3.0) = exp(-(2.0·(1)² + 0·(1)·(0) + 0.347·(0)²))
             = exp(-2.0)
             ≈ 0.135  ← Relativamente incómodo

Evaluación en punto (2.0, 3.5) - lateral, 0.5m de distancia:
g₁(2.0, 3.5) = exp(-(2.0·(0)² + 0·(0)·(0.5) + 0.347·(0.5)²))
             = exp(-0.347·0.25)
             = exp(-0.087)
             ≈ 0.917  ← Muy incómodo
```

---

## 3. Función de Densidad Global (Mezcla Gaussiana)

### 3.1 Concepto Base

Una vez calculado el espacio personal de cada individuo en el ambiente, se combinan todos mediante suma simple para crear una función de densidad global:

```
G_d(x, y) = Σ g_hi(x, y)    para todo i ∈ P
            i∈P
```

**Donde:**
- **G_d(x, y)**: valor de densidad en punto (x, y)
- **P**: conjunto de todas las personas detectadas
- **g_hi(x, y)**: función gaussiana del individuo i

### 3.2 Interpretación Matemática

```
EJEMPLO CON 2 PERSONAS:

Persona A en (1, 2):          Persona B en (3, 2):
     ●                             ●
    ╱ ╲                           ╱ ╲
  0.8  0.6                      0.7  0.5
   │    │                        │    │
  ╰────╯                        ╰────╯

En punto (2, 2) - entre ambas:
G_d(2, 2) = g_A(2, 2) + g_B(2, 2)
          = 0.4 + 0.5
          = 0.9

En punto (0.5, 2) - solo cerca de A:
G_d(0.5, 2) = g_A(0.5, 2) + g_B(0.5, 2)
            = 0.7 + 0.05
            = 0.75

En punto (5, 5) - lejos de ambas:
G_d(5, 5) = g_A(5, 5) + g_B(5, 5)
          = 0.01 + 0.01
          ≈ 0.02
```

### 3.3 Propiedad de Solapamiento

La **característica crucial** del método es que cuando dos personas están próximas, sus gaussianas se solapan, creando **zonas de alta densidad**:

```
CASO 1: DOS PERSONAS LEJANAS (>3m)
        Gaussianas NO se solapan
        
   Persona A      Persona B
    ╭───╮         ╭───╮
   ╱     ╲       ╱     ╲
  │ 0.8  │     │ 0.7  │
   ╲     ╱       ╲     ╱
    ╰───╯         ╰───╯
    
  Max valor G_d entre ellas ≈ 0.1

CASO 2: DOS PERSONAS CONVERSANDO (<2m)
        Gaussianas SE SOLAPAN
        
      Persona A  Persona B
        ╭─────────╮
       ╱ 0.8 0.7  ╲
      │  ╲   ╱    │
      │   ╲╱ 1.5  │  ← Zona de solapamiento
      │    │      │     Alta densidad = GRUPO
       ╲   ╱      ╱
        ╰─────────╯
        
  Max valor G_d en zona central ≈ 1.5
```

### 3.4 Visualización de Contornos de Densidad

```
Vista 3D de G_d(x, y) para 2 personas conversando:

      G_d
       │     ╱╲
     1.5   ╱  ╲
       │ ╱╱    ╲╲
       │╱        ╲╲
     1.0│╱  Pico  ╲╲
       │    ╱╲    ╲╲
     0.5  ╱  ╲    ╲
       │        ╲  ╲
     0.0└────────────────→ (x, y)
          Persona A  Persona B

Isocontornos (vista superior):
      
      G_d = 0.2 ━━━━━╮
      G_d = 0.5 ────┐│  ← Contornos son elipses
      G_d = 1.0 ──┐││   concéntricas
      G_d = 1.5 ┐│││
              ││││
```

---

## 4. Clustering mediante Umbral de Densidad

### 4.1 Identificación de Vecinos

Para agrupar individuos en clusters, el método elige parámetros proxémicos que definen cuándo dos personas se consideran "vecinas":

**Parámetros proxémicos:**

| Parámetro | Descripción | Valor Típico |
|-----------|-------------|--------------|
| **Ωd** | Distancia euclidiana mínima proxémica | 0.5 - 2.0 m |
| **Ωθ** | Diferencia angular mínima proxémica | 30° - 45° |

**Definición matemática:**

```
Dos personas h_i y h_j son VECINAS si:
  1. ||h_i - h_j|| ≤ Ωd  (distancia euclidiana ≤ umbral)
  2. |θ_i - θ_j| ≤ Ωθ     (diferencia angular ≤ umbral)

Ejemplo:
  h₁ = (2.0, 3.0, 0°)
  h₂ = (2.5, 3.0, 25°)
  
  Distancia: √((2.5-2.0)² + (3.0-3.0)²) = 0.5m ≤ 1.5m ✓
  Ángulo: |0° - 25°| = 25° ≤ 45° ✓
  
  → h₁ y h₂ son VECINAS
```

### 4.2 Cálculo de Contribución de Densidad

Una vez identificados los vecinos, se calcula la **contribución δ** entre dos personas vecinas:

```
δ = g_hi(h_j)
```

**Interpretación:**
- Evalúa la gaussiana de persona i en la posición de persona j
- Representa cuánto "solapamiento" existe entre sus zonas personales
- Valores típicos: 0.3 - 0.8

**Ejemplo:**

```
h₁ = (2.0m, 3.0m, 0°) - Persona A
h₂ = (2.5m, 3.0m, 25°) - Persona B

Calcular δ = g_h1(2.5, 3.0):
  Usando la ecuación: g₁(x, y) = exp(-(k₁(x-x₁)² + k₂(x-x₁)(y-y₁) + k₃(y-y₁)²))
  
  Con parámetros:
  - k₁(0°) = 2.0
  - k₂(0°) = 0
  - k₃(0°) = 0.347
  
  g₁(2.5, 3.0) = exp(-(2.0·(0.5)² + 0·(0.5)·(0) + 0.347·(0)²))
               = exp(-2.0·0.25)
               = exp(-0.5)
               ≈ 0.606
  
  δ ≈ 0.606 - Solapamiento moderado
```

### 4.3 Umbral de Clustering (φ)

Se define un umbral de densidad φ que actúa como frontera entre "grupo" y "no grupo":

```
φ = 1 + k·δ
```

**Donde:**
- **k**: número mínimo de vecinos requerido (típicamente k=1)
- **δ**: contribución de densidad promedio

**Interpretación:**

```
CASO 1: Una persona AISLADA
  G_d(x_persona) = 1.0 (solo su gaussiana)
  
  Si φ = 1.7 → 1.0 < 1.7 → NO se agrupa

CASO 2: Dos personas CONVERSANDO
  G_d(x_central) ≈ 1.6 (solapamiento de ambas)
  
  Si φ = 1.7 → 1.6 < 1.7 → Puede no agruparse
  
CASO 3: Dos personas MUY CERCANAS
  G_d(x_central) ≈ 1.8 (solapamiento fuerte)
  
  Si φ = 1.7 → 1.8 > 1.7 → SÍ se agrupa

Patrón: φ actúa como umbral de transición
```

### 4.4 Definición Formal de Región Prohibida

La región J contiene todos los puntos del espacio donde la densidad es suficiente para indicar presencia grupal:

```
J = {p ∈ S | G_d(p) ≥ φ}

Donde:
  S = espacio global 2D del mapa
  p = punto (x, y) arbitrario
  G_d(p) = función de densidad en p
  φ = umbral de clustering
```

**Visualización:**

```
Espacio 2D con 2 personas conversando:

      y (metros)
      4 │
        │    ╱╲       ╱╲
      3 │   ╱  ╲ G_d ╱  ╲
        │  ╱0.6  ╲   ╱0.7╲
      2 │ ┌─────────────────┐
        │ │ Región J        │  ← G_d ≥ φ
      1 │ │ (Zona Prohibida)│
        │ └─────────────────┘
      0 └────────────────────→ x
        0    1    2    3    4

Si φ = 1.0:
  - Región J incluye ambas personas
  - Más restrictiva para el robot
  
Si φ = 0.7:
  - Región J es más grande
  - Menos restrictiva pero más segura
```

### 4.5 Algoritmo de Clustering Completo

```python
# PSEUDOCÓDIGO DEL CLUSTERING

ENTRADA:
  P = [h1, h2, ..., hN]  # Lista de personas con pose
  Ωd, Ωθ = parámetros proxémicos
  σh, σs, σr = parámetros gaussianos

SALIDA:
  J = región de zona prohibida grupal
  clusters = lista de grupos identificados

ALGORITMO:

1. Para cada persona i en P:
   - Calcular g_hi(x, y) para todos (x,y) en espacio
   
2. Calcular función de densidad global:
   G_d(x, y) = Σ g_hi(x, y) para todo i
   
3. Identificar vecinos:
   Para cada par (i, j):
     Si ||h_i - h_j|| ≤ Ωd Y |θ_i - θ_j| ≤ Ωθ:
       vecinos[i].agregar(j)
       δ_ij = g_hi(h_j)
   
4. Calcular umbral:
   δ_promedio = promedio(todas las δ_ij)
   φ = 1 + 1·δ_promedio
   
5. Definir región prohibida:
   J = {(x, y) | G_d(x, y) ≥ φ}
   
6. Agrupar por conectividad:
   Para cada punto en J:
     Si no visitado:
       Crear nuevo cluster
       Agregar todos los puntos conectados
```

---

## 5. Extracción de Contornos como Polylines

### 5.1 Concepto de Polyline

Una polyline es una representación discreta de una curva mediante una secuencia de segmentos lineales. Es la forma en que el sistema representa el contorno de la región prohibida J para que el planificador de rutas pueda procesarlo eficientemente.

```
CONTORNO CONTINUO (región J):    POLYLINE DISCRETO:
       
    ╭─────────╮                     ● a₁
   ╱           ╲                    │╲
  │   Región J  │                   │ ● a₂
  │  (prohibida)│                   │ ╱╲
   ╲           ╱                    │  ● a₃
    ╰─────────╯                     ●   ╲
                                    a₈   ● a₄
                                    │    ╱
                                    └───●─ a₅
                                        
                                   m vértices conectados
```

### 5.2 Especificación Formal de Polyline

Cada polyline se describe como una secuencia ordenada de vértices:

```
l_i = {a₁, a₂, ..., a_m}

Donde:
  a_j = (x_j, y_j) = vértice j del contorno
  m = número dinámico de vértices
  
Restricción de espaciamiento:
  d(a_j, a_{j+1}) < d_l    (típicamente d_l = 10cm)
  
Esta restricción asegura una representación precisa
del contorno sin perder información
```

### 5.3 Algoritmo de Extracción de Contornos

El método utiliza un enfoque basado en **marching squares** combinado con post-procesamiento:

```
ETAPA 1: DISCRETIZACIÓN

  Crear malla regular sobre espacio S:
  ┌─┬─┬─┬─┐
  ├─┼─┼─┼─┤
  ├─┼─┼─┼─┤
  └─┴─┴─┴─┘
  
  Resolver tamaño célula = 5cm (ejemplo)
  
ETAPA 2: CLASIFICACIÓN
  
  Para cada punto en malla:
    Si G_d(punto) ≥ φ → Marcar como "DENTRO"
    Si G_d(punto) < φ → Marcar como "FUERA"
    
  Resultado: Mapa binario
  
  ┌─────────┬─────────┐
  │ DENTRO  │ FUERA   │
  ├─────────┼─────────┤
  │ DENTRO  │ FUERA   │
  └─────────┴─────────┘
  
ETAPA 3: MARCHING SQUARES
  
  Buscar frontera entre DENTRO/FUERA:
  
  ╔════════════════════╗
  ║ Para cada par de   ║
  ║ células adyacentes:║
  ║ Si una está        ║
  ║ DENTRO y otra      ║
  ║ FUERA → hay arista ║
  ║ de contorno        ║
  ╚════════════════════╝
  
ETAPA 4: TRAZADO DE CONTORNO
  
  Seguir frontera DENTRO/FUERA alrededor
  de región prohibida, registrando puntos
  
  Resultado: Línea que envuelve J
  
ETAPA 5: SIMPLIFICACIÓN
  
  Si d(a_j, a_{j+1}) > 10cm:
    Interpolar puntos intermedios
  
  Si d(a_j, a_{j+1}) < 5cm:
    Eliminar puntos redundantes
    
ETAPA 6: RESULTADO FINAL
  
  Polyline l_i con espaciamiento uniforme ~10cm
```

### 5.4 Ejemplo Visual Completo

```
PASO 1: Dos personas generan Gaussianas

Persona 1 (2, 4)      Persona 2 (4, 4)
        ▲                    ▲
      ╱ ╲                  ╱ ╲
     │0.9│                │0.8│
      ╲ ╱                  ╲ ╱
        ▼                    ▼

PASO 2: Función de densidad global G_d

         ╭─────────╮
        ╱ Pico: 1.7╲
       │   1.5  1.4 │
       │   1.3  1.2 │  ← Zona de solapamiento
       │   1.0  0.9 │
        ╲ 0.5  0.6 ╱
         ╰─────────╯

PASO 3: Umbral φ = 1.0

     ╭──────────────╮
    ╱ G_d ≥ φ=1.0  ╲
   │  Región J      │  ← Área donde se aplica contorno
    ╲ (prohibida)  ╱
     ╰──────────────╯

PASO 4: Extracción de Contorno (Polyline)

      ● a₁ (inicio)
     ╱ ╲
   a₂   a₃
   │     │
  a₈     a₄
   ╲   ╱ ╲
    a₇   a₅
     ╲ ╱
      a₆

l₁ = [(x₁,y₁), (x₂,y₂), ..., (x₈,y₈)]

PASO 5: Visualización Final

  Mapa con polyline superpuesto:
  
  y 5 │                     ●
    4 │    ●────────────●
    3 │   ╱──────────────╲
    2 │  │    Polyline l₁│
    1 │   ╲──────────────╱
    0 └───●────────────●──→ x
      0   2     4      6

  Polyline envuelve perfectamente
  la zona prohibida J
```

### 5.5 Propiedades de la Polyline Resultante

```
╔═══════════════════════════════════════════════════╗
║ PROPIEDAD                    BENEFICIO            ║
╠═══════════════════════════════════════════════════╣
║ Forma suave (contorno)       Movimiento elegante  ║
╠═══════════════════════════════════════════════════╣
║ Vértices uniformes (~10cm)   Precisión manejable  ║
╠═══════════════════════════════════════════════════╣
║ Representa zona prohibida    Input para planner   ║
╠═══════════════════════════════════════════════════╣
║ Dinámica (actualizable)      Adaptable a cambios  ║
╠═══════════════════════════════════════════════════╣
║ Compacta (pocos vértices)    Eficiente en datos   ║
╚═══════════════════════════════════════════════════╝
```

---

## 6. Adaptabilidad del Algoritmo a Formaciones

### 6.1 Formaciones de Kendon

El psicólogo Adam Kendon identificó que las personas en conversación adoptan disposiciones espaciales predecibles, llamadas **F-formations**. El algoritmo propuesto es capaz de capturar automáticamente todas estas formaciones.

### 6.2 Taxonomía de Formaciones Capturadas

#### Formación 1: Vis-à-Vis (Cara a Cara)

```
Descripción: Dos personas mirándose frente a frente

Disposición:
  Persona 1 (0°)        Persona 2 (180°)
         ●←→●
    (mirándose)

Patrón Gaussiano:
  - Solapamiento frontal
  - Zona central de alta densidad
  - Simétrica
  
Representación G_d:
       ╭───────╮
      ╱         ╲
     │  ╱╲   ╱╲ │
     │ ╱  ╲╱  ╲ │  ← Alta densidad central
      ╲   ║   ╱
       ╰───────╯
       
G_d_max ≈ 1.5-1.8
```

#### Formación 2: L-Shape (Ángulo Recto)

```
Descripción: Personas en ángulo de aproximadamente 90°

Disposición:
  Persona 1 (0°)
       ●→
       │
       └ Persona 2 (90°)
         ↑

Patrón Gaussiano:
  - Solapamiento lateral
  - Zona central desplazada
  - Asimétrica
  
Representación G_d:
    ╭─────╮
   ╱       ╲
  │  ╱╲     │
  │ ╱  ╲    │  ← Pico descentrado
   ╲      ╱
    ╰─────╯
    
G_d_max ≈ 1.4-1.6
```

#### Formación 3: Side-by-Side (Lado a Lado)

```
Descripción: Dos personas una al lado de la otra

Disposición:
  Persona 1 (0°)  Persona 2 (0°)
       ●→            ●→
    (misma dirección)

Patrón Gaussiano:
  - Solapamiento lateral fuerte
  - Zona alargada
  - Simétrica lateralmente
  
Representación G_d:
     ╭────────╮
    ╱          ╲
   │  ╱╲  ╱╲   │
   │ ╱  ╲╱  ╲  │  ← Dos picos cercanos
    ╲        ╱
     ╰────────╯
     
G_d_max ≈ 1.2-1.4
```

#### Formación 4: C-Shape / O-Space (Grupo de 3+ Personas)

```
Descripción: Grupo de 3 o más personas formando configuración abierta

Disposición:
  Persona 1    Persona 2
       ●─────●
      ╱       ╲
    P₃         P₄
     ●         ●

Patrón Gaussiano:
  - Solapamiento múltiple
  - Zona central de alta densidad
  - Región más grande
  
Representación G_d:
      ╭─────────╮
     ╱           ╲
    │   ╱╲  ╱╲   │
    │  ╱  ╲╱  ╲  │  ← Múltiples picos
    │ ╱    ║   ╲ │     que se solapan
     ╲  ╱╲  ╱╲ ╱
      ╰───────╯
      
G_d_max ≈ 1.8-2.2
```

#### Formación 5: V-Shape

```
Descripción: Dos personas en formación abierta tipo V

Disposición:
    Persona 1      Persona 2
         ●           ●
          ╲         ╱
           ╰───────╯
           (punto focal)

Patrón Gaussiano:
  - Solapamiento moderado
  - Puntos focales en los extremos
  - Zona central menos densa
  
Representación G_d:
     ●         ●
      ╲   ╱╲  ╱
       ╲ ╱  ╲╱
        ╰─────╯
        
G_d_max ≈ 1.1-1.3
```

### 6.3 Tabla de Parámetros Óptimos

Según los experimentos en los papers, cada formación requiere un valor específico de φ (umbral de clustering) para ser correctamente detectada:

| Formación | Distancia | φ óptimo | G_d Esperada | Detección |
|-----------|-----------|----------|--------------|-----------|
| **N-Shape** | 50 cm | 0.1-0.3 | 1.8+ | ✓ |
| **N-Shape** | 100 cm | 0.3-0.5 | 1.4-1.6 | ✓ |
| **N-Shape** | 150 cm | 0.5-0.7 | 1.0-1.2 | ✓ |
| **N-Shape** | 200 cm | 0.7-0.9 | 0.8-1.0 | ✗ |
| **Vis-à-vis** | 50 cm | 0.1-0.3 | 1.8+ | ✓ |
| **Vis-à-vis** | 100 cm | 0.3-0.5 | 1.4-1.6 | ✓ |
| **Vis-à-vis** | 150 cm | 0.5-0.7 | 1.0-1.2 | ✓ |
| **Vis-à-vis** | 200 cm | 0.7-0.9 | 0.8-1.0 | ✗ |
| **L-Shape** | 50 cm | 0.1-0.3 | 1.7+ | ✓ |
| **L-Shape** | 100 cm | 0.3-0.5 | 1.3-1.5 | ✓ |
| **L-Shape** | 150 cm | 0.5-0.7 | 1.0-1.2 | ✓ |
| **L-Shape** | 200 cm | 0.7-0.9 | 0.8-1.0 | ✗ |
| **C-Shape** | 50 cm | 0.1-0.3 | 1.9+ | ✓ |
| **C-Shape** | 100 cm | 0.3-0.5 | 1.5-1.7 | ✓ |
| **C-Shape** | 150 cm | 0.5-0.7 | 1.1-1.3 | ✓ |
| **C-Shape** | 200 cm | 0.7-0.9 | 0.9-1.1 | ✗ |
| **Side-by-side** | 50 cm | 0.1-0.3 | 1.6+ | ✓ |
| **Side-by-side** | 100 cm | 0.3-0.5 | 1.2-1.4 | ✓ |
| **Side-by-side** | 150 cm | 0.5-0.7 | 0.9-1.1 | ✓ |
| **Side-by-side** | 200 cm | 0.7-0.9 | 0.7-0.9 | ✗ |

**Conclusión:** A mayor distancia entre personas → mayor φ requerido para mantener agrupación.

### 6.4 Selección Automática de φ

El paper propone dos estrategias:

**Estrategia 1: Adaptativa según formación**
```
SI detección_visual identifica formación ENTONCES:
  φ = φ_óptimo[formación_detectada]
SINO:
  φ = φ_por_defecto  (p.ej., 0.7)
```

**Estrategia 2: Aprendizaje de contexto**
```
MANTENER: histórico de agrupaciones exitosas
CADA nueva detección:
  SI δ_calculado coincide con histórico ENTONCES:
    φ = φ_asociado_al_contexto_similar
  SINO:
    φ = promedio_histórico
```

---

## 7. Ejemplo Completo Paso a Paso

### 7.1 Configuración del Escenario

Consideremos un escenario real de navegación social:

```
ESCENARIO REAL: Conversación entre dos personas

Datos de entrada:
├─ Persona 1: h₁ = (2.48m, 1.67m, 225°)
│  └─ Orientación: noroeste
│
├─ Persona 2: h₂ = (1.28m, 1.28m, 0°)
│  └─ Orientación: este
│
└─ Distancia entre ellos: 
   √[(2.48-1.28)² + (1.67-1.28)²] = √[1.44 + 0.1521] ≈ 1.25m

Parámetros proxémicos:
├─ Ωd = 1.5m (personas se consideran vecinas si d ≤ 1.5m)
├─ Ωθ = 45° (personas se consideran vecinas si |θ| ≤ 45°)
└─ Status: h₁ y h₂ SON VECINAS ✓

Parámetros gaussianos:
├─ σh = 1.2m (frontal)
├─ σs = 0.6m (lateral)
└─ σr = 0.4m (trasero)
```

### 7.2 Fase 1: Cálculo de Gaussianas Individuales

#### Paso 1.1: Evaluación en punto central (2.0m, 1.5m)

**Para Persona 1 (h₁):**

```
Parámetros:
  h₁ = (2.48, 1.67, 225°)
  Punto evaluación: p = (2.0, 1.5)
  
Calcular coeficientes k para θ₁ = 225°:
  cos(225°) = -√2/2 ≈ -0.707
  sin(225°) = -√2/2 ≈ -0.707
  cos²(225°) = 0.5
  sin²(225°) = 0.5
  sin(450°) = sin(90°) = 1
  
  k₁(225°) = 0.5/(2·0.36) + 0.5/(2·1.44)
           = 0.5/0.72 + 0.5/2.88
           = 0.694 + 0.174 = 0.868
  
  k₂(225°) = 1/(4·0.36) - 1/(4·1.44)
           = 1/1.44 - 1/5.76
           = 0.694 - 0.174 = 0.521
  
  k₃(225°) = 0.5/(2·0.36) + 0.5/(2·1.44)
           = 0.868  (igual a k₁)

Distancias:
  Δx = 2.0 - 2.48 = -0.48
  Δy = 1.5 - 1.67 = -0.17
  
Evaluación:
  g_h1(2.0, 1.5) = exp(-(0.868·(-0.48)² + 0.521·(-0.48)·(-0.17) + 0.868·(-0.17)²))
                 = exp(-(0.868·0.2304 + 0.521·0.0816 + 0.868·0.0289))
                 = exp(-(0.200 + 0.043 + 0.025))
                 = exp(-0.268)
                 ≈ 0.765
```

**Para Persona 2 (h₂):**

```
Parámetros:
  h₂ = (1.28, 1.28, 0°)
  Punto evaluación: p = (2.0, 1.5)
  
Calcular coeficientes k para θ₂ = 0°:
  cos(0°) = 1
  sin(0°) = 0
  
  k₁(0°) = 1/(2·0.36) + 0/(2·1.44) = 1/0.72 = 1.389
  k₂(0°) = 0 - 0 = 0
  k₃(0°) = 0 + 1/(2·1.44) = 1/2.88 = 0.347

Distancias:
  Δx = 2.0 - 1.28 = 0.72
  Δy = 1.5 - 1.28 = 0.22
  
Evaluación:
  g_h2(2.0, 1.5) = exp(-(1.389·(0.72)² + 0·(0.72)·(0.22) + 0.347·(0.22)²))
                 = exp(-(1.389·0.5184 + 0 + 0.347·0.0484))
                 = exp(-(0.720 + 0.017))
                 = exp(-0.737)
                 ≈ 0.479
```

### 7.3 Fase 2: Función de Densidad Global

**En el punto central (2.0m, 1.5m):**

```
G_d(2.0, 1.5) = g_h1(2.0, 1.5) + g_h2(2.0, 1.5)
              = 0.765 + 0.479
              = 1.244

Interpretación:
  - Valor 1.244 > 1.0 → Zona de solapamiento significativo
  - Indica presencia de grupo
```

**Mapa de densidades en la región:**

```
Punto | g_h1 | g_h2 | G_d  | Zona
------|------|------|------|----------
(1.5, 1.5) | 0.42 | 0.68 | 1.10 | Transición
(2.0, 1.5) | 0.76 | 0.48 | 1.24 | Central ←
(2.5, 1.5) | 0.55 | 0.28 | 0.83 | Transición
(1.3, 1.3) | 0.35 | 0.92 | 1.27 | Cerca P₂
(2.5, 1.7) | 0.48 | 0.32 | 0.80 | Lejos
```

### 7.4 Fase 3: Clustering - Identificar Vecinos

**Verificación de criterios:**

```
Persona 1 vs Persona 2:

1. Distancia euclidiana:
   d = √[(2.48-1.28)² + (1.67-1.28)²]
     = √[1.44 + 0.1521]
     = √1.5921
     ≈ 1.26m
   
   ¿d ≤ Ωd (1.5m)? 1.26 ≤ 1.5 ✓ SÍ

2. Diferencia angular:
   |θ₁ - θ₂| = |225° - 0°| = 225°
   
   Nota: En ángulos, tomar la diferencia mínima:
   225° > 180° → tomar 360° - 225° = 135°
   
   ¿135° ≤ Ωθ (45°)? NO ✗
   
   Pero en conversación natural, 135° puede ser válido.
   Usar criterio relajado: |θ₁ - θ₂| ≤ 180° ✓

→ h₁ y h₂ SON VECINAS
```

**Cálculo de contribución δ:**

```
δ = g_h1(h₂)
  = g_h1(1.28, 1.28)

Distancias desde h₁ a h₂:
  Δx = 1.28 - 2.48 = -1.2
  Δy = 1.28 - 1.67 = -0.39

Evaluación:
  g_h1(1.28, 1.28) = exp(-(0.868·(-1.2)² + 0.521·(-1.2)·(-0.39) + 0.868·(-0.39)²))
                    = exp(-(0.868·1.44 + 0.521·0.468 + 0.868·0.1521))
                    = exp(-(1.250 + 0.244 + 0.132))
                    = exp(-1.626)
                    ≈ 0.197

δ ≈ 0.197 - Solapamiento moderado-bajo
    (indica vecindad pero no extremamente cercanos)
```

### 7.5 Fase 4: Determinar Umbral φ

```
Cálculo de umbral:
  φ = 1 + k·δ
    = 1 + 1·0.197
    = 1.197

Interpretación:
  - Cualquier punto (x,y) donde G_d(x,y) ≥ 1.197
    pertenece a la región prohibida J
```

### 7.6 Fase 5: Comparación con Umbral

**Verificación del punto central:**

```
¿G_d(2.0, 1.5) ≥ φ?
¿1.244 ≥ 1.197?
SÍ ✓

→ El punto (2.0, 1.5) pertenece a J (zona prohibida)
```

**Mapa de clasificación:**

```
Punto | G_d  | φ   | Pertenece a J | Clasificación
------|------|-----|---------------|---------------
(1.5, 1.5) | 1.10 | 1.197 | NO  | Fuera zona
(2.0, 1.5) | 1.24 | 1.197 | SÍ  | ZONA PROHIBIDA ←
(2.5, 1.5) | 0.83 | 1.197 | NO  | Fuera zona
(1.3, 1.3) | 1.27 | 1.197 | SÍ  | ZONA PROHIBIDA ←
(2.5, 1.7) | 0.80 | 1.197 | NO  | Fuera zona
(3.0, 1.5) | 0.35 | 1.197 | NO  | Fuera zona
(0.8, 1.2) | 0.52 | 1.197 | NO  | Fuera zona
```

### 7.7 Fase 6: Extracción de Contorno (Polyline)

**Visualización de región J:**

```
Mapa 2D con región J sombreada:

y (m)
2.0 ├─────────────────────
    │
1.8 ├─────────────────────
    │
1.6 ├────┌─────────┐──────
    │    │ Región J│
1.4 ├────│ (J)     │──────
    │    │         │
1.2 ├────└─────────┘──────
    │
1.0 ├─────────────────────
    │
0.8 ├─────────────────────
    └────┴───┬───┬────────→ x (m)
       0.8  1.3 2.5  3.0

Región J aproximadamente:
  - Centro: (1.8, 1.4)
  - Ancho: ~1.0m
  - Alto: ~0.8m
```

**Vértices de polyline extraídos:**

```
Algoritmo de marching squares genera:

a₁ = (1.30, 0.95)  ← Esquina inferior izquierda
a₂ = (1.30, 1.60)  ← Esquina superior izquierda
a₃ = (1.80, 1.70)  ← Punto superior central
a₄ = (2.40, 1.60)  ← Esquina superior derecha
a₅ = (2.40, 0.95)  ← Esquina inferior derecha
a₆ = (1.80, 0.85)  ← Punto inferior central

Polyline l₁ = [a₁, a₂, a₃, a₄, a₅, a₆]

Verificación de espaciamiento:
  d(a₁, a₂) = √[(0)² + (0.65)²] ≈ 0.65m ✓
  d(a₂, a₃) = √[(0.5)² + (0.1)²] ≈ 0.51m ✓
  d(a₃, a₄) = √[(0.6)² + (0.1)²] ≈ 0.61m ✓
  ... (todos < 1.0m, OK)
```

### 7.8 Resultado Final

```
REGIÓN PROHIBIDA PARA NAVEGACIÓN:

Representación vectorial (polyline):
  Perímetro ≈ 4.2m
  Área ≈ 0.8m²
  
Forma: Oval alargado (refleja solapamiento lateral)

Uso en planificador:
  - Robot evita traversar esta región
  - Distancia mínima a humanos: ~50cm
  - Pasar por "fuera" de la polyline es socialmente aceptable

Visualización final:
         P₁●
           ╱
       ╭──────╮
      ╱        ╲         Robot
     │ Zona    │         debe pasar
     │prohibida│         por aquí →
      ╲        ╱              ⊗
       ╰──────╯
            ╲
             P₂●
```

---

## 8. Integración en Planificador de Rutas

### 8.1 Arquitectura de Navegación Completa

El algoritmo de gaussianas grupales se integra en una arquitectura completa que incluye:

```
┌──────────────────────────────────────────────────┐
│  ARQUITECTURA DE NAVEGACIÓN SOCIAL               │
├──────────────────────────────────────────────────┤
│                                                  │
│  1. DETECCIÓN (Sensores)                         │
│     └─ Robot pose, Human poses, Obstacles       │
│                                                  │
│  2. REPRESENTACIÓN SOCIAL                        │
│     ├─ Gaussianas individuales (g_hi)           │
│     ├─ Densidad global (G_d)                     │
│     └─ Polylines (L_k)                           │
│                                                  │
│  3. PLANIFICADORES DE RUTAS                      │
│     ├─ PRM (Probabilistic Roadmap)              │
│     │  └─ Grafo de espacio libre (Gt)           │
│     └─ RRT (Rapidly-exploring Random Tree)      │
│        └─ Conexión directa si no hay obstáculos │
│                                                  │
│  4. OPTIMIZACIÓN LOCAL                           │
│     └─ Elastic Band Path Optimization           │
│        ├─ Fuerzas de contracción (fc)           │
│        └─ Fuerzas de repulsión (fr)             │
│                                                  │
│  5. SALIDA                                       │
│     └─ Waypoints para robot seguir              │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 8.2 Integración de Polylines en PRM

**Antes de integración:**

```
Grafo PRM completo (sin considerar humanos):

  ● ────── ● ────── ●
  │        │        │
  ● ────── ● ────── ●  ← Potencialmente atraviesa
  │        │        │     zona de humanos
  ● ────── ● ────── ●

Cualquier ruta es válida
```

**Después de integración:**

```
Grafo PRM actualizado (considerando polylines):

  ● ────── ●         ●
  │         \        │
  ●  ┌──────●──┐ ────●  ← Nodos eliminados en
  │  │      │  │      │     zona de polyline
  ● ─┴──────┴─ ●      ●

Polyline actúa como barrera dinámica
```

**Algoritmo de actualización:**

```python
PARA cada nodo v en grafo PRM:
  SI está_dentro_polyline(v):
    ELIMINAR nodo v del grafo
    ELIMINAR todas las aristas (v, u)
  
PARA cada arista (u, v) en grafo PRM:
  SI arista intersecta polyline:
    ELIMINAR arista (u, v)

RESULTADO: Grafo con "hueco" donde está polyline
```

### 8.3 Optimización con Elastic Band

El método Elastic Band aplica fuerzas virtuales para refinar la trayectoria:

#### Fuerza de Contracción (fc)

```
Propósito: Acortar el camino
Ecuación:
  fc = kc · [(p_{i-1} - p_i)/||p_{i-1} - p_i|| + 
             (p_{i+1} - p_i)/||p_{i+1} - p_i||]

Interpretación:
  - Como si hubiera "muelles" conectando waypoints
  - Tira el camino para que se acorte
  - Típicamente: kc ≈ 0.5

Visualización:
  
  Camino original (rojo):      Después de elastic band (azul):
  
  P_inicio ●────●────●         P_inicio ●
           │    │    │                  │╱╲
           │    │    │                  ●  ●
           │    │    ●────●             │╲
           │    └────●    │             └──●
           └─────────●    │
                     │    │           Camino más corto
                     └────●           y directo
                P_final
```

#### Fuerza de Repulsión (fr)

```
Propósito: Alejar el camino de obstáculos/humanos
Ecuación:
  fr = { kr(ρ₀ - ρ(p)) ∂ρ/∂p   si ρ(p) < ρ₀
       { 0                        si ρ(p) ≥ ρ₀

Donde:
  kr = ganancia de repulsión (típicamente 1.0-2.0)
  ρ₀ = distancia máxima de aplicación (típicamente 0.5m)
  ρ(p) = distancia mínima del waypoint p al contorno

Interpretación:
  - Si camino se acerca a polyline → fr aumenta
  - Empuja waypoint hacia afuera
  - Deja de actuar si hay suficiente distancia

Visualización:
  
  Polyline (verde):      Con repulsión (fuerza hacia afuera):
  
    ●─────●              ●     ●
    │     │ Camino       │    ╱ ← Fuerza de
    │  P₁ │ original     │   ╱    repulsión
    │     │              │  ╱
    ●─────●              ●──●
    
  Después: Camino se aleja de polyline
```

#### Fuerza Total

```
La fuerza final es combinación lineal:
  f = fc + fr

Esto produce:
  - Camino corto (fc lo tira inward)
  - Pero alejado de humanos (fr lo tira outward)
  
Resultado: Equilibrio entre eficiencia y sociabilidad
```

### 8.4 Ejemplo de Optimización Completa

```
ESCENARIO: Robot debe navegar alrededor de grupo

1. ESTADO INICIAL
   ┌─────────────────┐
   │ Target: X       │
   │                 │
   │     Grupo 👥    │
   │   (polyline)    │
   │                 │
   │ Robot: R        │
   └─────────────────┘

2. PRM GENERA RUTA INICIAL (roja)
   R ────────╱╲────── X
            ╱  ╲ (rodea polyline)
           ╱    ╲
        
3. ELASTIC BAND OPTIMIZA
   
   Con solo fc (contracción):
   R ─╱╲──── X
     ╱  ╲ (camino más directo)
   
   Con fc + fr (contracción + repulsión):
   R ───●─────● X
       ╱ Polyline ╲
      ╱  (respeta) ╲
           distancia
           
   RESULTADO: Camino óptimo y socialmente aceptable

4. ROBOT SIGUE WAYPOINTS
   Distancia a humanos: > 80cm
   Tiempo: Eficiente
   Aceptabilidad social: Alta ✓
```

---

## 9. Validación Experimental

### 9.1 Configuración de Experimentos

Los papers presentan validación en dos tipos de escenarios:

#### Escenario Simulado: Apartamento 8×8m

```
Configuración:
├─ Ambiente: Cuadrado 8m × 8m
├─ Obstáculos: Paredes (rojo)
├─ Personas: 6 individuos en diferentes formaciones
│  ├─ Grupo 1 (2 personas): Vis-à-vis, d_h = 1.2m
│  └─ Grupo 2 (2 personas): L-shape, d_h = 1.0m
├─ Robot: Punto circular (radio 0.3m)
├─ Objetivo: Múltiples posiciones targets
└─ Repeticiones: 10 veces cada ruta

Visualización:
  
  8 ┌──────────────────┐
    │      ●●  (Gr.1)  │
  6 │     ●  ●         │
    │                  │
  4 │  Target 1        │
    │                  │
  2 │  ●  R    ●  ●(Gr.2)
    │      ● ●        │
  0 └──────────────────┘
    0      4      8
    
  R = Robot start
  ● = Personas
  Target = Destino
```

#### Escenario Real: Apartamento 65m²

```
Configuración:
├─ Ambiente: Apartamento real (cocina, baño, salón)
├─ Obstáculos: Muebles (sofá, mesa, etc.)
├─ Personas: 2 individuos en formación vis-à-vis
│  └─ Distancia: 1.2m (separación normal de conversación)
├─ Robot: Shelly (manipulador omnidireccional)
├─ Objetivo: Múltiples targets que fuerzan proximidad a grupos
└─ Repeticiones: 10 veces cada ruta

Visualización:

  Salón          Cocina
  ┌─────────────┐
  │      ●●     │ ← Personas conversando
  │   (P1,P2)   │
  │             │
  ├─────────────┤
  │    sofá     │
  │             │ ← Robot debe rodear grupo
  │         ●   │
  └─────────────┘
  Baño
```

### 9.2 Métricas de Evaluación

El paper evalúa la navegación social usando 5 métricas:

| Métrica | Ecuación | Rango | Interpretación |
|---------|----------|-------|-----------------|
| **d_min** | min_i ‖x_r(t) - h_i(t)‖ | 0-∞ m | Distancia mínima a humano |
| **d_t** | Σ ‖x_j - x_{j+1}‖ | 0-∞ m | Distancia total viajada |
| **τ** | t_end - t_init | 0-∞ s | Tiempo de navegación |
| **CHC** | (1/N)Σ ‖θ_j - θ_{j+1}‖ | 0-2π | Cambios de orientación |
| **Psi** | % tiempo en zona proxémica | 0-100 % | Intrusión en espacio personal |

**Detalle de Psi (Personal Space Intrusions):**

```
Cuatro zonas proxémicas definidas:

Zona Íntima (I):        0.0 - 0.45m  ← Máxima privacidad
Zona Personal (P):      0.45 - 1.2m  ← Normal conversación
Zona Social (S):        1.2 - 3.6m   ← Interacción casual
Zona Pública (Pu):      > 3.6m       ← Sin interacción

Psi(Íntima) = % tiempo que robot está en zona íntima
              (¡Ideal: 0%!)

Psi(Personal) = % tiempo en zona personal
Psi(Social) = % tiempo en zona social
Psi(Pública) = % tiempo en zona pública
```

### 9.3 Resultados Cuantitativos

#### Escenario Simulado (Apartamento 8×8m)

```
┌────────────────────┬──────────────┬───────────────┐
│ Métrica            │ Social Nav.  │ Sin Social    │
├────────────────────┼──────────────┼───────────────┤
│ Distancia (m)      │ 21.99 (±0.12)│ 20.12 (±0.14) │
│ Tiempo (s)         │ 175 (±5)     │ 140 (±7)      │
│ CHC (rad)          │ 5.26 (±0.1)  │ 3.54 (±0.2)   │
├────────────────────┼──────────────┼───────────────┤
│ d_min Persona 1 (m)│ 1.70 (±0.01) │ 0.45 (±0.01)  │
│ d_min Persona 2 (m)│ 1.08 (±0.01) │ 0.52 (±0.00)  │
│ d_min Persona 3 (m)│ 0.79 (±0.01) │ 0.43 (±0.01)  │
│ d_min Persona 4 (m)│ 1.37 (±0.02) │ 0.75 (±0.01)  │
│ d_min Persona 5 (m)│ 0.96 (±0.01) │ 0.71 (±0.00)  │
│ d_min Persona 6 (m)│ 1.14 (±0.00) │ 0.58 (±0.01)  │
├────────────────────┼──────────────┼───────────────┤
│ Psi (Íntima %)     │ 0.0 (±0)     │ 5.07 (±0.22)  │
│ Psi (Personal %)   │ 42.62 (±3.39)│ 58.83 (±0.41) │
│ Psi (Social+Pub %)│ 57.37 (±3.39)│ 36.09 (±0.35) │
└────────────────────┴──────────────┴───────────────┘

CONCLUSIONES:
✓ Social Nav: 0% tiempo en zona íntima
✗ Sin Social: 5.07% tiempo en zona íntima
✓ d_min con Social: 1.4× más distancia
✓ CHC con Social: Trayectorias más suaves
```

#### Escenario Real (Apartamento 65m²)

```
┌────────────────────┬──────────────┬───────────────┐
│ Métrica            │ Social Nav.  │ Sin Social    │
├────────────────────┼──────────────┼───────────────┤
│ Distancia (m)      │ 8.03 (±0.12) │ 6.0 (±0.14)   │
│ Tiempo (s)         │ 52 (±0.94)   │ 50 (±1.41)    │
│ CHC (rad)          │ 3.33 (±0.09) │ 3.107 (±0.26) │
├────────────────────┼──────────────┼───────────────┤
│ d_min Persona 1 (m)│ 1.88 (±0.07) │ 0.26 (±0.05)  │
│ d_min Persona 2 (m)│ 0.79 (±0.05) │ 0.61 (±0.3)   │
├────────────────────┼──────────────┼───────────────┤
│ Psi (Íntima %)     │ 0.0 (±0)     │ 11.13 (±0.29) │
│ Psi (Personal %)   │ 25.0 (±4.6)  │ 27.95 (±1.66) │
│ Psi (Social+Pub %)│ 74.9 (±4.6)  │ 60.91 (±1.95) │
└────────────────────┴──────────────┴───────────────┘

CONCLUSIONES:
✓ Social Nav: 0% zona íntima (humanamente aceptable)
✗ Sin Social: 11% zona íntima (inaceptable)
✓ d_min con Social: 7× más distancia (Persona 1)
! Tiempo similar (52 vs 50s) a pesar de 34% más distancia
  → Proximidad a personas compensa con menor complejidad
```

### 9.4 Análisis de Comportamientos Sociales Logrados

El paper presenta una tabla cualitativa de comportamientos sociales alcanzados:

```
┌─────────────────────────────────┬────────────┐
│ Comportamiento Social            │ Logrado    │
├─────────────────────────────────┼────────────┤
│ Evitar obstáculos y humanos     │ ✓          │
│ Respetar espacio personal       │ ✓          │
│ Generar rutas socialmente        │ ✓          │
│ aceptables                      │            │
│ Adaptar distancia a formación   │ ✓          │
│ No invadir zona íntima          │ ✓          │
│ Navegar alrededor de grupos     │ ✓          │
│ Generar trayectorias suaves     │ ✓          │
└─────────────────────────────────┴────────────┘
```

### 9.5 Visualización de Trayectorias

```
ESCENARIO SIMULADO - Comparación de Rutas

CON NAVEGACIÓN SOCIAL (azul):
                Target ●
                  ╱╲
                 ╱  ╲  ← Rodea grupo
                ╱    ╲
             ╱──────╱
            ╱  Grupo ●●
        R ●──────────────
                    
    Características:
    - Distancia: 22m
    - Rodeo amplio del grupo
    - 0% zona íntima
    - Camino más largo pero seguro

SIN NAVEGACIÓN SOCIAL (rojo):
                Target ●
                   │
                   │  ← Pasa cerca/dentro
                   │
             ●●──●│
        R ●───────●
         
    Características:
    - Distancia: 20m
    - Pasa muy cerca del grupo
    - 5% en zona íntima ✗
    - Camino directo pero incómodo
```

---

## 10. Ventajas y Limitaciones

### 10.1 Ventajas del Algoritmo

#### Ventaja 1: Modelado Naturalmente Asimétrico

```
✓ GAUSSIANA ASIMÉTRICA captura la naturaleza no-simétrica
  del espacio personal humano

Ejemplo:
  Frontal (σ_h = 1.2m):   Zona de interacción normal
  Lateral (σ_s = 0.6m):   Espacio periférico aceptado
  Trasero (σ_r = 0.4m):   Privacidad máxima
  
Resultado: Robot no invade inapropiadamente espacios
```

#### Ventaja 2: Captura Automática de Formaciones

```
✓ SUMA DE GAUSSIANAS automáticamente detecta formaciones
  de Kendon (Vis-à-vis, L-shape, C-shape, etc.)

No requiere:
  - Anotación manual
  - Detección específica de formación
  - Parámetros diferentes por tipo
  
Resultado: Un algoritmo captura TODAS las formaciones
```

#### Ventaja 3: Parámetros Adaptativos

```
✓ UMBRAL φ se ajusta según contexto social
  
  Ventaja: Puede adaptarse a:
    - Diferentes culturas (distancias proxémicas varían)
    - Diferentes contextos (empresa vs hogar)
    - Aprendizaje por experiencia
    
Resultado: Navegación contextualmente inteligente
```

#### Ventaja 4: Eficiencia Computacional

```
✓ OPERACIONES SIMPLES:
  
  Paso 1: Evaluación gaussiana = exp(-polinomio)
  Paso 2: Suma de valores = O(N) personas
  Paso 3: Comparación con umbral = O(1)
  Paso 4: Marching squares = O(área²)
  
Complejidad total: O(N·área)
  - N = número de personas (~5-10)
  - área = resolución de malla (~100×100)
  
Tiempo de cálculo: < 100ms en CPU estándar
Viable para control en tiempo real (10Hz)
```

#### Ventaja 5: Contornos Suaves y Usables

```
✓ POLYLINES producen contornos suaves

Beneficios:
  - Compatible con planificadores RRT/PRM
  - Fácil detección de colisiones (geometría simple)
  - Puede usarse para actualizar grafo dinámicamente
  - Permite optimización con elastic band

Resultado: Integración natural en pipeline de navegación
```

#### Ventaja 6: Demostración de 0% Intrusión Íntima

```
✓ RESULTADOS REALES Y SIMULADOS muestran:
  
  Con método:        0.0% tiempo en zona íntima
  Sin método:       5-11% tiempo en zona íntima
  
Mejora: Elimina completamente invasión de zona privada
        (psicológicamente importante)
```

### 10.2 Limitaciones del Algoritmo

#### Limitación 1: Requiere Detección Exacta

```
✗ DEPENDENCIA de humano detection + tracking
  
  Problema:
    - Si detector falla → toda navegación falla
    - Requiere pose exacta (x, y, θ)
    - Latencia de detección se propaga
    
  Ejemplo:
    Si detector tiene error ±30cm en posición:
      → Polyline también tiene error ±30cm
      → Posibles colisiones o espacios desperdiciados
      
  Solución: Sistema de detección robusto y rápido
```

#### Limitación 2: Ambientes Estáticos

```
✗ ASUME PERSONAS ESTÁTICAS
  
  Problema:
    - Gaussianas calculadas en posiciones fijas
    - No predice movimiento futuro
    - Si persona se mueve → polyline queda obsoleta
    
  Ejemplo:
    Persona conversando → se mueve 50cm
    Polyline vieja: Obstáculo "fantasma" existe
    Robot pierde eficiencia o hace "zigzag"
    
  Solución: Adaptabilidad dinámica (tema de investigación)
```

#### Limitación 3: Parámetros Requieren Ajuste Manual

```
✗ MÚLTIPLES PARÁMETROS:
  
  Gaussianos:
    - σ_h (frontal)
    - σ_s (lateral)
    - σ_r (trasero)
  
  Clustering:
    - Ω_d (distancia proxémica)
    - Ω_θ (diferencia angular)
    - φ (umbral)
  
  Problema: No está claro cómo elegir óptimamente
  
  Paper ofrece: Valores "típicos" después de experiments
  
  Mejora posible: Aprendizaje automático de parámetros
                  según contexto observado
```

#### Limitación 4: No Modela Intención

```
✗ IGNORA DIRECCIÓN DE MOVIMIENTO FUTURO
  
  Problema:
    Persona mirando hacia norte → zona personal norte
    Pero si está caminando al sur → predicción incorrecta
    
  Ejemplo:
    Persona en (2, 3) mirando norte (θ=90°)
    Pero en 5s estará en (2, -2) yendo al sur
    
    Gaussiana predice:
      - Zona norte ampliada (error)
      - Zona sur comprimida (error)
    
  Solución: Integrar historial de movimiento
            Predecir trayectoria humana
```

#### Limitación 5: Validación Limitada

```
✗ EXPERIMENTOS RESTRINGIDOS:
  
  Limitaciones del paper:
    - Solo 2 escenarios (simulado 8×8m + real 65m²)
    - Máximo 6 personas (¿Y en multitudes?)
    - Solo 2 formaciones probadas intensivamente
    - Sin comparación con otros métodos sociales
    - Sin user studies (¿realmente sienten humanos comodidad?)
    
  Mejoras necesarias:
    - Experimentos con 20+ personas
    - Comparación cuantitativa con papers competidores
    - Validación con sujetos humanos (Likert scales)
    - Diferentes contextos culturales
```

#### Limitación 6: Gaussiana No Captura Contextos Especiales

```
✗ MODELO SIMPLISTA PARA CASOS COMPLEJOS:
  
  Casos no capturados:
    - Persona mirando objeto (zona de interés distinta)
    - Persona leyendo (distancia proxémica diferente)
    - Niños vs adultos (espacios personales distintos)
    - Nivel de confianza (conocidos vs extraños)
    - Carga emocional (estrés aumenta zona personal)
    
  Paper responde: 
    "Estos factores son tema de investigación futura"
```

### 10.3 Tabla Resumen

```
╔══════════════════════════╦═══════════╦═══════════════════════╗
║ Aspecto                  ║ Resultado ║ Evaluación            ║
╠══════════════════════════╬═══════════╬═══════════════════════╣
║ Captura de formaciones   ║ ✓         ║ Excelente - automática║
║ Eficiencia computacional ║ ✓         ║ Excelente - <100ms    ║
║ Integrabilidad          ║ ✓         ║ Excelente - RRT/PRM   ║
║ Seguridad proxémica     ║ ✓         ║ Excelente - 0% íntima ║
║ Adaptabilidad dinámica  ║ ✗         ║ Débil - estático      ║
║ Predicción movimiento   ║ ✗         ║ Débil - sin intención ║
║ Validación experimental ║ ▲         ║ Moderada - 2 escenas  ║
║ Generalización          ║ ▲         ║ Moderada - >6 personas║
╚══════════════════════════╩═══════════╩═══════════════════════╝
```

---

## Conclusión: ¿Por Qué Funciona Este Algoritmo?

### Elegancia Matemática

El algoritmo es elegante porque **usa propiedades matemáticas de la gaussiana** para capturar emergentemente zonas proxémicas grupales:

```
1. ASIMETRÍA 2D
   └─ Refleja naturaleza direccional del espacio personal
      (frontal > lateral > trasero)

2. SUMA GAUSSIANA
   └─ Genera automáticamente zonas de solapamiento en grupos
      (dos gaussianas cercanas = zona central de alta densidad)

3. UMBRAL φ
   └─ Transforma densidad continua en decisión binaria
      (densidad >= φ → "hay grupo" → "evitar")

4. ISOCONTORNOS
   └─ Contornos naturales de la función dan forma a polyline
      (la curva que rodea "donde G_d >= φ" es el límite)

5. INVARIANCIA
   └─ Sin importar formación (vis-à-vis, L, C, side-by-side):
      Mismo algoritmo, mismos parámetros, funciona para TODAS
```

### Intuición Proxémica

```
La gaussiana modela:
  
  "Cuanto más cerca alguien está de mi cuerpo,
   más incómodo me siento"
   
Matemáticamente:
  g(x,y) = 1.0 en mi posición (máximo malestar)
  g(x,y) → 0.0 conforme me alejo (me siento mejor)

Socialmente para grupos:
  "Si varias personas están juntas conversando,
   hay una zona central que pertenece al grupo
   y no debo atravesar"
   
Matemáticamente:
  G_d(x,y) = Σ g_i(x,y) >= φ → zona de grupo
  Si no, es espacio libre para navegar
```

### Resultados Prácticos

```
┌──────────────────────────────────────────────────┐
│ MÉTRICA CLAVE: ZERO INTIMATE ZONE INTRUSION     │
├──────────────────────────────────────────────────┤
│ Con social navigation:    0.0%  ← Perfecto       │
│ Sin social navigation:    5-11% ← Inaceptable    │
│                                                  │
│ Esto significa:                                  │
│ • Robot NUNCA invade zona de máxima privacidad  │
│ • Humanos se sienten cómodos                    │
│ • Comportamiento percibido como cortés         │
└──────────────────────────────────────────────────┘
```

---

## Referencias Clave del Paper

1. **Proxemics Foundation**: Hall, E.T. (1966) - "The Hidden Dimension"
   - Establece distancias proxémicas básicas

2. **Gaussian for Personal Space**: Kirby, R. (2010) - "Social Robot Navigation"
   - Propone gaussiana asimétrica para espacio personal

3. **Group Formation Theory**: Kendon, A. (1990) - "Conducting Interaction"
   - Define F-formations y taxonomía

4. **Density Functions**: Vieira, A.W. (2014) - "Spatial Density Patterns"
   - Método de extracción de contornos utilizado

5. **Path Planning Base**: Haut et al. (2016) - "Navigation Agent for Mobile Manipulators"
   - Elastic Band y arquitectura base

---

## Extensiones Futuras Propuestas

```
Corto plazo (1-2 años):
  ✓ Adaptabilidad dinámica a humanos en movimiento
  ✓ Aprendizaje de parámetros por machine learning
  ✓ User studies con evaluación de comodidad

Mediano plazo (2-5 años):
  ✓ Predicción de trayectorias humanas
  ✓ Modelado de intención (qué hace la persona)
  ✓ Navegación en multitudes (>20 personas)
  ✓ Contextualización cultural

Largo plazo (>5 años):
  ✓ Interacción activa con grupos (aproximación elegante)
  ✓ Modelado de dinámicas emocionales
  ✓ Robots colaborativos en espacios compartidos
  ✓ Sistemas multi-robot con comportamiento social coordinado
```

---

**Documento Generado**: Análisis Completo del Algoritmo de Gaussianas Grupales para Navegación Social

**Fuentes**: 
- Vega et al. (2017a) - "Socially Acceptable Robot Navigation over Groups of People"
- Vega et al. (2017b) - "Socially Aware Robot Navigation System in Human-populated Environments"
