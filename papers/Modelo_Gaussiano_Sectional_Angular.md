# Modelo Gaussiano Sectional Angular con Parametrización Adaptable para Representar Zonas Proxémicas de Grupos de Humanos

## 1. Introducción y Conceptos Fundamentales

### 1.1 Definición del Modelo

El modelo propone una función Gaussiana con parametrización adaptable, diseñada para representar dinámicamente zonas proxémicas de grupos de personas, considerando tanto el número de individuos como sus posiciones relativas espaciales.

### 1.2 Fundamento Teórico

El modelo se basa en:
- **Teoría de Proxémica de Hall**: Define cuatro zonas de interacción (íntima, personal, social, pública)
- **Espacios de Interacción de Kendon**: O-space (núcleo interactivo), P-space (espacio de participantes), R-space (región circundante)

## 2. Función Gaussiana Base

### 2.1 Ecuación Fundamental (Ecuación 1)

$$Z_g = \exp\left(-\frac{(X_g - X_{cg})^2}{2\sigma_x^2} - \frac{(Y_g - Y_{cg})^2}{2\sigma_y^2}\right)$$

### 2.2 Definición de Variables Base

| Variable | Definición | Rango |
|----------|-----------|-------|
| $Z_g$ | Valor de la función Gaussiana en el punto evaluado | $[0, 1]$ |
| $(X_g, Y_g)$ | Coordenadas del punto donde se evalúa la función Gaussiana | $\mathbb{R}^2$ |
| $(X_{cg}, Y_{cg})$ | Coordenadas del centro del grupo (CG) | $\mathbb{R}^2$ |
| $\sigma_x$ | Varianza en dirección x, controla la expansión horizontal de la gaussiana | $> 0$ |
| $\sigma_y$ | Varianza en dirección y, controla la expansión vertical de la gaussiana | $> 0$ |
| $Z_g(X_{cg}, Y_{cg})$ | Valor máximo de la gaussiana en el centro del grupo | $= 1$ |

## 3. Cálculo del Centro del Grupo

### 3.1 Centro Geométrico (Ecuaciones 9-10)

$$X_{cg} = \frac{\max(X) + \min(X)}{2}$$

$$Y_{cg} = \frac{\max(Y) + \min(Y)}{2}$$

Donde:
- $\max(X), \min(X)$ = máximo y mínimo de coordenadas X de los puntos del grupo
- $\max(Y), \min(Y)$ = máximo y mínimo de coordenadas Y de los puntos del grupo

## 4. Parámetros Variables del Modelo

### 4.1 Parámetros Intrínsecos al Modelo Gaussiano

#### 4.1.1 Varianza Mínima: $\sigma_{min}$

**Descripción**: Valor mínimo de ajuste añadido a la distancia radial de cada persona al centro del grupo

**Restricción matemática**: 
$$\sigma_{min} > 0$$

**Propósito**: 
- Evitar valores nulos o excesivamente pequeños en las varianzas
- Prevenir indeterminaciones en la ecuación fundamental
- Garantizar una extensión mínima de la superficie alrededor de cada punto

**Valor por defecto en este trabajo**: $\sigma_{min} = 0.5$

**Influencia**: Valores mayores resultan en mayor expansión alrededor de cada punto

#### 4.1.2 Incremento Angular: $\Delta\gamma$

**Descripción**: Incremento angular fijo utilizado para discretizar los intervalos entre individuos consecutivos

**Restricción matemática**:
$$\Delta\gamma > 0$$

**Propósito**:
- Definir la granularidad de las secciones angulares
- Controlar la suavidad de transiciones entre secciones
- Determinar el número total de secciones angulares

**Rango recomendado**: valores pequeños producen más secciones y transiciones más suaves; valores grandes reducen la resolución angular

**Comportamiento**: Cuando $\phi_j + \Delta\gamma \geq \omega_i$, se procede a la siguiente sección angular

### 4.2 Parámetros de Optimización del Modelo

#### 4.2.1 Distancia Angular Mínima: $\beta_{min}$

**Descripción**: Distancia angular mínima permitida entre dos individuos consecutivos, medida desde el centro del grupo

**Restricción matemática**:
$$\beta_{min} > 0°$$

