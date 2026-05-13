import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getRemoteConfig } from "firebase-admin/remote-config";

initializeApp();

// Región más cercana a Perú (menor latencia)
setGlobalOptions({ region: "us-central1" });

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-haiku-4-5-20251001";

interface AnthropicMessage {
  role: "user" | "assistant";
  content: unknown; // texto o array de bloques (imagen, documento, texto)
}

interface CallData {
  messages: AnthropicMessage[];
  maxTokens?: number;
}

// Cache en memoria para la API key leída desde Remote Config (TTL: 5 min)
let _cachedApiKey: string | null = null;
let _cacheTs = 0;
const CACHE_TTL_MS = 5 * 60 * 1000;

/**
 * Lee la API key con dos estrategias:
 * 1. Secret Manager (recomendado): configurar con
 *    `firebase functions:secrets:set ANTHROPIC_API_KEY`
 * 2. Fallback automático a Firebase Remote Config (clave: anthropic_api_key)
 *    — compatible con la configuración previa del proyecto.
 */
async function resolveApiKey(): Promise<string | null> {
  // Prioridad 1: Secret Manager inyectado como variable de entorno
  if (process.env.ANTHROPIC_API_KEY) {
    const key = process.env.ANTHROPIC_API_KEY.trim();
    console.info(`[resolveApiKey] Secret Manager: longitud=${key.length}`);
    return key;
  }

  // Prioridad 2: Remote Config (con caché de 5 minutos)
  const now = Date.now();
  if (_cachedApiKey && now - _cacheTs < CACHE_TTL_MS) {
    return _cachedApiKey;
  }

  try {
    const template = await getRemoteConfig().getTemplate();
    const param = template.parameters["anthropic_api_key"];
    const defaultValue = param?.defaultValue;
    if (defaultValue && "value" in defaultValue) {
      _cachedApiKey = (defaultValue as { value: string }).value.trim();
      _cacheTs = now;
      return _cachedApiKey;
    }
  } catch (e) {
    console.error("[resolveApiKey] Error leyendo Remote Config:", e);
  }

  return null;
}

/**
 * Proxy seguro hacia la API de Anthropic.
 * La API key nunca llega al cliente: se lee de Secret Manager o Remote Config.
 * Solo usuarios autenticados con Firebase Auth pueden invocar esta función.
 *
 * invoker: "public" es necesario para que Cloud Run acepte requests sin
 * credenciales GCP — la autenticación Firebase Auth se verifica en el código.
 * Sin este campo, Firebase Functions v2 puede dejar el servicio Cloud Run en
 * modo privado y rechazar todas las requests con HTTP 401 antes de que el
 * handler corra, lo que el SDK Flutter traduce como UNAUTHENTICATED.
 *
 * secrets: ["ANTHROPIC_API_KEY"] monta el secreto de Secret Manager como
 * process.env.ANTHROPIC_API_KEY en tiempo de ejecución.
 */
export const llamarIA = onCall(
  {
    timeoutSeconds: 120,
    memory: "256MiB",
    invoker: "public",
    secrets: ["ANTHROPIC_API_KEY"],
  },
  async (request) => {
    // ── 1. Verificar autenticación ──────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Se requiere iniciar sesión para usar la IA."
      );
    }

    // ── 2. Validar payload ──────────────────────────────────────────────────
    const { messages, maxTokens = 3000 } = request.data as CallData;

    if (!Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "El campo 'messages' debe ser un array no vacío."
      );
    }

    if (messages.length > 50) {
      throw new HttpsError(
        "invalid-argument",
        "Máximo 50 mensajes por llamada."
      );
    }

    const tokensLimitado = Math.min(Math.max(maxTokens, 100), 4096);

    // ── 3. Resolver API key (Secret Manager → Remote Config) ────────────────
    const apiKey = await resolveApiKey();
    if (!apiKey) {
      console.error(
        "ANTHROPIC_API_KEY no encontrada en Secret Manager ni en Remote Config."
      );
      throw new HttpsError(
        "internal",
        "Servicio de IA no configurado. Contacta al administrador."
      );
    }

    // ── 4. Llamar a Anthropic ───────────────────────────────────────────────
    let anthropicResponse: Response;
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
    } catch (networkError) {
      console.error("Error de red al llamar Anthropic:", networkError);
      throw new HttpsError(
        "unavailable",
        "No se pudo conectar al servicio de IA. Verifica tu conexión."
      );
    }

    // ── 5. Manejar errores de Anthropic ─────────────────────────────────────
    if (!anthropicResponse.ok) {
      const errorBody = await anthropicResponse.text().catch(() => "");
      console.error(
        `Anthropic error ${anthropicResponse.status}: ${errorBody}`
      );

      if (anthropicResponse.status === 429) {
        throw new HttpsError(
          "resource-exhausted",
          "Demasiadas solicitudes. Espera un momento e intenta de nuevo."
        );
      }
      if (anthropicResponse.status === 401) {
        throw new HttpsError(
          "permission-denied",
          "API key de Anthropic inválida. Verifica la configuración."
        );
      }
      if (anthropicResponse.status === 400) {
        throw new HttpsError(
          "invalid-argument",
          "La solicitud contiene contenido no válido."
        );
      }
      throw new HttpsError(
        "internal",
        `Error del servicio IA (${anthropicResponse.status}).`
      );
    }

    // ── 6. Retornar respuesta al cliente ─────────────────────────────────────
    return await anthropicResponse.json();
  }
);
