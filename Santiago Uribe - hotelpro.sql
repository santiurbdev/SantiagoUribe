CREATE DATABASE hotelpro;

USE hotelpro;



-- ------------------------------------------------------------------------------
-- Tabla hotel

CREATE TABLE hotel (
id_hotel INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
categoria_estrellas INT NOT NULL,
direccion VARCHAR(150) NOT NULL,
telefono VARCHAR(20) NOT NULL,
correo_electronico VARCHAR(100) NOT NULL UNIQUE,
anio_inauguracion INT NOT NULL,
numero_total_habitaciones INT NOT NULL,
hora_checkin TIME NOT NULL,
hora_checkout TIME NOT NULL,
id_gerente INT NULL
);

-- ------------------------------------------------------------------------------
-- Tabla empleado

CREATE TABLE empleado (
id_empleado INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
apellido VARCHAR(100) NOT NULL,
DNI VARCHAR(20) NOT NULL UNIQUE,
telefono VARCHAR(20) NOT NULL,
correo_electronico VARCHAR(100) NOT NULL UNIQUE,
cargo VARCHAR(50) NOT NULL,
fecha_contratacion DATE NOT NULL,
id_hotel INT NOT NULL,
FOREIGN KEY (id_hotel) REFERENCES hotel (id_hotel) ON DELETE CASCADE
);

ALTER TABLE hotel
ADD CONSTRAINT fk_gerente_hotel FOREIGN KEY (id_gerente) REFERENCES empleado (id_empleado) ON DELETE SET NULL;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tabla servicio_general

CREATE TABLE servicio_general (
id_servicio_general INT AUTO_INCREMENT PRIMARY KEY,
nombre_servicio_general VARCHAR(100) NOT NULL
);

-- ---------------------------------------------------------------------------------------------------------
-- Tabla hotel_servicio_general - pivote

CREATE TABLE hotel_servicio_general (
id_hotel INT NOT NULL,
id_servicio_general INT NOT NULL,
PRIMARY KEY (id_hotel, id_servicio_general),
FOREIGN KEY (id_hotel) REFERENCES hotel (id_hotel) ON DELETE CASCADE,
FOREIGN KEY (id_servicio_general) REFERENCES servicio_general (id_servicio_general) ON DELETE CASCADE
);

-- --------------------------------------------------------------------------------------------------------
-- Tabla tipo_habitacion

CREATE TABLE tipo_habitacion (
id_tipo_habitacion INT AUTO_INCREMENT PRIMARY KEY,
descripcion VARCHAR(255) NOT NULL,
capacidad_maxima_huespedes INT NOT NULL,
tamano_m2 DECIMAL(6,2) NOT NULL,
numero_camas INT NOT NULL,
tipo_camas VARCHAR(50) NOT NULL
);

-- -------------------------------------------------------------------------------------
-- Tabla amenidad

CREATE TABLE amenidad (
id_amenidad INT AUTO_INCREMENT PRIMARY KEY,
nombre_amenidad VARCHAR(100) NOT NULL
);

-- ----------------------------------------------------------------------------------------------------------------
-- Tabla tipo_habitacion_amenidad - pivote

