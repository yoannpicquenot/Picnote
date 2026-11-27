// Sends the housemates a push notification for each shared list or note
// someone created or changed, as soon as that person leaves it (the app
// calls release_activity) or after a minute of quiet. Called then, and
// every minute by the `notify-activity` cron job (see migrations/*push*).
// Called on the hour with {"kind": "reminders"} by the `daily-reminders`
// job, it reminds each phone whose hour it is of what is left to do.
// Called every 5 minutes with {"kind": "memos"} by the `memo-reminders`
// job, it sends the Pense-bête reminders whose time has come, only to whom
// each one is for.
//
// Secret: FIREBASE_SERVICE_ACCOUNT, the JSON key of a Firebase service
// account (Firebase console > Project settings > Service accounts).

import { createClient } from "jsr:@supabase/supabase-js@2";

type Device = { token: string; locale: string };

/** One person's changes to one list or note, from claim_activity_notifications. */
type Burst = {
  actor_name: string;
  list_id: string | null;
  note_id: string | null;
  title: string | null;
  created: boolean;
  added: string[];
  checked: number;
  unchecked: number;
  edited: number;
  deleted: number;
  devices: Device[];
};

/** A phone to remind, from due_reminders. */
type Reminder = { token: string; locale: string; today: string[]; tomorrow: string[] };

/** A Pense-bête reminder that is due, from claim_memo_reminders. */
type Memo = {
  task_id: string;
  title: string;
  author_name: string | null;
  repeat: "never" | "daily" | "weekly" | "monthly";
  /** YYYY-MM-DD, the day it rang for. */
  remind_on: string;
  devices: Device[];
};

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (request) => {
  // Checked before claiming, so nothing is lost while the secret is missing.
  const secret = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!secret) return Response.json({ error: "FIREBASE_SERVICE_ACCOUNT is not set" }, { status: 500 });
  const account = JSON.parse(secret) as ServiceAccount;
  const body = await request.json().catch(() => ({}));
  if (body?.kind === "reminders") return await remind(account);
  if (body?.kind === "memos") return await remindMemos(account);

  const { data, error } = await supabase.rpc("claim_activity_notifications");
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const bursts = (data ?? []) as Burst[];
  if (!bursts.some((b) => b.devices.length > 0)) return Response.json({ sent: 0 });

  const accessToken = await googleAccessToken(account);
  let sent = 0;
  for (const burst of bursts) {
    for (const device of burst.devices) {
      const message = wording(burst, device.locale === "fr" ? fr : en);
      if (message == null) continue;
      const route = burst.note_id != null ? `/notes/${burst.note_id}` : `/lists/${burst.list_id}`;
      if (await send(account.project_id, accessToken, device.token, message, route, route)) sent++;
    }
  }
  return Response.json({ sent });
});

async function remind(account: ServiceAccount): Promise<Response> {
  const { data, error } = await supabase.rpc("due_reminders");
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const phones = (data ?? []) as Reminder[];
  if (phones.length === 0) return Response.json({ sent: 0 });

  const accessToken = await googleAccessToken(account);
  let sent = 0;
  for (const phone of phones) {
    const message = reminderWording(phone, phone.locale === "fr" ? fr : en);
    if (await send(account.project_id, accessToken, phone.token, message, "/", "reminder")) sent++;
  }
  return Response.json({ sent });
}

/** Claimed even without phones to send to: a repeating one still moves on. */
async function remindMemos(account: ServiceAccount): Promise<Response> {
  const { data, error } = await supabase.rpc("claim_memo_reminders");
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const memos = (data ?? []) as Memo[];
  if (!memos.some((m) => m.devices.length > 0)) return Response.json({ sent: 0 });

  const accessToken = await googleAccessToken(account);
  let sent = 0;
  for (const memo of memos) {
    for (const device of memo.devices) {
      const message = memoWording(memo, device.locale === "fr" ? fr : en);
      if (await send(account.project_id, accessToken, device.token, message, "/pense-bete", `memo-${memo.task_id}`)) {
        sent++;
      }
    }
  }
  return Response.json({ sent });
}

// ---------------------------------------------------------------------------
// Wording
// ---------------------------------------------------------------------------

type Words = {
  untitled: string;
  noteCreated: (who: string, name: string) => string;
  noteEdited: (who: string, name: string) => string;
  listCreated: (who: string, name: string) => string;
  listEdited: (who: string, name: string) => string;
  added: (items: string) => string;
  checked: (n: number) => string;
  unchecked: (n: number) => string;
  renamed: (n: number) => string;
  deleted: (n: number) => string;
  and: string;
  others: (n: number) => string;
  leftToday: (n: number) => string;
  leftTomorrow: (n: number) => string;
  tomorrow: string;
  addedBy: (who: string) => string;
  daily: string;
  weekly: (weekday: number) => string;
  monthly: string;
};

const frDays = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"];
const enDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

const fr: Words = {
  untitled: "Sans titre",
  noteCreated: (who, name) => `${who} a créé la note ${name}`,
  noteEdited: (who, name) => `${who} a modifié la note ${name}`,
  listCreated: (who, name) => `${who} a créé la liste ${name}`,
  listEdited: (who, name) => `${who} a modifié la liste ${name}`,
  added: (items) => `Ajouté : ${items}`,
  checked: (n) => `${n} coché${n > 1 ? "s" : ""}`,
  unchecked: (n) => `${n} décoché${n > 1 ? "s" : ""}`,
  renamed: (n) => `${n} renommé${n > 1 ? "s" : ""}`,
  deleted: (n) => `${n} supprimé${n > 1 ? "s" : ""}`,
  and: "et",
  others: (n) => `${n} autre${n > 1 ? "s" : ""}`,
  leftToday: (n) => `${n} chose${n > 1 ? "s" : ""} à faire aujourd’hui`,
  leftTomorrow: (n) => `${n} chose${n > 1 ? "s" : ""} à faire demain`,
  tomorrow: "Demain",
  addedBy: (who) => `Ajoutée par ${who}`,
  daily: "chaque jour",
  weekly: (d) => `chaque ${frDays[d]}`,
  monthly: "chaque mois",
};

