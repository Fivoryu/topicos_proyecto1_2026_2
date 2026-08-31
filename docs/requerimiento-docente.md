# CUENTAS CLARAS

## AMIGO DURADERO

**Documento consolidado y ampliado para Spec-Driven Development (SDD)**

**Materia:** Tópicos para la Programación  
**Grupo asignado:** Grupo 2 - Spec-Driven Development  
**Proyecto 1:** App web para división y liquidación de gastos  
**Estado del documento:** Especificación previa a código  
**Versión:** 1.0 - 18 de agosto de 2026

> **REGLA DEL GRUPO 2**
> Durante esta etapa no se debe generar código. Primero se define y aprueba el entendimiento del producto, los requisitos, criterios de aceptación, casos borde, decisiones de diseño, fuera de alcance, archivo de contexto y plan de tareas.

Fuentes consolidadas: Consigna Proyecto 1 + transcripciones de los audios PTT-20260811-WA0071 y PTT-20260811-WA0072.

# 1. Propósito y criterio de interpretación

Este documento reúne lo solicitado por el docente en los audios y en la consigna formal del Proyecto 1, y lo reorganiza específicamente para el Grupo 2 - Spec-Driven Development. Su finalidad es servir como base de trabajo antes de generar código y como fuente de verdad versionada durante el desarrollo.

> **Prioridad de fuentes**
> Cuando exista una diferencia entre una explicación oral y la consigna escrita, la consigna oficial se toma como requisito mínimo prioritario. La diferencia no se oculta: se registra como pregunta abierta y se resuelve antes de implementar una funcionalidad que pueda ampliar el alcance.

El contenido se clasifica en cuatro tipos:

* Obligatorio: aparece expresamente en la consigna o en las reglas del Grupo 2.
* Decisión de diseño: elección técnica necesaria para poder implementar de forma consistente.
* Regla de negocio: interpretación concreta que convierte un requisito vago en comportamiento verificable.
* Fuera de alcance / pregunta abierta: elemento que no debe implementarse todavía sin confirmación.

# 2. Pedido oficial del cliente

El producto solicitado es una aplicación web para dividir gastos entre amigos durante un viaje. Debe permitir agregar participantes, registrar gastos indicando quién pagó y mostrar tanto el balance de cada persona como la forma de saldar las deudas al terminar.

> **Problema central**
> Registrar quién pagó qué, determinar cuánto le correspondía pagar a cada participante y transformar los balances resultantes en una lista clara de transferencias para que todos queden a mano.

La consigna deja intencionalmente decisiones sin definir. Por ello, el trabajo SDD consiste en descubrir y fijar esas decisiones antes de implementarlas.

# 3. Escenario oficial de aceptación: viaje a Samaipata

| Participante | Gasto                         | Monto pagado |
| ------------ | ----------------------------- | -----------: |
| Ana          | Cabaña + entradas a El Fuerte |   Bs. 960,00 |
| Beto         | Cena                          |   Bs. 400,00 |
| Carla        | Gasolina                      |   Bs. 240,00 |
| Diego        | Sin gastos                    |     Bs. 0,00 |

Total del viaje: **Bs. 1.600,00**. Si los cuatro participan en todos los gastos, a cada uno le corresponde **Bs. 400,00**.

| Participante |       Pagó | Le correspondía |      Balance |
| ------------ | ---------: | --------------: | -----------: |
| Ana          | Bs. 960,00 |      Bs. 400,00 | + Bs. 560,00 |
| Beto         | Bs. 400,00 |      Bs. 400,00 |     Bs. 0,00 |
| Carla        |   Bs. 240,00 |      Bs. 400,00 | - Bs. 160,00 |
| Diego        |   Bs. 0,00 |      Bs. 400,00 | - Bs. 400,00 |

Liquidación esperada:

* Diego → Ana: Bs. 400,00.
* Carla → Ana: Bs. 160,00.
* Beto no transfiere nada porque su balance es exactamente cero.

> **Invariante matemática obligatoria**
> La suma algebraica de todos los balances debe ser exactamente 0 centavos. Si no da 0, existe un error de cálculo o de redondeo.

# 4. Reglas del Grupo 2 - Spec-Driven Development

**1. Fase 1 - Especificar antes de codear.** Durante los primeros días/horas/minutos está prohibido generar código. Se debe dialogar con la IA para convertir la idea vaga en requisitos verificables.

**2. Fase 2 - Archivo de contexto.** Crear `AGENTS.md`, `CLAUDE.md` o `.cursor/rules`, según la herramienta, con las convenciones y restricciones del proyecto.