**Propósito**:
- Eliminar redundancias cuando individuos están excesivamente cercanos angularmente
- Evitar cambios abruptos en intervalos cortos
- Prevenir inconsistencias en las ecuaciones (2) y (3)

**Valor adoptado en este trabajo**: $\beta_{min} = 15°$

**Criterio de eliminación**: Si $\beta = \theta_{(i+1)} - \theta_i \leq \beta_{min}$, entonces se elimina el punto más cercano al centro del grupo (menor $d_i$)

#### 4.2.2 Distancia Angular Máxima: $\beta_{max}$

**Descripción**: Distancia angular máxima permitida entre dos individuos consecutivos antes de insertar un punto intermedio

**Restricción matemática**:
$$\beta_{max} > \beta_{min}$$

**Propósito**:
- Prevenir regiones vacías excesivamente grandes
- Garantizar cobertura homogénea del modelo
- Evitar expansión gaussiana excesiva

**Valor adoptado en este trabajo**: $\beta_{max} = 70°$

**Criterio de inserción**: Si $\beta = \theta_{(i+1)} - \theta_i > \beta_{max}$, entonces se inserta un nuevo punto $P_{new}$

### 4.3 Parámetros de Generación de Puntos Insertados

#### 4.3.1 Ángulo del Nuevo Punto: $\theta_{new}$

**Ecuación (18)**:
$$\theta_{new} = \frac{\theta_{(i+1)} + \theta_i}{2}$$

**Definición**:
- Ángulo del nuevo punto $P_{new}$ inserido entre dos puntos consecutivos
- Se calcula como el promedio angular de los puntos adyacentes
- Garantiza posicionamiento simétrico angularmente

**Propósito**: Asegurar continuidad direccional en la distribución angular de puntos

#### 4.3.2 Distancia Radial del Nuevo Punto: $d_{new}$

**Ecuación (19)**:
$$d_{new} = \frac{d_{(i+1)} + d_i}{4}$$

**Definición**:
- Distancia radial del nuevo punto $P_{new}$ respecto al centro del grupo
- Calculada como promedio ponderado de distancias radiales adyacentes
- Factor de división (4) coloca el punto más interior que el promedio aritmético simple

**Propósito**: Posicionar realísticamente el punto sintético entre individuos consecutivos

**Coordenadas cartesianas resultantes** (Ecuaciones 20-21):
$$X_{new} = d_{new} \times \cos(\theta_{new})$$
$$Y_{new} = d_{new} \times \sin(\theta_{new})$$

### 4.4 Parámetros de Filtrado de la Superficie Gaussiana

#### 4.4.1 Umbral de Corte Gaussiano: $Z_{corte}$

**Descripción**: Valor umbral aplicado a la salida $Z_g$ que filtra los puntos de la superficie gaussiana

**Restricción matemática**:
$$0 < Z_{corte} < 1$$

**Propósito**:
- Retener únicamente los puntos que representan adecuadamente la zona proxémica del grupo
- Optimizar la generación del modelo gaussiano
- Controlar el tamaño de la zona proxémica delimitada

**Valor adoptado en este trabajo**: $Z_{corte} = 0.55$

**Criterio de retención**:
$$\text{Si } Z_g \geq Z_{corte} \text{ entonces retener punto } (X_g, Y_g, Z_g)$$
$$\text{En caso contrario, descartar punto}$$

**Relación inversa con tamaño de zona**:
- Valores menores de $Z_{corte}$ → zona proxémica más grande
- Valores mayores de $Z_{corte}$ → zona proxémica más pequeña

**Comportamiento**: El tamaño y forma de la zona proxémica se adaptan coherentemente a la distribución espacial de los miembros del grupo

## 5. Variables Dinámicas del Modelo

### 5.1 Ángulo de Cada Individuo: $\theta_i$

**Ecuación (8)**:
$$\theta_i = \arctan2(Y_i - Y_{cg}, X_i - X_{cg})$$

**Definición**:
- Ángulo medido desde el eje X' positivo hasta la línea que conecta el centro CG con el punto $P_i$
- Medición en sentido counterclockwise (antihorario)

**Dominio restringido**:
$$0° \leq \theta_i \leq 360°$$

**Propósito**: Establecer la posición angular de cada individuo respecto al centro del grupo

### 5.2 Distancia Euclidiana de Cada Individuo: $d_i$

