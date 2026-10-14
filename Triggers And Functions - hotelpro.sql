USE hotelpro;

-- -----------------------------------------------------------------------------------------------------------------------------

-- TRIGGERS AND FUNCTIONS

-- -----------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------

-- TRIGGERS 

-- -----------------------------------------------------------------------------------------------------------------------------
-- 1. TR_ActualizarDisponibilidadHabitacion: Actualiza el estado de disponibilidad de habitaciones tras reservas o check-in/out.

DROP TRIGGER IF EXISTS tr_actualizar_disponibilidad_habitacion;

DELIMITER //

CREATE TRIGGER tr_actualizar_disponibilidad_habitacion
AFTER INSERT ON checkin_checkout
FOR EACH ROW
BEGIN

UPDATE habitacion
SET estado_actual = 'ocupada'
WHERE id_habitacion = NEW.id_habitacion;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 2. TR_CalcularTarifaTemporada: Aplica automáticamente la tarifa correspondiente según la temporada.

DROP TRIGGER IF EXISTS tr_calcular_tarifa_temporada;

DELIMITER //

CREATE TRIGGER tr_calcular_tarifa_temporada
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN

IF NEW.id_tarifa IS NULL THEN
SET NEW.id_tarifa = (
SELECT t.id_tarifa
FROM tarifa t
INNER JOIN temporada temp ON t.id_temporada = temp.id_temporada
WHERE NEW.fecha_llegada BETWEEN temp.fecha_inicio AND temp.fecha_fin
LIMIT 1
);
END IF;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 3. TR_AsignarHabitacionOptima: Sugiere la asignación óptima de habitación según las preferencias del cliente.

DROP TRIGGER IF EXISTS tr_asignar_habitacion_optima;

DELIMITER //

CREATE TRIGGER tr_asignar_habitacion_optima
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN

DECLARE v_preferencias VARCHAR(255);
DECLARE v_habitacion_sugerida VARCHAR(10);

SELECT preferencias_especiales INTO v_preferencias
FROM cliente
WHERE id_cliente = NEW.id_cliente;

IF v_preferencias IS NOT NULL THEN
SELECT numero_habitacion INTO v_habitacion_sugerida
FROM habitacion
WHERE id_tipo_habitacion = NEW.id_tipo_habitacion
AND estado_actual = 'disponible'
LIMIT 1;

IF v_habitacion_sugerida IS NOT NULL THEN
SET NEW.solicitudes_especiales = CONCAT(
COALESCE(NEW.solicitudes_especiales, ''),
'Sugerencia: Habitación ',
v_habitacion_sugerida,
' (preferencias: ',
v_preferencias,
')'
);
END IF;
END IF;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 4. TR_AcumularPuntosCliente: Actualiza los puntos del programa de fidelización tras una estancia.

CREATE TABLE IF NOT EXISTS puntos_cliente (
id_punto INT AUTO_INCREMENT PRIMARY KEY,
id_cliente INT,
puntos INT,
fecha_actualizacion DATETIME
);

DROP TRIGGER IF EXISTS tr_acumular_puntos_cliente;

DELIMITER //

CREATE TRIGGER tr_acumular_puntos_cliente
AFTER UPDATE ON checkin_checkout
FOR EACH ROW
BEGIN

DECLARE v_id_cliente INT;

IF NEW.fecha_hora_salida_real IS NOT NULL AND OLD.fecha_hora_salida_real IS NULL THEN

SELECT id_cliente INTO v_id_cliente
FROM reserva WHERE id_reserva = NEW.id_reserva;

INSERT INTO puntos_cliente(id_cliente, puntos, fecha_actualizacion)
VALUES(v_id_cliente, 100, NOW());

END IF;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 5. TR_VerificarOcupacionSalones: Verifica la no superposición al reservar salones para eventos.

DROP TRIGGER IF EXISTS tr_verificar_ocupacion_salones;

DELIMITER //

CREATE TRIGGER tr_verificar_ocupacion_salones
BEFORE INSERT ON evento
FOR EACH ROW
BEGIN

DECLARE v_ocupado INT;

SELECT COUNT(*) INTO v_ocupado
FROM evento
WHERE id_salon = NEW.id_salon
AND estado_evento IN ('confirmado', 'pendiente')
AND NEW.fecha_hora_inicio < DATE_ADD(fecha_hora_inicio, INTERVAL duracion*60 MINUTE)
AND DATE_ADD(NEW.fecha_hora_inicio, INTERVAL NEW.duracion*60 MINUTE) > fecha_hora_inicio;