CREATE TABLE tipo_habitacion_amenidad (
id_tipo_habitacion INT NOT NULL,
id_amenidad INT NOT NULL,
PRIMARY KEY (id_tipo_habitacion, id_amenidad),
FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion (id_tipo_habitacion) ON DELETE CASCADE,
FOREIGN KEY (id_amenidad) REFERENCES amenidad (id_amenidad) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------------------------------------------
-- Tabla habitacion

CREATE TABLE habitacion (
id_habitacion INT AUTO_INCREMENT PRIMARY KEY,
numero_habitacion VARCHAR(10) NOT NULL,
piso INT NOT NULL,
orientacion VARCHAR(30) NOT NULL,
estado_actual VARCHAR(30) NOT NULL,
caracteristicas_especiales VARCHAR(255),
tarifa_base DECIMAL(10,2) NOT NULL,
id_hotel INT NOT NULL,
id_tipo_habitacion INT NOT NULL,
FOREIGN KEY (id_hotel) REFERENCES hotel (id_hotel) ON DELETE CASCADE,
FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion (id_tipo_habitacion),
UNIQUE (id_hotel, numero_habitacion)
);

-- -------------------------------------------------------------------------------------------------------------------
-- Tabla nivel_fidelizacion 

CREATE TABLE nivel_fidelizacion (
id_nivel_fidelizacion INT AUTO_INCREMENT PRIMARY KEY,
nombre_nivel VARCHAR(30) NOT NULL UNIQUE
);

-- ----------------------------------------------------------------------------------------------------------------
-- Tabla cliente

CREATE TABLE cliente (
id_cliente INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
apellido VARCHAR(100) NOT NULL,
DNI VARCHAR(20) NOT NULL UNIQUE,
nacionalidad VARCHAR(50) NOT NULL,
fecha_nacimiento DATE NOT NULL,
direccion VARCHAR(150),
telefono VARCHAR(20) NOT NULL,
correo_electronico VARCHAR(100) NOT NULL UNIQUE,
preferencias_especiales TEXT,
id_nivel_fidelizacion INT NOT NULL,
FOREIGN KEY (id_nivel_fidelizacion) REFERENCES nivel_fidelizacion (id_nivel_fidelizacion)
);

-- -----------------------------------------------------------------------------------------------------------------------
-- Tabla temporada

CREATE TABLE temporada (
id_temporada INT AUTO_INCREMENT PRIMARY KEY,
nombre_temporada VARCHAR(30) NOT NULL,
fecha_inicio DATE NOT NULL,
fecha_fin DATE NOT NULL,
factor_precio DECIMAL(4,2) NOT NULL
);

-- -----------------------------------------------------------------------------------------------------
-- Tabla tarifa

CREATE TABLE tarifa (
id_tarifa INT AUTO_INCREMENT PRIMARY KEY,
tarifa_base DECIMAL(10,2) NOT NULL,
impuestos DECIMAL(10,2) NOT NULL,
descuento_estadia_prolongada DECIMAL(5,2),
condiciones_especiales VARCHAR(255),
id_tipo_habitacion INT NOT NULL,
id_temporada INT NOT NULL,
FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion (id_tipo_habitacion),
FOREIGN KEY (id_temporada) REFERENCES temporada (id_temporada)
);

-- -----------------------------------------------------------------------------------------------------
-- Tabla reserva

CREATE TABLE reserva (
id_reserva INT AUTO_INCREMENT PRIMARY KEY,
fecha_creacion DATETIME NOT NULL,
fecha_llegada DATE NOT NULL,
fecha_salida DATE NOT NULL,
numero_noches INT NOT NULL,
numero_adultos INT NOT NULL,
numero_ninos INT NOT NULL DEFAULT 0,
deposito_recibido DECIMAL(10,2),
metodo_pago_deposito VARCHAR(50),
solicitudes_especiales VARCHAR(255),
estado_reserva VARCHAR(30) NOT NULL,
id_cliente INT NOT NULL,
id_tipo_habitacion INT NOT NULL,
id_tarifa INT NOT NULL,
FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion (id_tipo_habitacion),
FOREIGN KEY (id_tarifa) REFERENCES tarifa (id_tarifa)
);

-- ------------------------------------------------------------------------------------------------------------
-- Tabla reserva_habitacion - pivote

CREATE TABLE reserva_habitacion (
id_reserva INT NOT NULL,
id_habitacion INT NOT NULL,
PRIMARY KEY (id_reserva, id_habitacion),
FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva) ON DELETE CASCADE,
FOREIGN KEY (id_habitacion) REFERENCES habitacion (id_habitacion) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------------------------------------------------
-- Tabla checkin_checkout

CREATE TABLE checkin_checkout (
id_checkin_checkout INT AUTO_INCREMENT PRIMARY KEY,
fecha_hora_llegada_real DATETIME,
fecha_hora_salida_real DATETIME,
forma_pago VARCHAR(50) NOT NULL,
deposito_garantia DECIMAL(10,2),
observaciones VARCHAR(255),
id_reserva INT NOT NULL,
id_habitacion INT NOT NULL,
id_empleado INT NOT NULL,
FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva) ON DELETE CASCADE,
FOREIGN KEY (id_habitacion) REFERENCES habitacion (id_habitacion),
FOREIGN KEY (id_empleado) REFERENCES empleado (id_empleado)
);