**Ecuación (11)**:
$$d_i = \sqrt{(X_i - X_{cg})^2 + (Y_i - Y_{cg})^2}$$

**Definición**:
- Distancia euclidiana entre el punto $P_i$ y el centro del grupo CG
- Medida radial desde el centro

**Restricción**: 
$$d_i > 0 \text{ para todo } i$$

**Propósito**: Determinar la extensión radial de la zona proxémica en cada dirección

### 5.3 Intervalo Angular: $\omega_i$

**Ecuación (5)**:
$$\omega_i = \theta_{(i+1)} - \theta_i$$

**Definición**:
- Intervalo angular definido entre dos puntos consecutivos $P_i$ y $P_{(i+1)}$
- Representa el "ancho" angular de la sección

**Restricción**:
$$\omega_i > 0, \forall i \in \{1, 2, \ldots, n\}$$

**Propósito**: Definir los límites angulares de cada sección gaussiana

### 5.4 Ángulos Discretos de Sección: $\phi_j$

**Ecuación (6)**:
$$\phi_{(j+1)} = \phi_j + \Delta\gamma$$

**Definición**:
- Ángulos generados mediante incremento fijo $\Delta\gamma$ dentro de cada intervalo $\omega_i$
- Discretizan el intervalo entre dos individuos consecutivos

**Proceso iterativo**:
- Inicio: $\phi_j = \theta_i$ (ángulo del primer individuo de la sección)
- Actualización: $\phi_j \leftarrow \phi_j + \Delta\gamma$
- Terminación: Cuando $\phi_j \geq \omega_i$, proceder a siguiente sección (ver Ecuación 7)

**Criterio de transición de sección** (Ecuación 7):
$$\text{Si } \phi_j \geq \omega_i \text{ entonces } i \leftarrow i + 1$$

## 6. Varianzas Madres del Modelo

### 6.1 Cálculo de Varianzas Madres (Ecuación 4)

$$\sigma_{Mxi} = \sigma_{Myi} = d_i + \sigma_{min}$$

**Definición**:
- Varianzas madre asociadas a cada punto de distribución $P_i$
- Representan los valores base de varianza en direcciones x e y
- Varían dependiendo de la distancia del individuo al centro del grupo

**Propósito**:
- Servir como valores base desde los cuales se derivan $\sigma_{xj}$ y $\sigma_{yj}$
- Individuos más alejados del centro generan varianzas más grandes
- Individuos cercanos al centro generan varianzas más pequeñas (ajustadas por $\sigma_{min}$)

**Individuos consecutivos**:
- $\sigma_{Mxi}, \sigma_{Myi}$: Varianzas madre del punto $P_i$
- $\sigma_{Mx(i+1)}, \sigma_{My(i+1)}$: Varianzas madre del punto $P_{(i+1)}$

## 7. Varianzas Interpoladas de Secciones

### 7.1 Interpolación de Varianzas en X (Ecuación 2)

$$\sigma_{xj} = \left(\frac{\omega_i - \phi_j}{\omega_i}\right) \sigma_{Mxi} + \left(\frac{\phi_j}{\omega_i}\right) \sigma_{Mx(i+1)}$$

**Definición**:
- Varianza en dirección x asignada al área entre los ángulos $\phi_j$ y $\phi_{(j+1)}$
- Interpolación lineal entre varianzas madres de puntos consecutivos
- Ponderación basada en posición angular relativa

**Componentes**:
- $\left(\frac{\omega_i - \phi_j}{\omega_i}\right)$: Factor de peso decreciente (acercamiento a $P_{(i+1)}$)
- $\left(\frac{\phi_j}{\omega_i}\right)$: Factor de peso creciente (alejamiento de $P_i$)

### 7.2 Interpolación de Varianzas en Y (Ecuación 3)

$$\sigma_{yj} = \left(\frac{\omega_i - \phi_j}{\omega_i}\right) \sigma_{Myi} + \left(\frac{\phi_j}{\omega_i}\right) \sigma_{My(i+1)}$$

**Definición**:
- Varianza en dirección y asignada al área entre los ángulos $\phi_j$ y $\phi_{(j+1)}$
- Estructura idéntica a la interpolación en X pero para dirección y

**Propósito de ambas interpolaciones**:
- Garantizar transiciones suaves y continuas entre secciones angulares
- Evitar cambios abruptos en los contornos de la función gaussiana
- Mantener continuidad matemática de la superficie

