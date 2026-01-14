## 📋 Descripción

Este PR agrega el sistema completo de login, dashboard y mejoras de frontend al proyecto GYM.

## ✨ Cambios realizados

### 🔐 Sistema de Login
- Implementación de pantalla de login con diseño moderno
- Autenticación de usuarios mediante AuthBloc (BLoC pattern)
- Manejo de sesiones con SharedPreferences
- Validación de credenciales contra base de datos

### 📊 Dashboard
- Pantalla de dashboard con estadísticas en tiempo real
- Métricas principales:
  - Total de socios
  - Ingresos mensuales
  - Cuotas vencidas
  - Cuotas por vencer (7 días)
- Recordatorios de cuotas próximas a vencer y vencidas
- Actualización manual con pull-to-refresh

### 🎨 Frontend y Navegación
- Mejoras en la interfaz de usuario con tema oscuro
- Implementación de navegación principal con BottomNavigationBar
- Pantalla de navegación principal (MainNavigationScreen)
- Integración de AuthWrapper para manejo de autenticación
- Diseño responsive y moderno

## 📁 Archivos modificados/agregados

### Nuevos archivos:
- `lib/pages/login_screen.dart` - Pantalla de login
- `lib/pages/dashboard_screen.dart` - Pantalla de dashboard
- `lib/pages/main_navigation_screen.dart` - Navegación principal
- `lib/blocs/auth_bloc.dart` - Lógica de autenticación
- `lib/blocs/auth_event.dart` - Eventos de autenticación
- `lib/blocs/auth_state.dart` - Estados de autenticación
- `lib/models/usuario.dart` - Modelo de usuario

### Archivos modificados:
- `lib/main.dart` - Configuración de AuthWrapper y routing

## 🧪 Testing

- ✅ Login funcional con usuario por defecto (admin/admin123)
- ✅ Dashboard muestra estadísticas correctas
- ✅ Navegación entre pantallas funciona correctamente
- ✅ Cierre de sesión implementado

## 📸 Screenshots

*(Opcional: puedes agregar capturas de pantalla aquí)*

## 🔗 Issues relacionados

*(Si hay issues relacionados, mencionarlos aquí)*

## ✅ Checklist

- [x] Código compila sin errores
- [x] No hay errores de linter
- [x] Funcionalidad probada localmente
- [x] Archivos relacionados incluidos
- [ ] Revisión de código pendiente