-- ------------------------------------------------------------------------------------------------------------------------------
-- Tabla servicio_adicional

CREATE TABLE servicio_adicional (
id_servicio_adicional INT AUTO_INCREMENT PRIMARY KEY,
nombre_servicio VARCHAR(100) NOT NULL,
descripcion TEXT,
horario_disponibilidad VARCHAR(100),
precio DECIMAL(10,2) NOT NULL,
duracion_tipica VARCHAR(30),
capacidad_maxima INT
);

-- --------------------------------------------------------------------------------------------------------------------------------
-- Tabla consumo_servicio

CREATE TABLE consumo_servicio (
id_consumo INT AUTO_INCREMENT PRIMARY KEY,
fecha_hora_consumo DATETIME NOT NULL,
cantidad INT NOT NULL,
precio_aplicado DECIMAL(10,2) NOT NULL,
observaciones VARCHAR(255),
id_cliente INT NOT NULL,
id_habitacion INT NOT NULL,
id_servicio_adicional INT NOT NULL,
id_empleado INT NOT NULL,
FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
FOREIGN KEY (id_habitacion) REFERENCES habitacion (id_habitacion),
FOREIGN KEY (id_servicio_adicional) REFERENCES servicio_adicional (id_servicio_adicional),
FOREIGN KEY (id_empleado) REFERENCES empleado (id_empleado)
);

-- -------------------------------------------------------------------------------------------------------------------------------------
-- Tabla salon

CREATE TABLE salon (
id_salon INT AUTO_INCREMENT PRIMARY KEY,
nombre_salon VARCHAR(100) NOT NULL,
ubicacion_en_hotel VARCHAR(100) NOT NULL,
capacidad_maxima INT NOT NULL,
tamano_m2 DECIMAL(6,2) NOT NULL,
id_hotel INT NOT NULL,
FOREIGN KEY (id_hotel) REFERENCES hotel (id_hotel) ON DELETE CASCADE
);

-- -------------------------------------------------------------------------------------------------------------------------
-- Tabla salon_configuracion