**Restricción fundamental**:
$$\sigma_{xj} > 0, \sigma_{yj} > 0, \forall j \in \{1, 2, \ldots, n\}$$

## 8. Dirección del Grupo

### 8.1 Cálculo del Vector Resultante (Ecuación 14)

$$\vec{R}(X_R, Y_R) = \sum_{i=1}^{n} (X_i - X_{cg}, Y_i - Y_{cg})$$

**Definición**:
- Vector resultante que integra las posiciones relativas de todos los individuos respecto al centro CG
- Representa la dirección global del grupo
- Suma vectorial de posiciones relativas

**Componentes**:
- $X_R$: Componente cartesiana x del vector resultante
- $Y_R$: Componente cartesiana y del vector resultante

### 8.2 Ángulo de Referencia del Grupo (Ecuación 15)

$$\alpha = \arctan2(Y_R, X_R)$$

**Definición**:
- Ángulo de referencia del grupo calculado desde el vector resultante $\vec{R}$
- Medido respecto al eje X' positivo
- Determina la orientación global del grupo

**Propósito**: Identificar al primer individuo como el más cercano a la dirección del grupo en sentido counterclockwise, evitando ambigüedades

## 9. Rotación y Alineación de Coordenadas

### 9.1 Transformación de Coordenadas (Ecuación 16)

$$\begin{bmatrix} X_i^r \\ Y_i^r \end{bmatrix} = \begin{bmatrix} \cos(-\theta_{(n-1)}) & -\sin(-\theta_{(n-1)}) \\ \sin(-\theta_{(n-1)}) & \cos(-\theta_{(n-1)}) \end{bmatrix} \left( \begin{bmatrix} X_i \\ Y_i \end{bmatrix} - \begin{bmatrix} X_{cg} \\ Y_{cg} \end{bmatrix} \right) + \begin{bmatrix} X_{cg} \\ Y_{cg} \end{bmatrix}$$

**Definición**:
- Transforma coordenadas de todos los puntos mediante rotación alrededor del centro del grupo
- Realiza una traslación inicial hacia origen global, rotación, y traslación de retorno

**Parámetro de rotación**:
- $\theta_{(n-1)}$: Ángulo del primer individuo seleccionado (en sentido counterclockwise)

**Resultado**:
- $(X_i^r, Y_i^r)$: Coordenadas transformadas del punto $P_i$ en el nuevo sistema de referencia
- El primer individuo se posiciona sobre el eje X' con ángulo $\theta = 0$

**Propósito**: Simplificar cálculos del modelo al alinear al menos un individuo con el eje de referencia

### 9.2 Rotación Inversa (Ecuación 22)

$$\begin{bmatrix} X_g \\ Y_g \\ Z_g \end{bmatrix} = \begin{bmatrix} \cos(\theta_{(n-1)}) & -\sin(\theta_{(n-1)}) & 0 \\ \sin(\theta_{(n-1)}) & \cos(\theta_{(n-1)}) & 0 \\ 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} X_g - X_{cg} \\ Y_g - Y_{cg} \\ Z_g \end{bmatrix} + \begin{bmatrix} X_{cg} \\ Y_{cg} \\ 0 \end{bmatrix}$$

**Definición**:
- Retorna todos los puntos generados a sus posiciones en el sistema de coordenadas original
- Deshace la rotación aplicada en la Ecuación 16
- Asegura que la representación gaussiana corresponda a la distribución original del grupo

**Resultado**:
- $(X_g, Y_g, Z_g)$: Coordenadas finales del punto en el sistema original
- La zona proxémica representa la morfología del grupo en su configuración original

**Propósito**: Garantizar que el modelo gaussiano generado corresponda correctamente al grupo original sin distorsiones rotacionales

## 10. Asignación de Varianzas a Puntos de Evaluación

### 10.1 Cálculo de Ángulo del Punto de Evaluación (Ecuación 12)

$$\alpha_{gk} = \arctan2(Y_{gk}, X_{gk})$$

**Definición**:
- Ángulo asociado con el punto $(X_{gk}, Y_{gk})$ en la malla de evaluación
- Medido respecto al eje X' positivo
- Determina a qué sección angular pertenece el punto