**3. Fase 3 - Plan derivado del spec.** Pedir a la IA un plan de tareas derivado de la especificación. El equipo debe revisarlo, corregirlo y aprobarlo antes de implementar.

**4. Fase 4 - Implementación incremental.** Implementar una tarea por vez y comprobar sus criterios de aceptación antes de avanzar.

**5. Fase 5 - Versionado conjunto.** Los specs se versionan en Git junto al código. Si cambia el entendimiento, primero se modifica el spec y después el código.

> **Gate de entrada a implementación**
> No iniciar `src/`, componentes o lógica de negocio hasta que el spec, los casos borde, las decisiones de diseño, el fuera de alcance, el archivo de contexto y el plan estén revisados por el equipo.

# 5. Funcionalidad mínima obligatoria

| ID    | Requisito                                                                              |
| ----- | -------------------------------------------------------------------------------------- |
| FM-01 | Agregar participantes.                                                                 |
| FM-02 | Listar participantes.                                                                  |
| FM-03 | Registrar un gasto con descripción, monto, pagador y participantes entre quienes se divide. |
| FM-04 | Seleccionar por defecto a todos los participantes al crear un gasto y poder excluir personas. |
| FM-05 | Editar gastos.                                                                         |
| FM-06 | Eliminar gastos.                                                                       |
| FM-07 | Mostrar saldos individuales: positivo = le deben; negativo = debe.                    |
| FM-08 | Mostrar una liquidación como lista de transferencias X → Y: monto.                    |
| FM-09 | Persistir los datos al refrescar la página.                                            |

# 6. Ambigüedades y preguntas abiertas antes de programar

| ID    | Pregunta                                                      | Origen                                                                                       | Decisión provisional                                                                      |
| ----- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| OQ-01 | ¿La app manejará un solo viaje activo o varios viajes/grupos? | La consigna escrita exige participantes y gastos; el audio mencionó crear/unirse a un grupo. | Para el MVP: un viaje activo. No implementar cuentas/invitaciones hasta confirmar.        |
| OQ-02 | ¿Se permiten nombres de participantes repetidos?              | No está definido.                                                                            | No. Comparar nombre normalizado sin distinguir mayúsculas/minúsculas y recortar espacios. |
| OQ-03 | ¿Puede eliminarse un participante con gastos asociados?       | La consigna exige considerar este caso borde.                                                | No. Primero deben editarse/eliminarse los gastos que lo referencian.                      |
| OQ-04 | ¿El pagador puede quedar excluido del reparto?                | No está especificado.                                                                        | Sí, porque una persona puede pagar por otros. El redondeo seguirá una regla determinista. |
| OQ-05 | ¿Se admite división desigual, porcentajes o montos manuales?  | No está pedido.                                                                              | No en el MVP. Solo división igualitaria entre los participantes seleccionados.            |
| OQ-06 | ¿Habrá usuarios, login y sincronización cloud?                | No aparecen en la consigna mínima.                                                           | Fuera de alcance del MVP.                                                                 |

# 7. Alcance acordado para el MVP SDD

## 7.1 Incluido

* Una aplicación web responsive orientada a un viaje activo.
* Administración local de participantes del viaje.
* Registro de gastos con división igualitaria entre participantes seleccionados.
* Edición y eliminación de gastos.
* Cálculo determinista de balances en centavos.
* Generación de transferencias de liquidación.
* Persistencia local para sobrevivir a recargas del navegador.
* Validaciones y mensajes para entradas inválidas.
* Pruebas automatizadas de la lógica matemática y de los criterios críticos.

## 7.2 Fuera de alcance

* Autenticación, cuentas personales y recuperación de contraseña.
* Invitaciones por enlace, código o QR y colaboración multiusuario en tiempo real.
* Backend, base de datos remota y sincronización cloud para el primer MVP.
* Múltiples monedas y conversión de divisas.
* División por porcentajes, pesos, cantidades o montos personalizados.
* Fotografías/OCR de recibos, categorías inteligentes y estadísticas avanzadas.
* Notificaciones, pagos reales o integración con bancos/billeteras.
* Marcar transferencias como pagadas y mantener un libro de pagos separado.
* Algoritmo de optimización matemática global del número mínimo absoluto de transferencias; el MVP usará una liquidación determinista y válida.

> **Nota SDD**
> Si el docente pide posteriormente alguna función de esta lista, primero se actualiza esta sección, los requisitos afectados y los criterios de aceptación; recién después se modifica el código.

# 8. Reglas de negocio y decisiones matemáticas

