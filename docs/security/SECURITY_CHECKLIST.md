# Security Checklist — ExamBoost Togo Backend

- **Date** : 2 juillet 2026
- **Auteur** : Agent BY
- **Usage** : a appliquer a chaque nouvelle PR backend, a chaque nouvel endpoint, a chaque mise en production. Cases a cocher (literalement `[ ]` dans le source Markdown) pour revue en equipe.

> Reference : OWASP Top 10 2021 + Loi n° 2019-014 (Togo). Voir aussi `OWASP_AUDIT_REPORT.md` et `SECURITY_FIXES.md`.

---

## 1. Injection (A03:2021)

- [ ] Toutes les requetes DB utilisent l'ORM SQLAlchemy 2.x (`select(...).where(...)`), jamais de concatenation de chaine SQL.
- [ ] Aucun appel a `db.execute(text("... " + user_input))`. Si `text()` est inévitable, les parametres sont lies (`text("... :x").bindparams(x=user_input)`).
- [ ] Aucun `eval`, `exec`, `os.system`, `subprocess.call(shell=True)` sur des donnees utilisateur.
- [ ] Aucun `pickle.loads` / `marshal.loads` / `yaml.load` (sans `Loader=SafeLoader`) sur des donnees utilisateur.
- [ ] Les uploads de fichiers sont valides (type MIME + extension + taille max, cf. F-05).

## 2. Authentification (A07:2021)

- [ ] `SECRET_KEY` provient d'une variable d'environnement (jamais en dur dans le code).
- [ ] Le validateur `SECRET_KEY` rejette le demarrage en prod si la valeur par defaut est utilisee (F-01).
- [ ] `ACCESS_TOKEN_EXPIRE_MINUTES` <= 1440 (24 h). Refresh token prevu pour les sessions longues.
- [ ] Mot de passe : `min_length=8`, pattern complexe, rejet des mots de passe communs (F-03).
- [ ] Mots de passe hashe avec bcrypt (cout >= 12). Jamais stockes en clair, jamais loggues.
- [ ] `password_hash` n'apparait jamais dans un schema de sortie (`UserOut`, `Token`, etc.).
- [ ] Rate limiting actif sur `/auth/login` et `/auth/register` (10/min, F-02).
- [ ] Messages d'erreur de login / register generiques (anti-enumeration, F-04).
- [ ] Endpoint `/auth/logout` (ou denylist JWT) prevu.
- [ ] JWT decode avec `algorithms=[...]` explicite (jamais `algorithms=None`).
- [ ] Claims JWT minimises : `sub`, `exp`, `iat`, `type`. Pas d'email en clair (F-03-low).

## 3. Donnees sensibles (A02:2021)

- [ ] HTTPS force en prod (middleware `security_headers.py` actif, HSTS pose).
- [ ] Base de donnees chiffree au repos (volume chiffre Railway/Render ou SQLCipher pour SQLite).
- [ ] Aucun secret (cle API, mot de passe DB, DSN) dans le code source — tout via env vars.
- [ ] `.env` est dans `.gitignore`. Aucun `.env` commité.
- [ ] Logs ne contiennent jamais : mot de passe, JWT complet, numero de carte, email en clair (preferer hash ou masquage `a***@example.com`).
- [ ] Sauvegardes DB chiffrees et stockees dans une region differente.

## 4. Access control (A01:2021)

- [ ] Chaque endpoint qui manipule des donnees utilisateur exige `Depends(get_current_user)`.
- [ ] Aucun endpoint n'accepte un `user_id` path/body param sans verifier `current_user.id == user_id` ou `current_user.is_admin`.
- [ ] Les endpoints admin utilisent `Depends(get_admin_user)`.
- [ ] Les endpoints enseignant (classroom) utilisent `Depends(get_teacher_user)` (a creer).
- [ ] Verification d'appartenance sur toutes les ressources (`ReviewCard.user_id`, `Response.user_id`, `Simulation.user_id`).
- [ ] Les codes de session classroom ont une entropie >= 8 caracteres alphanumeriques.
- [ ] Rate limiting sur les endpoints sensibles (auth, admin, classroom create).
- [ ] Aucun endpoint de debug (`/classroom`, `/sync/health` detail) exposé sans auth admin.

