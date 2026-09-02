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

## Cambios recientes
Fecha: 2026-08-27

### 1) `MODELOS/Individual_model.m`
- Se actualizó la firma a:

```matlab
[xrot, yrot, zrot] = Individual_model(x, y, theta)
```

- Ahora recibe una sola persona (`x`, `y` escalares) y su orientación `theta` en grados.
- La gaussiana se genera primero con orientación base `0` y luego se rota con `theta`, para mantener forma consistente entre orientaciones.
- Mantiene la misma salida (`xrot`, `yrot`, `zrot`).

### 2) `MODELOS/Aracelly_model_theta.m`
- Se corrigió para usar explícitamente `theta` de entrada por persona (en grados).
- Ya no calcula la orientación mirando al centro del grupo.
- Se añadió validación de tamaño: `theta` debe tener el mismo número de elementos que `x` e `y`.
- La salida sigue siendo la malla global de la mezcla gaussiana (`xrot`, `yrot`, `zrot`).

### 3) `modelo_humano.m`
- Se integró el uso de orientaciones para los modelos:
  - Curva grupal usando `Aracelly_model_theta(...)`.
  - Curva individual por persona llamando `Individual_model(x(k), y(k), theta(k))`.
- Se añadieron curvas de contorno individuales (corte en nivel `h`) para cada persona.
- Se mantiene la visualización de cuerpo, zonas proxémicas y flecha de orientación.

### Ejemplo rápido
```matlab
x = [4.5, 4, 3, 2];
y = [1, -1, 0, 1];
theta = [200, 45, 30, 15]; % grados
run('modelo_humano.m');
```

---

Fecha: 2026-09-01

### 1) `MODELOS/Individual_Group_Model.m`
- Nuevo parámetro de entrada `op`:
  - `op == 1` -> `h` se calcula **analíticamente**, evaluando la suma de gaussianas del modelo en `(xh, yh)` (antes se obtenía por interpolación de la malla con `interp2`, lo que introducía error dependiente de la resolución de la malla).
  - `op ~= 1` -> `h` usa un valor fijo por defecto (`h_default = 0.85`), obtenido empíricamente como el nivel que en promedio incluye la zona proxémica íntima del grupo.
- `(xh, yh)` es el punto ubicado al borde de la zona proxémica íntima de Hall de la persona **más alejada** del centro geométrico del grupo, proyectado hacia afuera (`Dh = R_HB + D_iz`).
- Los parámetros del modelo (`lado`, `paso`, `sigma`, `R_HB`, `D_iz`, `Dh`, `h_default`) se agruparon y documentaron en un bloque único al inicio de la función.
- Se documentó que el "centro del grupo" (`xcm`, `ycm`) es el centro del bounding box (no el centroide/promedio), y por qué se prefiere así.
- Se documentó que el punto anterior (elegir a la persona más alejada vía `max`) es una decisión discreta: puede cambiar de golpe entre cuadros si dos personas quedan casi empatadas en distancia al centro, o si cambia la pertenencia a un grupo.

### 2) `MODELOS/Aracelly_model_theta.m`, `MODELOS/De_Sousa_Model.m`, `MODELOS/Paco_Model.m`
- Se añadió el mismo mecanismo de `op` para obtener `h` que en `Individual_Group_Model.m`, adaptado a la fórmula de densidad propia de cada modelo:
  - `Aracelly_model_theta`: gaussiana asimétrica orientada por persona (`k1,k2,k3`).
  - `De_Sousa_Model`: gaussiana asimétrica por sectores frontal/trasero/izquierda/derecha (`Assimetric_Gaussian.m`).
  - `Paco_Model`: gaussiana con varianzas variables por ángulo, evaluada deshaciendo la rotación que aplica `rotar_gaussiana.m` para ubicar `(xh,yh)` en el marco correcto.
- Los tres modelos ahora aceptan `theta` (orientación por persona, en grados) en su firma para tener la misma firma que `Modelo.m` espera; hoy solo `Aracelly_model_theta` la usa para el cálculo de densidad, las otras dos la reciben pero no la usan todavía.
- Valor por defecto de `h` (cuando `op ~= 1`) unificado a `0.85` en los cuatro modelos (antes `Paco_Model` y `De_Sousa_Model` usaban `0.5` fijo).
- En `Paco_Model.m` se corrigió una colisión de nombres: la variable interna que calculaba el ángulo de cada punto de la malla se llamaba `theta`, igual que el nuevo parámetro de orientación de personas; se renombró a `angGrid` para evitar confusión.

### 3) `Experimento_01.m`
- Las llamadas a `Modelo(...)` ahora pasan también `theta` (la orientación actual de cada persona), además de `mo` y `op`.
- Nueva función local `ExtractGroupTheta`: recupera el `theta` de cada persona de un grupo detectado por `Group_Detector_Distan`, emparejando sus coordenadas `(xin,yin)` con los vectores originales `x, y, theta_deg`.
- Suavizado exponencial de `h` entre cuadros de la animación (`hSmooth`, `alphaH = 0.2`), indexado por posición del grupo, para atenuar los saltos bruscos del contorno grupal que se documentaron en `Individual_Group_Model.m` (cambio de la persona "más alejada", o alguien entra/sale de un grupo).

