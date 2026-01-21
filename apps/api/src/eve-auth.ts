import type { Request, Response, NextFunction } from 'express';
import { createRemoteJWKSet, jwtVerify, decodeJwt } from 'jose';

export type EveUser = {
  user_id: string;
  org_id?: string;
  scopes?: string[];
};

export type EveRequest = Request & { eveUser?: EveUser };

const jwksUrl = process.env.EVE_JWKS_URL;
const jwks = jwksUrl ? createRemoteJWKSet(new URL(jwksUrl)) : null;

function getBearerToken(header?: string): string | null {
  if (!header) return null;
  const [scheme, token] = header.split(' ');
  if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) {
    return null;
  }
  return token;
}

function extractUser(claims: Record<string, unknown>): EveUser | null {
  const userId = typeof claims.user_id === 'string'
    ? claims.user_id
    : typeof claims.sub === 'string'
      ? claims.sub
      : null;
  if (!userId) return null;

  const orgId = typeof claims.org_id === 'string'
    ? claims.org_id
    : typeof claims.org === 'string'
      ? claims.org
      : undefined;
  const scopes = Array.isArray(claims.scopes) ? claims.scopes.filter((scope) => typeof scope === 'string') : undefined;

  return { user_id: userId, org_id: orgId, scopes };
}

export async function eveAuthMiddleware(req: EveRequest, res: Response, next: NextFunction) {
  const authHeader = typeof req.headers.authorization === 'string' ? req.headers.authorization : undefined;
  const token = getBearerToken(authHeader);
  if (!token) {
    return next();
  }

  try {
    if (jwks) {
      const verified = await jwtVerify(token, jwks);
      req.eveUser = extractUser(verified.payload as Record<string, unknown>) ?? undefined;
      return next();
    }

    // No JWKS configured; fall back to decoding without verification for local/demo usage.
    const decoded = decodeJwt(token);
    req.eveUser = extractUser(decoded as Record<string, unknown>) ?? undefined;
    return next();
  } catch (error) {
    res.status(401).json({ error: 'invalid_auth', message: 'Invalid authorization token.' });
  }
}