**Propósito**: Identificar la sección angular correspondiente para asignar varianzas apropiadas

### 10.2 Criterio de Asignación de Varianzas (Ecuación 13)

$$\text{Si } \phi_i < \alpha_{gk} < \phi_{(j+1)} \text{ entonces } \sigma_{xk} = \sigma_{x(j+1)}, \sigma_{yk} = \sigma_{y(j+1)}$$

**Definición**:
- Asigna a cada punto de malla $(X_{gk}, Y_{gk})$ las varianzas correspondientes a su sección angular
- Búsqueda de sección: encontrar los ángulos límite $\phi_i$ y $\phi_{(j+1)}$ que contienen a $\alpha_{gk}$

**Variables asignadas**:
- $\sigma_{xk}$: Varianza en x para el punto $(X_{gk}, Y_{gk})$
- $\sigma_{yk}$: Varianza en y para el punto $(X_{gk}, Y_{gk})$
- $\sigma_{x(j+1)}, \sigma_{y(j+1)}$: Varianzas de la sección encontrada

**Propósito**: Establecer correspondencia entre evaluación de puntos y secciones angulares, garantizando consistencia en la representación gaussiana

## 11. Flujo del Algoritmo Completo

### 11.1 Etapa 1: Organización de Datos de Entrada

1. **Entrada**: Posiciones de los n individuos del grupo: $(X_1, Y_1), (X_2, Y_2), \ldots, (X_n, Y_n)$

2. **Cálculo del Centro del Grupo**:
   - Calcular $X_{cg}$ usando Ecuación 9
   - Calcular $Y_{cg}$ usando Ecuación 10

3. **Ordenamiento de Puntos**:
   - Ordenar los n puntos en sentido counterclockwise alrededor de CG
   - Comenzar desde el punto más cercano al eje X' positivo
   - Continuar hasta completar la vuelta completa

4. **Cálculo de Variables Básicas**:
   - Para cada individuo i, calcular:
     - $\theta_i$ usando Ecuación 8
     - $d_i$ usando Ecuación 11

5. **Determinación de Primer Individuo**:
   - Calcular vector resultante $\vec{R}(X_R, Y_R)$ usando Ecuación 14
   - Calcular ángulo de referencia $\alpha$ usando Ecuación 15
   - Seleccionar como primer individuo $P_1$ aquel cuyo $\theta_i$ sea más cercano a $\alpha$ en sentido counterclockwise

### 11.2 Etapa 2: Optimización del Modelo

#### Paso 1: Eliminación de Puntos Cercanos

Realizar iterativamente:
- Para cada par de puntos consecutivos $(P_i, P_{(i+1)})$:
  - Calcular $\beta = \theta_{(i+1)} - \theta_i$
  - Si $\beta \leq \beta_{min}$:
    - Comparar distancias $d_i$ y $d_{(i+1)}$
    - Eliminar el punto con menor distancia al centro (más cercano a CG)
  - Repetir hasta que no se eliminen más puntos

#### Paso 2: Inserción de Puntos Distantes

Realizar iterativamente:
- Para cada par de puntos consecutivos $(P_i, P_{(i+1)})$:
  - Calcular $\beta = \theta_{(i+1)} - \theta_i$
  - Si $\beta > \beta_{max}$:
    - Calcular $\theta_{new}$ usando Ecuación 18
    - Calcular $d_{new}$ usando Ecuación 19
    - Calcular $X_{new}$ usando Ecuación 20
    - Calcular $Y_{new}$ usando Ecuación 21
    - Insertar nuevo punto $P_{new}$ en la lista ordenada
  - Repetir hasta que todos los intervalos satisfagan $\beta_{min} < \beta \leq \beta_{max}$

**Resultado**: Lista optimizada de puntos con mejor cobertura angular y distribución radial

### 11.3 Etapa 3: Rotación del Sistema

- Calcular ángulo de rotación como $-\theta_{(n-1)}$ (negativo del ángulo del primer punto)
- Aplicar transformación de coordenadas usando Ecuación 16 a todos los puntos
- Alinear el primer punto con el eje X' ($\theta = 0°$)

### 11.4 Etapa 4: Cálculo de Varianzas Madres

