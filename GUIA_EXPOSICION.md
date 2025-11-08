# 🏋️ Guía Completa de Exposición: Sistema de Gestión de Gimnasio (GYM)

> **Versión actualizada** - Incluye todas las funcionalidades implementadas, Docker, y mejores prácticas

## 📋 Índice
1. [Introducción y Contexto](#introducción-y-contexto)
2. [Tecnologías y Stack Tecnológico](#tecnologías-y-stack-tecnológico)
3. [Arquitectura del Proyecto (BLoC Pattern)](#arquitectura-del-proyecto-bloc-pattern)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Funcionalidades Principales](#funcionalidades-principales)
6. [Base de Datos SQLite](#base-de-datos-sqlite)
7. [Flujo de la Aplicación](#flujo-de-la-aplicación)
8. [Diseño y UI/UX (Material Design 3)](#diseño-y-uiux-material-design-3)
9. [Características Técnicas Destacadas](#características-técnicas-destacadas)
10. [Despliegue con Docker](#despliegue-con-docker)
11. [Guía de Demostración Práctica](#guía-de-demostración-práctica)
12. [Preguntas Frecuentes y Respuestas](#preguntas-frecuentes-y-respuestas)
13. [Métricas y Estadísticas](#métricas-y-estadísticas)
14. [Mejoras Futuras](#mejoras-futuras)

---

## 🎯 Introducción y Contexto

### ¿Qué es este proyecto?
**GYM Manager** es una aplicación multiplataforma desarrollada en **Flutter** para la gestión integral de un gimnasio. Permite administrar socios, pagos, cuotas y generar reportes en tiempo real desde cualquier dispositivo.

### Problema que resuelve
- ❌ **Gestión manual ineficiente**: Elimina el uso de planillas Excel o papel
- ❌ **Falta de control**: No hay seguimiento automático de cuotas y pagos
- ❌ **Pérdida de información**: Datos dispersos y difíciles de consultar
- ❌ **Sin alertas**: No hay notificaciones de cuotas próximas a vencer
- ❌ **Acceso limitado**: Solo funciona en un lugar específico

### Solución propuesta
- ✅ **Sistema digital completo**: Todo centralizado en una aplicación
- ✅ **Control automatizado**: Seguimiento de pagos y cuotas en tiempo real
- ✅ **Base de datos local**: Información persistente y segura
- ✅ **Alertas inteligentes**: Notificaciones de cuotas vencidas y por vencer
- ✅ **Multiplataforma**: Funciona en móviles (Android/iOS) y web

### Objetivos del proyecto
✅ Gestión completa de socios (CRUD completo)  
✅ Control de pagos y cuotas con historial  
✅ Dashboard con métricas en tiempo real  
✅ Sistema de autenticación seguro  
✅ Interfaz moderna y responsive (Material Design 3)  
✅ Base de datos local (SQLite) sin necesidad de servidor  
✅ Containerización con Docker para fácil despliegue  

---

## 🛠️ Tecnologías y Stack Tecnológico

### Framework Principal
- **Flutter 3.24.0** (SDK Dart 3.8+)
  - Framework multiplataforma de Google
  - Un solo código para Android, iOS y Web
  - Hot Reload para desarrollo rápido
  - Alto rendimiento nativo (compilación AOT)
  - Widget tree optimizado

### Gestión de Estado
- **flutter_bloc (v9.1.1)**: Patrón BLoC (Business Logic Component)
  - Separación clara entre lógica de negocio y UI
  - Manejo predecible de estados (State Management)
  - Flujo unidireccional de datos (Events → BLoC → States)
  - Fácil testing y mantenimiento
  - Escalable para aplicaciones grandes

### Base de Datos
- **SQLite (sqflite v2.3.0)**: Base de datos local
  - Almacenamiento persistente en el dispositivo
  - Sin necesidad de servidor o conexión a internet
  - Soporte para relaciones (Foreign Keys con CASCADE)
  - Migraciones automáticas (sistema de versionado)
  - Transacciones ACID
  - **sqflite_common_ffi_web**: Soporte SQLite para web

### Dependencias Adicionales
- **intl (v0.20.2)**: Formateo de fechas y números en español
- **shared_preferences (v2.2.2)**: Almacenamiento de sesiones y configuraciones
- **path_provider (v2.1.1)**: Gestión de rutas de archivos multiplataforma
- **equatable (v2.0.5)**: Comparación de objetos para estados BLoC
- **provider (v6.0.5)**: Inyección de dependencias

### Herramientas de Desarrollo y Despliegue
- **Docker & Docker Compose**: Containerización para desarrollo y producción
- **Git & GitHub**: Control de versiones y colaboración
- **Material Design 3**: Sistema de diseño moderno de Google
- **Visual Studio Code / Android Studio**: IDEs de desarrollo

---

## 🏗️ Arquitectura del Proyecto

### Patrón BLoC (Business Logic Component)

```
┌─────────────────────────────────────────┐
│           UI (Widgets)                  │
│  (LoginScreen, DashboardScreen, etc.)  │
└──────────────┬──────────────────────────┘
               │ Events
               ▼
┌─────────────────────────────────────────┐
│           BLoC Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌────────┐│
│  │AuthBloc  │  │SociosBloc│  │PagosBloc││
│  └──────────┘  └──────────┘  └────────┘│
└──────────────┬──────────────────────────┘
               │ States
               ▼
┌─────────────────────────────────────────┐
│      Repository Layer                    │
│     (DatabaseHelper)                     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         SQLite Database                  │
│  (usuario, socio, pago)                  │
└─────────────────────────────────────────┘
```

### Ventajas de esta arquitectura:
1. **Separación de responsabilidades**: UI, lógica y datos están separados
2. **Testeable**: Cada capa se puede probar independientemente
3. **Escalable**: Fácil agregar nuevas funcionalidades
4. **Mantenible**: Código organizado y predecible

### Componentes BLoC:

#### 1. **AuthBloc** - Autenticación
- **Eventos**: `LoginEvent`, `LogoutEvent`, `CheckAuthEvent`
- **Estados**: `AuthInitialState`, `AuthLoadingState`, `AuthAuthenticatedState`, `AuthUnauthenticatedState`
- **Responsabilidad**: Validar credenciales, manejar sesiones

#### 2. **SociosBloc** - Gestión de Socios
- **Eventos**: `CargarSociosEvent`, `AgregarSocioEvent`, `ActualizarSocioEvent`, `EliminarSocioEvent`
- **Estados**: `SociosInitialState`, `SociosLoadingState`, `SociosLoadedState`, `SociosErrorState`
- **Responsabilidad**: CRUD completo de socios

#### 3. **PagosBloc** - Gestión de Pagos
- **Eventos**: `AgregarPagoEvent`, `CargarPagosEvent`, `CargarPagosPorSocioEvent`
- **Estados**: `PagosInitialState`, `PagosLoadingState`, `PagosLoadedState`, `PagosErrorState`
- **Responsabilidad**: Registrar pagos, calcular ingresos

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada, configuración de la app
├── blocs/                       # Lógica de negocio (BLoC)
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   ├── auth_state.dart
│   ├── socios_bloc.dart
│   ├── socios_event.dart
│   ├── socios_state.dart
│   ├── pagos_bloc.dart
│   ├── pagos_event.dart
│   └── pagos_state.dart
├── models/                      # Modelos de datos
│   ├── usuario.dart
│   ├── socio.dart
│   └── pago.dart
├── pages/                       # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── main_navigation_screen.dart
│   ├── dashboard_screen.dart
│   ├── lista_socios_screen.dart
│   ├── agregar_socio_screen.dart
│   ├── agregar_pago_screen.dart
│   └── historial_pagos_screen.dart
├── repositories/                # Acceso a datos
│   └── database_helper.dart     # Singleton para SQLite
└── utils/                       # Utilidades
    └── test_database.dart
```

### Principios de organización:
- **Separación por capas**: Cada tipo de archivo en su carpeta
- **Nomenclatura clara**: Nombres descriptivos y consistentes
- **Single Responsibility**: Cada archivo tiene una responsabilidad única

---

## ⚙️ Funcionalidades Principales

### 1. 🔐 Sistema de Autenticación

**Características:**
- Login con usuario y contraseña
- Validación de credenciales contra base de datos
- Persistencia de sesión (no requiere login en cada inicio)
- Usuario por defecto: `admin` / `admin123`
- Logout seguro

**Implementación:**
```dart
// El AuthBloc maneja todos los eventos de autenticación
AuthBloc()..add(LoginEvent(username, password))
```

### 2. 📊 Dashboard (Panel de Control)

**Métricas en tiempo real:**
- **Total de Socios**: Contador de socios activos
- **Ingresos Mensuales**: Suma de pagos del mes actual
- **Cuotas Vencidas**: Socios con cuota vencida
- **Cuotas por Vencer**: Socios con cuota próxima a vencer (7 días)

**Recordatorios:**
- Lista de socios con cuotas próximas a vencer
- Lista de socios con cuotas vencidas
- Actualización manual con pull-to-refresh

**Código destacado:**
```dart
// Cálculo de ingresos mensuales
Future<double> getIngresosMensuales() async {
  final ahora = DateTime.now();
  final inicioMes = DateTime(ahora.year, ahora.month, 1);
  // Consulta SQL optimizada
}
```

### 3. 👥 Gestión de Socios

**Operaciones CRUD:**
- ✅ **Crear**: Agregar nuevo socio con validaciones
- 📖 **Leer**: Lista de todos los socios con filtros
- ✏️ **Actualizar**: Editar información de socios
- 🗑️ **Eliminar**: Eliminar socio (con confirmación)

**Campos del socio:**
- Nombre completo
- DNI (único)
- Teléfono
- Correo electrónico
- Fecha de inicio
- Fecha de vencimiento
- Precio mensual
- Tipo de plan

**Validaciones:**
- DNI único (no permite duplicados)
- Fechas válidas
- Campos obligatorios

### 4. 💰 Gestión de Pagos

**Funcionalidades:**
- ✅ Registrar pagos asociados a un socio
- ✅ Historial completo de pagos por socio
- ✅ Métodos de pago: Efectivo, Tarjeta, Transferencia, Otro
- ✅ Observaciones opcionales para cada pago
- ✅ Cálculo automático de ingresos mensuales
- ✅ Actualización automática de fecha de vencimiento al registrar pago
- ✅ Selección de fecha personalizada para pagos pasados

**Relación con socios:**
- Foreign Key: `pago.socioId → socio.id`
- Eliminación en cascada: Si se elimina un socio, se eliminan sus pagos automáticamente
- Integridad referencial garantizada por SQLite

**Flujo de registro de pago:**
1. Usuario selecciona un socio desde la lista
2. Accede a "Agregar Pago" o "Historial de Pagos"
3. Completa formulario: monto, fecha, método de pago, observaciones
4. Al guardar, se actualiza automáticamente la fecha de vencimiento del socio
5. El pago queda registrado en el historial

### 5. 🔔 Sistema de Alertas

**Estados de cuota:**
- 🟢 **Verde**: Cuota al día
- 🟡 **Ámbar**: Vencida hace menos de 15 días
- 🔴 **Rojo**: Vencida hace más de 15 días

**Lógica implementada:**
```dart
String get estadoCuota {
  final diferencia = fechaVencimiento.difference(DateTime.now()).inDays;
  if (diferencia < 0) {
    return diferencia.abs() <= 15 ? 'Ambar' : 'Rojo';
  }
  return 'Verde';
}
```

---

## 🗄️ Base de Datos

### Esquema de Base de Datos

#### Tabla: `usuario`
```sql
CREATE TABLE usuario(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  nombre TEXT NOT NULL
)
```

#### Tabla: `socio`
```sql
CREATE TABLE socio(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombreCompleto TEXT NOT NULL,
  dni TEXT NOT NULL UNIQUE,
  telefono TEXT NOT NULL,
  correo TEXT NOT NULL,
  fechaInicio TEXT NOT NULL,
  fechaVencimiento TEXT NOT NULL,
  precioMensual REAL NOT NULL,
  tipoPlan TEXT NOT NULL
)
```

#### Tabla: `pago`
```sql
CREATE TABLE pago(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  socioId INTEGER NOT NULL,
  monto REAL NOT NULL,
  fecha TEXT NOT NULL,
  metodoPago TEXT NOT NULL,
  observaciones TEXT,
  FOREIGN KEY (socioId) REFERENCES socio(id) ON DELETE CASCADE
)
```

### Características de la BD:
- **Versionado**: Sistema de migraciones (versión 4)
- **Integridad referencial**: Foreign Keys con CASCADE
- **Singleton Pattern**: Una sola instancia de DatabaseHelper
- **Inicialización automática**: Usuario por defecto y datos de prueba

### Migraciones:
```dart
onUpgrade: (db, oldVersion, newVersion) async {
  if (oldVersion < 2) {
    // Crear tabla usuario
  }
  if (oldVersion < 3) {
    // Agregar columna correo
  }
  if (oldVersion < 4) {
    // Crear tabla pago
  }
}
```

---

## 🔄 Flujo de la Aplicación

### Flujo de Inicio:
```
1. App inicia → main()
2. Inicializa base de datos
3. Crea usuario por defecto (si no existe)
4. Crea socios ficticios (si BD está vacía)
5. AuthWrapper verifica sesión
6. Si hay sesión → Dashboard
7. Si no hay sesión → Login
```

### Flujo de Autenticación:
```
Usuario ingresa credenciales
    ↓
LoginScreen envía LoginEvent
    ↓
AuthBloc valida con DatabaseHelper
    ↓
Si es válido → AuthAuthenticatedState
    ↓
AuthWrapper redirige a MainNavigationScreen
    ↓
Sesión guardada en SharedPreferences
```

### Flujo de Gestión de Socios:
```
Usuario selecciona "Socios"
    ↓
ListaSociosScreen carga SociosBloc
    ↓
SociosBloc emite CargarSociosEvent
    ↓
DatabaseHelper consulta BD
    ↓
SociosLoadedState con lista de socios
    ↓
UI muestra lista con estados de cuota
```

### Flujo de Registro de Pago:
```
Usuario selecciona socio → "Agregar Pago"
    ↓
AgregarPagoScreen muestra formulario
    ↓
Usuario completa datos → Envía AgregarPagoEvent
    ↓
PagosBloc inserta en BD
    ↓
Actualiza fecha de vencimiento del socio
    ↓
Muestra confirmación
```

---

## 🎨 Diseño y UI/UX

### Tema Oscuro (Dark Mode)
- **Color primario**: Azul vibrante (#2196F3)
- **Color secundario**: Cyan/Turquesa (#03DAC6)
- **Fondo**: Casi negro (#121212)
- **Superficie**: Gris oscuro (#1E1E1E)
- **Errores**: Rojo suave (#CF6679)

### Principios de Diseño:
1. **Material Design 3**: Última versión del sistema de diseño de Google
2. **Consistencia**: Mismos componentes en toda la app
3. **Feedback visual**: Estados claros (loading, error, éxito)
4. **Navegación intuitiva**: BottomNavigationBar para acceso rápido
5. **Responsive**: Adaptable a diferentes tamaños de pantalla

### Componentes Reutilizables:
- **Tarjetas de métricas**: Dashboard
- **Lista de socios**: Con indicadores de estado
- **Formularios**: Validación en tiempo real
- **Diálogos de confirmación**: Para acciones destructivas

### Experiencia de Usuario:
- ✅ **Pull-to-refresh**: Actualizar datos deslizando hacia abajo
- ✅ **Loading states**: Indicadores de carga claros
- ✅ **Mensajes de error**: Informativos y accionables
- ✅ **Confirmaciones**: Para eliminar o cerrar sesión

---

## ⚡ Características Técnicas Destacadas

### 1. Singleton Pattern (DatabaseHelper)
```dart
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  // Una sola instancia en toda la app
}
```

### 2. Manejo de Estados Asíncronos
```dart
FutureBuilder<Map<String, dynamic>>(
  future: _estadisticasFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    // Renderizar datos
  }
)
```

### 3. Formateo de Fechas en Español
```dart
await initializeDateFormatting('es_ES', null);
DateFormat('dd/MM/yyyy', 'es_ES').format(fecha);
```

### 4. Soporte Multiplataforma
```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb;
}
// Mismo código funciona en móvil y web
```

### 5. Validaciones y Seguridad
- DNI único en base de datos
- Validación de sesión al iniciar
- Confirmaciones para acciones críticas
- Manejo de errores robusto

---

## 🐳 Despliegue con Docker

### Configuración Docker:
- **Dockerfile**: Imagen basada en Ubuntu 22.04 con Flutter SDK 3.24.0
- **docker-compose.yml**: Dos servicios configurados:
  - `flutter-dev`: Desarrollo con hot reload (puerto 39421)
  - `flutter-prod`: Producción con build optimizado (puerto 8081)
- **Volúmenes**: Cache de dependencias (`flutter-pub-cache`) para builds rápidos
- **Redes**: Red aislada (`gym-network`) para comunicación entre servicios

### Características técnicas:
- ✅ Configuración Git optimizada para clonado estable
- ✅ Precache de dependencias web
- ✅ Soporte para hot reload en desarrollo
- ✅ Build de producción optimizado con Python HTTP server
- ✅ Exposición de puertos configurada

### Comandos principales:
```bash
# Desarrollo (con hot reload)
docker-compose up flutter-dev
# Acceso: http://localhost:39421

# Producción (build optimizado)
docker-compose up flutter-prod
# Acceso: http://localhost:8081

# Ver logs en tiempo real
docker-compose logs -f flutter-dev

# Detener servicios
docker-compose stop

# Reconstruir imágenes
docker-compose build --no-cache
```

### Ventajas:
- ✅ **Entorno consistente**: Mismo ambiente en cualquier máquina
- ✅ **Fácil despliegue**: Un solo comando para iniciar
- ✅ **Aislamiento**: Dependencias aisladas del sistema host
- ✅ **Reproducible**: Funciona igual en Windows, Mac, Linux
- ✅ **Escalable**: Fácil agregar más servicios (BD, API, etc.)

---

## 🎬 Guía de Demostración Práctica

### ⏱️ Secuencia recomendada para la exposición (5-7 minutos):

#### 1. **Introducción y Contexto** (30 seg)
**Qué mostrar:**
- Abrir la aplicación (si es web, mostrar en navegador)
- Mostrar logo y pantalla de login

**Qué decir:**
> "Esta es una aplicación multiplataforma desarrollada en Flutter para la gestión integral de un gimnasio. Funciona tanto en móviles como en web, y utiliza una base de datos local SQLite, por lo que no requiere conexión a internet ni servidor."

#### 2. **Sistema de Autenticación** (45 seg)
**Qué mostrar:**
- Pantalla de login
- Ingresar credenciales: Usuario: `admin` / Contraseña: `admin123`
- Mostrar validación en tiempo real

**Qué decir:**
> "El sistema cuenta con autenticación segura. Las credenciales se validan contra la base de datos local. La sesión se mantiene persistente, por lo que no es necesario iniciar sesión cada vez que se abre la aplicación."

#### 3. **Dashboard - Panel de Control** (1.5 min)
**Qué mostrar:**
- Métricas principales (tarjetas con números)
- Lista de recordatorios (cuotas vencidas y por vencer)
- Pull-to-refresh (deslizar hacia abajo para actualizar)

**Qué decir:**
> "El dashboard muestra métricas en tiempo real:
> - Total de socios registrados
> - Ingresos del mes actual (calculados automáticamente)
> - Cuotas vencidas (socios que deben pagar)
> - Cuotas por vencer en los próximos 7 días
> 
> También muestra recordatorios automáticos para que el administrador pueda contactar a los socios antes de que se venza su cuota."

#### 4. **Gestión de Socios - CRUD Completo** (2 min)
**Qué mostrar:**
- Lista de socios con indicadores de color
- Búsqueda de socios (barra de búsqueda)
- Agregar nuevo socio (formulario completo)
- Editar socio existente
- Eliminar socio (con confirmación)
- Mostrar validación de DNI único

**Qué decir:**
> "La gestión de socios incluye todas las operaciones CRUD:
> - **Crear**: Agregar nuevos socios con validaciones
> - **Leer**: Lista completa con búsqueda en tiempo real
> - **Actualizar**: Editar información de cualquier socio
> - **Eliminar**: Eliminar socios con confirmación de seguridad
> 
> Los indicadores de color muestran el estado de la cuota:
> - 🟢 Verde: Cuota al día
> - 🟡 Ámbar: Vencida hace menos de 15 días
> - 🔴 Rojo: Vencida hace más de 15 días
> 
> El sistema valida que el DNI sea único para evitar duplicados."

#### 5. **Gestión de Pagos** (1.5 min)
**Qué mostrar:**
- Seleccionar un socio de la lista
- Acceder a "Agregar Pago" o "Historial"
- Completar formulario de pago
- Mostrar historial de pagos del socio
- Explicar actualización automática de fecha de vencimiento

**Qué decir:**
> "El sistema de pagos permite:
> - Registrar pagos asociados a cada socio
> - Ver el historial completo de pagos por socio
> - Seleccionar método de pago (Efectivo, Tarjeta, Transferencia)
> - Agregar observaciones opcionales
> 
> Cuando se registra un pago, el sistema actualiza automáticamente la fecha de vencimiento del socio, sumando un mes desde la fecha del pago. Esto mantiene el control de cuotas siempre actualizado."

#### 6. **Navegación y UX** (30 seg)
**Qué mostrar:**
- Cambiar entre pestañas (Socios/Dashboard)
- Mostrar menú de logout
- Confirmación de logout

**Qué decir:**
> "La navegación es intuitiva con un menú inferior que permite cambiar rápidamente entre las secciones principales. El sistema incluye confirmaciones para acciones críticas como cerrar sesión o eliminar socios."

#### 7. **Aspectos Técnicos (Opcional - si hay tiempo)** (1 min)
**Qué mostrar:**
- Abrir código de un BLoC (si es posible)
- Mostrar estructura de carpetas
- Mencionar Docker

**Qué decir:**
> "La aplicación utiliza el patrón BLoC para la gestión de estado, lo que permite:
> - Separación clara entre lógica de negocio y UI
> - Código testeable y mantenible
> - Escalabilidad para futuras funcionalidades
> 
> El proyecto está containerizado con Docker, lo que permite ejecutarlo en cualquier entorno de forma consistente."

### 🎯 Puntos clave a destacar durante la demostración:
1. ✅ **Multiplataforma**: Funciona en móvil (Android/iOS) y web con el mismo código
2. ✅ **Sin servidor**: Base de datos local SQLite, funciona offline
3. ✅ **Arquitectura profesional**: BLoC pattern para gestión de estado
4. ✅ **UI moderna**: Material Design 3 con tema oscuro
5. ✅ **Funcionalidad completa**: CRUD completo para socios y pagos
6. ✅ **Automatización**: Cálculos y actualizaciones automáticas
7. ✅ **Containerización**: Docker para fácil despliegue

---

## 📈 Métricas y Estadísticas

### Datos que se pueden mostrar en el Dashboard:
- **Total de socios registrados**: Contador en tiempo real
- **Ingresos del mes actual**: Suma automática de todos los pagos del mes
- **Cuotas vencidas**: Lista de socios con cuota vencida
- **Cuotas próximas a vencer**: Socios con cuota que vence en los próximos 7 días

### Cálculos automáticos implementados:
- ✅ **Suma de pagos por mes**: Consulta SQL optimizada que suma pagos del mes actual
- ✅ **Días hasta vencimiento**: Cálculo dinámico basado en fecha actual
- ✅ **Días desde vencimiento**: Para cuotas ya vencidas
- ✅ **Estado de cuota**: Lógica de tres estados (Verde/Ámbar/Rojo)
- ✅ **Actualización de fecha de vencimiento**: Automática al registrar pago

### Ejemplo de consulta SQL:
```sql
-- Ingresos mensuales
SELECT SUM(monto) FROM pago 
WHERE strftime('%Y-%m', fecha) = strftime('%Y-%m', 'now')
```

### Datos de prueba:
El sistema incluye socios ficticios que se crean automáticamente si la base de datos está vacía, facilitando las demostraciones.

---

## 🔮 Mejoras Futuras (Opcional para mencionar)

### Funcionalidades que se podrían agregar:

1. **Notificaciones push**: 
   - Alertas automáticas de cuotas vencidas
   - Recordatorios antes del vencimiento
   - Notificaciones de nuevos pagos

2. **Reportes y exportación**:
   - Generar reportes en PDF
   - Exportar datos a CSV/Excel
   - Gráficos de ingresos y tendencias

3. **Sincronización en la nube**:
   - Backup automático en servidor
   - Sincronización entre múltiples dispositivos
   - Restauración de datos

4. **Sistema de usuarios avanzado**:
   - Múltiples usuarios con roles (Admin, Recepcionista, etc.)
   - Permisos granulares por funcionalidad
   - Historial de acciones (auditoría)

5. **Visualizaciones avanzadas**:
   - Gráficos de ingresos mensuales/anuales
   - Comparativas de períodos
   - Análisis de tendencias

6. **Búsqueda y filtros avanzados**:
   - Filtros por múltiples criterios simultáneos
   - Búsqueda por nombre, DNI, teléfono, correo
   - Filtros por estado de cuota, tipo de plan, etc.

7. **Integración con sistemas externos**:
   - Envío de emails automáticos
   - Integración con sistemas de pago
   - API REST para integraciones

8. **App móvil nativa**:
   - Notificaciones nativas
   - Acceso rápido desde el móvil
   - Modo offline completo

### Nota importante:
> "El sistema actual ya funciona completamente offline y cubre todas las necesidades básicas de gestión. Las mejoras futuras se pueden implementar de forma modular gracias a la arquitectura BLoC."

---

## 💡 Puntos Clave para la Exposición

### 🎯 Mensaje principal:
> "Sistema completo de gestión de gimnasio desarrollado con Flutter, utilizando arquitectura BLoC y base de datos SQLite local. Permite gestionar socios, pagos y cuotas con una interfaz moderna y responsive. El proyecto está containerizado con Docker para facilitar el despliegue y la colaboración."

### 💪 Fortalezas a destacar:
1. ✅ **Código limpio y organizado**: Arquitectura bien estructurada siguiendo el patrón BLoC
2. ✅ **Escalable**: Fácil agregar nuevas funcionalidades sin afectar el código existente
3. ✅ **Multiplataforma**: Un solo código base para Android, iOS y Web
4. ✅ **Sin dependencias externas**: Funciona completamente offline
5. ✅ **UI profesional**: Material Design 3 con tema oscuro moderno
6. ✅ **Base de datos robusta**: SQLite con integridad referencial y migraciones
7. ✅ **Containerización**: Docker para entornos consistentes y reproducibles

## ❓ Preguntas Frecuentes y Respuestas

### **¿Por qué Flutter?**
> "Flutter permite desarrollar aplicaciones multiplataforma con un solo código base. Esto reduce significativamente el tiempo de desarrollo y mantenimiento. Además, ofrece excelente rendimiento ya que compila a código nativo, y el Hot Reload permite ver cambios instantáneamente durante el desarrollo."

### **¿Por qué BLoC?**
> "BLoC (Business Logic Component) es un patrón de arquitectura que separa claramente la lógica de negocio de la interfaz de usuario. Esto hace que el código sea más testeable, mantenible y escalable. Además, facilita el trabajo en equipo ya que cada desarrollador puede trabajar en diferentes capas sin conflictos."

### **¿Por qué SQLite?**
> "SQLite es una base de datos local que no requiere servidor ni conexión a internet. Esto es ideal para aplicaciones que necesitan funcionar offline. Además, es rápida, confiable y soporta relaciones complejas con integridad referencial."

### **¿Es seguro?**
> "Sí, el sistema incluye varias capas de seguridad:
> - Validaciones en base de datos (DNI único, campos obligatorios)
> - Autenticación de usuarios con sesiones persistentes
> - Confirmaciones para acciones críticas (eliminar socio, cerrar sesión)
> - Manejo robusto de errores"

### **¿Cómo se despliega?**
> "El proyecto está containerizado con Docker. Esto permite ejecutarlo en cualquier máquina con Docker instalado, sin necesidad de configurar Flutter o dependencias manualmente. Tenemos dos modos: desarrollo (con hot reload) y producción (build optimizado)."

### **¿Puede crecer el proyecto?**
> "Absolutamente. La arquitectura BLoC está diseñada para escalar. Es fácil agregar nuevas funcionalidades como:
> - Notificaciones push
> - Reportes en PDF
> - Sincronización con servidor
> - Múltiples usuarios con roles
> - Gráficos y estadísticas avanzadas"

### **¿Qué pasa si se pierde el dispositivo?**
> "Actualmente los datos están almacenados localmente. Una mejora futura sería implementar backup en la nube o sincronización con un servidor. Sin embargo, para gimnasios pequeños, la base de datos local es suficiente y más rápida."

### **¿Cuánto tiempo tomó desarrollarlo?**
> "El proyecto demuestra conocimiento completo del stack Flutter, desde la UI hasta la gestión de estado y base de datos. La arquitectura permite que el desarrollo sea modular y eficiente."

---

## 📝 Conclusión

### Este proyecto demuestra:
- ✅ **Dominio técnico completo**: Flutter, Dart, SQLite, BLoC pattern
- ✅ **Arquitectura profesional**: Separación de responsabilidades, escalabilidad
- ✅ **Manejo de datos**: Base de datos relacional con integridad referencial
- ✅ **Diseño de interfaces**: Material Design 3, UX moderna y responsive
- ✅ **Buenas prácticas**: Código limpio, nomenclatura clara, estructura organizada
- ✅ **DevOps básico**: Containerización con Docker, control de versiones con Git
- ✅ **Funcionalidad completa**: CRUD completo, cálculos automáticos, validaciones

### Valor del proyecto:
> "Este proyecto no es solo una aplicación funcional, sino una demostración de habilidades completas en desarrollo multiplataforma, desde la UI hasta la gestión de datos, pasando por arquitectura de software y despliegue."

**Tiempo estimado de exposición**: 5-7 minutos (demostración) + 2-3 minutos (preguntas)

---

## 🎯 Tips para la Presentación

### Antes de la exposición:
1. ✅ **Preparar datos de prueba**: Asegurarse de tener socios y pagos de ejemplo
2. ✅ **Practicar el flujo**: Saber navegar rápidamente entre pantallas
3. ✅ **Preparar respuestas**: Anticipar preguntas técnicas comunes
4. ✅ **Verificar que todo funciona**: Probar login, agregar socio, agregar pago
5. ✅ **Tener código listo**: Si hay tiempo, mostrar un BLoC o la estructura de BD

### Durante la exposición:
1. ✅ **Mantener calma**: Si algo falla, explicar cómo se solucionaría
2. ✅ **Destacar lo único**: Arquitectura BLoC, diseño moderno, funcionalidad completa
3. ✅ **Ser claro y conciso**: Explicar conceptos técnicos de forma comprensible
4. ✅ **Mostrar confianza**: Demostrar conocimiento del código y decisiones técnicas
5. ✅ **Interactuar**: Hacer preguntas retóricas o invitar a preguntas

### Estructura recomendada:
```
1. Introducción (30 seg) → ¿Qué es y qué problema resuelve?
2. Demostración práctica (4-5 min) → Mostrar funcionalidades
3. Aspectos técnicos (1-2 min) → Arquitectura y tecnologías
4. Preguntas (2-3 min) → Responder dudas
```

### Frases útiles para empezar:
- "Esta aplicación resuelve el problema de gestión manual de gimnasios..."
- "Desarrollada completamente en Flutter, lo que permite..."
- "Utiliza el patrón BLoC para separar la lógica de negocio..."
- "La base de datos SQLite permite funcionar sin servidor..."

### Si algo falla durante la demo:
> "Como pueden ver, este es un proyecto en desarrollo activo. Si algo no funciona como esperado, la arquitectura BLoC facilita el debugging y la corrección de errores. Además, el sistema de versionado de la base de datos permite migraciones seguras."

---

## 🎓 Recursos Adicionales

### Para profundizar:
- **Flutter Documentation**: https://docs.flutter.dev
- **BLoC Pattern**: https://bloclibrary.dev
- **SQLite Documentation**: https://www.sqlite.org/docs.html
- **Material Design 3**: https://m3.material.io

### Credenciales de prueba:
- **Usuario**: `admin`
- **Contraseña**: `admin123`

---

¡Éxito en tu exposición! 🚀

> **Recuerda**: Lo más importante es demostrar que entiendes el código, las decisiones técnicas y cómo todo funciona en conjunto. La confianza y el conocimiento técnico son clave.

