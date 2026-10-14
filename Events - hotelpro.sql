USE hotelpro;

SET GLOBAL event_scheduler = ON;

-- -------------------------------------------------------------------------------------------------------------------------------------
-- EVENTS
-- -------------------------------------------------------------------------------------------------------------------------------------
-- 1. EVT_EnviarConfirmacionReserva: Genera confirmaciones para reservas próximas.


CREATE TABLE IF NOT EXISTS evt_notificaciones_reserva (
id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
id_reserva INT,
mensaje VARCHAR(255),
fecha_generacion DATETIME
);

DROP EVENT IF EXISTS evt_enviar_confirmacion_reserva;

DELIMITER //

CREATE EVENT evt_enviar_confirmacion_reserva
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN

TRUNCATE TABLE evt_notificaciones_reserva;

INSERT INTO evt_notificaciones_reserva(id_reserva, mensaje, fecha_generacion)
SELECT
r.id_reserva,
CONCAT('Confirmación enviada al cliente ', c.nombre, ' ', c.apellido),
NOW()
FROM reserva r
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
WHERE r.fecha_llegada BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 365 DAY)
AND r.estado_reserva = 'confirmada';

END//

DELIMITER ;



-- ---------------------------------------------------------------------------------------------------------------------------
-- 2. EVT_ActualizarTarifasTemporada: Actualiza tarifas automáticamente según cambios de temporada.


CREATE TABLE IF NOT EXISTS evt_tarifas_actualizadas (
id_registro INT AUTO_INCREMENT PRIMARY KEY,
id_tarifa INT,
nombre_temporada VARCHAR(30),
tarifa_base DECIMAL(10,2),
factor_temporada DECIMAL(4,2),
tarifa_calculada DECIMAL(10,2),
fecha_actualizacion DATETIME
);

DROP EVENT IF EXISTS evt_actualizar_tarifas_temporada;

DELIMITER //

CREATE EVENT evt_actualizar_tarifas_temporada
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN

TRUNCATE TABLE evt_tarifas_actualizadas;

INSERT INTO evt_tarifas_actualizadas(
id_tarifa,
nombre_temporada,
tarifa_base,
factor_temporada,
tarifa_calculada,
fecha_actualizacion
)
SELECT
t.id_tarifa,
temp.nombre_temporada,
t.tarifa_base,
temp.factor_precio,
t.tarifa_base * temp.factor_precio,
NOW()
FROM tarifa t
INNER JOIN temporada temp ON t.id_temporada = temp.id_temporada;

END//

DELIMITER ;



-- -------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. EVT_VerificarLlegadasDelDia: Genera lista diaria de llegadas previstas.


CREATE TABLE IF NOT EXISTS evt_llegadas_del_dia (
id_llegada INT AUTO_INCREMENT PRIMARY KEY,
id_reserva INT,
cliente VARCHAR(200),
dni VARCHAR(20),
telefono VARCHAR(20),
fecha_llegada DATE,
numero_noches INT,
estado_reserva VARCHAR(30),
fecha_generacion DATETIME
);

DROP EVENT IF EXISTS evt_verificar_llegadas_del_dia;

DELIMITER //

CREATE EVENT evt_verificar_llegadas_del_dia
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN

TRUNCATE TABLE evt_llegadas_del_dia;

INSERT INTO evt_llegadas_del_dia(
id_reserva,
cliente,
dni,
telefono,
fecha_llegada,
numero_noches,
estado_reserva,
fecha_generacion
)
SELECT
r.id_reserva,
CONCAT(c.nombre, ' ', c.apellido),
c.DNI,
c.telefono,
r.fecha_llegada,
r.numero_noches,
r.estado_reserva,
NOW()
FROM reserva r
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
WHERE r.fecha_llegada BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 365 DAY)
AND r.estado_reserva IN ('confirmada', 'pendiente');

END//

DELIMITER ;



-- ---------------------------------------------------------------------------------------------------------------------------------------------
-- 4. EVT_LiberarReservasSinGarantia: Libera reservas sin garantía que no se confirmaron.


CREATE TABLE IF NOT EXISTS evt_reservas_liberadas (
id_liberacion INT AUTO_INCREMENT PRIMARY KEY,
id_reserva INT,
cliente VARCHAR(200),
fecha_llegada DATE,
deposito_recibido DECIMAL(10,2),
estado_reserva VARCHAR(30),
motivo VARCHAR(100),
fecha_generacion DATETIME
);

DROP EVENT IF EXISTS evt_liberar_reservas_sin_garantia;

DELIMITER //

CREATE EVENT evt_liberar_reservas_sin_garantia
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN

TRUNCATE TABLE evt_reservas_liberadas;

INSERT INTO evt_reservas_liberadas(
id_reserva,
cliente,
fecha_llegada,
deposito_recibido,
estado_reserva,
motivo,
fecha_generacion
)
SELECT
r.id_reserva,
CONCAT(c.nombre, ' ', c.apellido),
r.fecha_llegada,
r.deposito_recibido,
r.estado_reserva,
'Reserva no confirmada - candidata a liberar',
NOW()
FROM reserva r
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
WHERE r.estado_reserva != 'confirmada';

END//

DELIMITER ;



-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. EVT_GenerarReporteOcupacion: Genera reportes periódicos de ocupación y pronósticos.


CREATE TABLE IF NOT EXISTS evt_reporte_ocupacion (
id_reporte INT AUTO_INCREMENT PRIMARY KEY,
total_habitaciones INT,
habitaciones_ocupadas INT,
habitaciones_disponibles INT,
habitaciones_mantenimiento INT,
porcentaje_ocupacion DECIMAL(5,2),
reservas_futuras INT,
fecha_generacion DATETIME
);

DROP EVENT IF EXISTS evt_generar_reporte_ocupacion;

DELIMITER //

CREATE EVENT evt_generar_reporte_ocupacion
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN

TRUNCATE TABLE evt_reporte_ocupacion;

INSERT INTO evt_reporte_ocupacion(
total_habitaciones,
habitaciones_ocupadas,
habitaciones_disponibles,
habitaciones_mantenimiento,
porcentaje_ocupacion,
reservas_futuras,
fecha_generacion
)
SELECT
COUNT(*),
SUM(CASE WHEN estado_actual = 'ocupada' THEN 1 ELSE 0 END),
SUM(CASE WHEN estado_actual = 'disponible' THEN 1 ELSE 0 END),
SUM(CASE WHEN estado_actual = 'en mantenimiento' THEN 1 ELSE 0 END),
ROUND(
(SUM(CASE WHEN estado_actual = 'ocupada' THEN 1 ELSE 0 END) / COUNT(*)) * 100,
2
),
(SELECT COUNT(*) FROM reserva
WHERE fecha_llegada BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 365 DAY)
AND estado_reserva = 'confirmada'),
NOW()
FROM habitacion;

END//

DELIMITER ;



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN
-- Ejecutar después de esperar 30-60 segundos para ver los resultados
-- ----------------------------------------------------------------------------

-- SELECT * FROM evt_notificaciones_reserva;
-- SELECT * FROM evt_tarifas_actualizadas;
-- SELECT * FROM evt_llegadas_del_dia;
-- SELECT * FROM evt_reservas_liberadas;
-- SELECT * FROM evt_reporte_ocupacion;