## 5. Configuration (A05:2021)

- [ ] `CORS_ORIGINS` ne contient jamais `*` en prod (F-14). Liste explicite des domaines.
- [ ] `allow_credentials=True` uniquement si `CORS_ORIGINS` est une liste stricte.
- [ ] `allow_methods` et `allow_headers` restreints au minimum (pas `*`).
- [ ] `DEBUG=false` en prod. `uvicorn --reload` interdit en prod.
- [ ] `/docs`, `/redoc`, `/openapi.json` desactives en prod (F-21).
- [ ] Headers de securite poses par `SecurityHeadersMiddleware` (CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy).
- [ ] `app.debug = False` explicite.
- [ ] Stack traces non renvoyees au client (FastAPI default, mais verifier).
- [ ] Messages d'erreur generiques (pas de `str(e)` dans une reponse JSON, F-15).
- [ ] Limite de taille sur tous les uploads (5 Mo par defaut, F-05).
- [ ] Versionnage des dependances pinnees (`==`), pas de `>=` en prod.

## 6. XSS (A03:2021 — XSS)

- [ ] Backend ne sert jamais de HTML rendu depuis des donnees utilisateur.
- [ ] CSP pose par le middleware (`default-src 'none'` pour API JSON).
- [ ] Messages d'erreur sanitises avant inclusion dans une reponse (`input_validation.sanitize_for_log`).
- [ ] Si un futur client web est ajouté : escaping systematique des sorties (Jinja2 `autoescape=True`).
- [ ] Reponses du tuteur IA traitees comme non-sures (jamais rendues en HTML sans sanitization).

## 7. Deserialisation (A08:2021)

- [ ] Aucun `pickle` / `marshal` / `yaml.load(unsafe=True)`.
- [ ] Tous les payloads JSON sont valides par Pydantic avant traitement.
- [ ] Uploads JSON limites en taille (F-05) et valides champ par champ.
- [ ] Verification d'integrite des dependances en CI (`pip-audit` ou `safety`).

## 8. Composants (A06:2021)

- [ ] `safety check` passe sans alerte avant chaque mise en prod.
- [ ] `bandit -r backend/ -ll` passe sans alerte avant chaque mise en prod.
- [ ] Dependances critique (auth, crypto, parsing) suivies en dependabot / Renovate.
- [ ] `python-jose` >= 3.4.0 (F-16) ou migration vers `PyJWT`.
- [ ] `python-multipart` >= 0.0.18 (F-17).
- [ ] `passlib` retire du `requirements.txt` des que le fallback n'est plus necessaire.

## 9. Logging & monitoring (A09:2021)

- [ ] Tous les evenements d'auth sont logges (login success/failure, register, token invalide — F-18).
- [ ] Tous les 401/403 sont logges avec IP + user_id (si connu) + endpoint.
- [ ] Toutes les actions admin sont persistees dans `admin_action_logs` (deja en place).
- [ ] Aucun `print()` dans le code (remplaces par `logging`, F-19).
- [ ] Configuration logging centralisee (`logging.basicConfig` ou dictConfig au demarrage).
- [ ] Niveau de log `INFO` en prod, `DEBUG` en dev uniquement.
- [ ] Sentry (ou equivalent) branche avec DSN depuis env var.
- [ ] Healthcheck `/health` ne fuite aucune info interne (uniquement `{"status": "ok"}`).
- [ ] Alerting sur : pics de 401, pics de 429, erreurs 5xx, logs d'audit anormaux.

## 10. Conformite Loi 2019-014 (Togo)

