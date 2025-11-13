# 📱 GYM Manager - Guía de Uso (Últimas Implementaciones)

## 🎯 Dashboard (Pantalla Principal)

El dashboard ahora es **100% clickeable**. Cada tarjeta es interactiva:

### Tarjetas Disponibles:

1. **Cuotas Vencidas** (Rojo)
   - Muestra cantidad de socios con cuota vencida
   - Al hacer clic: Abre lista de socios VENCIDOS
   - Puedes registrar pago directamente desde ahí

2. **Por Vencer** (Naranja)
   - Muestra cantidad de socios cuya cuota vence proximamente
   - Al hacer clic: Abre lista de socios POR VENCER
   - Útil para hacer llamadas de aviso

3. **Al Día** (Verde)
   - Muestra cantidad de socios con cuota vigente
   - Al hacer clic: Abre lista de TODOS los socios al día
   - Para visualizar la base de socios activos

4. **Ingresos Diarios** (Púrpura)
   - Muestra dinero total ingresado hoy
   - Al hacer clic: Abre **Resumen Detallado de Ingresos**
   - Ves quién cobró, cuánto y a qué socio

### Funcionalidad Extra:
- **Pull to Refresh**: Desliza hacia abajo para actualizar números
- **Resumen General**: Abajo ves totales de socios e ingresos

---

## 💰 Registro de Pagos (Lista de Socios)

Cuando haces clic en "Pagar Cuota":

1. **Se registra en BD** con:
   - ID del socio
   - Monto pagado
   - Fecha y hora
   - **Operador que cobró** (tu usuario actual)
   - Método de pago

2. **Se genera PDF** con:
   - Nombre del socio
   - Monto
   - Nueva fecha de vencimiento
   - Quién lo cobró
   - Se guarda en almacenamiento local del teléfono

3. **Se envía Telegram** al socio:
   - Mensaje: "✅ PAGO CONFIRMADO"
   - Incluye monto y nueva fecha de vencimiento
   - Solo se envía si el socio tiene chatId registrado

---

## 📊 Resumen de Ingresos Diarios

Acceso:
- Desde Dashboard: Clic en tarjeta "Ingresos Diarios"
- Desde Drawer: "Gestión de Socios" → (cuando lo implementemos)

Muestra:
- **Total ingresado hoy**: En grande arriba
- **Por operador**: 
  - Quién cobró cuánto
  - Cantidad de transacciones
  - Subtotal por persona
- **Listado completo**: 
  - Cada transacción individual
  - Socio que pagó
  - Monto
  - Método (Efectivo, Transferencia, etc.)

Funciones:
- **Date Picker**: Cambiar fecha para ver ingresos históricos
- **Actualizar**: Pull to refresh

---

## 🔐 Panel de Reportes (SOLO ADMIN)

Acceso:
- Drawer → "Reportes de Ingresos" (solo si eres admin)
- Pantalla idéntica a "Resumen de Ingresos Diarios"

Diferencia:
- Los admins acceden directamente desde el drawer
- Operadores deben ir por dashboard

---

## 📋 Filtros en Lista de Socios

Cuando abres "Gestión de Socios" puedes filtrar:

1. **Vencidos**: Socios con cuota vencida
2. **Por Vencer**: Socios cuya cuota vence pronto
3. **Al Día**: Socios con cuota vigente
4. **Todos**: Ver todos los socios
5. **Pagos del Día**: Socios que pagaron hoy

---

## 🔔 Notificaciones Telegram

**Cuándo se envía:**
- Cuando un socio se registra por Telegram
- Cuando registras un pago para un socio
- Cuando envías notificación manual de estado de cuota

**Qué se envía:**
- Mensajes en **Markdown** con emojis
- Información clara del estado
- Nuevas fechas de vencimiento

**Requisito:**
- El socio debe tener `chatId` válido
- No es un `temp_` (temporal)

---

## 📄 Comprobantes en PDF

**Cuándo se genera:**
- Automáticamente cuando se registra un pago
- Se guarda en: `/data/data/com.example.gym/app_flutter/`

**Qué incluye:**
- Logo y título: "GYM MANAGER"
- Datos del socio (Nombre, ID, Teléfono)
- Monto pagado
- Método de pago (Efectivo)
- Fecha y hora exacta
- Quién lo cobró (Operador)
- Confirmación: "✅ PAGO REGISTRADO"

**Tamaño:** A5 (pequeño, ideal para imprimir)

---

## ⚙️ Configuración Recomendada

### Roles de Usuarios:
- **admin**: Acceso a todo + Reportes + Gestión de usuarios
- **operador**: Puede registrar pagos + Ver estadísticas
- **socio**: Recibe notificaciones (usuario de la app si lo habilitamos)

### Base de Datos:
- **Tabla: socios** - Info de miembros
- **Tabla: usuarios** - Operadores y admins
- **Tabla: pagos** (v5) - Historial con usuarioId
- Versión actual: 5

---

## 🐛 Si algo no funciona...

**Dashboard tarjetas no clickeables:**
- Solución: Ya arreglado (cambio a SingleChildScrollView)

**Notificaciones no llegan:**
- Verificar que el socio tiene `chatId` válido
- No puede empezar con `temp_`
- Revisar logs: "❌ Notificación de pago: ... no tiene chatId válido"

**PDF no se genera:**
- Revisar permisos de almacenamiento
- Revisar que ComprobanteService está siendo llamado
- Verificar logs: "✅ Comprobante generado:" o "❌ Error generando..."

---

## 📈 Estadísticas en Tiempo Real

El dashboard obtiene datos de:
- `db.getSocios()` - Lista completa de socios
- `db.getIngresosDiarios(fecha)` - Suma de pagos del día
- Contador manual de estados de cuota

Se actualiza:
- Al entrar al dashboard
- Al hacer pull-to-refresh
- Automáticamente cada vez que registras un pago

---

## 🎯 Flujo Típico del Día

1. **Abres la app** → Ves el Dashboard
2. **Ves "Cuotas Vencidas"** → Llamas a esos socios
3. **Un socio llega** → Clic en su nombre → Pagar Cuota
   - Se registra en BD
   - Se genera PDF
   - Se envía notificación Telegram
4. **Al final del día** → Clic en "Ingresos Diarios"
   - Ves cuánto cobraste (y otros operadores)
   - Desglose de cada transacción
5. **Como admin** → Drawer → "Reportes de Ingresos"
   - Ves totales y por operador
   - Puedes cambiar fecha para ver histórico

---

## 💡 Tips

- Usa Pull-to-Refresh frecuentemente para actualizar números
- Los filtros en lista de socios son acumulativos
- Los PDF se guardan automáticamente
- Los ingresos se muestran con 2 decimales
- Cada operador solo ve sus propios pagos en los detalles

---

**Última actualización:** 13 de noviembre de 2025
**Versión:** 5.0 (Dashboard clickeable + Notificaciones + PDF)