| ID    | Regla                                                                                                                                                                                                                      |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RN-01 | Todo monto monetario se representa internamente como entero de centavos; no se usan números flotantes para la lógica de dinero.                                                                                            |
| RN-02 | Un gasto debe tener monto mayor a 0 centavos.                                                                                                                                                                              |
| RN-03 | Un gasto necesita exactamente un pagador existente y al menos un participante beneficiario seleccionado.                                                                                                                   |
| RN-04 | Al abrir el formulario de gasto, todos los participantes se seleccionan por defecto; el usuario puede excluir a quienes no participaron.                                                                                   |
| RN-05 | El costo del gasto se divide en centavos enteros entre los participantes seleccionados.                                                                                                                                    |
| RN-06 | Si la división produce residuo y el pagador está incluido, el pagador absorbe el residuo. Si no está incluido, el residuo se distribuye determinísticamente desde el primer participante seleccionado según orden estable. |
| RN-07 | Balance = total pagado - total que le correspondía pagar. Balance positivo significa acreedor; negativo, deudor.                                                                                                           |
| RN-08 | La suma de balances debe ser exactamente 0 centavos después de cada alta, edición o eliminación de gasto.                                                                                                                  |
| RN-09 | Las deudas de liquidación no se almacenan como verdad independiente: se derivan de los balances actuales para evitar inconsistencias.                                                                                      |
| RN-10 | Un participante referenciado por un gasto no puede eliminarse hasta eliminar o editar esas referencias.                                                                                                                    |

# 9. Regla explícita de redondeo

El caso indicado por el docente debe convertirse en un criterio comprobable.

Ejemplo: gasto de **Bs. 100,00 = 10.000 centavos**, pagado por Ana y dividido entre 3 participantes incluyendo a Ana.

| Concepto                | Resultado                                                             |
| ----------------------- | -------------------------------------------------------------------- |
| División base           | 10.000 // 3 = 3.333 centavos = Bs. 33,33                             |
| Residuo                 | 10.000 - (3.333 × 3) = 1 centavo                                     |
| Regla                   | Como Ana es la pagadora y participa del gasto, su parte es Bs. 33,34. |
| Otros dos participantes | Cada uno debe Bs. 33,33.                                              |
| Balances                | Ana + Bs. 66,66; deudor 1 - Bs. 33,33; deudor 2 - Bs. 33,33.          |
| Comprobación            | 66,66 - 33,33 - 33,33 = Bs. 0,00.                                    |

# 10. Especificación funcional con criterios de aceptación

Se definen **10 requisitos funcionales**, superando el mínimo de 8 solicitado. Cada requisito contiene criterios verificables en formato **Dado / Cuando / Entonces**.

## RF-01 - Agregar participante

Permitir registrar una persona que participará en el viaje.

**CA-01-01:** Dado que el usuario está en la vista de participantes, cuando ingresa “Ana” y confirma, entonces Ana aparece en la lista con un identificador único.

**CA-01-02:** Dado que el nombre está vacío o contiene solo espacios, cuando intenta guardar, entonces el sistema rechaza la operación y no crea un participante.

**CA-01-03:** Dado que ya existe “Ana”, cuando intenta agregar “ ana ”, entonces el sistema lo considera duplicado y muestra un error sin crear otro participante.

## RF-02 - Listar y persistir participantes

Mostrar la lista actual y conservarla después de una recarga.

**CA-02-01:** Dado que existen Ana, Beto, Carla y Diego, cuando se abre la vista de participantes, entonces los cuatro aparecen en la lista.

**CA-02-02:** Dado que se agregaron participantes, cuando se refresca la página, entonces la lista permanece disponible con los mismos identificadores y nombres.

## RF-03 - Registrar gasto

Crear un gasto válido con pagador y reparto.

**CA-03-01:** Dado que existen participantes, cuando el usuario crea un gasto con descripción, monto mayor a cero y un pagador válido, entonces el gasto se guarda.

**CA-03-02:** Dado que se abre un nuevo gasto, entonces todos los participantes aparecen seleccionados por defecto para el reparto.

**CA-03-03:** Dado que no se selecciona ningún participante para el reparto, cuando se intenta guardar, entonces el gasto es rechazado.

## RF-04 - Excluir participantes de un gasto

Permitir que un gasto se reparta solo entre quienes participaron.

**CA-04-01:** Dado que existen Ana, Beto, Carla y Diego, cuando se registra un gasto y se excluye a Diego, entonces Diego no recibe ninguna parte de ese gasto.