- [ ] Ecran de consentement CGU dans l'app Flutter (avec version + date + IP traces en base).
- [ ] Politique de confidentialite accessible depuis l'app (URL stable).
- [ ] Mention de la declaration ARP (numero a obtenir) dans les CGU.
- [ ] Contact DPO (`dpo@examboost.tg`) visible.
- [ ] Endpoint `/users/me/export` (droit d'acces, article 16) — renvoie JSON de toutes les donnees.
- [ ] Endpoint `/users/me` en PUT (droit de rectification, article 17).
- [ ] Endpoint `/users/me` en DELETE (droit a l'effacement, article 18) — soft delete + purge async apres 30 j.
- [ ] Script de purge des comptes inactifs > 3 ans (tache planifiee).
- [ ] Anonymisation des `responses` apres 5 ans (agregats conserves pour calibration IRT/ML).
- [ ] Tracage du consentement dans `consent_events(user_id, version, timestamp, ip)`.
- [ ] En cas de violation de donnees : procedure de notification ARP sous 72 h (article 22).
- [ ] Contrats de sous-traitance (Railway/Render, Anthropic) signes avec clauses donnees perso.

---

## Revue de code — Checklist express (5 min par PR)

Pour chaque nouvelle route ou modification de route existante, repondre :

1. L'endpoint exige-t-il une authentification ? Si oui, laquelle (`get_current_user`, `get_admin_user`, `get_teacher_user`) ?
2. Si l'endpoint prend un `user_id` en parametre : est-il verifie contre le JWT ?
3. L'entree est-elle validee par Pydantic avec contraintes (`min_length`, `pattern`, `ge`/`le`) ?
4. La sortie exclut-elle `password_hash` et tout champ sensible ?
5. Y a-t-il un rate limiting sur l'endpoint (si sensible) ?
6. Les erreurs renvoyent-elles un message generique (pas de `str(e)`) ?
7. Y a-t-il un log d'audit si l'action est sensible (auth, admin, sync) ?
8. Aucune concatenation SQL, aucun `eval`, aucun `pickle` ?
9. CORS / headers / secrets : la config est-elle toujours valide en prod ?
10. La dependance ajoutee est-elle pingee et verifiee par `safety` ?

Si une seule reponse est "non" ou "je ne sais pas", bloquer la PR.

---

## Commandes utiles

```bash
# Lancer bandit (SAST)
bandit -r backend/ -ll -x backend/tests,backend/.venv

# Lancer safety (SCA)
safety check --full-report

# Verifier les headers d'une route
curl -sI https://api.examboost.tg/health | grep -iE "content-security|strict-transport|x-frame|x-content|referrer"

# Tester un JWT expire
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login -d '{"email":"x@y.z","password":"12345678"}' -H "Content-Type: application/json" | jq -r .access_token)
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8000/auth/me

# Tester le rate limiting
for i in $(seq 1 15); do curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8000/auth/login -d '{"email":"x@y.z","password":"x"}' -H "Content-Type: application/json"; done
# Doit renvoyer 401 x fois puis 429
```

---

## Reference rapide — OWASP Top 10 2021

| ID  | Nom                                              | Couvert dans |
|-----|--------------------------------------------------|--------------|
| A01 | Broken Access Control                            | Section 4    |
| A02 | Cryptographic Failures                           | Section 3    |
| A03 | Injection (inclut XSS)                           | Sections 1, 6|
| A04 | Insecure Design                                  | Transverse   |
| A05 | Security Misconfiguration (inclut XXE)           | Section 5    |
| A06 | Vulnerable and Outdated Components               | Section 8    |
| A07 | Identification and Authentication Failures       | Section 2    |
| A08 | Software and Data Integrity Failures             | Section 7    |
| A09 | Security Logging and Monitoring Failures         | Section 9    |
| A10 | Server-Side Request Forgery (SSRF)               | N/A (pas de fetch d'URL utilisateur dans le perimetre audite) |

> A04 (Insecure Design) et A10 (SSRF) n'ont pas de section dediee dans cette checklist car :
> - A04 est transverse et couvert par l'ensemble de la checklist.
> - A10 (SSRF) n'est pas applicable : aucun endpoint ne prend une URL en entree et ne la fetch cote serveur. A surveiller si un endpoint d'import d'image ou de webhook est ajoute.