Para cada punto optimizado $P_i$:
- Calcular $\sigma_{Mxi}$ y $\sigma_{Myi}$ usando Ecuación 4:
  $$\sigma_{Mxi} = \sigma_{Myi} = d_i + \sigma_{min}$$

### 11.5 Etapa 5: Generación de la Malla Gaussiana

1. **Inicialización de malla**:
   - Definir dominio rectangular que contenga al grupo
   - Generar puntos de malla $(X_{gk}, Y_{gk})$ con paso de discretización
   - Total de L puntos de malla a evaluar

2. **Para cada punto de malla** $(X_{gk}, Y_{gk})$ donde $k = 1, 2, \ldots, L$:

   a. **Calcular ángulo del punto**:
      - $\alpha_{gk}$ usando Ecuación 12

   b. **Encontrar sección angular**:
      - Determinar los índices i y j tales que $\phi_i < \alpha_{gk} < \phi_{(j+1)}$
      - Esta búsqueda se realiza iterando sobre las secciones generadas

   c. **Asignar varianzas** usando Ecuación 13:
      - $\sigma_{xk} = \sigma_{x(j+1)}$
      - $\sigma_{yk} = \sigma_{y(j+1)}$

   d. **Calcular valor gaussiano**:
      - $Z_{gk} = \exp\left(-\frac{(X_{gk} - X_{cg})^2}{2\sigma_{xk}^2} - \frac{(Y_{gk} - Y_{cg})^2}{2\sigma_{yk}^2}\right)$

3. **Almacenar resultado**:
   - Guardar tupla $(X_{gk}, Y_{gk}, Z_{gk})$

### 11.6 Etapa 6: Filtrado de Puntos

Para cada punto de malla $(X_{gk}, Y_{gk}, Z_{gk})$:
- Si $Z_{gk} \geq Z_{corte}$:
  - Retener punto como parte de la zona proxémica
- Si $Z_{gk} < Z_{corte}$:
  - Descartar punto

**Resultado**: Conjunto filtrado de puntos que delimitan la zona proxémica

### 11.7 Etapa 7: Rotación Inversa

