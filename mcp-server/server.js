// A tiny MCP server. It gives the SpendWise agent ONE new skill:
// converting naira to US dollars. The app never ships this code; it just
// asks the server "what can you do?" and hands the answer to Gemini.

import express from 'express';
import { pathToFileURL } from 'node:url';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { z } from 'zod';

// A fixed demo rate, so the workshop never depends on a third-party API.
// Set LIVE_RATES=true to look up today's rate instead (falls back to the fixed one).
const FIXED_NGN_PER_USD = Number(process.env.NGN_PER_USD ?? 1500);

async function currentRate() {
  if (process.env.LIVE_RATES !== 'true') return FIXED_NGN_PER_USD;
  try {
    const res = await fetch('https://open.er-api.com/v6/latest/USD', { signal: AbortSignal.timeout(3000) });
    const rate = (await res.json()).rates?.NGN;
    return Number.isFinite(rate) ? rate : FIXED_NGN_PER_USD;
  } catch {
    return FIXED_NGN_PER_USD;
  }
}

/** The maths. Gemini never does this; the server does. */
export function nairaToUsd(amount, ngnPerUsd) {
  return Math.round((amount / ngnPerUsd) * 100) / 100;
}

/** Each request gets its own small server: no sessions, nothing to clean up. */
function buildServer() {
  const server = new McpServer({ name: 'spendwise-fx', version: '1.0.0' });

  server.registerTool(
    'convert_naira_to_usd',
    {
      title: 'Naira to US dollars',
      description: 'Convert an amount in Nigerian naira (NGN) to US dollars (USD) at the current rate.',
      inputSchema: { amount: z.number().positive().describe('Amount in naira, for example 4500') },
    },
    async ({ amount }) => {
      const rate = await currentRate();
      const usd = nairaToUsd(amount, rate);
      return {
        content: [{ type: 'text', text: `₦${amount.toLocaleString('en-US')} is about US$${usd.toFixed(2)} (at ₦${rate} to the dollar).` }],
      };
    },
  );

  // ── DEMO: to show "new skill, no app update", paste a second tool here,
  //    redeploy, and ask the app something new. See README.md. ──

  return server;
}

export function createApp() {
  const app = express();
  app.use(express.json());

  // Chrome (Flutter web) refuses to call a server that doesn't say it is allowed to.
  app.use((req, res, next) => {
    res.set({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Accept, Mcp-Protocol-Version, Mcp-Session-Id',
      'Access-Control-Expose-Headers': 'Mcp-Session-Id',
    });
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });

  app.get('/', (_req, res) => res.send('SpendWise MCP server is running. The MCP endpoint is POST /mcp.'));

  app.post('/mcp', async (req, res) => {
    const server = buildServer();
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    res.on('close', () => {
      transport.close();
      server.close();
    });
    try {
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      console.error('MCP request failed:', error);
      if (!res.headersSent) {
        res.status(500).json({ jsonrpc: '2.0', error: { code: -32603, message: 'Internal server error' }, id: null });
      }
    }
  });

  // We keep no sessions, so there is no stream to open.
  app.get('/mcp', (_req, res) =>
    res.status(405).json({ jsonrpc: '2.0', error: { code: -32000, message: 'Method not allowed.' }, id: null }),
  );

  return app;
}

// Start listening only when run directly (`node server.js`), not when imported by the tests.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 8080); // Cloud Run sets PORT
  createApp().listen(port, () => console.log(`MCP server listening on :${port}`));
}
