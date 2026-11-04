# proyecto1-bases2
### Nombre y carné de los integrantes: 
- Noé López Durón (2024234500).
- Julián Pizarro Castro (2024146595).

### Estado del proyecto:
Finalizado.

### Objetivos del proyecto.

#### Cumplidos:
- CRUD completo de todas las entidades implicadas (clientes, inventario, proveedores y ventas).
- Reportes estadísticos 1, 2, 3, 4, 5, 6, 7, 8 y 10.
- Interfaz gráfica de usuario.
- Conexión entre GUI y backend funcionales.

#### No cumplidos:
- Reporte estadístico 9.

### Enlace del video: https://youtu.be/JJduwYpR-js


---

## Estándar para la gestión de ramas.
- Rama principal (main): Es la única rama de larga duración. Siempre debe contener la versión más reciente y estable del proyecto.
- Rama de desarrollo (dev): Es la rama que contiene las versiones intermedias del proyecto. Se debe confirmar que todo funciona aquí antes de hacer el merge con **main**.

- Para mantener el repositorio ordenado y saber en qué se está trabajando, se usará el formato *tipo/descripcion-breve*.

|Tipo de Rama |	Prefijo |	Ejemplo |	Descripción |
| ---   | --- | --- | --- |
Nueva funcionalidad | feature/ | feature/nueva-query | Son ramas de corta duración que se crean a partir de **dev** para cada nueva funcionalidad.
Nueva interfaz/página |	ui/ |	ui/pagina-inicio	| Para el diseño de nuevas pantallas o componentes visuales.
Corrección de errores	| fix/ |	fix/contraseña-boton	| Para solucionar problemas detectados en el diseño o prototipo.
Refactorización	| refactor/	| refactor/estilos-globales	| Para reestructurar código o componentes sin cambiar su función.
Documentación | doc/ | doc/análisis-sitio-web | Para redactar, revisar o actualizar cualquier archivo de documentación del proyecto.

---

## Documentación del proyecto.

### 1. Introducción.

El proyecto utiliza una solución para analizar la información de la base de datos **Wide World Importers** (SQL Server).

Las dos funcionalidades desarrolladas son las siguientes:

| Funcionalidad | Descripción |
|---|---|
| Gestión operativa | CRUD de clientes, proveedores, inventario y ventas mediante una aplicación web React conectada a una API REST. |
| Reportes y estadísticas | Reportes (1, 2, 3, 4, 5, 6, 7, 8 y 10) implementados como stored procedures. |

Tanto el CRUD como los reportes están encapsulados dentro de stored procedures.

---

### 2. Tecnologías utilizadas.

| Capa | Tecnología | Uso principal |
|---|---|---|
| Lógica de datos. | SQL Server. | Procedimientos almacenados, filtros, agregaciones, rankings y tablas. |
| API. | Node.js y Express 5. | Módulos de CRUD mediante HTTP y JSON. |
| Acceso a datos. | Biblioteca `mssql`. | Conexión de Node.js con SQL Server y ejecución tipada de SP. |
| Configuración. | `dotenv`. | Variables de entorno. |
| GUI | React 19. | Desarrollo de páginas y componentes de la aplicación. |
| Enrutamiento. | React Route. | Rutas para la aplicación web. |
| Componentes visuales. | CoreUI React. | Template para el panel administrativo. |
| Desarrollo. | Vite 8. | Servidor local. |

Para este proyecto se utilizó una instancia de SQL Server 2025 (basada en **GNU/Linux**) a través de Docker Desktop.

---

### 3. Requisitos de instalación.

Se requiere lo siguiente:

- Una instancia de SQL Server (preferiblemente 2025).
- Base de datos `WideWorldImporters` restaurada.
- Node.js 20 en adelante.
- Docker Desktop, si se quiere ejecutar en un contenedor.

---

### 4. Instalación e inicialización.

#### 4.1. Obtener el proyecto.

```bash
git clone <URL_DEL_REPOSITORIO>
cd proyecto1-bases2
```

La raíz debe contener los directorios `Api/`, `Script/` y `WebSite/`.

#### 4.2. Preparar la base de datos.

Restaurar Wide World Importers y verificar que la base esté registrada con el nombre:

```text
WideWorldImporters
```

#### 4.3. Instalar los stored procedures del CRUD.

Ejecutar los scripts dentro de la base de datos `WideWorldImporters` en el siguiente orden:

Consultas, detalles y catálogos:

```text
Script/modulos/consultas/clientes.sql
Script/modulos/consultas/proveedores.sql
Script/modulos/consultas/inventarios.sql
Script/modulos/consultas/ventas.sql
```

Operaciones de escritura:

```text
Script/modulos/crud/clientes.sql
Script/modulos/crud/proveedores.sql
Script/modulos/crud/inventarios.sql
Script/modulos/crud/ventas.sql
```

Los archivos utilizan `CREATE OR ALTER PROCEDURE`, por lo que, se pueden instalar los stored procedures siempre. Se hizo de esta manera para simplificar el proceso y volver más robustos los scripts.

#### 4.4. Instalar los reportes estadísticos.

Ejecutar los siguientes archivos en SQL Server, en el siguiente orden:

```text
Script/estadisticas/reporte1.sql
Script/estadisticas/reporte2.sql
Script/estadisticas/reporte3.sql
Script/estadisticas/reporte4.sql
Script/estadisticas/reporte5.sql
Script/estadisticas/reporte6.sql
Script/estadisticas/reporte7.sql
Script/estadisticas/reporte8.sql
Script/estadisticas/reporte10.sql
```

Los scripts crean los sinónimos requeridos si no existen.

#### 4.5. Configurar la API.

Crear `Api/ .env` con los datos de la instancia:

```dotenv
PORT=3000
DB_USER=usuario_sql
DB_PASSWORD=contraseña_sql
DB_SERVER=localhost
DB_DATABASE=WideWorldImporters
DB_PORT=1433
```

Si SQL Server corre en Docker, `DB_SERVER` y `DB_PORT` deben corresponder al host y el puerto configurados para el contenedor.

Cabe decir, que se necesitan inicializar dos terminales, una para iniciar la API y otra para iniciar la GUI.

Instalar dependencias e iniciar la API:

```bash
cd Api
npm install
npm run dev
```

Para ejecución sin reinicio automático:

```bash
npm start
```

La API arrancará en: `http://localhost:3000`.

También se desarrolló el siguiente endpoint para comprobar si la API funciona correctamente (se puede probar en un cliente HTTP cualquiera):

```http
GET http://localhost:3000/api/health
```

Si la API funciona bien debe retornar:

```json
{
  "message": "API y base de datos disponibles"
}
```

#### 4.6. Instalar e iniciar la interfaz.

En una segunda terminal:

```bash
cd WebSite
npm install
npm run dev
```

La interfaz gráfica de usuario será iniciada en `http://localhost:5173`. 

Tanto la terminal de la API, como de la GUI deben permanecer activos.

Este comando ejecuta el análisis estático y la compilación de producción.

---

### 5. Estructura del repositorio.

#### 5.1. `Api/`.

Contiene el servidor HTTP y la lógica para las peticiones web.

| Archivo | Responsabilidad |
|---|---|
| `src/index.js` | Inicia Express.js en el puerto configurado. |
| `src/app.js` | Permite el uso de JSON y prepara las rutas. |
| `src/config.js` | Inyecta las variables de entorno. |
| `src/database/connection.js` | Configura `mssql` y obtiene el pool de conexiones. |
| `src/routes/wwi.routes.js` | Asocia método y URL con un controlador. |
| `src/controllers/wwi.controller.js` | Alberga la lógica, ejecuta stored procedures y da respuestas JSON. |

#### 5.2. `Script/`

Contiene los scripts de SQL Server.

| Directorio | Contenido |
|---|---|
| `modulos/consultas/` | Listados filtrados, detalles, catálogos y búsqueda de ciudades. |
| `modulos/crud/` | Creación, actualización y eliminación de las tuplas de las entidades de la base de datos. |
| `estadisticas/` | Reportes estadísticos 1–8 y 10. |

#### 5.3. `WebSite/`

Contiene la interfaz gráfica de usuario en React.

| Elemento | Responsabilidad |
|---|---|
| `src/main.jsx` | Inicializa React, React Router y los estilos globales. |
| `src/App.jsx` | Establece las rutas de navegación. |
| `src/layout/` | Define barra lateral, el encabezado y el área principal. |
| `src/pages/` | Implementa listados, formularios, detalles y vistas de reportes. |
| `src/components/` | Reúne tablas, filtros, formularios, mapas y editores reutilizables. |
| `src/config/` | Centraliza campos, columnas, etiquetas y la definición visual de reportes. |
| `src/services/` | Encapsula las peticiones HTTP del CRUD. |
| `src/index.css` | Contiene los estilos propios. |

