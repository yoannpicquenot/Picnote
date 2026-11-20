// What every Picnote email shares: the layout (colors of picnote.cc), the
// code block, and sending through Brevo from noreply@picnote.cc.
//
// Secret: BREVO_API_KEY, a Brevo API key allowed to send transactional
// email (Brevo > SMTP & API > API keys). The sender must be verified there.

const sender = { name: "Picnote", email: "noreply@picnote.cc" };

/** An email with a code in it: a title, a line, the code, then what to do. */
export type CodeEmail = {
  lang: string;
  subject: string;
  title: string;
  intro: string;
  code: string;
  /** Numbered steps under the code, if any. */
  steps?: string[];
  /** Small print under the steps (how long the code lasts). */
  note: string;
  footer: string;
};

export type Recipient = { email: string; name?: string };

/** Sends [email] to [to]. Throws with Brevo's reason when it refuses. */
export async function send(to: string, email: CodeEmail, replyTo?: Recipient): Promise<void> {
  const apiKey = Deno.env.get("BREVO_API_KEY");
  if (!apiKey) throw new Error("BREVO_API_KEY is not set");
  const response = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: { "api-key": apiKey, "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({
      sender,
      to: [{ email: to }],
      ...(replyTo ? { replyTo } : {}),
      subject: email.subject,
      htmlContent: html(email),
      textContent: text(email),
    }),
  });
  if (!response.ok) throw new Error(`Brevo refused the email (${response.status}): ${await response.text()}`);
}

function text(e: CodeEmail): string {
  const steps = e.steps?.length ? `${e.steps.map((s, i) => `${i + 1}. ${s}`).join("\n")}\n\n` : "";
  return `${e.title}\n\n${e.intro}\n\n${e.code}\n\n${steps}${e.note}\n\n${e.footer}\n`;
}

function html(e: CodeEmail): string {
  const steps = e.steps?.length
    ? `<ol style="margin:0 0 20px;padding-left:20px;font-size:16px;line-height:1.5">${
      e.steps.map((s) => `<li style="margin:0 0 6px">${escape(s)}</li>`).join("")
    }</ol>`
    : "";
  return `<!doctype html>
<html lang="${e.lang}">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="margin:0;padding:0;background:#fef7ef;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#171311">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#fef7ef">
    <tr><td align="center" style="padding:32px 16px">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#fffdfa;border:1px solid #e2dddc;border-radius:20px">
        <tr><td style="padding:32px 28px">
          <p style="margin:0 0 24px;font-size:14px;font-weight:700;letter-spacing:1px;color:#af5c3c">PICNOTE.</p>
          <h1 style="margin:0 0 16px;font-size:24px;line-height:1.25;font-weight:700">${escape(e.title)}</h1>
          <p style="margin:0 0 20px;font-size:16px;line-height:1.5">${escape(e.intro)}</p>
          <p style="margin:0 0 24px;padding:16px;background:#fce0c4;border-radius:14px;text-align:center;font-family:Menlo,Consolas,monospace;font-size:32px;font-weight:700;letter-spacing:8px;color:#9e4e30">${escape(e.code)}</p>
          ${steps}
          <p style="margin:0 0 24px;font-size:14px;color:#7b6c65">${escape(e.note)}</p>
          <p style="margin:0;font-size:13px;color:#7b6c65">${escape(e.footer)}</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function escape(s: string): string {
  return s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}