**CA-04-02:** Dado un gasto de Bs. 300 dividido entre Ana, Beto y Carla, entonces el costo asignado total es exactamente Bs. 300,00 y Diego recibe Bs. 0,00 de ese gasto.

## RF-05 - Editar gasto

Modificar los datos de un gasto existente y recalcular resultados.

**CA-05-01:** Dado un gasto guardado, cuando se cambia su monto, pagador, descripción o participantes y se confirma, entonces se reemplazan los valores anteriores.

**CA-05-02:** Dado que una edición modifica el reparto, cuando se guarda, entonces los balances y la liquidación se recalculan inmediatamente.

**CA-05-03:** Dado que la edición produce un monto inválido o cero participantes, entonces no se guarda el cambio.

## RF-06 - Eliminar gasto

Eliminar un gasto y revertir su efecto económico.

**CA-06-01:** Dado un gasto existente, cuando el usuario confirma su eliminación, entonces el gasto desaparece del listado.

**CA-06-02:** Dado que el gasto eliminado afectaba balances, cuando se elimina, entonces los balances y la liquidación se recalculan sin considerar dicho gasto.

## RF-07 - Calcular y mostrar saldos

Mostrar el balance neto de cada participante.

**CA-07-01:** Dado el escenario de Samaipata, cuando se abre la pantalla de saldos, entonces Ana muestra +Bs. 560,00; Beto Bs. 0,00; Carla -Bs. 160,00; Diego -Bs. 400,00.

**CA-07-02:** Dado cualquier conjunto válido de gastos, cuando se calculan los balances, entonces la suma de todos los balances es exactamente 0 centavos.

**CA-07-03:** Dado un balance positivo, entonces la interfaz lo identifica como “le deben”; dado uno negativo, lo identifica como “debe”.

## RF-08 - Generar liquidación

Convertir balances en transferencias entre deudores y acreedores.

**CA-08-01:** Dado el escenario de Samaipata, cuando se abre la liquidación, entonces se muestran Diego → Ana Bs. 400,00 y Carla → Ana Bs. 160,00, sin transferencia para Beto.

**CA-08-02:** Dado que todos los balances son cero, cuando se abre la liquidación, entonces se indica que no hay transferencias pendientes.

**CA-08-03:** Dado una liquidación generada, entonces la suma de las transferencias que salen de cada deudor coincide con la magnitud de su saldo negativo y ningún monto es cero o negativo.

## RF-09 - Persistencia al refrescar

Conservar el estado funcional de la app después de recargar el navegador.

**CA-09-01:** Dado que existen participantes y gastos registrados, cuando el usuario refresca la página, entonces los datos permanecen.

**CA-09-02:** Dado que los datos se restauran, entonces los balances y la liquidación reconstruidos coinciden con los existentes antes del refresco.

## RF-10 - Manejo de casos inválidos y referencias

Evitar estados imposibles o inconsistentes.

**CA-10-01:** Dado que no existen participantes, cuando se intenta registrar un gasto, entonces la app impide continuar y explica que primero debe agregarse al menos un participante.

**CA-10-02:** Dado un monto de Bs. 0 o negativo, cuando se intenta guardar, entonces el gasto es rechazado.

**CA-10-03:** Dado un participante que figura como pagador o beneficiario en algún gasto, cuando se intenta eliminarlo, entonces la app bloquea la eliminación e indica que primero deben resolverse los gastos asociados.

# 11. Requisitos no funcionales propuestos

| ID     | Atributo              | Especificación                                                                            |
| ------ | --------------------- | ----------------------------------------------------------------------------------------- |
| RNF-01 | Correctitud monetaria | Toda operación monetaria usa centavos enteros; ningún resultado puede depender de errores de coma flotante. |
| RNF-02 | Persistencia          | La información debe sobrevivir a una recarga del navegador en el mismo dispositivo y perfil. |
| RNF-03 | Usabilidad            | El flujo principal debe poder demostrarse en menos de 3 minutos con el escenario de Samaipata. |
| RNF-04 | Trazabilidad          | Cada requisito funcional debe relacionarse al menos con una tarea de implementación y una verificación/prueba. |
| RNF-05 | Mantenibilidad        | La lógica de cálculo no debe vivir dentro de componentes visuales; debe ser independiente y testeable. |
| RNF-06 | Determinismo          | Con los mismos participantes y gastos, los balances y la liquidación deben producir siempre el mismo resultado. |
| RNF-07 | Compatibilidad        | El MVP debe funcionar en versiones actuales de navegadores Chromium de escritorio. |
| RNF-08 | Recuperación          | Si los datos persistidos están corruptos o no pueden cargarse, la app debe informar el problema y permitir reiniciar el estado local de forma controlada. |

