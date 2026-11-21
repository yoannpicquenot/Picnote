// Emails the household invitation, with its code, through Brevo. Called
// with {"household_id": ...} by the email_invite trigger each time an
// invite is sent or sent again (see migrations/*invite_email*). The invite
// is claimed first, so calling it again sends nothing more.
//
// Secret: BREVO_API_KEY (see _shared/email.ts).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { type CodeEmail, send } from "../_shared/email.ts";

/** One invite to mail, from claim_invite_email. */
type Invite = {
  email: string;
  code: string;
  inviter_name: string;
  inviter_email: string;
  household_name: string;
  locale: string;
};

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (request) => {
  // Checked before claiming, so nothing is lost while the secret is missing.
  if (!Deno.env.get("BREVO_API_KEY")) return Response.json({ error: "BREVO_API_KEY is not set" }, { status: 500 });
  const body = await request.json().catch(() => ({}));
  const householdId = body?.household_id;
  if (typeof householdId !== "string") return Response.json({ error: "household_id is missing" }, { status: 400 });

  const { data, error } = await supabase.rpc("claim_invite_email", { hid: householdId });
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const invite = ((data ?? []) as Invite[])[0];
  // An invite given by hand, as a code, has no address to mail.
  if (invite == null || !invite.email.trim()) return Response.json({ sent: 0 });

  const words = invite.locale === "fr" ? fr : en;
  const inviter = invite.inviter_name.trim() || words.someone;
  const household = invite.household_name.trim() || "Picnote";
  try {
    await send(
      invite.email,
      words.email(inviter, household, invite.code),
      invite.inviter_email ? { email: invite.inviter_email, name: inviter } : undefined,
    );
  } catch (e) {
    console.error(e);
    // Lets the next resend (or a retry of this call) try again.
    await supabase.from("invites").update({ emailed_at: null }).eq("household_id", householdId);
    return Response.json({ error: String(e) }, { status: 502 });
  }
  return Response.json({ sent: 1 });
});

// ---------------------------------------------------------------------------
// Wording
// ---------------------------------------------------------------------------

type Words = { someone: string; email: (who: string, household: string, code: string) => CodeEmail };

const fr: Words = {
  someone: "Quelqu’un",
  email: (who, household, code) => ({
    lang: "fr",
    subject: `${who} t’invite à rejoindre ${household} sur Picnote`,
    title: `${who} t’invite à rejoindre ${household}.`,
    intro: "Pour partager vos listes et vos notes, voici ton code d’invitation :",
    code,
    steps: [
      "Installe Picnote et connecte-toi avec cette adresse e-mail.",
      "Choisis « Rejoindre un foyer ».",
      "Saisis le code ci-dessus.",
    ],
    note: "Ce code est valable 7 jours.",
    footer: "Tu n’attendais pas cette invitation ? Ignore simplement cet e-mail.",
  }),
};

const en: Words = {
  someone: "Someone",
  email: (who, household, code) => ({
    lang: "en",
    subject: `${who} invites you to join ${household} on Picnote`,
    title: `${who} invites you to join ${household}.`,
    intro: "To share your lists and notes, here is your invitation code:",
    code,
    steps: [
      "Install Picnote and sign in with this email address.",
      "Choose “Join a household”.",
      "Enter the code above.",
    ],
    note: "This code is valid for 7 days.",
    footer: "Weren’t expecting this invitation? Just ignore this email.",
  }),
};
