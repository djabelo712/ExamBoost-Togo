// app/api/beta-signup/route.ts
// POST /api/beta-signup
// Body: { email: string, role: 'eleve' | 'enseignant' | 'directeur' | 'autre' }
// Persists to data/signups.json (file-based storage for the beta landing).
// Responses:
//   200 { ok: true, message: "Merci !" }
//   400 { error: "Email invalide" }
//   409 { error: "Email déjà inscrit" }
//   500 { error: "Erreur serveur" }
import { NextResponse } from "next/server";
import { promises as fs } from "node:fs";
import path from "node:path";
import { betaSignupSchema, type BetaRole } from "@/lib/validators";

const DATA_DIR = path.join(process.cwd(), "data");
const SIGNUPS_FILE = path.join(DATA_DIR, "signups.json");

interface SignupEntry {
  email: string;
  role: BetaRole;
  date: string;
}

// Ensures data dir + file exist. Safe to call on every request.
async function ensureStore(): Promise<void> {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try {
    await fs.access(SIGNUPS_FILE);
  } catch {
    await fs.writeFile(SIGNUPS_FILE, "[]", "utf8");
  }
}

async function readSignups(): Promise<SignupEntry[]> {
  await ensureStore();
  const raw = await fs.readFile(SIGNUPS_FILE, "utf8");
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed as SignupEntry[];
  } catch {
    return [];
  }
}

async function writeSignups(entries: SignupEntry[]): Promise<void> {
  await ensureStore();
  // Atomic write via temp file + rename (best effort on POSIX / Vercel tmp).
  const tmp = `${SIGNUPS_FILE}.tmp`;
  await fs.writeFile(tmp, JSON.stringify(entries, null, 2), "utf8");
  await fs.rename(tmp, SIGNUPS_FILE);
}

// Allow long-running requests (file I/O) on serverless too.
export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST(request: Request): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "JSON invalide" },
      { status: 400 }
    );
  }

  const parsed = betaSignupSchema.safeParse(body);
  if (!parsed.success) {
    const firstError = parsed.error.issues[0];
    return NextResponse.json(
      { error: firstError?.message ?? "Email invalide" },
      { status: 400 }
    );
  }

  const { email, role } = parsed.data;

  try {
    const entries = await readSignups();
    const exists = entries.some(
      (e) => e.email.toLowerCase() === email.toLowerCase()
    );
    if (exists) {
      return NextResponse.json(
        { error: "Email déjà inscrit" },
        { status: 409 }
      );
    }

    const newEntry: SignupEntry = {
      email,
      role,
      date: new Date().toISOString(),
    };
    entries.push(newEntry);
    await writeSignups(entries);

    return NextResponse.json(
      { ok: true, message: "Merci !" },
      {
        status: 200,
        headers: { "Cache-Control": "no-store" },
      }
    );
  } catch (err) {
    console.error("[beta-signup] persistence error:", err);
    return NextResponse.json(
      { error: "Erreur serveur" },
      { status: 500 }
    );
  }
}

// Optional: GET endpoint for quick health check / debugging.
export async function GET(): Promise<NextResponse> {
  try {
    const entries = await readSignups();
    return NextResponse.json(
      { count: entries.length },
      { headers: { "Cache-Control": "no-store" } }
    );
  } catch {
    return NextResponse.json({ count: 0 });
  }
}
