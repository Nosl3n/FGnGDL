# FGnGDL

# 📌 Funciones de Procesamiento y Visualización en MATLAB

Este repositorio contiene una colección de funciones en MATLAB para el procesamiento, ordenamiento y visualización de datos relacionados con puntos y su distribución en el espacio. 

## 📂 Contenido

Las siguientes funciones están incluidas en este proyecto:

### 📌 1. `aumentar_02(maximo, x_ord, y_ord, xcm, ycm)`
**Descripción:**  
Ajusta la distribución de puntos `(x_ord, y_ord)` respecto a un centro de masa `(xcm, ycm)`, añadiendo nuevos puntos si las distancias angulares entre puntos consecutivos superan un valor máximo `(maximo)`.  

**Uso:**
```matlab
[x_aaum, y_aaum] = aumentar_02(maximo, x_ord, y_ord, xcm, ycm);
