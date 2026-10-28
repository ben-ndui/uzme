"use strict";

/**
 * Jeu de données des tests de bout en bout — écrit dans les ÉMULATEURS
 * Firebase, jamais en production. `tools/e2e/run.sh` l'appelle avant
 * chaque campagne pour repartir d'un état connu.
 *
 * Portée actuelle (socle initial, 28/10/2026) : les 3 comptes de
 * connexion (artiste/studio/ingénieur) + un profil studio minimal. Les
 * données de réservation/service restent à cartographier avant d'être
 * semées ici — ne pas deviner leur forme exacte.
 */

process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= "127.0.0.1:9099";

const admin = require("firebase-admin");
admin.initializeApp({projectId: "uzme-app"});

const db = admin.firestore();
const auth = admin.auth();

const MOT_DE_PASSE = "Test1234!";

const COMPTES = {
  artiste: {
    email: "e2e.artiste@uzme.app",
    name: "Artiste E2E",
    role: "client",
  },
  studio: {
    email: "e2e.studio@uzme.app",
    name: "Studio E2E",
    role: "admin",
  },
  ingenieur: {
    email: "e2e.ingenieur@uzme.app",
    name: "Ingénieur E2E",
    role: "worker",
  },
};

/** Vide les collections que le scénario écrit, pour repartir de zéro. */
async function vider() {
  for (const c of ["users", "useme_favorites", "useme_bookings",
    "useme_sessions"]) {
    const snap = await db.collection(c).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

/** Crée (ou réutilise) un compte Auth + son document `users/{uid}`. */
async function creerCompte(cle, infos, extra = {}) {
  let user;
  try {
    user = await auth.getUserByEmail(infos.email);
  } catch (_) {
    user = await auth.createUser({
      email: infos.email,
      password: MOT_DE_PASSE,
      displayName: infos.name,
      emailVerified: true,
    });
  }

  const maintenant = new Date().toISOString();
  await db.collection("users").doc(user.uid).set({
    uid: user.uid,
    email: infos.email,
    name: infos.name,
    displayName: infos.name,
    photoUrl: null,
    phoneNumber: null,
    role: infos.role,
    fcmToken: null,
    isFirstTime: false,
    isOnline: false,
    isBlocked: false,
    createdAt: maintenant,
    updatedAt: maintenant,
    studioIds: [],
    genres: [],
    pioneerProgramIds: [],
    confirmedSessionsCount: 0,
    messagesSentCount: 0,
    activeDaysCount: 0,
    isDevMaster: false,
    ...extra,
  }, {merge: true});

  return user.uid;
}

async function main() {
  console.log("Nettoyage…");
  await vider();

  console.log("Comptes…");
  const artisteUid = await creerCompte("artiste", COMPTES.artiste);

  const studioUid = await creerCompte("studio", COMPTES.studio, {
    isPartner: true,
    studioProfile: {
      name: "Studio E2E",
      description: "Studio de test pour le harnais Maestro.",
      address: "1 rue de Test",
      city: "Paris",
      postalCode: "75001",
      country: "France",
      location: new admin.firestore.GeoPoint(48.8566, 2.3522),
      photos: [],
      genres: ["hip hop"],
      services: ["Enregistrement"],
      hourlyRate: 50,
      currency: "EUR",
      workingHours: null,
      openingHours: null,
      googlePlaceId: null,
      googlePlaceName: null,
      rating: null,
      reviewCount: 0,
      website: null,
      phone: null,
      isVerified: true,
      claimedAt: admin.firestore.Timestamp.now(),
      allowNoEngineer: true,
      studioType: "pro",
    },
  });

  const ingenieurUid = await creerCompte("ingenieur", COMPTES.ingenieur, {
    studioId: studioUid,
  });

  console.log("✔ Comptes prêts :");
  console.log(`  artiste    : ${COMPTES.artiste.email} / ${MOT_DE_PASSE} (${artisteUid})`);
  console.log(`  studio     : ${COMPTES.studio.email} / ${MOT_DE_PASSE} (${studioUid})`);
  console.log(`  ingénieur  : ${COMPTES.ingenieur.email} / ${MOT_DE_PASSE} (${ingenieurUid})`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
