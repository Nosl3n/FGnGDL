# GANGL_V05 - Generación de Mallas Gaussianas en MATLAB

La función `GANGL_V05` procesa un conjunto de puntos `(x, y)` para determinar su distribución, orientación y generar una **malla gaussiana 3D**.  
La función incluye varias etapas:  

 **Determinación del centro del grupo**  
 **Ordenamiento de puntos**  
 **Cálculo de distancias y ángulos**  
 **Eliminación y adición de puntos**  
 **Rotación y graficación de la malla gaussiana**  

---

## Uso

```matlab
Area = GANGL_V05(x, y, graf, VISTA, per);
```

## Parámetros de entrada

- `x`: Vector con coordenadas **x** de los puntos.  
- `y`: Vector con coordenadas **y** de los puntos.  
- `graf`: Control de visualización (`1 = Sí`, `0 = No`).  
- `VISTA`: Modo de visualización (`2 = 2D`, `3 = 3D`).  
- `per`: Control de representación de personas (`1 = Con personas`, `0 = Sin personas`).  

---

## Salida

- `Area`: Devuelve el área bajo el contorno de nivel **0.3** de la malla gaussiana generada.  

---

## Explicación del Proceso  

###  1. Determinación del Centro del Grupo
El **centro de masa** `(xcm, ycm)` se calcula a partir de los puntos proporcionados.  

###  2. Ordenamiento de Puntos
Se ordenan los puntos en sentido horario respecto al centro de masa con la función:  

```matlab
[x_ord, y_ord] = ordenar_puntos(xcm, ycm, x, y);
```

###  3. Cálculo de Distancias y Ángulos  
Se determinan las distancias y los ángulos de cada punto respecto al eje **x** y al centro de masa:  

```matlab
[dis, ang] = dis_ang(x_ord, y_ord, xcm, ycm);
```

###  4. Determinación de la Orientación del Grupo
Se calcula la dirección angular del grupo utilizando la función: 

```matlab
ang_vec = orientacion_vec(x_ord, y_ord, xcm, ycm, graf);
```

###  5. Eliminación y Adición de Puntos
- Se eliminan personas si están demasiado cerca (entre_personas).
- Se añaden personas si hay espacios muy grandes (aumentar_02).

```matlab
[x_mod, y_mod] = entre_personas(15, ang, dis, x_ord, y_ord);
[x_aum, y_aum] = aumentar_02(70, x_mod, y_mod, xcm, ycm);

```

###  6. Rotación de los Puntos
Los puntos se rotan para alinear la orientación con el ángulo calculado:

```matlab
[xrot, yrot, zrot] = rotar_gaussiana(xx, yy, zz, rotacion, xcm, ycm);
```

###  7. Generación de la Malla Gaussiana
Se genera una malla en 2D/3D para representar la distribución de los puntos:

```matlab
zz = exp(-(xx - xcm).^2 ./ (2 .* varianzax.^2) - (yy - ycm).^2 ./ (2 .* varianzay.^2));
```

###  8. Cálculo del Área Bajo la Curva
El área bajo el contorno de nivel 0.3 se calcula mediante integración numérica:

```matlab
Area = polyarea(x_contour, y_contour);
```

## Ejemplo de Uso

también puede ver el archivo `Principal.m` para ver un ejemplo de funcionamiento.

### Definir coordenadas de los puntos

```matlab
x = [1, 3, 5, 7, 9];
y = [2, 4, 6, 8, 10];
```

### Generar la malla gaussiana en 3D con personas

```matlab
Area = GANGL_V05(x, y, 1, 3, 1);
```

### Ver el área total

```matlab
fprintf("Área: %f", Area);
```

## Cambios recientes (auto-generado)
Fecha: 2026-08-26

Resumen de archivos modificados / añadidos (según git status):

