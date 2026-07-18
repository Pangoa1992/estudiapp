"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordarRachaEstudio = exports.notificarLogro = exports.recordarExpiracionTrial = exports.onReferidoUsado = exports.onPremiumActivado = exports.llamarIA = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const LIMITE_GRATUITO = 5;
// ── Región más cercana a Perú ─────────────────────────────────────────────────
(0, v2_1.setGlobalOptions)({ region: "us-central1" });
// ── Helpers de fecha Lima (UTC-5, Perú no usa horario de verano) ───────────────
/** Fecha de hoy en Lima: "yyyy-MM-dd" */
function fechaHoyLima() {
    const lima = new Date(Date.now() - 5 * 60 * 60 * 1000);
    return lima.toISOString().substring(0, 10);
}
/** Fecha de ayer en Lima: "yyyy-MM-dd" */
function fechaAyerLima() {
    const lima = new Date(Date.now() - 5 * 60 * 60 * 1000 - 24 * 60 * 60 * 1000);
    return lima.toISOString().substring(0, 10);
}
// ── Racha sin cupo ─────────────────────────────────────────────────────────────
/**
 * Envía una notificación FCM al usuario sugiriéndole Premium después de 3 días
 * consecutivos agotando sus búsquedas IA.
 */
async function notificarPremiumAlUsuario(uid) {
    const perfilDoc = await db.collection("perfiles").doc(uid).get();
    const token = perfilDoc.data()?.fcmToken;
    if (!token) {
        console.warn(`[notificarPremiumAlUsuario] Sin token FCM para uid=${uid}`);
        return;
    }
    try {
        await (0, messaging_1.getMessaging)().send({
            token,
            notification: {
                title: "💡 ¿Listo para más?",
                body: "Agotaste tus búsquedas IA 3 días seguidos. Con Premium, acceso ilimitado.",
            },
            data: { tipo: "limite_premium_sugerido", uid },
            android: {
                notification: {
                    channelId: "estudio_inteligente_canal",
                    priority: "high",
                },
            },
        });
        console.info(`[notificarPremiumAlUsuario] Push enviado. uid=${uid}`);
    }
    catch (e) {
        console.error(`[notificarPremiumAlUsuario] Error FCM: ${e}`);
    }
}
// ── Límite diario + racha ──────────────────────────────────────────────────────
/**
 * Verifica el límite diario y descuenta 1 búsqueda en una transacción atómica.
 *
 * Además rastrea días consecutivos sin cupo (ia_racha_sin_cupo). Cuando el
 * contador llega a 3, dispara una notificación FCM al usuario ofreciéndole Premium.
 *
 * Lanza HttpsError("resource-exhausted") si el cupo diario está agotado.
 * Los usuarios Premium siempre pasan sin límite.
 */