IF v_ocupado > 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Error: el salón ya está ocupado en esa fecha/hora';
END IF;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- PRUEBAS DE TRIGGERS
-- -----------------------------------------------------------------------------------------------------------------------------

-- Prueba del trigger 2 (crear reserva con tarifa NULL)
INSERT INTO reserva(
fecha_creacion, fecha_llegada, fecha_salida, numero_noches,
numero_adultos, numero_ninos, estado_reserva,
id_cliente, id_tipo_habitacion, id_tarifa
)
VALUES(
NOW(), '2026-04-15', '2026-04-18', 3,
2, 0, 'confirmada',
1, 1, NULL
);

-- Prueba del trigger 3 (crear reserva y ver sugerencia)
INSERT INTO reserva(
fecha_creacion, fecha_llegada, fecha_salida, numero_noches,
numero_adultos, numero_ninos, estado_reserva,
id_cliente, id_tipo_habitacion, id_tarifa
)
VALUES(
NOW(), '2026-05-15', '2026-05-18', 3,
2, 0, 'confirmada',
1, 1, 1
);

-- Prueba del trigger 4 (check-out para acumular puntos)
UPDATE checkin_checkout
SET fecha_hora_salida_real = NULL
WHERE id_checkin_checkout = 7;

UPDATE checkin_checkout
SET fecha_hora_salida_real = NOW()
WHERE id_checkin_checkout = 7;

-- Prueba del trigger 5 (crear evento en fecha aleatoria)
INSERT INTO evento(
tipo_evento, fecha_hora_inicio, duracion, numero_asistentes,
montaje_solicitado, precio_total, estado_evento,
id_cliente, id_salon
)
VALUES(
'Conferencia',
DATE_ADD(NOW(), INTERVAL FLOOR(RAND() * 5000) DAY),
4, 50, 'Auditorio', 3000000, 'confirmado',
1, 1
);

-- -----------------------------------------------------------------------------------------------------------------------------
-- VERIFICACIÓN
-- -----------------------------------------------------------------------------------------------------------------------------

SELECT id_habitacion, numero_habitacion, estado_actual
FROM habitacion
WHERE id_habitacion = 3;

SELECT id_reserva, fecha_llegada, id_tarifa
FROM reserva
ORDER BY id_reserva DESC
LIMIT 1;

SELECT id_reserva, id_cliente, id_tipo_habitacion, solicitudes_especiales
FROM reserva
ORDER BY id_reserva DESC
LIMIT 3;

SELECT * FROM puntos_cliente;

SELECT id_evento, tipo_evento, fecha_hora_inicio, duracion, id_salon
FROM evento
WHERE id_salon = 1
ORDER BY fecha_hora_inicio;

-- -----------------------------------------------------------------------------------------------------------------------------

-- FUNCTIONS

-- -----------------------------------------------------------------------------------------------------------------------------
-- 1. FN_CalcularPrecioEstancia: Calcula el precio total de una estancia según habitación, servicios y descuentos.

DROP FUNCTION IF EXISTS fn_calcular_precio_estancia;

DELIMITER //