# 12. Modelo de datos propuesto

Decisión: la deuda/liquidación será un dato derivado, no una entidad persistida. La fuente de verdad serán participantes y gastos. Esto evita que una deuda guardada quede desactualizada cuando se edita o elimina un gasto.

| Entidad             | Campos mínimos                                                                   | Notas                                                                                      |
| ------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Trip                | id, name                                                                         | Raíz del estado. Para el MVP puede existir un solo viaje activo.                           |
| Participant         | id, name, createdAt                                                              | El nombre visible es único después de normalizar espacios y mayúsculas/minúsculas.         |
| Expense             | id, description, amountCents, payerId, splitParticipantIds, createdAt, updatedAt | `amountCents` es entero positivo. `splitParticipantIds` contiene al menos un participante. |
| Balance (derivado)  | participantId, paidCents, owedCents, balanceCents                                | No se persiste; se recalcula desde los gastos.                                             |
| Transfer (derivado) | fromParticipantId, toParticipantId, amountCents                                  | No se persiste; se genera desde balances.                                                  |

# 13. Decisiones de diseño y arquitectura propuestas

## 13.1 Stack recomendado para el MVP

| Capa                 | Elección                    | Motivo                                                                            |
| -------------------- | --------------------------- | --------------------------------------------------------------------------------- |
| Frontend             | React + TypeScript + Vite   | App web simple, rápida de montar y con buen soporte para componentes y pruebas.   |
| Estado               | Zustand o store equivalente | Centraliza participantes/gastos y facilita separar la lógica de UI.               |
| Persistencia         | localStorage para el MVP    | Cumple la exigencia de sobrevivir al refresco sin introducir backend innecesario. |
| Estilos              | CSS Modules o Tailwind CSS  | Cualquiera es válido; elegir uno y fijarlo en AGENTS.md.                          |
| Pruebas              | Vitest + Testing Library    | Permite verificar lógica de balances, redondeo, persistencia y componentes.       |
| Control de versiones | Git + GitHub                | Versiona especificaciones y código en el mismo repositorio.                       |

> **Decisión de alcance técnico**
> No se propone backend para el primer MVP porque la consigna no exige colaboración remota ni cuentas. Agregarlo antes de ser necesario aumentaría superficie de fallo sin aportar a los criterios evaluados.

## 13.2 Estructura conceptual de componentes

* `AppShell`: estructura y navegación general.
* `ParticipantsView / ParticipantForm`: alta y listado de participantes.
* `ExpensesView / ExpenseForm / ExpenseList`: alta, edición, eliminación y listado de gastos.
* `BalancesView`: saldos netos por participante.
* `SettlementView`: transferencias sugeridas para quedar a mano.
* `Domain services`: cálculo de reparto, balances y liquidación.
* `Persistence adapter`: lectura/escritura del estado local.

## 13.3 Dónde vive el estado

El estado del viaje vive en un store de aplicación. La UI nunca modifica balances o transferencias directamente. Los balances y la liquidación se calculan a partir de participantes y gastos mediante funciones de dominio puras. La persistencia guarda únicamente la fuente de verdad necesaria.

# 14. Especificación del cálculo de liquidación

El algoritmo debe ser explicable por cualquier integrante durante la demo. No es suficiente decir que lo generó la IA.

1. Calcular el balance de cada participante en centavos.
2. Separar acreedores (`balance > 0`), deudores (`balance < 0`) y neutros (`balance = 0`).
3. Ordenar de manera estable para que el resultado sea determinista, por ejemplo, por identificador/orden de creación.
4. Tomar un deudor y un acreedor.
5. Transferir el mínimo entre la deuda absoluta del deudor y el crédito del acreedor.
6. Restar ese monto de ambos saldos residuales.
7. Cuando uno llegue a 0, avanzar al siguiente.
8. Terminar cuando todos los saldos residuales sean 0 centavos.

> **Propiedad a demostrar**
> Las transferencias no crean ni destruyen dinero: únicamente redistribuyen saldos. Al finalizar, todo saldo residual debe ser exactamente 0 centavos.

# 15. Casos borde explícitos