CREATE TABLE salon_configuracion (
id_configuracion INT AUTO_INCREMENT PRIMARY KEY,
nombre_configuracion VARCHAR(50) NOT NULL,
capacidad_configuracion INT NOT NULL,
id_salon INT NOT NULL,
FOREIGN KEY (id_salon) REFERENCES salon (id_salon) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------------------------------------------------
-- Tabla salon_tarifa_duracion 

CREATE TABLE salon_tarifa_duracion (
id_tarifa_salon INT AUTO_INCREMENT PRIMARY KEY,
duracion_horas DECIMAL(4,2) NOT NULL,
tarifa DECIMAL(10,2) NOT NULL,
id_salon INT NOT NULL,
FOREIGN KEY (id_salon) REFERENCES salon (id_salon) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------------------------------------------------
-- Tabla evento

CREATE TABLE evento (
id_evento INT AUTO_INCREMENT PRIMARY KEY,
tipo_evento VARCHAR(50) NOT NULL,
fecha_hora_inicio DATETIME NOT NULL,
duracion DECIMAL(5,2) NOT NULL,
numero_asistentes INT NOT NULL,
montaje_solicitado VARCHAR(100),
precio_total DECIMAL(10,2) NOT NULL,
estado_evento VARCHAR(30) NOT NULL,
id_cliente INT NOT NULL,
id_salon INT NOT NULL,
FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
FOREIGN KEY (id_salon) REFERENCES salon (id_salon)
);

-- ------------------------------------------------------------------------------------------------------------------------
-- Tabla Catering

CREATE TABLE catering (
id_catering INT AUTO_INCREMENT PRIMARY KEY,
nombre_catering VARCHAR(100) NOT NULL,
descripcion TEXT,
precio_por_persona DECIMAL(10,2) NOT NULL,
minimo_personas INT
);

-- -----------------------------------------------------------------------------------------------------------------------
-- Tabla evento_catering - pivote

CREATE TABLE evento_catering (
id_evento INT NOT NULL,
id_catering INT NOT NULL,
cantidad INT NOT NULL DEFAULT 1,
PRIMARY KEY (id_evento, id_catering),
FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON DELETE CASCADE,
FOREIGN KEY (id_catering) REFERENCES catering (id_catering) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------------------------------------------------
-- Tabla equipamiento

CREATE TABLE equipamiento (
id_equipo INT AUTO_INCREMENT PRIMARY KEY,
nombre_equipo VARCHAR(100) NOT NULL
);

-- -------------------------------------------------------------------------------------------------------------------------
-- Tabla evento_equipamiento - pivote

CREATE TABLE evento_equipamiento (
id_evento INT NOT NULL,
id_equipo INT NOT NULL,
cantidad INT NOT NULL DEFAULT 1,
PRIMARY KEY (id_evento, id_equipo),
FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON DELETE CASCADE,
FOREIGN KEY (id_equipo) REFERENCES equipamiento (id_equipo) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------------------------------------------------------------------------

-- REGISTROS

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO hotel (nombre, categoria_estrellas, direccion, telefono, correo_electronico, anio_inauguracion, numero_total_habitaciones, hora_checkin, hora_checkout, id_gerente) VALUES
('Estancias de Lujo Bogota', 5, 'Cra 7 # 82-45, Bogota', '6016015550', 'bogota@estanciasdelujo.com', 2010, 80, '15:00:00', '12:00:00', NULL),
('Estancias de Lujo Cartagena', 5, 'Calle Bocagrande #5-10, Cartagena', '6056655500', 'cartagena@estanciasdelujo.com', 2015, 60, '15:00:00', '12:00:00', NULL),
('Estancias de Lujo Medellin', 4, 'Cra 43A #7-50, El Poblado', '6044445500', 'medellin@estanciasdelujo.com', 2018, 50, '14:00:00', '11:00:00', NULL),
('Estancias de Lujo Cali', 4, 'Av 6N #23-45, Cali', '6023335500', 'cali@estanciasdelujo.com', 2012, 45, '15:00:00', '12:00:00', NULL),
('Estancias de Lujo San Andres', 5, 'Av Colombia s/n, San Andres', '6085125500', 'sanandres@estanciasdelujo.com', 2020, 40, '15:00:00', '12:00:00', NULL);

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO empleado (nombre, apellido, DNI, telefono, correo_electronico, cargo, fecha_contratacion, id_hotel) VALUES
('Carlos', 'Ramirez', '1001234567', '3001112233', 'carlos.ramirez@estanciasdelujo.com', 'Gerente', '2015-03-01', 1),
('Maria', 'Gomez', '1002234567', '3002223344', 'maria.gomez@estanciasdelujo.com', 'Gerente', '2016-05-15', 2),
('Andres', 'Lopez', '1003234567', '3003334455', 'andres.lopez@estanciasdelujo.com', 'Gerente', '2019-01-10', 3),
('Laura', 'Torres', '1004234567', '3004445566', 'laura.torres@estanciasdelujo.com', 'Gerente', '2013-07-20', 4),
('Jorge', 'Martinez', '1005234567', '3005556677', 'jorge.martinez@estanciasdelujo.com', 'Gerente', '2021-02-11', 5),
('Diana', 'Vargas', '1006234567', '3006667788', 'diana.vargas@estanciasdelujo.com', 'Recepcionista', '2020-04-12', 1),
('Felipe', 'Castro', '1007234567', '3007778899', 'felipe.castro@estanciasdelujo.com', 'Botones', '2018-09-05', 2),
('Valentina', 'Rios', '1008234567', '3008889900', 'valentina.rios@estanciasdelujo.com', 'Mesero', '2017-06-23', 3);

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ahora los UPDATE — conectan al gerente con su hotel

UPDATE hotel SET id_gerente = 1 WHERE id_hotel = 1;
UPDATE hotel SET id_gerente = 2 WHERE id_hotel = 2;
UPDATE hotel SET id_gerente = 3 WHERE id_hotel = 3;
UPDATE hotel SET id_gerente = 4 WHERE id_hotel = 4;
UPDATE hotel SET id_gerente = 5 WHERE id_hotel = 5;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
INSERT INTO servicio_general (nombre_servicio_general) VALUES
('Wifi gratuito'),
('Piscina'),
('Gimnasio'),
('Parqueadero'),
('Spa');

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO hotel_servicio_general (id_hotel, id_servicio_general) VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 5),
(3, 3);

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO tipo_habitacion (descripcion, capacidad_maxima_huespedes, tamano_m2, numero_camas, tipo_camas) VALUES
('Individual', 1, 18.50, 1, 'Sencilla'),
('Doble', 2, 25.00, 2, 'Dobles'),
('Suite', 4, 45.00, 2, 'Queen'),
('Familiar', 5, 55.00, 3, 'Mixta'),
('Presidencial', 6, 90.00, 2, 'King');

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO amenidad (nombre_amenidad) VALUES
('Minibar'),
('TV por cable'),
('Caja fuerte'),
('Aire acondicionado'),
('Balcon privado');

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO tipo_habitacion_amenidad (id_tipo_habitacion, id_amenidad) VALUES
(1, 2),
(2, 2),
(2, 4),
(3, 1),
(5, 5);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO habitacion (numero_habitacion, piso, orientacion, estado_actual, caracteristicas_especiales, tarifa_base, id_hotel, id_tipo_habitacion) VALUES
('101', 1, 'Vista ciudad', 'disponible', NULL, 250000.00, 1, 1),
('201', 2, 'Vista piscina', 'ocupada', NULL, 320000.00, 1, 2),
('305', 3, 'Vista mar', 'disponible', 'Cuarto accesible', 550000.00, 2, 3),
('402', 4, 'Interior', 'en mantenimiento', NULL, 280000.00, 3, 1),
('501', 5, 'Vista mar', 'disponible', NULL, 950000.00, 5, 5);

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO nivel_fidelizacion (nombre_nivel) VALUES
('Bronce'),
('Plata'),
('Oro'),
('Platino'),
('Diamante');

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO cliente (nombre, apellido, DNI, nacionalidad, fecha_nacimiento, direccion, telefono, correo_electronico, preferencias_especiales, id_nivel_fidelizacion) VALUES
('Ana', 'Fernandez', '55123456', 'Colombiana', '1990-05-12', 'Cra 10 #20-30, Bogota', '3101112233', 'ana.fernandez@mail.com', 'Piso alto, sin fumar', 2),
('Pedro', 'Sanchez', '79456123', 'Colombiana', '1985-11-23', 'Calle 45 #12-08, Medellin', '3102223344', 'pedro.sanchez@mail.com', NULL, 1),
('Sofia', 'Restrepo', '43789456', 'Colombiana', '1992-02-17', 'Av Siempre Viva 742, Cali', '3103334455', 'sofia.restrepo@mail.com', 'Alergica al gluten', 3),
('John', 'Smith', 'PA1234567', 'Estadounidense', '1978-08-30', '5th Ave, New York', '3104445566', 'john.smith@mail.com', NULL, 4),
('Camila', 'Ortiz', '1098765432', 'Colombiana', '2000-01-05', 'Cra 15 #33-20, Cartagena', '3105556677', 'camila.ortiz@mail.com', 'Prefiere vista al mar', 5);

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO temporada (nombre_temporada, fecha_inicio, fecha_fin, factor_precio) VALUES
('Alta', '2026-12-15', '2027-01-15', 1.50),
('Media', '2026-04-01', '2026-06-30', 1.10),
('Baja', '2026-02-01', '2026-03-31', 0.80),
('Alta Semana Santa', '2026-03-28', '2026-04-05', 1.40),
('Baja Noviembre', '2026-11-01', '2026-11-30', 0.75);

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO tarifa (tarifa_base, impuestos, descuento_estadia_prolongada, condiciones_especiales, id_tipo_habitacion, id_temporada) VALUES
(250000.00, 47500.00, 10.00, 'No reembolsable', 1, 3),
(380000.00, 72200.00, 5.00, NULL, 2, 2),
(600000.00, 114000.00, NULL, 'Incluye desayuno', 3, 1),
(700000.00, 133000.00, 15.00, NULL, 4, 1),
(950000.00, 180500.00, NULL, 'Tarifa VIP', 5, 4);

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO reserva (fecha_creacion, fecha_llegada, fecha_salida, numero_noches, numero_adultos, numero_ninos, deposito_recibido, metodo_pago_deposito, solicitudes_especiales, estado_reserva, id_cliente, id_tipo_habitacion, id_tarifa) VALUES
('2026-09-01 10:15:00', '2026-09-10', '2026-09-13', 3, 2, 0, 100000.00, 'Tarjeta', NULL, 'confirmada', 1, 1, 1),
('2026-09-02 11:00:00', '2026-09-15', '2026-09-18', 3, 2, 1, 150000.00, 'Tarjeta', 'Cama adicional', 'confirmada', 2, 2, 2),
('2026-08-20 09:30:00', '2026-09-05', '2026-09-08', 3, 4, 0, 200000.00, 'Efectivo', NULL, 'completada', 3, 3, 3),
('2026-07-15 14:20:00', '2026-08-01', '2026-08-05', 4, 5, 2, 300000.00, 'Transferencia', 'Necesitan cuna', 'cancelada', 4, 4, 4),
('2026-09-20 16:45:00', '2026-12-20', '2026-12-27', 7, 2, 0, 500000.00, 'Tarjeta', 'Luna de miel', 'confirmada', 5, 5, 5);

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO reserva_habitacion (id_reserva, id_habitacion) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO checkin_checkout (fecha_hora_llegada_real, fecha_hora_salida_real, forma_pago, deposito_garantia, observaciones, id_reserva, id_habitacion, id_empleado) VALUES
(NULL, NULL, 'Tarjeta', 100000.00, 'Pendiente por llegar', 1, 1, 3),
(NULL, NULL, 'Tarjeta', 150000.00, 'Pendiente por llegar', 2, 2, 3),
('2026-09-05 15:10:00', '2026-09-08 11:05:00', 'Efectivo', 200000.00, 'Todo en orden', 3, 3, 3),
(NULL, NULL, 'Transferencia', NULL, 'Reserva cancelada antes de la llegada', 4, 4, 5),
(NULL, NULL, 'Tarjeta', 500000.00, NULL, 5, 5, 3);

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

INSERT INTO servicio_adicional (nombre_servicio, descripcion, horario_disponibilidad, precio, duracion_tipica, capacidad_maxima) VALUES
('Masaje relajante', 'Masaje corporal de 60 minutos', '9:00 - 19:00', 120000.00, '60 minutos', 1),
('Lavanderia express', 'Lavado y planchado en 24 horas', '8:00 - 20:00', 35000.00, '24 horas', NULL),
('Room service 24h', 'Servicio a la habitacion', '24 horas', 25000.00, '30 minutos', NULL),
('Clases de yoga', 'Sesion grupal en zona de piscina', '7:00 - 8:00', 40000.00, '45 minutos', 15),
('Facial spa', 'Tratamiento facial hidratante', '10:00 - 18:00', 90000.00, '50 minutos', 1);

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO consumo_servicio (fecha_hora_consumo, cantidad, precio_aplicado, observaciones, id_cliente, id_habitacion, id_servicio_adicional, id_empleado) VALUES
('2026-09-11 16:00:00', 1, 120000.00, NULL, 1, 1, 1, 5),
('2026-09-16 09:00:00', 2, 70000.00, 'Dos piezas de ropa', 2, 2, 2, 5),
('2026-09-06 20:00:00', 1, 25000.00, NULL, 3, 3, 3, 3),
('2026-08-02 07:15:00', 2, 80000.00, 'Clase privada', 4, 4, 4, 5),
('2026-09-22 11:00:00', 1, 90000.00, NULL, 5, 5, 5, 3); 

-- Los id 5 y 3 son gerentes: los use porque solo hay 8 empleados de prueba (no 20),
-- asi que no habia personal especifico para otras tareas en esos hoteles

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO salon (nombre_salon, ubicacion_en_hotel, capacidad_maxima, tamano_m2, id_hotel) VALUES
('Salon Imperial', 'Piso 2, Ala Norte', 200, 180.00, 1),
('Salon Cartagena', 'Piso 1', 150, 130.00, 2),
('Salon Poblado', 'Piso 3', 100, 90.00, 3),
('Salon Pacifico', 'Piso 1', 120, 100.00, 4),
('Salon Caribe', 'Piso 2', 250, 220.00, 5);

-- ---------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO salon_configuracion (nombre_configuracion, capacidad_configuracion, id_salon) VALUES
('Teatro', 200, 1),
('Banquete', 150, 1),
('En U', 60, 3),
('Coctel', 180, 5),
('Escuela', 100, 4);

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO salon_tarifa_duracion (duracion_horas, tarifa, id_salon) VALUES
(4.00, 2000000.00, 1),
(8.00, 3500000.00, 1),
(4.00, 1200000.00, 3),
(6.00, 2500000.00, 5),
(3.00, 900000.00, 4);

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO evento (tipo_evento, fecha_hora_inicio, duracion, numero_asistentes, montaje_solicitado, precio_total, estado_evento, id_cliente, id_salon) VALUES
('Boda', '2026-12-20 18:00:00', 6.00, 150, 'Mesas redondas', 12000000.00, 'confirmado', 5, 5),
('Conferencia', '2026-10-05 08:00:00', 8.00, 80, 'Auditorio', 4500000.00, 'confirmado', 4, 1),
('Reunion corporativa', '2026-09-30 09:00:00', 3.00, 20, 'Sala de juntas', 900000.00, 'confirmado', 2, 4),
('Cumpleanos', '2026-11-15 19:00:00', 5.00, 60, 'Coctel', 3000000.00, 'pendiente', 3, 3),
('Lanzamiento de producto', '2026-10-20 17:00:00', 4.00, 100, 'Coctel', 5000000.00, 'confirmado', 1, 2);

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO catering (nombre_catering, descripcion, precio_por_persona, minimo_personas) VALUES
('Banquete de 3 tiempos', 'Entrada, plato fuerte y postre', 90000.00, 50),
('Coctel de bienvenida', 'Pasabocas y bebidas', 35000.00, 30),
('Desayuno buffet', 'Buffet completo de desayuno', 25000.00, 20),
('Estacion de postres', 'Mesa dulce variada', 20000.00, 20),
('Barra libre premium', 'Licores premium por 4 horas', 60000.00, 40);

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO evento_catering (id_evento, id_catering, cantidad) VALUES
(1, 1, 150),
(1, 2, 150),
(2, 3, 80),
(3, 4, 20),
(5, 2, 100);

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO equipamiento (nombre_equipo) VALUES
('Proyector'),
('Microfono inalambrico'),
('Pantalla gigante'),
('Sistema de sonido'),
('Iluminacion LED');

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO evento_equipamiento (id_evento, id_equipo, cantidad) VALUES
(1, 4, 1),
(1, 5, 1),
(2, 1, 1),
(2, 2, 2),   
(3, 2, 1); 

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