const en: Words = {
  untitled: "Untitled",
  noteCreated: (who, name) => `${who} created the note ${name}`,
  noteEdited: (who, name) => `${who} edited the note ${name}`,
  listCreated: (who, name) => `${who} created the list ${name}`,
  listEdited: (who, name) => `${who} edited the list ${name}`,
  added: (items) => `Added: ${items}`,
  checked: (n) => `${n} checked`,
  unchecked: (n) => `${n} unchecked`,
  renamed: (n) => `${n} renamed`,
  deleted: (n) => `${n} deleted`,
  and: "and",
  others: (n) => `${n} other${n > 1 ? "s" : ""}`,
  leftToday: (n) => `${n} thing${n > 1 ? "s" : ""} to do today`,
  leftTomorrow: (n) => `${n} thing${n > 1 ? "s" : ""} to do tomorrow`,
  tomorrow: "Tomorrow",
  addedBy: (who) => `Added by ${who}`,
  daily: "every day",
  weekly: (d) => `every ${enDays[d]}`,
  monthly: "every month",
};

/** The task as title; "Ajoutée par Mel, chaque mardi" below. */
function memoWording(m: Memo, w: Words): { title: string; body?: string } {
  const weekday = new Date(`${m.remind_on}T12:00:00Z`).getUTCDay();
  const repeat = m.repeat === "daily"
    ? w.daily
    : m.repeat === "weekly"
    ? w.weekly(weekday)
    : m.repeat === "monthly"
    ? w.monthly
    : null;
  const parts = [m.author_name ? w.addedBy(m.author_name) : null, repeat].filter((p) => p != null) as string[];
  if (parts.length === 0) return { title: m.title };
  const body = parts.join(", ");
  return { title: m.title, body: body[0].toUpperCase() + body.slice(1) };
}

/** "Lait, Pain et Œufs", or "Lait, Pain, Œufs et 2 autres". */
function itemList(items: string[], w: Words): string {
  const shown = items.slice(0, 3);
  const rest = items.length - shown.length;
  const parts = rest > 0 ? [...shown, w.others(rest)] : shown;
  return parts.length === 1 ? parts[0] : `${parts.slice(0, -1).join(", ")} ${w.and} ${parts[parts.length - 1]}`;
}

/** The title says who did what; for a list, the body says what changed:
 * "Ajouté : Lait et Pain · 2 cochés". */
function wording(b: Burst, w: Words): { title: string; body?: string } | null {
  const name = b.title?.trim() || w.untitled;
  if (b.note_id != null) {
    return { title: (b.created ? w.noteCreated : w.noteEdited)(b.actor_name, name) };
  }
  const changes: string[] = [];
  if (b.added.length > 0) changes.push(b.created ? itemList(b.added, w) : w.added(itemList(b.added, w)));
  if (b.checked > 0) changes.push(w.checked(b.checked));
  if (b.unchecked > 0) changes.push(w.unchecked(b.unchecked));
  if (b.edited > 0) changes.push(w.renamed(b.edited));
  if (b.deleted > 0) changes.push(w.deleted(b.deleted));
  if (!b.created && changes.length === 0) return null;
  const title = (b.created ? w.listCreated : w.listEdited)(b.actor_name, name);
  return changes.length > 0 ? { title, body: changes.join(" · ") } : { title };
}

/** "3 choses à faire aujourd’hui" over "Lait, Pain et 1 autre · Demain : 2",
 * or only tomorrow's when today is clear. */
function reminderWording(r: Reminder, w: Words): { title: string; body: string } {
  if (r.today.length === 0) return { title: w.leftTomorrow(r.tomorrow.length), body: itemList(r.tomorrow, w) };
  const body = itemList(r.today, w);
  return {
    title: w.leftToday(r.today.length),
    body: r.tomorrow.length > 0 ? `${body} · ${w.tomorrow} : ${r.tomorrow.length}` : body,
  };
}

// ---------------------------------------------------------------------------
// Firebase Cloud Messaging
// ---------------------------------------------------------------------------

/** True when sent. A token Firebase no longer knows is forgotten. */
async function send(
  projectId: string,
  accessToken: string,
  token: string,
  message: { title: string; body?: string },
  route: string,
  tag: string,
): Promise<boolean> {
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token,
        notification: message,
        data: { route },
        android: {
          priority: "high",
          // A newer notification about the same list or note, or a newer
          // reminder, replaces it.
          notification: { tag },
        },
      },
    }),
  });
  if (response.ok) return true;
  const text = await response.text();
  if (response.status === 404 || text.includes("UNREGISTERED")) {
    await supabase.rpc("forget_device", { device_token: token });
  } else {
    console.error(`FCM ${response.status}: ${text}`);
  }
  return false;
}

/** An OAuth token for FCM, from the service account's key (RS256 JWT). */
async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const encoder = new TextEncoder();
  const unsigned = `${base64url(encoder.encode(JSON.stringify(header)))}.${
    base64url(encoder.encode(JSON.stringify(claims)))
  }`;
  const pem = account.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned)));

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error(`Google OAuth ${response.status}: ${await response.text()}`);
  return (await response.json()).access_token;
}

function base64url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