| ID    | Caso                             | Comportamiento esperado                                                                                             |
| ----- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| CB-01 | 0 participantes                  | No se puede crear un gasto; mostrar mensaje para agregar participantes primero.                                     |
| CB-02 | Monto 0                          | Rechazar gasto.                                                                                                     |
| CB-03 | Monto negativo                   | Rechazar gasto.                                                                                                     |
| CB-04 | Monto con más de 2 decimales     | Rechazar o normalizar de forma explícita; propuesta: rechazar y pedir máximo 2 decimales.                           |
| CB-05 | División no exacta               | Aplicar regla de centavos RN-06; suma exacta del gasto.                                                             |
| CB-06 | 0 beneficiarios seleccionados    | Rechazar gasto.                                                                                                     |
| CB-07 | Pagador inexistente              | Rechazar gasto.                                                                                                     |
| CB-08 | Participante duplicado           | Rechazar nombre duplicado normalizado.                                                                              |
| CB-09 | Eliminar participante con gastos | Bloquear y explicar dependencias.                                                                                   |
| CB-10 | Editar gasto y cambiar pagador   | Recalcular todos los balances y liquidación.                                                                        |
| CB-11 | Eliminar gasto                   | Recalcular y retirar completamente su efecto.                                                                       |
| CB-12 | Refrescar página                 | Restaurar participantes y gastos; resultados derivados deben coincidir.                                             |
| CB-13 | Todos en cero                    | Mostrar “Todos están a mano” y ninguna transferencia.                                                               |
| CB-14 | Solo un participante             | Puede registrar gastos para sí mismo; balance siempre 0.                                                            |
| CB-15 | Pagador excluido del reparto     | El pagador registra crédito por todo el monto y no recibe parte del costo; reparto se hace entre los seleccionados. |
| CB-16 | Estado persistido corrupto       | Informar y permitir reiniciar datos; no romper la interfaz silenciosamente.                                         |

# 16. Juegos de datos de aceptación obligatorios

| Caso                | Entrada                                                      | Resultado esperado                                                                                 |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| DA-01 Samaipata     | Ana 960; Beto 400; Carla 240; Diego 0; todos participan      | Balances: Ana +560; Beto 0; Carla -160; Diego -400. Liquidación: Diego → Ana 400; Carla → Ana 160. |
| DA-02 Redondeo      | Gasto Bs. 100 pagado por Ana; 3 participantes incluyendo Ana | Partes: Ana 33,34; otros 33,33. Balances suman exactamente 0.                                      |
| DA-03 Exclusión     | Gasto Bs. 300; 4 personas; Diego excluido                    | Solo 3 participantes reciben Bs. 100 de costo; Diego recibe 0.                                     |
| DA-04 Todos en cero | Cada persona paga exactamente su parte                       | Sin transferencias.                                                                                |
| DA-05 Persistencia  | Participantes + gastos creados y luego refresh               | Datos y resultados se conservan.                                                                   |

# 17. Matriz inicial de trazabilidad

| Requisito | Tarea prevista           | Verificación prevista         |
| --------- | ------------------------ | ----------------------------- |
| RF-01     | T-02 Participantes       | UT/CT participantes           |
| RF-02     | T-02 + T-03 Persistencia | CT persistencia participantes |
| RF-03     | T-04 Gastos              | CT validación gasto           |
| RF-04     | T-04 Gastos              | UT reparto seleccionado       |
| RF-05     | T-05 Editar gastos       | CT edición + recálculo        |
| RF-06     | T-05 Eliminar gastos     | CT eliminación + recálculo    |
| RF-07     | T-06 Balances            | UT balances + DA-01/DA-02     |
| RF-08     | T-07 Liquidación         | UT liquidación + DA-01        |
| RF-09     | T-03 Persistencia        | CT/IT refresh                 |
| RF-10     | T-02/T-04/T-05           | UT/CT casos inválidos         |

# 18. Contenido requerido para AGENTS.md

La consigna exige un archivo de contexto para la IA. Se recomienda usar `AGENTS.md` porque es neutral respecto de una herramienta concreta. Antes de codear, debería contener al menos:

* Objetivo del producto y escenario de Samaipata.
* Alcance y fuera de alcance.
* Reglas monetarias: centavos enteros, balance total 0 y redondeo determinista.
* Modelo de datos acordado.
* Stack y estructura de carpetas.
* Convenciones de nombres, TypeScript estricto y estilo de componentes.
* Regla de separación: lógica de dominio fuera de la UI.
* Regla de pruebas: ningún requisito se considera terminado sin verificar sus criterios de aceptación.
* Regla SDD: si cambia el entendimiento, primero modificar `/specs` y después el código.
* Prohibición de introducir funciones fuera de alcance sin actualizar el spec.

> **Importante**
> `AGENTS.md` no reemplaza la especificación. Su función es recordar a la IA cómo debe trabajar dentro del proyecto y qué convenciones no debe violar.

# 19. Estructura de repositorio recomendada