- M FUNCTIONS/Assimetric_Gaussian.m
- M MODELOS/Individual_Group_Model.m
- M MODELOS/Modelo.m
- M MODELOS/Paco_Model.m
- RD Algoritmo_RGD_mv.m -> dinamic_exaple.m (rename/duplicado)
- RM Principal.m -> individual_dinamic.m (rename/moved)
- R  Algoritmo_RGD.m -> static_example.m (rename)
- ?? Experimento_01.m (nuevo)
- ?? MODELOS/Aracelly_model.m (nuevo/untracked)
- ?? analisis_algoritmo_gaussianas_grupales.md (nuevo)
- ?? dinamic_example.m (nuevo)
- ?? dinamic_example_M.m (nuevo)
- ?? individual_dinamic_3d.m (nuevo)
- ?? individual_dinamic_M.m (nuevo)
- ?? modelo_humano.m (nuevo)
- ?? static_example_M.m (nuevo)

Notas y descripción de cambios relevantes (detallado para los archivos desarrollados en esta sesión):

- Experimento_01.m (nuevo)
  - Script para crear una simulación controlada con un número fijo de personas (N = 7 por defecto).
  - Posiciones iniciales editables en la variable positions_init (N x 2).
  - Representación de cada persona como triángulo orientado (vista aérea).
  - Integración con MODELOS/Modelo.m para graficar un único modelo proxémico (uso de Modelo(x,y,m)).
  - Parámetros de simulación configurables (duration, fps). Nota: el script fue adaptado durante la sesión — revisarlo antes de usar en producción.

- modelo_humano.m (nuevo/modificado)
  - Script estático para dibujar personas en vista superior sin animación.
  - Entrada: vectores x, y (posiciones) y theta (orientaciones en grados) o orient (en radianes).
  - Representación por "capsule" (rectángulo con extremos semicirculares) que simula la anchura de hombros; la cápsula está centrada en (x,y) y el lado largo queda perpendicular a la orientación (anchura lateral).
  - Círculo central (radio = 0.1525 m) representando la cabeza/torso (se pinta encima de la cápsula).
  - Zona amarilla: círculo relleno (radio = 0.45 + 0.1525/4) pintado debajo del cuerpo (opacidad configurable).
  - Zona roja: círculo relleno más grande (radio = 0.45 + half_len) pintado debajo de la amarilla (opacidad configurable).
  - Flecha (quiver) que indica la orientación (apunta hacia theta).
  - Soporta definición manual de orientaciones: definir theta = [t1, t2, ...] en grados antes de ejecutar el script.

- MODELOS/* (archivos modificados)
  - Varios archivos bajo MODELOS aparecen como modificados: puede incluir correcciones o actualizaciones del comportamiento de los modelos proxémicos (Paco_Model, Individual_Group_Model, Modelo.m, etc.). Revisar estas funciones si se necesita compatibilidad con Experimento_01 o modelo_humano.

- Archivos renombrados/movidos
  - Algoritmo_RGD_mv.m fue renombrado a dinamic_exaple.m (RD)
  - Principal.m fue renombrado a individual_dinamic.m (RM)
  - Algoritmo_RGD.m renombrado a static_example.m (R)
  - Verificar estas renombraciones para mantener scripts que llamen a los nombres anteriores.

Sugerencias de uso rápido
- Para dibujar un conjunto de personas con orientaciones en grados:

```matlab
x = [1, 2, 3];
y = [1, 1.5, 2];
theta = [0, 45, 135]; % grados
run('modelo_humano.m');
```

- Para probar el ejemplo estático/experimental:
  - Editar positions_init en Experimento_01.m y ejecutar el script en MATLAB/Octave.
  - Ajustar model_id para seleccionar el modelo proxémico (ver MODELOS/Modelo.m).

Notas finales
- Este resumen fue generado automáticamente a partir del estado git del repositorio en la fecha indicada. Para más detalles ver los diffs con `git diff` o revisar cada archivo directamente.

---





