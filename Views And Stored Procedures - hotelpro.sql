USE hotelpro;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- VIEWS AND STORED PROCEDURES

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- STORED PROCEDURES

-- -----------------------------------------------------------------------------------------------------------------------------------------
-- 1. CrearReserva: Crea una nueva reserva verificando disponibilidad de habitaciones para las fechas

DELIMITER //

CREATE PROCEDURE sp_crear_reserva(
IN p_id_cliente INT,
IN p_id_tipo_habitacion INT,
IN p_id_tarifa INT,
IN p_fecha_llegada DATE,
IN p_fecha_salida DATE,
IN p_num_adultos INT,
IN p_num_ninos INT
)

BEGIN
DECLARE v_noches INT;
DECLARE v_disponibles INT;

-- Calcular noches
SET v_noches = DATEDIFF(p_fecha_salida, p_fecha_llegada);

-- Verificar disponibilidad
SELECT COUNT(*) INTO v_disponibles

FROM habitacion
WHERE id_tipo_habitacion = p_id_tipo_habitacion
AND id_habitacion NOT IN (
SELECT rh.id_habitacion
FROM reserva_habitacion rh
INNER JOIN reserva r ON rh.id_reserva = r.id_reserva
WHERE p_fecha_llegada < r.fecha_salida
AND p_fecha_salida > r.fecha_llegada
);

-- Si hay disponibilidad, insertar
IF v_disponibles > 0 THEN

INSERT INTO reserva (
fecha_creacion, fecha_llegada, fecha_salida, numero_noches,
numero_adultos, numero_ninos, estado_reserva,
id_cliente, id_tipo_habitacion, id_tarifa
) VALUES (
NOW(), p_fecha_llegada, p_fecha_salida, v_noches,
p_num_adultos, p_num_ninos, 'confirmada',
p_id_cliente, p_id_tipo_habitacion, p_id_tarifa
);
SELECT 'Reserva creada con éxito' AS mensaje;
ELSE
SELECT 'No hay habitaciones disponibles' AS mensaje;
END IF;
END//

DELIMITER ;

CALL sp_crear_reserva(1, 1, 1, '2026-11-01', '2026-11-05', 2, 0);

-- ------------------------------------------------------------------------------------------------------------------
-- 2. ProcesarCheckIn: Registra el check-in de un cliente asignando habitación y registrando depósito

DELIMITER //

CREATE PROCEDURE sp_procesar_checkin(
IN p_id_reserva INT,
IN p_id_habitacion INT,
IN p_id_empleado INT,
IN p_forma_pago VARCHAR(50),
IN p_deposito_garantia DECIMAL(10,2)
)
BEGIN

INSERT INTO checkin_checkout(
fecha_hora_llegada_real,
forma_pago,
deposito_garantia,
id_reserva,
id_habitacion,
id_empleado
)
VALUES(
NOW(),
p_forma_pago,
p_deposito_garantia,
p_id_reserva,
p_id_habitacion,
p_id_empleado
);

UPDATE habitacion
SET estado_actual = 'ocupada'
WHERE id_habitacion = p_id_habitacion;

SELECT 'Check-in registrado correctamente' AS mensaje;

END//

DELIMITER ;

CALL sp_procesar_checkin(1, 1, 6, 'Tarjeta', 100000);

-- -------------------------------------------------------------------------------------------------------------------------------------
-- 3. RegistrarConsumoServicio: Registra consumo de servicios adicionales durante la estancia.

DELIMITER //

CREATE PROCEDURE sp_registrar_consumo_servicio(
IN p_id_cliente INT,
IN p_id_habitacion INT,
IN p_id_servicio_adicional INT,
IN p_id_empleado INT,
IN p_cantidad INT,
IN p_precio_aplicado DECIMAL(10,2),
IN p_observaciones VARCHAR(255)
)
BEGIN

INSERT INTO consumo_servicio(
fecha_hora_consumo,
cantidad,
precio_aplicado,
observaciones,
id_cliente,
id_habitacion,
id_servicio_adicional,
id_empleado
)
VALUES(
NOW(),
p_cantidad,
p_precio_aplicado,
p_observaciones,
p_id_cliente,
p_id_habitacion,
p_id_servicio_adicional,
p_id_empleado
);

SELECT 'Consumo registrado correctamente' AS mensaje;

END//

DELIMITER ;

CALL sp_registrar_consumo_servicio(1, 1, 1, 5, 1, 120000, 'Masaje relajante');

-- ---------------------------------------------------------------------------------------------------------------------------------------
-- 4. ProcesarCheckOut: Gestiona el check-out calculando cargos totales y liberando la habitación

