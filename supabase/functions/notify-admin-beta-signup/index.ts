import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Replace with your actual verified sender email in Mailtrap
const SENDER_EMAIL = "hello@oneearthrising.com"; 
const ADMIN_EMAIL = "jan@oneearthrising.com"; 
const LOGO_URL = "https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-files/oga_logo.png";
const DISCORD_LINK = "https://discord.gg/G9mbqyNhYD";

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const newProfile = payload.record;

    if (!newProfile || !newProfile.email) {
      return new Response("No profile or email found in payload", { status: 400 });
    }

    const newTesterEmail = newProfile.email;
    const mailtrapToken = Deno.env.get("MAILTRAP_API_TOKEN");
    
    if (!mailtrapToken) {
      throw new Error("MAILTRAP_API_TOKEN environment variable is missing.");
    }

    // ─── 1. SEND ADMIN NOTIFICATION (To You) ───
    const adminRes = await fetch("https://send.api.mailtrap.io/api/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${mailtrapToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: { email: SENDER_EMAIL, name: "OGA Command Center" },
        to: [{ email: ADMIN_EMAIL }],
        subject: "Action Required: New Beta Tester Request",
        html: `
          <div style="font-family: sans-serif; color: #121212;">
            <h2>New Beta Tester Request</h2>
            <p>A new user has just signed up and is waiting for beta access approval.</p>
            <p><strong>Email:</strong> ${newTesterEmail}</p>
            <br/>
            <a href="https://oga.oneearthrising.com/admin" style="background-color: #39FF14; color: #000; padding: 10px 20px; text-decoration: none; font-weight: bold; border-radius: 5px;">Go to Command Center</a>
          </div>
        `,
      }),
    });

    if (!adminRes.ok) console.error("Admin email failed:", await adminRes.text());

    // ─── 2. SEND WELCOME EMAIL (To the User) ───
    const userHtml = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>Beta Access Pending - OGA</title>
        </head>
    <body style="margin: 0; padding: 0; background-color: #0a0a0a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #0a0a0a;">
            <tr>
                <td style="padding: 40px 20px;">
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: #1a1a1a; border-radius: 16px; overflow: hidden;">
                        
                        <tr>
                            <td style="padding: 0; position: relative;">
                                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                    <tr>
                                        <td style="height: 4px; background: linear-gradient(90deg, #00ff00 0%, #00cc00 100%);"></td>
                                    </tr>
                                </table>
                                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                    <tr>
                                        <td style="padding: 48px 40px 40px; text-align: center; background-color: #1a1a1a;">
                                            <img src="${LOGO_URL}" alt="OGA Logo" width="120" style="display: block; margin: 0 auto; max-width: 120px; height: auto;">
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
    
                        <tr>
                            <td style="padding: 0 40px 48px;">
                                <h1 style="margin: 0 0 24px; font-size: 32px; font-weight: 900; color: #ffffff; line-height: 1.2; text-align: center; letter-spacing: 1px;">
                                    BETA ACCESS PENDING
                                </h1>
                                
                                <p style="margin: 0 0 16px; font-size: 16px; line-height: 1.6; color: #b0b0b0; text-align: center;">
                                    Your account has been created successfully! 
                                </p>
                                <p style="margin: 0 0 32px; font-size: 16px; line-height: 1.6; color: #b0b0b0; text-align: center;">
                                    OGA is currently in closed beta, so your dashboard access requires approval. We will notify you the moment your access is granted. In the meantime, come hang out with the community!
                                </p>
    
                                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                    <tr>
                                        <td style="text-align: center; padding: 0 0 32px;">
                                            <a href="${DISCORD_LINK}" style="display: inline-block; padding: 18px 56px; background-color: #00ff00; color: #000000; text-decoration: none; font-weight: 800; font-size: 14px; border-radius: 8px; letter-spacing: 1px; transition: all 0.3s; mso-hide: all;">
                                                JOIN OUR DISCORD
                                            </a>
                                            </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
    
                        <tr>
                            <td style="padding: 32px 40px; background-color: #0f0f0f; border-top: 1px solid #2a2a2a;">
                                <p style="margin: 0 0 12px; font-size: 13px; line-height: 1.6; color: #808080; text-align: center;">
                                    Need help? Contact our support team
                                </p>
                                <p style="margin: 0; font-size: 12px; line-height: 1.6; color: #606060; text-align: center;">
                                    © 2024 OGA. All rights reserved.
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    `;

    const userRes = await fetch("https://send.api.mailtrap.io/api/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${mailtrapToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: { email: SENDER_EMAIL, name: "OGA" },
        to: [{ email: newTesterEmail }],
        subject: "Welcome to the OGA Closed Beta Waitlist!",
        html: userHtml,
      }),
    });

    if (!userRes.ok) console.error("User email failed:", await userRes.text());

    return new Response(JSON.stringify({ success: true, message: "Emails dispatched" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "An unknown error occurred";
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});