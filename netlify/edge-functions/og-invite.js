// ═══════════════════════════════════════════════════════════════════
// OG INVITE — Netlify Edge Function
// ═══════════════════════════════════════════════════════════════════
// Intercepts social media crawlers hitting invite URLs and serves
// dynamic HTML with Open Graph meta tags for rich link previews.
// Real users pass through to the Flutter SPA unchanged.
//
// URLs handled:
//   /invite/{CODE}              → inviter's library preview
//   /invite/{CODE}/{characterId} → specific character preview
//
// Deploy: Copy to netlify/edge-functions/og-invite.js
// Config: Add to netlify.toml [[edge_functions]] block
// ═══════════════════════════════════════════════════════════════════

// Known social media / link preview crawler user agents
const CRAWLER_PATTERNS = [
  'facebookexternalhit',
  'Facebot',
  'Twitterbot',
  'WhatsApp',
  'Slackbot',
  'Discordbot',
  'LinkedInBot',
  'Googlebot',
  'TelegramBot',
  'Applebot',        // iMessage link previews
  'iMessageBot',
  'Pinterestbot',
  'redditbot',
  'Embedly',
  'Quora Link Preview',
  'Showyoubot',
  'outbrain',
  'vkShare',
];

// Character metadata (matches oga_character.dart hardcoded data)
const CHARACTERS = {
  ryu: {
    name: 'Ryu',
    title: 'THE ETERNAL WARRIOR',
    description: 'A disciplined martial artist seeking true strength. Master of Ansatsuken with powerful strikes and precise technique.',
    ip: 'Street Fighter',
    rarity: 'Legendary',
    image: 'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/characters/heroes/ryu.png',
  },
  vegeta: {
    name: 'Vegeta',
    title: 'THE SAIYAN PRINCE',
    description: 'The Prince of all Saiyans. Royal pride with devastating power, constantly pushing beyond his limits.',
    ip: 'Dragon Ball Z',
    rarity: 'Legendary',
    image: 'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/characters/heroes/vegeta.png',
  },
  guggimon: {
    name: 'Guggimon',
    title: 'THE FASHION HORROR',
    description: 'A fashion-obsessed horror bunny from the metaverse. Iconic, unpredictable, and always dripping in style.',
    ip: 'Superplastic',
    rarity: 'Epic',
    image: 'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/characters/heroes/guggimon.png',
  },
};

// Brand constants
const BRAND = {
  siteName: 'OGA — Ownable Game Assets',
  defaultTitle: 'Join OGA — One Character. Infinite Worlds.',
  defaultDescription: 'Collect, trade, and play with unique heroes across multiple games. Your characters persist forever.',
  defaultImage: 'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-filles/og-link.png',  // Fallback OG image
  themeColor: '#39FF14',
  baseUrl: 'https://oga.oneearthrising.com',
};

function isCrawler(userAgent) {
  if (!userAgent) return false;
  const ua = userAgent.toLowerCase();
  return CRAWLER_PATTERNS.some(pattern => ua.includes(pattern.toLowerCase()));
}

function buildOgHtml({ title, description, image, url, characterName }) {
  const fullImageUrl = image.startsWith('http') ? image : `${BRAND.baseUrl}${image}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${title}</title>

  <!-- Open Graph -->
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="${BRAND.siteName}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:image" content="${fullImageUrl}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="${url}">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${fullImageUrl}">

  <!-- Theme -->
  <meta name="theme-color" content="${BRAND.themeColor}">

  <!-- Redirect real browsers that somehow got here -->
  <meta http-equiv="refresh" content="0;url=${url}">
</head>
<body style="background:#000;color:#fff;font-family:Helvetica,Arial,sans-serif;text-align:center;padding:40px;">
  <h1 style="color:#39FF14;">${characterName ? `Check out ${characterName}` : 'You\'ve been invited to OGA'}</h1>
  <p>${description}</p>
  <p><a href="${url}" style="color:#39FF14;">Open in OGA →</a></p>
</body>
</html>`;
}

export default async function handler(request, context) {
  const userAgent = request.headers.get('user-agent') || '';

  // Only intercept crawlers — real users get the SPA
  if (!isCrawler(userAgent)) {
    return context.next();
  }

  const url = new URL(request.url);
  // Edge function runs on the actual path, not the hash fragment.
  // Netlify config routes /#/invite/* to this function via path rewrite.
  // Parse: /invite/OGA-XXXX or /invite/OGA-XXXX/ryu
  const pathParts = url.pathname.split('/').filter(Boolean);
  // pathParts: ['invite', 'OGA-XXXX'] or ['invite', 'OGA-XXXX', 'ryu']

  if (pathParts[0] !== 'invite' || pathParts.length < 2) {
    return context.next();
  }

  const inviteCode = pathParts[1];
  const characterId = pathParts.length >= 3 ? pathParts[2] : null;
  const character = characterId ? CHARACTERS[characterId.toLowerCase()] : null;

  let ogData;

  if (character) {
    // Character-specific OG
    ogData = {
      title: `${character.name} — ${character.title} | OGA`,
      description: `${character.description} View ${character.name} in the OGA Multigameverse and see them across ${character.ip} and more.`,
      image: character.image,
      url: `${BRAND.baseUrl}/#/invite/${inviteCode}/${characterId}`,
      characterName: character.name,
    };
  } else {
    // Library-level OG
    ogData = {
      title: BRAND.defaultTitle,
      description: BRAND.defaultDescription,
      image: BRAND.defaultImage,
      url: `${BRAND.baseUrl}/#/invite/${inviteCode}`,
      characterName: null,
    };
  }

  const html = buildOgHtml(ogData);

  return new Response(html, {
    status: 200,
    headers: {
      'Content-Type': 'text/html;charset=utf-8',
      'Cache-Control': 'public, max-age=3600', // Cache for 1 hour
    },
  });
}