DELIMITER //

CREATE PROCEDURE sp_procesar_checkout(
IN p_id_checkin INT,
IN p_id_habitacion INT,
IN p_id_reserva INT,
IN p_id_cliente INT,
OUT p_total DECIMAL(10,2)
)
BEGIN
DECLARE v_id_tarifa INT;
DECLARE v_noches INT;
DECLARE v_total_tarifa DECIMAL(10,2);
DECLARE v_total_consumos DECIMAL(10,2);

-- 1) Registrar la salida
UPDATE checkin_checkout
SET fecha_hora_salida_real = NOW()
WHERE id_checkin_checkout = p_id_checkin;

-- 2) Liberar la habitación
UPDATE habitacion
SET estado_actual = 'disponible'
WHERE id_habitacion = p_id_habitacion;

-- 3) Obtener tarifa y noches de la reserva
SELECT id_tarifa, numero_noches
INTO v_id_tarifa, v_noches
FROM reserva
WHERE id_reserva = p_id_reserva;

-- 4) Calcular total de la tarifa
SELECT (tarifa_base + impuestos) * v_noches
INTO v_total_tarifa
FROM tarifa
WHERE id_tarifa = v_id_tarifa;

-- 5) Calcular total de consumos
SELECT COALESCE(SUM(cantidad * precio_aplicado), 0)
INTO v_total_consumos
FROM consumo_servicio
WHERE id_cliente = p_id_cliente;

-- 6) Total final
SET p_total = v_total_tarifa + v_total_consumos;

SELECT p_total AS total_a_pagar;
END//

DELIMITER ;

CALL sp_procesar_checkout(3, 3, 3, 3, @total);
SELECT @total AS total_pagar;

-- -------------------------------------------------------------------------------------------------------------------------------------
-- 5. ProgramarEvento: Reserva salones y servicios para eventos verificando disponibilidad.

DELIMITER //

CREATE PROCEDURE sp_programar_evento(
IN p_id_cliente INT,
IN p_id_salon INT,
IN p_tipo_evento VARCHAR(50),
IN p_fecha_hora_inicio DATETIME,
IN p_duracion DECIMAL(5,2),
IN p_numero_asistentes INT,
IN p_montaje_solicitado VARCHAR(100),
IN p_precio_total DECIMAL(10,2)
)
BEGIN
DECLARE v_capacidad INT;
DECLARE v_ocupado INT;

-- 1) Verificar que el salón existe y traer su capacidad
SELECT capacidad_maxima INTO v_capacidad
FROM salon
WHERE id_salon = p_id_salon;

IF v_capacidad IS NULL THEN
SELECT 'Error: el salón no existe' AS mensaje;
ELSE
-- 2) Verificar que quepan los asistentes
IF p_numero_asistentes > v_capacidad THEN
SELECT 'Error: el número de asistentes supera la capacidad del salón' AS mensaje;
ELSE
-- 3) Verificar disponibilidad del salón en esa fecha/hora
SELECT COUNT(*) INTO v_ocupado
FROM evento
WHERE id_salon = p_id_salon
AND estado_evento IN ('confirmado', 'pendiente')
AND p_fecha_hora_inicio < DATE_ADD(fecha_hora_inicio, INTERVAL duracion*60 MINUTE)
AND DATE_ADD(p_fecha_hora_inicio, INTERVAL p_duracion*60 MINUTE) > fecha_hora_inicio;

IF v_ocupado > 0 THEN
SELECT 'Error: el salón ya está ocupado en esa fecha/hora' AS mensaje;
ELSE
-- 4) Insertar el evento
INSERT INTO evento(
tipo_evento, fecha_hora_inicio, duracion, numero_asistentes,
montaje_solicitado, precio_total, estado_evento,
id_cliente, id_salon
)
VALUES(
p_tipo_evento, p_fecha_hora_inicio, p_duracion, p_numero_asistentes,
p_montaje_solicitado, p_precio_total, 'confirmado',
p_id_cliente, p_id_salon
);

SELECT 'Evento programado con éxito' AS mensaje;
END IF;
END IF;
END IF;
END//

DELIMITER ;

CALL sp_programar_evento(1, 1, 'Conferencia', '2026-12-01 09:00:00', 4, 50, 'Auditorio', 3000000);

-- prueba para demostrar el ELSE
CALL sp_programar_evento(1, 1, 'Conferencia', '2026-12-01 09:00:00', 4, 50, 'Auditorio', 3000000);

