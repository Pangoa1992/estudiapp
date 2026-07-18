# Meta Audience Network (Facebook Ads SDK)
# El SDK referencia anotaciones internas de Facebook que no existen en tiempo
# de compilación; R8 pide suprimir estas advertencias (missing_rules.txt).
-dontwarn com.facebook.infer.annotation.Nullsafe
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode

# Conserva las clases públicas del SDK de anuncios de Meta (se usan por
# reflexión desde el código nativo del plugin easy_audience_network).
-keep class com.facebook.ads.** { *; }
-keep interface com.facebook.ads.** { *; }
