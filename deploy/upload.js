// Sube el AAB a Google Play Store via Android Publisher API v3
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

const SERVICE_ACCOUNT = path.join(__dirname, 'service-account.json');
const AAB_PATH = path.join(__dirname, '..', 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab');
const PACKAGE_NAME = 'com.willy.estudiapp';
const TRACK = process.argv[2] || 'production'; // interno | alpha | beta | production

async function main() {
  if (!fs.existsSync(SERVICE_ACCOUNT)) {
    console.error('ERROR: Falta deploy/service-account.json');
    console.error('Descárgalo desde Play Console → Configuración → Cuentas de servicio');
    process.exit(1);
  }
  if (!fs.existsSync(AAB_PATH)) {
    console.error('ERROR: AAB no encontrado. Ejecuta flutter build appbundle --release primero.');
    process.exit(1);
  }

  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const play = google.androidpublisher({ version: 'v3', auth });

  // 1. Crear edición
  const editRes = await play.edits.insert({ packageName: PACKAGE_NAME });
  const editId = editRes.data.id;
  console.log(`Edición creada: ${editId}`);

  try {
    // 2. Subir AAB
    console.log('Subiendo AAB...');
    const bundleRes = await play.edits.bundles.upload({
      packageName: PACKAGE_NAME,
      editId,
      media: { mimeType: 'application/octet-stream', body: fs.createReadStream(AAB_PATH) },
    });
    const versionCode = bundleRes.data.versionCode;
    console.log(`AAB subido. versionCode: ${versionCode}`);

    // 3. Asignar al track
    await play.edits.tracks.update({
      packageName: PACKAGE_NAME,
      editId,
      track: TRACK,
      requestBody: {
        track: TRACK,
        releases: [{ versionCodes: [String(versionCode)], status: 'completed' }],
      },
    });

    // 4. Confirmar edición
    await play.edits.commit({ packageName: PACKAGE_NAME, editId });
    console.log(`✓ Publicado en track "${TRACK}" (versionCode ${versionCode})`);
  } catch (err) {
    await play.edits.delete({ packageName: PACKAGE_NAME, editId }).catch(() => {});
    console.error('Error:', err.message);
    process.exit(1);
  }
}

main();
