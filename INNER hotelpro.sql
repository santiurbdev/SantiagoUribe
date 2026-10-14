-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10 INNER

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Utiliza INNER JOIN con WHERE para encontrar todas las reservas de un tipo específico de habitación para el próximo mes


SELECT 
r.id_reserva,
r.fecha_llegada,
r.fecha_salida,
th.descripcion
FROM reserva r
INNER JOIN tipo_habitacion th
ON r.id_tipo_habitacion = th.id_tipo_habitacion
WHERE th.descripcion = 'Suite'
  AND r.fecha_llegada BETWEEN '2026-10-01' AND '2026-10-31';

-- Devuelve 0 filas: la única reserva de tipo Suite llega el 2026-09-05
-- y ninguna reserva de los datos de prueba llega en octubre de 2026.

-- --------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Aplica LEFT JOIN con ORDER BY para listar todos los clientes y sus reservas históricas (si las tienen) ordenadas por fecha de llegada


SELECT 
c.id_cliente,
c.nombre,
c.apellido,
r.id_reserva,
r.fecha_llegada,
r.fecha_salida,
r.estado_reserva
FROM cliente c
LEFT JOIN reserva r
ON c.id_cliente = r.id_cliente
ORDER BY r.fecha_llegada;

-- Lista todos los clientes con sus reservas, ordenados por fecha de llegada
-- Devuelve 5 filas: cada cliente tiene 1 reserva

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Usa RIGHT JOIN con GROUP BY y HAVING para encontrar servicios adicionales contratados más de 20 veces en el último trimestre y calcular el ingreso total


SELECT 
sa.id_servicio_adicional,
sa.nombre_servicio,
COUNT(cs.id_consumo)  AS veces_contratado,
SUM(cs.precio_aplicado)  AS ingreso_total
FROM consumo_servicio cs
RIGHT JOIN servicio_adicional sa
ON cs.id_servicio_adicional = sa.id_servicio_adicional
WHERE cs.fecha_hora_consumo >= '2026-07-01'
AND cs.fecha_hora_consumo <  '2026-10-01'
GROUP BY sa.id_servicio_adicional, sa.nombre_servicio
HAVING COUNT(cs.id_consumo) > 20;

-- Muestra los servicios adicionales contratados más de 20 veces en el último trimestre
-- (jul-sep 2026) y cuánto dinero generó cada uno.
-- Devuelve 0 filas: cada servicio se contrató solo 1 vez, y se piden más de 20

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Implementa INNER JOIN múltiple con BETWEEN para listar check-ins realizados en un rango de fechas específico junto con los datos del cliente, habitación y tarifa aplicada


SELECT 
cc.id_checkin_checkout,
cc.fecha_hora_llegada_real,
c.nombre,
c.apellido,
h.numero_habitacion,
h.piso,
t.tarifa_base,
t.impuestos
FROM checkin_checkout cc
INNER JOIN reserva r ON cc.id_reserva = r.id_reserva
INNER JOIN cliente c ON r.id_cliente = c.id_cliente
INNER JOIN habitacion h ON cc.id_habitacion = h.id_habitacion
INNER JOIN tarifa t ON r.id_tarifa = t.id_tarifa
WHERE cc.fecha_hora_llegada_real BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59';

-- Lista los check-ins realizados en septiembre de 2026 con el cliente
-- la habitación y la tarifa de la reserva
-- Devuelve 1 fila: solo la reserva 3 (Sofia Restrepo) hizo check-in real en ese rango

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. Combina LEFT JOIN con IS NULL para identificar habitaciones que no han tenido reservas en los últimos 30 días


SELECT 
h.id_habitacion,
h.numero_habitacion,
h.piso,
h.estado_actual
FROM habitacion h
LEFT JOIN (reserva_habitacion rh
INNER JOIN reserva r
ON rh.id_reserva = r.id_reserva
AND r.fecha_llegada BETWEEN '2026-08-31' AND '2026-09-30')
ON h.id_habitacion = rh.id_habitacion
WHERE r.id_reserva IS NULL;

-- Muestra las habitaciones que NO tuvieron reservas en los últimos 30 días
-- (del 31-ago al 30-sep de 2026).
-- Devuelve 2 filas: la 402 y la 501, porque sus reservas llegan fuera de ese rango

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Utiliza INNER JOIN con IN para encontrar reservas realizadas por clientes de ciertos países específicos