---

### 6. Explicación de la arquitectura.

El proyecto utiliza una arquitectura por capas, donde se separan responsabilidades claramente y cada parte se encarga de hacer solo una cosa. Esto para cumplir con los principios ACID y facilitar el desarrollo. A continuación, se detallan brevemente dichas capas:

1. **GUI:** Interfaz para el usuario.
2. **Servicios:** La GUI utiliza los servicios para construir las peticiones. Los servicios envían las peticiones a las rutas correspondientes.
4. **Rutas:** Enlazan las URLs y endpoints con cada controlador.
5. **Controladores:** Gestionan la lógica y ejecutan los stored procedures.
6. **Stored procedures:** Almacenan operaciones que modifican la base de datos.
7. **Base de datos:** Almacena la información.

El flujo puede verse de la siguiente forma:

`GUI -> servicios -> rutas -> controladores -> stored procedures -> base de datos`.

#### 6.1. Capa gráfica.

`main.jsx` monta la aplicación y habilita `BrowserRouter`. `App.jsx` relaciona las URL con las páginas del sistema:

```text
/clientes
/proveedores
/inventario
/ventas
/reportes
```

Los módulos de CRUD incluyen listado, creación, detalle y edición. Las páginas cargan los datos, el estado de los formularios y los mensajes de respuesta.

`entities.js` se encarga de la definición de campos y columnas de clientes e inventario. Las páginas de proveedores y ventas son relativamente diferentes. `reports.js` gestiona aspectos visuales de los reportes.

#### 6.2. Servicios de la GUI.

Los servicios implementan el `fetch`. Los archivos son los siguientes:

```text
customerApi.js
supplierApi.js
inventoryApi.js
salesApi.js
```

Cada servicio construye la URL, utiliza las rutas y valida las respuestas.

#### 6.3. Rutas de la API.

Las rutas son las siguientes:

| Recurso | Listar | Detalle | Crear | Actualizar | Eliminar |
|---|---|---|---|---|---|
| Clientes | `GET /api/customers` | `GET /api/customers/:CustomerID` | `POST /api/customers` | `PUT /api/customers/:CustomerID` | `DELETE /api/customers/:CustomerID` |
| Proveedores | `GET /api/suppliers` | `GET /api/suppliers/:SupplierID` | `POST /api/suppliers` | `PUT /api/suppliers/:SupplierID` | `DELETE /api/suppliers/:SupplierID` |
| Inventario | `GET /api/inventory` | `GET /api/inventory/:StockItemID` | `POST /api/inventory` | `PUT /api/inventory/:StockItemID` | `DELETE /api/inventory/:StockItemID` |
| Ventas | `GET /api/sales` | `GET /api/sales/:InvoiceID` | `POST /api/sales` | `PUT /api/sales/:InvoiceID` | `DELETE /api/sales/:InvoiceID` |

También hay rutas de catálogos para cada módulo y `GET /api/cities` para la búsqueda de ciudades.

#### 6.4. Controladores.

Los controladores reciben las requests, que pueden resumirse en la siguientes tres:

| Origen | Uso |
|---|---|
| `req.query` | Para filtrados. |
| `req.params` | Para recibir un identificador (normalmente una primary key). |
| `req.body` | Cuerpo de una request con datos para crear o modificar datos. |

A la hora de ejecutar los stored procedures, se definen los tipos explícitos de SQL Server a través de la biblioteca `mssql`, para asegurar la consistencia de los datos.

El controlador devuelve el resultado como JSON y traduce los errores a estados HTTP. Los principales son `400` para datos inválidos, `404` para recursos inexistentes, `409` para conflictos de integridad y `500` para errores no previstos.

#### 6.5. Procedimientos almacenados.

Se encargan de encapsular la lógica para operar sobre las tablas:

- Filtros opcionales.
- Uniones entre tablas.
- Catálogos para llaves foráneas.
- Validación de datos.
- Generación de identificadores mediante las secuencias de Wide World Importers.
- Transacciones con `COMMIT` y `ROLLBACK`.
- Operaciones sobre encabezados y detalles.
- Agregaciones, rankings y demás para reportes.

Los scripts utilizan sinónimos `dbo.src_*` por cuestiones de seguridad.
