---
description: Work through PLAN-S1-S14.md item by item, using the repo's subagents for review
argument-hint: [número de item opcional, ej. S9, o vacío para todos los pendientes]
---

Lee `AGENTS.md` y `PLAN-S1-S14.md` completos antes de tocar nada.

Ítems marcados "Cerrado" en el plan ya están resueltos y verificados — no los
reinvestigues ni los vuelvas a tocar salvo que se te pida explícitamente.

Para cada ítem pendiente en la sección "Prioridad 2" (o el ítem específico dado en
$ARGUMENTS si se especificó uno):
1. Implementa el cambio descrito en la columna "Nota".
2. Antes de dar el cambio por terminado, invoca al subagente `k8s-manifest-reviewer`
   si el cambio toca algo bajo `k8s/`, o `docs-consistency-checker` si toca `docs/`,
   `README.md`, o `scripts/`.
3. Si el subagente marca algo como "blocker", corrígelo antes de continuar al
   siguiente ítem — no acumules blockers sin resolver.
4. Actualiza `PLAN-S1-S14.md` marcando el ítem como resuelto, con una línea breve de
   qué se hizo (no borres la fila, solo agrega el estado).

Al terminar todos los ítems pendientes (o el ítem único de $ARGUMENTS), muestra un
resumen corto de qué se cambió y qué, si algo, quedó pendiente de decisión humana
(ej. S3, que necesita confirmar si el código realmente lee `auth.mode` antes de
poder resolverse solo).