CREATE FUNCTION fn_calcular_precio_estancia(
p_id_reserva INT,
p_id_cliente INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN

DECLARE v_id_tarifa INT;
DECLARE v_noches INT;
DECLARE v_precio_base DECIMAL(10,2);
DECLARE v_consumos DECIMAL(10,2);
DECLARE v_descuento DECIMAL(10,2);

SELECT id_tarifa, numero_noches
INTO v_id_tarifa, v_noches
FROM reserva
WHERE id_reserva = p_id_reserva;

SELECT (tarifa_base + impuestos) * v_noches
INTO v_precio_base
FROM tarifa
WHERE id_tarifa = v_id_tarifa;

SELECT COALESCE(SUM(cantidad * precio_aplicado), 0)
INTO v_consumos
FROM consumo_servicio
WHERE id_cliente = p_id_cliente;

SELECT COALESCE(descuento_estadia_prolongada, 0)
INTO v_descuento
FROM tarifa
WHERE id_tarifa = v_id_tarifa;

RETURN (v_precio_base + v_consumos) - v_descuento;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 2. FN_VerificarDisponibilidadPeriodo: Verifica disponibilidad de un tipo de habitación para un periodo.

DROP FUNCTION IF EXISTS fn_verificar_disponibilidad_periodo;

DELIMITER //

CREATE FUNCTION fn_verificar_disponibilidad_periodo(
p_id_tipo_habitacion INT,
p_fecha_inicio DATE,
p_fecha_fin DATE
)
RETURNS INT
DETERMINISTIC
BEGIN

DECLARE v_disponibles INT;

SELECT COUNT(*) INTO v_disponibles
FROM habitacion
WHERE id_tipo_habitacion = p_id_tipo_habitacion
AND id_habitacion NOT IN (
SELECT rh.id_habitacion
FROM reserva_habitacion rh
INNER JOIN reserva r ON rh.id_reserva = r.id_reserva
WHERE p_fecha_inicio < r.fecha_salida
AND p_fecha_fin > r.fecha_llegada
);

IF v_disponibles > 0 THEN
RETURN 1;
ELSE
RETURN 0;
END IF;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 3. FN_ObtenerHabitacionesRecomendadas: Sugiere habitaciones según preferencias del cliente.

DROP FUNCTION IF EXISTS fn_obtener_habitaciones_recomendadas;

DELIMITER //

CREATE FUNCTION fn_obtener_habitaciones_recomendadas(
p_id_cliente INT
)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN

DECLARE v_preferencias VARCHAR(255);
DECLARE v_habitacion VARCHAR(10);

SELECT preferencias_especiales INTO v_preferencias
FROM cliente
WHERE id_cliente = p_id_cliente;

IF v_preferencias IS NOT NULL THEN
SELECT numero_habitacion INTO v_habitacion
FROM habitacion
WHERE estado_actual = 'disponible'
AND caracteristicas_especiales LIKE CONCAT('%', v_preferencias, '%')
LIMIT 1;
END IF;

RETURN v_habitacion;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 4. FN_CalcularDescuentoFidelizacion: Calcula descuento aplicable según nivel de fidelización.

DROP FUNCTION IF EXISTS fn_calcular_descuento_fidelizacion;

DELIMITER //

CREATE FUNCTION fn_calcular_descuento_fidelizacion(
p_id_cliente INT
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN

DECLARE v_id_nivel INT;
DECLARE v_descuento DECIMAL(5,2);

SELECT id_nivel_fidelizacion INTO v_id_nivel
FROM cliente
WHERE id_cliente = p_id_cliente;

SET v_descuento = CASE v_id_nivel
WHEN 1 THEN 5
WHEN 2 THEN 10
WHEN 3 THEN 15
WHEN 4 THEN 20
WHEN 5 THEN 25
ELSE 0
END;

RETURN v_descuento;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- 5. FN_ObtenerTarifaAplicable: Determina la tarifa aplicable según habitación, temporada y promociones.

DROP FUNCTION IF EXISTS fn_obtener_tarifa_aplicable;

DELIMITER //

CREATE FUNCTION fn_obtener_tarifa_aplicable(
p_id_tipo_habitacion INT,
p_fecha DATE
)
RETURNS INT
DETERMINISTIC
BEGIN

DECLARE v_id_tarifa INT;

SELECT t.id_tarifa INTO v_id_tarifa
FROM tarifa t
INNER JOIN temporada temp ON t.id_temporada = temp.id_temporada
WHERE t.id_tipo_habitacion = p_id_tipo_habitacion
AND p_fecha BETWEEN temp.fecha_inicio AND temp.fecha_fin
LIMIT 1;

RETURN v_id_tarifa;

END//

DELIMITER ;

-- -----------------------------------------------------------------------------------------------------------------------------
-- PRUEBAS DE FUNCTIONS
-- -----------------------------------------------------------------------------------------------------------------------------

SELECT fn_calcular_precio_estancia(1, 1) AS total_estancia;
SELECT fn_verificar_disponibilidad_periodo(1, '2026-11-01', '2026-11-05') AS disponible;
SELECT fn_obtener_habitaciones_recomendadas(1) AS habitacion_recomendada;
SELECT fn_calcular_descuento_fidelizacion(1) AS descuento;
SELECT fn_obtener_tarifa_aplicable(1, '2026-03-15') AS tarifa_aplicable;

-- -----------------------------------------------------------------------------------------------------------------------------