Antes de generar código, el repositorio puede contener únicamente documentación y configuración de especificaciones:

```text
/
├── README.md
├── AGENTS.md
├── specs/
│   └── 001-core-gastos/
│       ├── spec.md
│       ├── acceptance-criteria.md
│       ├── edge-cases.md
│       ├── data-model.md
│       └── out-of-scope.md
├── docs/
│   ├── decisions/
│   │   ├── ADR-001-stack.md
│   │   ├── ADR-002-money-in-cents.md
│   │   └── ADR-003-persistence.md
│   └── demo-samaipata.md
└── PLAN.md
```

Una vez aprobado el plan, se agregan las carpetas de implementación y pruebas. El código y las specs permanecerán en el mismo repositorio y evolucionarán juntos.

# 20. Plan de tareas propuesto para revisión

Este plan representa una versión revisada que puede utilizarse como referencia cuando se le pida a la IA generar el plan derivado del spec. La consigna exige revisarlo y aprobarlo antes de programar.

| Tarea | Nombre                                   | Resultado verificable                               | RF                  |
| ----- | ---------------------------------------- | --------------------------------------------------- | ------------------- |
| T-00  | Cerrar preguntas abiertas y aprobar spec | OQ resueltas; documento v1.0 aprobado.              | -                   |
| T-01  | Preparar contexto y decisiones           | AGENTS.md + ADRs + PLAN.md aprobados.               | -                   |
| T-02  | Participantes                            | Alta, listado, duplicados, eliminación restringida. | RF-01, RF-02, RF-10 |
| T-03  | Persistencia local                       | Guardar/restaurar estado; manejo de corrupción.     | RF-02, RF-09        |
| T-04  | Registro de gastos                       | Formulario, validaciones, selección/exclusión.      | RF-03, RF-04, RF-10 |
| T-05  | Edición y eliminación                    | Modificar/borrar gasto y recalcular.                | RF-05, RF-06        |
| T-06  | Motor de balances                        | Reparto en centavos, redondeo, invariante 0.        | RF-07               |
| T-07  | Motor de liquidación                     | Generar transferencias deterministas.               | RF-08               |
| T-08  | Pantallas de saldos/liquidación          | Presentar resultados y estados vacíos.              | RF-07, RF-08        |
| T-09  | Escenario Samaipata                      | Caso reproducible para demo.                        | DA-01               |
| T-10  | Pruebas de aceptación                    | Ejecutar DA-01..DA-05 y casos borde.                | Todos               |
| T-11  | Pulido para demo                         | Usabilidad, errores y guion de 3 minutos.           | RNF-03              |

# 21. Flujo SDD durante la implementación

1. Seleccionar la siguiente tarea aprobada del `PLAN.md`.
2. Leer los RF y criterios relacionados.
3. Pedir a la IA implementar solo esa tarea, sin ampliar el alcance.
4. Ejecutar las pruebas previstas y reproducir los criterios de aceptación.
5. Si falla un criterio, corregir dentro de la misma tarea.
6. Si aparece una ambigüedad nueva, detener la implementación y actualizar primero el spec.
7. Hacer commit de spec/código/pruebas de forma trazable.
8. Marcar la tarea como terminada solamente cuando todos sus criterios estén verificados.

# 22. Versionado y control de cambios

La regla de oro del proyecto debe aplicarse literalmente: el código nunca debe convertirse en la fuente de verdad sobre una decisión nueva.

| Situación                               | Orden correcto                                                                                                                      |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Se descubre un caso borde nuevo         | 1) actualizar spec/casos borde; 2) revisar impacto; 3) modificar plan si corresponde; 4) implementar; 5) probar.                    |
| El docente cambia un requisito          | 1) registrar cambio; 2) actualizar RF/CA/fuera de alcance; 3) revisar modelo/arquitectura; 4) actualizar plan; 5) modificar código. |
| La IA propone una función no solicitada | No implementarla. Registrar como idea futura o fuera de alcance.                                                                    |
| Una prueba contradice el spec           | Resolver primero cuál comportamiento es correcto; actualizar spec si cambió el entendimiento y luego corregir prueba/código.        |

Convención sugerida de commits:

* `spec: define RF-07 balances y redondeo`
* `docs: agrega ADR-002 dinero en centavos`
* `feat: implementa RF-07 motor de balances`
* `test: verifica DA-02 redondeo Bs100/3`
* `fix: corrige reparto de residuo según RN-06`

# 23. Entregables y demo de 3 minutos

## 23.1 Entregables obligatorios

* Repositorio Git con la aplicación funcionando.
* Demo de 3 minutos cargando el escenario de Samaipata y mostrando la liquidación.

