/**
 * Cloudflare Worker entry — thin shell around the testable handler.
 * Deploy: `wrangler deploy` (see server/README.md).
 */
import { handleRequest } from './src/relay.js';

export default {
  fetch(request, env) {
    return handleRequest(request, env, fetch);
  },
};