---

Fecha: 2026-09-02

### 1) `MODELOS/Paco_Model_paper.m` — corrección de `Delta_gamma`
- Se detectó que `Delta_gamma` (incremento angular de discretización, Sección 4.1.2 del paper) estaba **desconectado** del resto del código: solo incrementaba la variable `cont`, mientras que el bucle principal (`for i = 1:360`), el tamaño de los arreglos (`sigma_xj`, `sigma_yj`, dimensionados en `zeros(1,360)`) y la asignación de sección a cada punto de la malla (`idx_gk`) estaban fijos a `360`, sin depender de `Delta_gamma`. Cambiar `Delta_gamma` a cualquier valor distinto de `1` producía interpolaciones inconsistentes (secciones desincronizadas entre el ángulo real y el índice del bucle).
- Corrección: se agregó `n_secciones = 360 / Delta_gamma` (con validación `mod(360, Delta_gamma) == 0`), y se reemplazó todo uso del literal `360` relacionado con el número de secciones por `n_secciones`. El bucle principal ahora separa el índice de arreglo (`i`) del ángulo real que representa (`angulo_actual = i * Delta_gamma`), y `idx_gk`/`idx_h` mapean el ángulo continuo a sección con `ceil(alpha / Delta_gamma)` en vez de `round(alpha)`.
- Con `Delta_gamma = 1` el comportamiento es idéntico al original (regresión verificada).

### 2) Hallazgo (sin corregir): `Z_corte` no filtra nada dentro de la función
- Tanto `Paco_Model_paper.m` como el `Paco_Model.m` original documentan en su encabezado que la función "devuelve solo los puntos cuya altura `Zg` es >= `h`" (filtro por `Z_corte`, Sección 4.4.1/Etapa 6 del paper). En la práctica, ninguna de las dos implementa ese filtrado: `rotar_gaussiana` devuelve siempre la malla completa sin recortar, y `h` solo se retorna como valor extra. Todos los llamadores existentes (`Experimento_01.m`, `dinamic_example*.m`, `static_example*.m`, `modelo_humano.m`) usan `h` únicamente como nivel para `contour(...)`, nunca para descartar puntos.
- No se modificó nada al respecto (queda documentado como comportamiento conocido, no como bug a resolver en esta sesión).

### 3) `MODELOS/Paco_Model_Paper_HO.m` — "h optimizado por sección"
- Nueva variante de `Paco_Model_paper.m` que reemplaza el corte plano (un único `Z_corte`/`h` paralelo al plano XY) por un **corte por sección angular**: cada una de las `n_secciones` tiene su propio umbral, calculado evaluando la gaussiana de esa misma sección (`sigma_xj(j)`, `sigma_yj(j)`) en el punto ubicado al borde de su propia zona íntima de Hall (radio `d_interpolado(j) + Dh`, proyectado hacia afuera en la dirección angular de la sección). Generaliza a todas las secciones el mismo principio que `Paco_Model_paper.m` aplicaba solo a la persona más expuesta del grupo.
- `d_interpolado(j)` se obtiene de `sigma_xj(j) - sigma_min` (no requiere interpolar `d_i` por separado, ya que `sigma_xj` es la interpolación lineal de `sigma_Mx = d_i + sigma_min`).
- Firma con una salida adicional: `[xrot, yrot, zrot, h, Dcorte] = Paco_Model_Paper_HO(x, y, theta_xy, op)`.
  - `op == 1` -> `h` es un **vector** `1 x n_secciones` (superficie de corte con forma).
  - `op ~= 1` -> `h` es el escalar fijo de siempre (`Z_corte_default`, plano paralelo a XY).
  - `Dcorte = Zg - h_por_sección`: su curva de nivel `0` (`contour(xrot, yrot, Dcorte, [0, 0])`) traza el borde de corte —plano o con forma según `op`— con el mismo costo computacional que un `contour` de nivel fijo, sin necesidad de dibujar la nube de puntos filtrados (más cara de renderizar que una curva).
- Verificado con MATLAB en modo headless: `op=0` da `h` escalar (p. ej. `0.5`); `op=1` da un vector de 720 valores (con `Delta_gamma = 0.5`) con variación real entre secciones (no degenerado a un solo valor).

### 4) `prueba.m` (nuevo, en la raíz del proyecto)
- Script de demostración, con el mismo esqueleto dinámico que `Experimento_01.m` (personas moviéndose con retorno suave a su posición inicial, rebote contra los límites y entre personas usando la cápsula corporal, siluetas dibujadas con `Individual_Human_Model`), pero recortado de la planificación A*/robot (no aporta a la comparación) y adaptado para llamar únicamente a `Paco_Model_Paper_HO.m`.
- Por cada grupo y cuadro, llama dos veces a `Paco_Model_Paper_HO` (mismas posiciones, distinto `op`) y superpone ambos contornos para que la diferencia sea directamente visible:
  - `op = 0` → corte constante, en azul.
  - `op = 1` → corte optimizado por sección, en rojo.
- Verificado ejecutándolo de punta a punta en MATLAB (modo headless, `-batch`) sin errores.
