-- Verificar si ya existe un usuario administrador
SELECT * FROM usuarios WHERE email = 'admin@gym.com';

-- Insertar el usuario administrador si no existe
INSERT OR IGNORE INTO usuarios (
  nombreCompleto, 
  email, 
  telefono, 
  dni, 
  rol, 
  fechaCreacion, 
  activo
) VALUES (
  'Administrador',
  'admin@gym.com',
  'admin',
  'admin',
  'admin',
  datetime('now'),
  1
);

-- Verificar que se haya insertado correctamente
SELECT * FROM usuarios WHERE email = 'admin@gym.com';
