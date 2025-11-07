# Animaciones Rive

## Cómo agregar una animación Rive del lobo haciendo ejercicio

### Opción 1: Crear la animación en Rive Editor

1. Ve a [rive.app](https://rive.app) y crea una cuenta gratuita
2. Crea un nuevo archivo
3. Diseña un lobo haciendo ejercicio (flexiones, levantando pesas, etc.)
4. Exporta el archivo como `.riv`
5. Coloca el archivo aquí como `gym_wolf.riv`

### Opción 2: Usar una animación existente

1. Busca animaciones de lobos o ejercicios en [rive.app/community](https://rive.app/community)
2. Descarga un archivo `.riv` compatible
3. Renómbralo a `gym_wolf.riv`
4. Colócalo en este directorio

### Opción 3: Usar la animación alternativa

Si no tienes un archivo `.riv`, la aplicación usará automáticamente una animación avanzada creada con Flutter nativo que simula movimientos de ejercicio.

### Estructura del State Machine (si creas tu propia animación)

Si creas tu propia animación en Rive, asegúrate de:
- Nombrar el State Machine como "State Machine 1"
- Incluir estados como: "Idle", "Exercise", "Breathing"
- Usar triggers para cambiar entre estados si es necesario

### Notas

- El archivo debe llamarse exactamente `gym_wolf.riv`
- El tamaño recomendado es 240x240 píxeles o más
- La animación debe ser circular o cuadrada para que se vea bien en el contenedor circular