async function verificarLimiteYConsumir(uid) {
    const perfilRef = db.collection("perfiles").doc(uid);
    let cupoAgotado = false;
    let debeNotificarRacha = false;
    await db.runTransaction(async (tx) => {
        const doc = await tx.get(perfilRef);
        const data = doc.data() ?? {};
        // ── Usuarios Premium: acceso ilimitado ─────────────────────────────────
        if (data.isPremium === true) {
            const expiry = data.premiumExpiry?.toDate?.();
            if (!expiry || expiry > new Date())
                return;
        }
        // ── Calcular usos del día actual ────────────────────────────────────────
        const hoy = fechaHoyLima();
        const mismodia = data.ia_fecha_hoy === hoy;
        const usos = mismodia ? Number(data.ia_usos_hoy ?? 0) : 0;
        const bonus = mismodia ? Number(data.ia_bonus_hoy ?? 0) : 0;
        if (usos >= LIMITE_GRATUITO + bonus) {
            cupoAgotado = true;
            // ── Rastrear días consecutivos sin cupo ─────────────────────────────
            const ultDia = data.ia_ult_dia_sin_cupo;
            const ayer = fechaAyerLima();
            let racha = Number(data.ia_racha_sin_cupo ?? 0);
            // Evitar contar dos veces el mismo día
            if (ultDia !== hoy) {
                if (ultDia === ayer) {
                    racha++; // día consecutivo
                }
                else {
                    racha = 1; // reiniciar racha
                }
                tx.set(perfilRef, { ia_racha_sin_cupo: racha, ia_ult_dia_sin_cupo: hoy }, { merge: true });
                if (racha >= 3) {
                    debeNotificarRacha = true;
                }
            }
            return; // No lanzar dentro de la transacción — se lanza después
        }
        // ── Incrementar contador (escritura atómica, solo Admin SDK) ───────────
        tx.set(perfilRef, { ia_usos_hoy: usos + 1, ia_fecha_hoy: hoy }, { merge: true });
    });
    // ── Acciones post-transacción ───────────────────────────────────────────────
    if (debeNotificarRacha) {
        // No esperamos: no queremos demorar la respuesta al usuario
        notificarPremiumAlUsuario(uid).catch((e) => console.error("[verificarLimiteYConsumir] Error enviando FCM usuario:", e));
    }
    if (cupoAgotado) {
        throw new https_1.HttpsError("resource-exhausted", "Límite diario de búsquedas alcanzado. Vuelve mañana o gana más viendo un anuncio.");
    }
}
// ── Cache API key ──────────────────────────────────────────────────────────────
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-haiku-4-5-20251001";
/** Lee la API key desde Secret Manager (variable de entorno inyectada por Firebase). */
function resolveApiKey() {
    const key = process.env.ANTHROPIC_API_KEY?.trim();
    if (key) {
        console.info(`[resolveApiKey] Secret Manager OK: longitud=${key.length}`);
        return key;
    }
    return null;
}
// ── Cloud Function: Proxy IA ───────────────────────────────────────────────────
/**
 * Proxy seguro hacia la API de Anthropic.
 * La API key nunca llega al cliente: se lee de Secret Manager o Remote Config.
 * Solo usuarios autenticados con Firebase Auth pueden invocar esta función.
 */
exports.llamarIA = (0, https_1.onCall)({
    timeoutSeconds: 120,
    memory: "256MiB",
    invoker: "public",
    secrets: ["ANTHROPIC_API_KEY"],
}, async (request) => {
    // ── 1. Verificar autenticación ────────────────────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Se requiere iniciar sesión para usar la IA.");
    }
    // ── 2. Validar payload ────────────────────────────────────────────────────
    const { messages, maxTokens = 3000 } = request.data;
    if (!Array.isArray(messages) || messages.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "El campo 'messages' debe ser un array no vacío.");
    }
    if (messages.length > 50) {
        throw new https_1.HttpsError("invalid-argument", "Máximo 50 mensajes por llamada.");
    }
    const tokensLimitado = Math.min(Math.max(maxTokens, 100), 8000);
    // ── 3. Verificar límite diario y descontar 1 búsqueda ─────────────────────
    await verificarLimiteYConsumir(request.auth.uid);
    // ── 4. Resolver API key desde Secret Manager ──────────────────────────────
    const apiKey = await resolveApiKey();
    if (!apiKey) {
        console.error("ANTHROPIC_API_KEY no encontrada en Secret Manager ni en Remote Config.");
        throw new https_1.HttpsError("internal", "Servicio de IA no configurado. Contacta al administrador.");
    }
    // ── 5. Llamar a Anthropic ─────────────────────────────────────────────────
    let anthropicResponse;
    try {
        anthropicResponse = await fetch(ANTHROPIC_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
            },
            body: JSON.stringify({
                model: MODEL,
                max_tokens: tokensLimitado,
                messages,
            }),
        });
    }
    catch (networkError) {
        console.error("Error de red al llamar Anthropic:", networkError);
        throw new https_1.HttpsError("unavailable", "No se pudo conectar al servicio de IA. Verifica tu conexión.");
    }
    // ── 6. Manejar errores de Anthropic ───────────────────────────────────────
    if (!anthropicResponse.ok) {
        const errorBody = await anthropicResponse.text().catch(() => "");
        console.error(`Anthropic error ${anthropicResponse.status}: ${errorBody}`);
        if (anthropicResponse.status === 429) {
            throw new https_1.HttpsError("resource-exhausted", "Demasiadas solicitudes. Espera un momento e intenta de nuevo.");
        }
        if (anthropicResponse.status === 401) {
            throw new https_1.HttpsError("permission-denied", "API key de Anthropic inválida. Verifica la configuración.");
        }
        if (anthropicResponse.status === 400) {
            throw new https_1.HttpsError("invalid-argument", "La solicitud contiene contenido no válido.");
        }
        throw new https_1.HttpsError("internal", `Error del servicio IA (${anthropicResponse.status}).`);
    }
    // ── 7. Retornar respuesta al cliente ──────────────────────────────────────
    return await anthropicResponse.json();
});
// ── Cloud Function: Notificar al admin cuando alguien activa Premium ───────────
/**
 * Se dispara cuando se escribe en cualquier documento de `perfiles/{uid}`.
 * Si `isPremium` cambió de false/null a true, envía una push notification al
 * celular del admin (token guardado en fcm_tokens/admin por FcmService.dart).
 */
