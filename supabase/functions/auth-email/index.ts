// Emails the 6-digit sign-in code through Brevo, with the same look as the
// invitation. Supabase Auth calls it instead of sending its own email: the
// "Send Email" auth hook (Authentication > Hooks in the dashboard) points
// here, and signs each call with the hook's secret.
//
// Secrets: BREVO_API_KEY (see _shared/email.ts) and SEND_EMAIL_HOOK_SECRET,
// the secret the dashboard shows for the hook ("v1,whsec_...").

import { createClient } from "jsr:@supabase/supabase-js@2";
import { Webhook } from "npm:standardwebhooks@1.0.0";
import { type CodeEmail, send } from "../_shared/email.ts";

/** The parts of the hook's payload used here. */
type Payload = {
  user: { id: string; email: string; new_email?: string; user_metadata?: { locale?: string } };
  email_data: { token: string; token_new?: string; email_action_type: string };
};

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (request) => {
  const secret = Deno.env.get("SEND_EMAIL_HOOK_SECRET");
  if (!secret) return failure("SEND_EMAIL_HOOK_SECRET is not set");

  let payload: Payload;
  try {
    const body = await request.text();
    payload = new Webhook(secret.replace("v1,whsec_", "")).verify(body, Object.fromEntries(request.headers)) as Payload;
  } catch {
    return failure("Invalid signature", 401);
  }

  const { user, email_data: data } = payload;
  const words = (await locale(user)) === "fr" ? fr : en;
  try {
    if (data.email_action_type === "email_change" && user.new_email) {
      // The new address gets token_new; the current one gets token when
      // both must confirm.
      await send(user.new_email, words.email(data.token_new || data.token));
      if (data.token_new && data.token) await send(user.email, words.email(data.token));
    } else {
      await send(user.email, words.email(data.token));
    }
  } catch (e) {
    console.error(e);
    return failure(String(e));
  }
  return Response.json({});
});

/** The app's language at sign-up, else the one of the person's latest phone. */
async function locale(user: Payload["user"]): Promise<string> {
  const chosen = user.user_metadata?.locale;
  if (chosen === "fr" || chosen === "en") return chosen;
  const { data } = await supabase.from("device_tokens").select("locale").eq("user_id", user.id)
    .order("updated_at", { ascending: false }).limit(1).maybeSingle();
  return data?.locale === "en" ? "en" : "fr";
}

/** Auth shows [message] in its logs and tells the app the email failed. */
function failure(message: string, status = 500): Response {
  return Response.json({ error: { http_code: status, message } }, { status });
}

// ---------------------------------------------------------------------------
// Wording
// ---------------------------------------------------------------------------

type Words = { email: (code: string) => CodeEmail };

const fr: Words = {
  email: (code) => ({
    lang: "fr",
    subject: `${code} est ton code Picnote`,
    title: "Ton code de connexion.",
    intro: "Saisis ce code dans Picnote pour te connecter :",
    code,
    note: "Ce code est valable 1 heure.",
    footer: "Tu n’as pas demandé ce code ? Ignore simplement cet e-mail : personne ne peut se connecter sans lui.",
  }),
};

const en: Words = {
  email: (code) => ({
    lang: "en",
    subject: `${code} is your Picnote code`,
    title: "Your sign-in code.",
    intro: "Enter this code in Picnote to sign in:",
    code,
    note: "This code is valid for 1 hour.",
    footer: "Didn’t ask for this code? Just ignore this email: no one can sign in without it.",
  }),
};
