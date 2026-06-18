# THEETIFY - Entry Test Prep App (Version 1)

An AI-powered study platform for students preparing for entrance exams in Pakistan
(NUST NET, SAT, LSAT, NTS, GIKI, and more).

---

## What this app does (in simple words)

- A student logs in.
- They pick an exam (for example: NUST NET).
- They pick a topic (for example: Trigonometry).
- The app shows them, for that topic:
  - An interactive HTML lesson
  - Deep, in-depth notes
  - Short "3-hour crash revision" notes
  - A quiz to test themselves
  - An AI teacher they can chat with (study questions only)
  - Video lectures (YouTube + AI-generated slideshow lectures)
- YOU (the owner) only type a TOPIC NAME in the Admin Dashboard and press
  "Generate". The app uses AI to create ALL of the above automatically.

---

## The technology we use (and why it is cheap/free)

| Part             | Tool we use         | Cost to start |
|------------------|---------------------|---------------|
| App (frontend)   | Flutter Web         | Free          |
| Login + Database | Supabase            | Free tier     |
| AI teacher       | Groq (for testing)  | Free tier     |
| Hosting          | GitLab Pages        | Free          |
| Payments (intl)  | Stripe              | Free to setup |
| Payments (PK)    | JazzCash            | Free to setup |

Later, before going live, you can swap the free Groq AI key for a paid Claude key
by changing ONE value. No code rewrite needed.

---

## IMPORTANT: Secrets / API keys (read this!)

Steps:
1. Make a copy of `.env.example` and rename the copy to `.env`.
2. Open `.env` and paste your real keys next to each name.
3. Save. Done. The app reads them automatically.

---

## How to run this on your computer (using VS Code)

Detailed click-by-click steps are in `docs/SETUP_GUIDE.md`.

---

## Project status

This is the initial scaffold. Features are being built step by step.
See `docs/ROADMAP.md` for what is done and what is coming next.