exports.onPremiumActivado = (0, firestore_1.onDocumentWritten)({ document: "perfiles/{uid}", region: "us-central1" }, async (event) => {
    const uid = event.params.uid;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    // Solo actuar cuando isPremium cambia a true
    const antesEraFalso = !before?.isPremium;
    const ahoraEsTrue = after?.isPremium === true;
    if (!antesEraFalso || !ahoraEsTrue)
        return null;
    // Leer el token FCM del admin (guardado por FcmService.dart)
    const adminTokenDoc = await db.collection("fcm_tokens").doc("admin").get();
    const adminToken = adminTokenDoc.data()?.token;
    if (!adminToken) {
        console.warn("[onPremiumActivado] Token del admin no encontrado en fcm_tokens/admin.");
        return null;
    }
    const nombre = after?.nombre ?? "Un usuario";
    const plan = after?.planPremium ?? "desconocido";
    const esTrial = plan === "trial_7d";
    try {
        await (0, messaging_1.getMessaging)().send({
            token: adminToken,
            notification: {
                title: esTrial
                    ? "🎁 Nuevo trial Premium"
                    : "🎉 ¡Nueva suscripción Premium!",
                body: esTrial
                    ? `${nombre} activó el trial gratuito de 7 días.`
                    : `${nombre} se suscribió al plan ${plan}. ¡Cha-ching! 💰`,
            },
            data: {
                tipo: "nuevo_premium",
                uid,
                plan,
            },
            android: {
                notification: {
                    channelId: "admin_alertas",
                    priority: "high",
                },
            },
        });
        console.info(`[onPremiumActivado] Push al admin. uid=${uid}, plan=${plan}`);
    }
    catch (e) {
        console.error("[onPremiumActivado] Error al enviar FCM al admin:", e);
    }
    return null;
});
// ── Cloud Function: Otorgar monedas al referidor ──────────────────────────────
/**
 * Se dispara al crear `referidos/{codigo}/usos/{usuarioId}` (cuando alguien
 * aplica un código de referido). Otorga al DUEÑO del código sus monedas de
 * recompensa incrementando `monedas` en su perfil.
 *
 * Esta escritura la hace la Cloud Function (Admin SDK) porque el cliente NO
 * puede escribir el perfil de otro usuario: las reglas de Firestore solo
 * permiten al propietario. Antes se intentaba desde `aplicarCodigo()` en el
 * cliente y fallaba con PERMISSION_DENIED (el referidor nunca recibía monedas
 * y al aplicante le salía "error").
 *
 * Idempotencia: cada documento de uso usa el uid del aplicante como id y solo
 * puede crearse una vez, así que este trigger corre una sola vez por referido.
 * Los reintentos automáticos están desactivados por defecto en gen2.
 */
exports.onReferidoUsado = (0, firestore_1.onDocumentCreated)({ document: "referidos/{codigo}/usos/{usuarioId}", region: "us-central1" }, async (event) => {
    const codigo = event.params.codigo;
    const uso = event.data?.data();
    if (!uso)
        return null;
    const monedas = Number(uso.monedasReferidor ?? 0);
    if (monedas <= 0) {
        console.warn(`[onReferidoUsado] Uso sin monedas. codigo=${codigo}`);
        return null;
    }
    // El dueño del código está en el doc padre referidos/{codigo}.uid
    const refDoc = await db.collection("referidos").doc(codigo).get();
    const referidorUid = refDoc.data()?.uid;
    if (!referidorUid) {
        console.warn(`[onReferidoUsado] Código sin dueño. codigo=${codigo}`);
        return null;
    }
    try {
        await db.collection("perfiles").doc(referidorUid).set({ monedas: firestore_2.FieldValue.increment(monedas) }, { merge: true });
        console.info(`[onReferidoUsado] +${monedas} monedas al referidor ${referidorUid} (codigo=${codigo}).`);
    }
    catch (e) {
        console.error(`[onReferidoUsado] Error al otorgar monedas: ${e}`);
    }
    return null;
});
// ── Cloud Function: Recordar expiración del trial (cron diario 9 AM Lima) ─────
/**
 * Se ejecuta todos los días a las 9:00 AM (hora Lima, UTC-5).
 * Busca trials activos que expiran en 3, 2 o 1 día(s) y envía un push al
 * usuario para que se suscriba antes de perder el acceso.
 *
 * Usa campos anti-duplicado en Firestore para no mandar la misma
 * notificación dos veces:
 *   trialNotif_3d, trialNotif_2d, trialNotif_1d  (boolean, se marcan tras enviar)
 */