## 23.2 Guion recomendado

| Tiempo    | Acción                                                                                                                  |
| --------- | ----------------------------------------------------------------------------------------------------------------------- |
| 0:00-0:20 | Explicar en una frase el problema y que el grupo trabajó con SDD.                                                       |
| 0:20-0:45 | Agregar/listar Ana, Beto, Carla y Diego.                                                                                |
| 0:45-1:35 | Registrar cabaña 800, entradas 160, cena 400 y gasolina 240 con sus pagadores.                                          |
| 1:35-2:05 | Mostrar saldos: Ana +560; Beto 0; Carla -160; Diego -400.                                                               |
| 2:05-2:30 | Mostrar liquidación: Diego → Ana 400 y Carla → Ana 160.                                                                |
| 2:30-2:45 | Refrescar la página y demostrar persistencia.                                                                           |
| 2:45-3:00 | Explicar el principio del cálculo: pagado - parte correspondiente; balances suman 0; deudores transfieren a acreedores. |

# 24. Explicación que cualquier integrante debe saber

Respuesta breve sugerida para explicar la liquidación sin decir “lo hizo la IA”:

> **Explicación**
> Primero convertimos todos los montos a centavos. Para cada gasto calculamos cuánto pagó cada persona y cuánto le correspondía asumir según los participantes seleccionados. El balance es pagado menos lo que le correspondía. Los balances positivos son acreedores y los negativos deudores, y su suma siempre debe ser cero. La liquidación enfrenta deudores con acreedores y transfiere el menor monto necesario hasta llevar ambos saldos a cero.

# 25. Checklist antes de generar la primera línea de código

* [ ] La consigna oficial fue incorporada al spec.
* [ ] Existen al menos 8 requisitos funcionales; este documento define 10.
* [ ] Todos los RF tienen criterios Dado/Cuando/Entonces verificables.
* [ ] Los casos borde de 0 participantes, monto inválido, redondeo, eliminación con gastos, duplicados y refresh están resueltos.
* [ ] El modelo de datos está definido.
* [ ] Está decidido cómo representar dinero y cómo repartir centavos.
* [ ] Está decidido que balance y transferencias son datos derivados.
* [ ] El stack y la persistencia están documentados.
* [ ] El fuera de alcance está explícito.
* [ ] Las diferencias entre audio y consigna están registradas como preguntas abiertas.
* [ ] `AGENTS.md` está preparado.
* [ ] El plan derivado del spec fue generado, revisado y aprobado.
* [ ] El escenario de Samaipata tiene resultados esperados calculados.
* [ ] Cada integrante entiende el cálculo de balance y liquidación.

# 26. Próximo paso recomendado

El siguiente paso no es programar. El equipo debe revisar este documento, resolver las preguntas abiertas que puedan cambiar el alcance y convertir la versión aprobada en los archivos versionables del repositorio: `spec.md`, `acceptance-criteria.md`, `edge-cases.md`, `data-model.md`, `out-of-scope.md`, ADRs y `AGENTS.md`. Después se solicita a la IA un plan basado exclusivamente en esos documentos y se lo revisa antes de autorizar cualquier implementación.

> **Resultado esperado de la etapa SDD**
> Antes del código, otro integrante debería poder leer las especificaciones y responder sin adivinar: qué se construye, qué no se construye, cómo se reparten centavos, qué ocurre en cada caso borde, cómo se representan los datos y exactamente cuándo una funcionalidad se considera aceptada.

# Anexo A. Correspondencia con la consigna del docente

| Elemento de la consigna            | Dónde queda cubierto |
| ---------------------------------- | -------------------- |
| Pedido del cliente                 | Secciones 2, 5 y 10  |
| Escenario Samaipata                | Secciones 3, 16 y 23 |
| Mínimo 8 RF + Dado/Cuando/Entonces | Sección 10 (10 RF)   |
| Casos borde explícitos             | Secciones 8, 9 y 15  |
| Decisiones de diseño               | Secciones 12 y 13    |
| Fuera de alcance                   | Sección 7.2          |
| Archivo de contexto IA             | Sección 18           |
| Plan derivado del spec             | Sección 20           |
| Implementar tarea por tarea        | Sección 21           |
| Specs versionados con el código    | Sección 22           |
| Funcionalidad mínima               | Sección 5            |
| Balances suman 0 y redondeo        | Secciones 8, 9 y 16  |
| Repositorio y demo 3 min           | Sección 23           |
| Explicar cálculo de liquidación    | Secciones 14 y 24    |