-- ------------------------------------------------------------------------------------------------------------------------------------------------
-- Todos los Stored Procedures de la Base de Datos
SHOW PROCEDURE STATUS WHERE Db = 'hotelpro';

-- ------------------------------------------------------------------------------------------------------------------------------------------------

-- VIEWS

-- -------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. V_DisponibilidadHabitaciones: Muestra la disponibilidad de habitaciones por tipo y fecha.

CREATE VIEW vw_disponibilidad_habitaciones AS
SELECT
th.descripcion AS tipo_habitacion,
h.id_habitacion,
h.numero_habitacion,
h.estado_actual
FROM tipo_habitacion th
INNER JOIN habitacion h ON th.id_tipo_habitacion = h.id_tipo_habitacion
WHERE h.estado_actual = 'disponible';

SELECT * FROM vw_disponibilidad_habitaciones;

-- -------------------------------------------------------------------------------------------------------------------------------
-- 2. V_ReservasFuturas: Presenta todas las reservas futuras con detalles de clientes.

CREATE VIEW vw_reservas_futuras AS
SELECT
r.id_reserva,
r.fecha_llegada,
r.fecha_salida,
r.numero_noches,
r.numero_adultos,
r.numero_ninos,
r.estado_reserva,
c.nombre,
c.apellido,
c.DNI,
c.telefono,
c.correo_electronico
FROM reserva r
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
WHERE r.fecha_llegada > CURDATE();

SELECT * FROM vw_reservas_futuras;

-- -----------------------------------------------------------------------------------------------------------------
-- 3. V_OcupacionActual: Detalla la ocupación actual del hotel por tipo de habitación.

CREATE VIEW vw_ocupacion_actual AS
SELECT
th.descripcion AS tipo_habitacion,
h.numero_habitacion,
h.estado_actual
FROM habitacion h
INNER JOIN tipo_habitacion th ON h.id_tipo_habitacion = th.id_tipo_habitacion
WHERE h.estado_actual = 'ocupada';

SELECT * FROM vw_ocupacion_actual;

-- -----------------------------------------------------------------------------------------------------------------
-- 4. V_EventosProgramados: Calendario de eventos programados con salones y servicios.

CREATE VIEW vw_eventos_programados AS
SELECT
e.id_evento,
e.tipo_evento,
e.fecha_hora_inicio,
e.duracion,
e.numero_asistentes,
e.estado_evento,
s.nombre_salon AS salon,
s.ubicacion_en_hotel AS ubicacion,
GROUP_CONCAT(DISTINCT cat.nombre_catering SEPARATOR ', ') AS catering,
GROUP_CONCAT(DISTINCT eq.nombre_equipo SEPARATOR ', ') AS equipamiento
FROM evento e
INNER JOIN salon s ON e.id_salon = s.id_salon
LEFT JOIN evento_catering ec ON e.id_evento = ec.id_evento
LEFT JOIN catering cat ON ec.id_catering = cat.id_catering
LEFT JOIN evento_equipamiento ee ON e.id_evento = ee.id_evento
LEFT JOIN equipamiento eq ON ee.id_equipo = eq.id_equipo
GROUP BY e.id_evento, e.tipo_evento, e.fecha_hora_inicio, e.duracion,
e.numero_asistentes, e.estado_evento, s.nombre_salon, s.ubicacion_en_hotel;

SELECT * FROM vw_eventos_programados;

-- ------------------------------------------------------------------------------------------------------------------------------
-- 5. V_EstadisticasOcupacion: Estadísticas de ocupación por periodo, habitación y temporada.

CREATE VIEW vw_estadisticas_ocupacion AS
SELECT
t.nombre_temporada AS temporada,
t.fecha_inicio,
t.fecha_fin,
th.descripcion AS tipo_habitacion,
COUNT(r.id_reserva) AS total_reservas,
SUM(r.numero_noches) AS total_noches
FROM temporada t
INNER JOIN tarifa ta ON t.id_temporada = ta.id_temporada
INNER JOIN tipo_habitacion th ON ta.id_tipo_habitacion = th.id_tipo_habitacion
LEFT JOIN reserva r ON r.id_tarifa = ta.id_tarifa
GROUP BY t.nombre_temporada, t.fecha_inicio, t.fecha_fin, th.descripcion;

SELECT * FROM vw_estadisticas_ocupacion;

-- -----------------------------------------------------------------------------------------------------------------------------
-- -- Todas las Views de la Base de Datos
SHOW FULL TABLES WHERE table_type = 'VIEW';

-- -----------------------------------------------------------------------------------------------------------------------------