exports.recordarExpiracionTrial = (0, scheduler_1.onSchedule)({
    schedule: "0 9 * * *", // 9:00 AM todos los días
    timeZone: "America/Lima", // UTC-5, zona de Perú
    region: "us-central1",
}, async () => {
    const ahora = new Date();
    // Solo perfiles con trial activo (isPremium=true, plan=trial_7d)
    const snap = await db.collection("perfiles")
        .where("isPremium", "==", true)
        .where("planPremium", "==", "trial_7d")
        .get();
    if (snap.empty) {
        console.info("[recordarExpiracionTrial] Sin trials activos hoy.");
        return;
    }
    let enviados = 0;
    for (const doc of snap.docs) {
        const data = doc.data();
        const expiry = data.premiumExpiry?.toDate?.();
        if (!expiry || expiry <= ahora)
            continue; // ya expiró o sin fecha
        // Días completos restantes (redondeado hacia arriba)
        const msRestantes = expiry.getTime() - ahora.getTime();
        const diasRestantes = Math.ceil(msRestantes / (1000 * 60 * 60 * 24));
        if (![1, 2, 3].includes(diasRestantes))
            continue;
        // Evitar enviar dos veces el mismo día
        const campoGuarda = `trialNotif_${diasRestantes}d`;
        if (data[campoGuarda] === true)
            continue;
        const token = data.fcmToken;
        if (!token) {
            console.warn(`[recordarExpiracionTrial] Sin token FCM. uid=${doc.id}`);
            continue;
        }
        const titulo = diasRestantes === 1
            ? "⚠️ ¡Tu Premium expira mañana!"
            : `⏳ Tu Premium expira en ${diasRestantes} días`;
        const cuerpo = diasRestantes === 1
            ? "Último día. Suscríbete ahora y no pierdas las búsquedas IA ilimitadas."
            : diasRestantes === 2
                ? "Quedan 2 días. Suscríbete al plan anual y ahorra 45%."
                : "Tu trial está por terminar. ¿Seguimos estudiando juntos? 🎓";
        try {
            await (0, messaging_1.getMessaging)().send({
                token,
                notification: { title: titulo, body: cuerpo },
                data: {
                    tipo: "trial_expirando",
                    dias: String(diasRestantes),
                },
                android: {
                    notification: {
                        channelId: "estudio_inteligente_canal",
                        priority: "high",
                    },
                },
            });
            // Marcar como notificado para no repetir
            await doc.ref.set({ [campoGuarda]: true }, { merge: true });
            enviados++;
            console.info(`[recordarExpiracionTrial] Push enviado. uid=${doc.id}, dias=${diasRestantes}`);
        }
        catch (e) {
            console.error(`[recordarExpiracionTrial] Error al enviar push. uid=${doc.id}: ${e}`);
        }
    }
    console.info(`[recordarExpiracionTrial] Resumen: ${enviados} push(es) enviados de ${snap.size} trial(s) revisados.`);
});
// ── Cloud Function: Notificar logro al propio usuario ─────────────────────────
/**
 * Callable desde Flutter. Envía una push notification FCM al propio usuario
 * que hizo la llamada (token guardado en perfiles/{uid}.fcmToken).
 * Se usa para: 20/20 en simulacro, ruta de aprendizaje generada, etc.
 */