Para cada punto retenido $(X_g, Y_g, Z_g)$:
- Aplicar transformación inversa usando Ecuación 22
- Retornar punto al sistema de coordenadas original
- Generar $(X_g', Y_g', Z_g')$ en coordenadas globales

**Resultado**: Zona proxémica del grupo en su configuración y posición original

### 11.8 Etapa 8: Salida del Modelo

**Retorna**:
- Conjunto de puntos $(X_g', Y_g', Z_g')$ que representan la zona proxémica gaussiana del grupo
- Estos puntos pueden usarse directamente como:
  - Contornos de la zona proxémica
  - Mapa de costos para planificadores basados en costmap
  - Restricciones de navegación para robots

## 12. Algoritmo Estructurado Completo (Pseudoalgoritmo)

```
ALGORITMO: MallaGaussiana

ENTRADA: 
  - Posiciones de individuos: x, y (coordenadas cartesianas de n puntos)
  
PARÁMETROS:
  - σmin = 0.5              (varianza mínima)
  - Δγ = [valor específico] (incremento angular)
  - βmin = 15°              (distancia angular mínima)
  - βmax = 70°              (distancia angular máxima)
  - Zcorte = 0.55           (umbral de corte gaussiano)

SALIDA:
  - Conjunto de puntos (Xg, Yg, Zg) representando la zona proxémica

═════════════════════════════════════════════════════════════════

SECCIÓN 1: ORGANIZACIÓN DE DATOS
  1.1 CALCULAR centro del grupo (Xcg, Ycg)
      Xcg ← (max(x) + min(x)) / 2
      Ycg ← (max(y) + min(y)) / 2
  
  1.2 ORDENAR puntos en sentido counterclockwise alrededor de CG
      xord, yord ← SortCounterclockwise(Xcg, Ycg, x, y)
  
  1.3 CALCULAR ángulos y distancias para cada punto
      PARA i = 1 hasta n:
          θi ← arctan2(yord[i] - Ycg, xord[i] - Xcg)
          di ← √[(xord[i] - Xcg)² + (yord[i] - Ycg)²]
  
  1.4 CALCULAR dirección del grupo
      XR ← SUMA(xord[i] - Xcg) para i = 1 hasta n
      YR ← SUMA(yord[i] - Ycg) para i = 1 hasta n
      α ← arctan2(YR, XR)
  
  1.5 IDENTIFICAR primer individuo
      P1 ← punto cuyo θi es más cercano a α en sentido counterclockwise

═════════════════════════════════════════════════════════════════

SECCIÓN 2: OPTIMIZACIÓN
  2.1 ELIMINAR puntos cercanos
      MIENTRAS existan puntos para eliminar:
          PARA cada par (Pi, P(i+1)):
              β ← θ(i+1) - θi
              SI β ≤ βmin:
                  Eliminar punto con menor di
  
  2.2 INSERTAR puntos distantes
      MIENTRAS existan intervalos por llenar:
          PARA cada par (Pi, P(i+1)):
              β ← θ(i+1) - θi
              SI β > βmax:
                  θnew ← (θ(i+1) + θi) / 2
                  dnew ← (d(i+1) + di) / 4
                  Xnew ← dnew × cos(θnew)
                  Ynew ← dnew × sin(θnew)
                  Insertar Pnew

═════════════════════════════════════════════════════════════════

SECCIÓN 3: ROTACIÓN INICIAL
  3.1 CALCULAR ángulo de rotación
      rot ← -θ(primer_punto)
  
  3.2 ROTAR todos los puntos usando Ecuación 16
      PARA cada punto Pi:
          (Xr[i], Yr[i]) ← Matriz_Rotación(rot, Xi, Yi, Xcg, Ycg)

═════════════════════════════════════════════════════════════════

SECCIÓN 4: VARIANZAS MADRES
  4.1 CALCULAR varianzas madres para cada punto
      PARA i = 1 hasta n:
          σMxi ← di + σmin
          σMyi ← di + σmin

═════════════════════════════════════════════════════════════════

SECCIÓN 5: GENERACIÓN DE MALLA
  5.1 DEFINIR dominio y crear malla de puntos (Xgk, Ygk), k=1..L
  
  5.2 PARA cada punto de malla (Xgk, Ygk):
      
      5.2.1 CALCULAR ángulo del punto
            αgk ← arctan2(Ygk, Xgk)
      
      5.2.2 ENCONTRAR sección angular
            ENCONTRAR i, j tal que: φi < αgk < φ(j+1)
      
      5.2.3 ASIGNAR varianzas
            σxk ← σx(j+1)
            σyk ← σy(j+1)
      
      5.2.4 EVALUAR función gaussiana
            Zgk ← exp(-(Xgk - Xcg)²/(2σxk²) - (Ygk - Ycg)²/(2σyk²))
      
      5.2.5 ALMACENAR punto
            Guardar (Xgk, Ygk, Zgk)

═════════════════════════════════════════════════════════════════

SECCIÓN 6: FILTRADO
  6.1 PARA cada punto de malla (Xgk, Ygk, Zgk):
      SI Zgk ≥ Zcorte:
          Retener punto
      SINO:
          Descartar punto

═════════════════════════════════════════════════════════════════

SECCIÓN 7: ROTACIÓN INVERSA
  7.1 PARA cada punto retenido (Xg, Yg, Zg):
      (Xg', Yg', Zg') ← Matriz_Rotación_Inversa(-rot, Xg, Yg, Zg, Xcg, Ycg)
      usando Ecuación 22

═════════════════════════════════════════════════════════════════

SECCIÓN 8: RETORNO DE RESULTADOS
  8.1 RETORNAR conjunto de puntos (Xg', Yg', Zg') con Zg' ≥ Zcorte

FINALGORITMO
```

## 13. Restricciones y Condiciones de Validez

### 13.1 Restricciones Matemáticas Fundamentales

$$\omega_i > 0, \forall i \in \{1, 2, \ldots, n\}$$
$$\sigma_{xj} > 0, \forall j \in \{1, 2, \ldots, n\}$$

Los valores nulos en estas variables conducen a indeterminaciones en la Ecuación 1.

### 13.2 Restricciones de Parámetros

$$\sigma_{min} > 0$$
$$\Delta\gamma > 0$$
$$0 < \beta_{min} < \beta_{max}$$
$$0 < Z_{corte} < 1$$

### 13.3 Supuestos del Modelo

1. **Grupo ya identificado**: El modelo asume que el sistema de identificación de grupos ya ha completado su tarea
2. **Posiciones conocidas**: Se requiere acceso a las posiciones precisas de todos los individuos
3. **Número finito de individuos**: El grupo debe tener un número discreto y acotado de miembros
4. **Ambiente estático**: Durante la evaluación del modelo, se asume que las posiciones permanecen relativamente estables

## 14. Integración en Sistema de Navegación ROS

### 14.1 Uso del Modelo en Costmap

Los valores $Z_g$ generados por el modelo se utilizan directamente en el costmap del Navigation Stack:

- Puntos con $Z_g$ alto (cercanos a 1) → Costo elevado (zona prohibida)
- Puntos con $Z_g$ bajo (cercanos a 0) → Costo bajo (navegable)
- El máximo ($Z_g = 1$) se asigna al centro del grupo coincidiendo con O-space de Kendon
- Esto produce un costo prohibitivamente alto para navegación

### 14.2 Proceso de Integración

1. **Detección de grupo** → Obtener posiciones de individuos
2. **Ejecución del modelo** → Generar puntos $(X_g', Y_g', Z_g')$
3. **Población del costmap** → Asignar valores Z a las celdas correspondientes
4. **Planificación global** → A* genera ruta evitando altos costos
5. **Planificación local** → DWA o similar genera trayectoria suave respetando costmap

## 15. Métricas de Evaluación del Modelo

### 15.1 Área Ocupada

$$A_{propuesto} = \text{Área delimitada por el contorno exterior de la zona proxémica generada}$$

### 15.2 Porcentaje de Área Ahorrada

$$\%A_{ahorrado} = \frac{A_{De Sousa} - A_{propuesto}}{A_{De Sousa}} \times 100\%$$

Donde $A_{De Sousa}$ es el área del método de referencia.

### 15.3 Suavidad de Trayectoria

Métrica que evalúa cambios angulares en segmentos consecutivos de la trayectoria generada. Valores menores indican trayectorias más fluidas.

### 15.4 Distancia Promedio a Grupo

$$d_{promedio} = \frac{\sum_{i=1}^{n} d_{min,i}}{n}$$

Donde $d_{min,i}$ es la distancia mínima del miembro i a la trayectoria del robot.

## 16. Resumen de Notación

| Símbolo | Definición | Rango/Tipo |
|---------|-----------|-----------|
| $n$ | Número de individuos en el grupo | $\mathbb{N}^+$ |
| $P_i$ | Punto/individuo i-ésimo | Punto del grupo |
| $(X_i, Y_i)$ | Coordenadas cartesianas del individuo i | $\mathbb{R}^2$ |
| $(X_{cg}, Y_{cg})$ | Centro geométrico del grupo | $\mathbb{R}^2$ |
| $\theta_i$ | Ángulo del individuo i respecto a CG | $[0°, 360°)$ |
| $d_i$ | Distancia radial del individuo i respecto a CG | $\mathbb{R}^+$ |
| $\omega_i$ | Intervalo angular entre Pi y P(i+1) | $\mathbb{R}^+$ |
| $\phi_j$ | Ángulo discreto j dentro de sección i | $\mathbb{R}$ |
| $\sigma_x, \sigma_y$ | Varianzas en direcciones x e y | $\mathbb{R}^+$ |
| $\sigma_{Mxi}, \sigma_{Myi}$ | Varianzas madres del punto i | $\mathbb{R}^+$ |
| $\sigma_{xj}, \sigma_{yj}$ | Varianzas interpoladas de sección j | $\mathbb{R}^+$ |
| $Z_g$ | Valor de la función gaussiana | $[0, 1]$ |
| $Z_{corte}$ | Umbral de corte gaussiano | $[0, 1]$ |
| $(X_g, Y_g, Z_g)$ | Punto de la malla gaussiana | $\mathbb{R}^3$ |
| $\alpha_{gk}$ | Ángulo del punto de malla k | $\mathbb{R}$ |
| $\vec{R}$ | Vector resultante de posiciones relativas | $\mathbb{R}^2$ |
| $\alpha$ | Ángulo de referencia del grupo | $\mathbb{R}$ |

---

**Documento generado basado en**: "Social Robots Navigation using Angular Sectioned Gaussian Model, with Adaptive Parametrization, for Representing Proxemic Zones of Groups of Humans" por Nelson Paco-Chipana et al.
