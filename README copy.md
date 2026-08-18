# FGnGDL

Este directorio contiene un conjunto de scripts de MATLAB para modelar grupos de personas como una nube de puntos y analizar su distribución con una representación gaussiana. La idea principal es que, a partir de un conjunto de posiciones `(x, y)`, el código construye una sección gaussiana, determina su orientación y genera una envolvente que representa la zona del grupo.

El proyecto está pensado para pruebas en simulación, visualización de grupos y análisis de densidad en 2D/3D. En términos prácticos, combina movimiento de personas, cálculo de centro del grupo, generación de una superficie gaussiana y exploración de contornos por encima de un umbral.

## ¿Qué contiene este directorio?

### `GANGL_V05.m`
Script principal de generación de una malla gaussiana a partir de un conjunto de posiciones. Su propósito es:

- calcular el centro del grupo,
- ordenar los puntos alrededor del centro,
- estimar la orientación del conjunto,
- generar una malla gaussiana en torno a los puntos,
- devolver una sección o contorno por encima de un nivel de altura.

Es la pieza central del enfoque científico del proyecto: transformar una nube de posiciones en una representación continua de densidad espacial.

### `Section_Gaussian.m`
Función que toma coordenadas `(x, y)` y devuelve la sección gaussiana filtrada por un umbral `h`.

Su lógica principal es:

- determinar el centro geométrico del grupo,
- ordenar los puntos alrededor de dicho centro,
- calcular distancias y ángulos respecto a él,
- construir la distribución gaussiana orientada,
- devolver solo los puntos cuya altura `z` cumple la condición `z >= h`.

Esto permite trabajar con una versión “de sección” de la distribución, en vez de con la nube completa.

### `Principal.m`
Archivo de ejemplo de uso del método en MATLAB. Sirve como demostración del flujo básico:

- generar un conjunto aleatorio de posiciones,
- simular movimiento simple de personas,
- actualizar la representación gaussiana del grupo,
- dibujar contornos de nivel sobre la distribución.

Es útil para entender cómo se integra la sección gaussiana dentro de una animación o visualización.

### `Prueba_Gaussiana.m`
Versión más enfocada a simulación de personas como un único grupo gaussiano. Aquí se observa la idea de que todas las personas forman una misma agrupación y se procesan como una sola nube de puntos.

Incluye:

- movimiento individual con dirección e intensidad,
- rebote dentro de un rectángulo de simulación,
- separación para evitar traslapes entre personas,
- generación de la sección gaussiana del conjunto completo,
- dibujo de los puntos 2D que superan el umbral `H` en `z`.

Es una prueba útil para visualizar la relación entre la estructura del grupo y la distribución gaussiana.

### `simulacion.m`
Script de simulación más general para visualizar personas moviéndose en una escena 2D. En este archivo se simula el comportamiento de un conjunto de individuos, con movimiento, orientación y detección de grupos.

Su propósito es mostrar cómo se comporta una población en una ventana de simulación y cómo se pueden dibujar contornos, agrupaciones y trayectorias asociados al conjunto.

### `Principal.asv`
Archivo de respaldo generado automáticamente por MATLAB durante una sesión previa. No es la versión principal de trabajo y suele conservar una copia automática del último script ejecutado.

### `README.md`
Documentación general del proyecto y archivo base de referencia para la descripción del funcionamiento del código.

### `README copy.md`
Este archivo: una versión de documentación enfocada en explicar el contenido del directorio sin entrar en funciones auxiliares ni en la carpeta `FUNCTIONS`.

### `LICENSE`
Licencia del proyecto. Define las condiciones de uso, redistribución y distribución del código.

## Cómo encajan todos los archivos

El flujo general del proyecto es:

1. Se tienen posiciones de personas o puntos `(x, y)`.
2. Se alimentan a `Section_Gaussian` o a `GANGL_V05`.
3. El código calcula el centro, la orientación y la densidad del conjunto.
4. Se produce una representación gaussiana del grupo.
5. Se filtra por un umbral de altura `h` o `H`.
6. Se dibujan contornos o puntos relevantes en MATLAB.

En resumen, el proyecto convierte una nube de personas o puntos en una estructura gaussiana que puede visualizarse y analizarse como un conjunto continuo.

## Conceptos clave

### Grupo gaussiano
Un grupo se modela como una distribución espacial centralizada. Las personas no se consideran de manera aislada, sino como parte de una misma estructura que puede representarse mediante una nube o una elipse/gaussiana alrededor de un centro.

### Sección gaussiana
La sección gaussiana es la porción de la distribución que sobrepasa un umbral de altura. Esto permite seleccionar solo los puntos relevantes del grupo y no toda la estructura completa.

### Contornos y puntos filtrados
Una vez generada la distribución, se pueden dibujar:

- contornos de nivel,
- regiones del grupo,
- o solo los puntos que cumplen la condición `z >= h`.

Esto ayuda a representar visualmente la ocupación del espacio por el grupo.

## Requisitos

- MATLAB o Octave compatible con gráficos 2D/3D.
- Scripts de MATLAB ejecutados desde la carpeta del proyecto.
- Dependencias mínimas: el código del proyecto y, en algunos casos, las funciones auxiliares de `FUNCTIONS` cuando se usan en versiones más completas del análisis.

## Uso recomendado

Para empezar, lo más típico es ejecutar:

```matlab
Principal
```

o bien abrir `Prueba_Gaussiana.m` para una versión enfocada a la simulación visual de personas como grupo gaussiano.

También puede probarse el cálculo directo de la sección gaussiana con coordenadas reales:

```matlab
[x_sec, y_sec, z_sec] = Section_Gaussian(x, y, h);
```

## Resumen

Este directorio reúne un conjunto de herramientas MATLAB para:

- modelar grupos de personas como una distribución espacial,
- generar una sección gaussiana del grupo,
- filtrar la densidad por umbral,
- visualizar el comportamiento del conjunto en 2D o 3D,
- y servir como base para simulaciones y análisis de densidad de grupos.

Es un proyecto orientado a la representación visual y analítica de colectivos mediante modelos gaussianos, con aplicaciones en simulación de movimiento, formación de grupos y análisis espacial.