exports.notificarLogro = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "No autenticado.");
    }
    const { tipo, titulo, cuerpo } = request.data;
    if (!tipo || !titulo || !cuerpo) {
        throw new https_1.HttpsError("invalid-argument", "Faltan campos: tipo, titulo, cuerpo.");
    }
    const perfilDoc = await db.collection("perfiles").doc(request.auth.uid).get();
    const token = perfilDoc.data()?.fcmToken;
    if (!token)
        return { ok: false, reason: "sin_token" };
    try {
        await (0, messaging_1.getMessaging)().send({
            token,
            notification: { title: titulo, body: cuerpo },
            data: { tipo },
            android: {
                notification: {
                    channelId: "estudio_inteligente_canal",
                    priority: "high",
                },
            },
        });
        console.info(`[notificarLogro] Push enviado. uid=${request.auth.uid}, tipo=${tipo}`);
        return { ok: true };
    }
    catch (e) {
        console.error(`[notificarLogro] Error FCM: ${e}`);
        throw new https_1.HttpsError("internal", "Error al enviar la notificación.");
    }
});
// ── Cloud Function: Recordar racha de estudio (todos los días 7 PM Lima) ──────
/**
 * Se ejecuta todos los días a las 7:00 PM (hora Lima, UTC-5).
 * Busca usuarios que NO han abierto la app hoy (ultimaVisita no es hoy en Lima)
 * y les envía un recordatorio para mantener su racha de estudio.
 *
 * Anti-duplicado: campo ultimoRecordatorioDia en perfiles/{uid} con la fecha Lima.
 */
exports.recordarRachaEstudio = (0, scheduler_1.onSchedule)({
    schedule: "0 19 * * *",
    timeZone: "America/Lima",
    region: "us-central1",
}, async () => {
    const hoyLima = fechaHoyLima();
    const snap = await db.collection("perfiles")
        .where("fcmToken", "!=", "")
        .get();
    let enviados = 0;
    for (const doc of snap.docs) {
        const data = doc.data();
        const fcmToken = data.fcmToken;
        if (!fcmToken)
            continue;
        // Anti-duplicado: no enviar más de una vez por día
        if (data.ultimoRecordatorioDia === hoyLima)
            continue;
        // Si el usuario ya abrió la app hoy (Lima), no molestar
        const ultimaVisita = data.ultimaVisita?.toDate?.();
        if (ultimaVisita) {
            const visitaLima = new Date(ultimaVisita.getTime() - 5 * 60 * 60 * 1000);
            const fechaVisita = visitaLima.toISOString().substring(0, 10);
            if (fechaVisita === hoyLima)
                continue;
        }
        const racha = data.racha ?? 0;
        const nombre = data.nombre ?? "Estudiante";
        const titulo = racha >= 7
            ? `🔥 ¡Tu racha de ${racha} días está en riesgo!`
            : racha >= 3
                ? `⚡ No pierdas tu racha de ${racha} días`
                : racha > 0
                    ? `📚 ¡${nombre}, no olvides estudiar hoy!`
                    : "📚 ¡Es hora de estudiar!";
        const cuerpo = racha >= 7
            ? `Llevas ${racha} días seguidos. Estudia algo hoy y que no se rompa. 💪`
            : racha >= 3
                ? `Solo unos minutos de estudio mantienen viva tu racha. ¡Vamos! 🎯`
                : racha > 0
                    ? `Un día sin estudiar y se va la racha. Abre la app ahora. 🚀`
                    : `Retoma tus hábitos de estudio. Cada día construye tu futuro. ✨`;
        try {
            await (0, messaging_1.getMessaging)().send({
                token: fcmToken,
                notification: { title: titulo, body: cuerpo },
                data: { tipo: "recordatorio_racha", racha: String(racha) },
                android: {
                    notification: {
                        channelId: "estudio_inteligente_canal",
                        priority: "high",
                    },
                },
            });
            await doc.ref.set({ ultimoRecordatorioDia: hoyLima }, { merge: true });
            enviados++;
            console.info(`[recordarRachaEstudio] Push enviado uid=${doc.id}, racha=${racha}`);
        }
        catch (e) {
            console.error(`[recordarRachaEstudio] Error uid=${doc.id}: ${e}`);
        }
    }
    console.info(`[recordarRachaEstudio] ${enviados} recordatorio(s) de ${snap.size} perfiles revisados.`);
});
//# sourceMappingURL=index.js.map