SELECT 
r.id_reserva,
c.nombre,
c.apellido,
c.nacionalidad
FROM reserva r
INNER JOIN cliente c
ON r.id_cliente = c.id_cliente
WHERE c.nacionalidad IN ('Estadounidense');

-- Muestra las reservas de clientes de nacionalidad estadounidense
-- Devuelve 1 fila: la reserva 4 de John Smith.

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. Aplica JOIN con función de agregación SUM y GROUP BY para calcular los ingresos totales por tipo de habitación y temporada


SELECT th.descripcion,
te.nombre_temporada,
SUM(t.tarifa_base * r.numero_noches) AS ingreso_total
FROM reserva r
INNER JOIN tipo_habitacion th ON r.id_tipo_habitacion = th.id_tipo_habitacion
INNER JOIN tarifa t ON r.id_tarifa = t.id_tarifa
INNER JOIN temporada te ON t.id_temporada = te.id_temporada
WHERE r.estado_reserva <> 'cancelada'
GROUP BY th.descripcion, te.nombre_temporada;

-- Calcula el ingreso total (tarifa por noche x noches) por tipo de habitación y temporada,
-- sin contar reservas canceladas.
-- Devuelve 4 filas: una por cada combinación de tipo y temporada con reservas.

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Usa INNER JOIN con LIKE para encontrar clientes con ciertas palabras en sus preferencias, junto con sus próximas reservas


SELECT 
c.nombre,
c.apellido,
c.preferencias_especiales,
r.id_reserva,
r.fecha_llegada
FROM cliente c
INNER JOIN reserva r
ON c.id_cliente = r.id_cliente
WHERE (c.preferencias_especiales LIKE '%vista%'
OR c.preferencias_especiales LIKE '%piso%')
AND r.fecha_llegada >= '2026-09-30';

-- Muestra los clientes cuyas preferencias contienen "vista" o "piso",
-- junto con sus reservas futuras (desde el 30-sep-2026).
-- Devuelve 1 fila: la reserva 5 de Camila. Ana tiene "piso" pero su reserva ya pasó

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 9. Implementa JOIN múltiple con subconsulta para identificar las habitaciones con tasa de ocupación superior al promedio de su categoría


SELECT h.numero_habitacion,
SUM(r.numero_noches) AS noches_ocupadas
FROM habitacion h
INNER JOIN reserva_habitacion rh ON h.id_habitacion = rh.id_habitacion
INNER JOIN reserva r ON rh.id_reserva = r.id_reserva
WHERE r.estado_reserva <> 'cancelada'
GROUP BY h.id_habitacion, h.numero_habitacion, h.id_tipo_habitacion
HAVING SUM(r.numero_noches) > (
SELECT SUM(r2.numero_noches) / COUNT(DISTINCT h2.id_habitacion)
FROM habitacion h2
LEFT JOIN reserva_habitacion rh2 ON h2.id_habitacion = rh2.id_habitacion
LEFT JOIN reserva r2  ON rh2.id_reserva = r2.id_reserva
AND r2.estado_reserva <> 'cancelada'
WHERE h2.id_tipo_habitacion = h.id_tipo_habitacion
);


-- Muestra las habitaciones que han estado ocupadas más noches que el promedio
-- de las habitaciones de su mismo tipo (sin contar reservas canceladas)
-- Devuelve 1 fila: la 101 (3 noches, el promedio de su tipo es 1.5)

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Combina LEFT JOIN con función de fecha para listar eventos programados para los próximos 3 meses junto con el cliente organizador, incluso si no hay eventos próximos


SELECT 
c.nombre,
c.apellido,
e.tipo_evento,
e.fecha_hora_inicio
FROM cliente c
LEFT JOIN evento e
ON c.id_cliente = e.id_cliente
AND e.fecha_hora_inicio >= CURDATE()
AND e.fecha_hora_inicio <  DATE_ADD(CURDATE(), INTERVAL 3 MONTH);

-- Lista los clientes con sus eventos de los próximos 3 meses (desde hoy).
-- Si un cliente no tiene eventos en ese rango, igual aparece con el evento en NULL.
-- Devuelve 5 filas: cada cliente tiene 1 evento dentro de los próximos 3 meses.

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
