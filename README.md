# THEETIFY — AI-Powered Entry Test Prep
-------------------------------------------------------------------------------------------------------------------------------------------------------------

This experiment is now complete. The goal was never to ship a product. It was to answer a question honestly, by actually doing the thing rather than theorising about it — taking a real app idea, a real AI assistant, a real deployment pipeline, and a real non-technical operator, and seeing what happens when you push that combination as far as it will go. What happened is documented across every post in this series. The app got surprisingly far. Features that would have taken an experienced developer days to architect were generated, debugged, and deployed in hours. A 10-table database with proper security policies. A student dashboard. An AI tutor. A subscription system. All of it written by a machine responding to text. And then it stopped working, not dramatically, not with a clear error message, but quietly — a blank white screen caused by a single file that ended up in the wrong folder because the person running the commands did not fully understand the environment they were operating in. That is the finding. Not that AI is bad at writing code, because it is genuinely good at it. The finding is that the bottleneck was never the code. It was everything surrounding the code — the environment, the judgment, the ability to verify that what was generated actually matched what was deployed. Those things did not come from the AI. They never do. The experiment set out to test whether AI can replace a web developer. The answer the data gave back was straightforward. Not yet. And the reason is not capability. It is the irreplaceable layer of understanding that sits between a correct piece of code and a working piece of software.

-------------------------------------------------------------------------------------------------------------------------------------------------------------


> A web application that turns a topic name into a complete study package in one click. Built for Pakistani students preparing for **NUST NET, SAT, NTS, GIKI, LSAT, FAST NU, UET, and PIEAS**.

---

## What it does

A student logs in, picks an exam, picks a topic, and gets six things instantly:

| Tab | What the student sees |
|---|---|
| **Lesson** | An interactive HTML lesson with animations |
| **Deep Notes** | Comprehensive in-depth study notes |
| **Crash Notes** | A 3-hour pre-exam revision summary |
| **Quiz** | A 10-question multiple-choice test with instant scoring |
| **AI Teacher** | A live chat tutor locked to exam-relevant questions only |
| **Videos** | YouTube search for that topic |

As the **admin**, you type an exam name and a topic name, press **Generate**, and the AI writes all six pieces automatically. You review them, then press **Publish**. That is the entire workflow.

Students also get a personal **Home Dashboard** with progress tracking, daily streak, bookmarks, weak-area flags from quiz history, an AI-generated study timetable, and a topic search across the entire content library.

---

## Tech stack

| Layer | Tool | Cost |
|---|---|---|
| Frontend | Flutter Web (Dart) | Free |
| Routing | GoRouter | Free |
| Auth + Database | Supabase (PostgreSQL + RLS) | Free tier |
| AI generation + chat | Groq (`llama-3.3-70b`) | Free tier |
| CI/CD + Hosting | GitHub Actions + GitHub Pages | Free |
| Lesson rendering | sandboxed `<iframe>` (dart:html) | — |
| Notes rendering | flutter\_widget\_from\_html | — |

When you are ready to launch commercially, swap `AI_PROVIDER=groq` to `AI_PROVIDER=claude` in your `.env` file. No code changes needed.

---

## Project structure

```
lib/
├── config/         # AppConfig — reads all keys from .env
├── router/         # GoRouter — all URL routes
├── screens/        # One file per screen
│   ├── home_screen.dart
│   ├── auth_screen.dart
│   ├── dashboard_screen.dart
│   ├── exam_list_screen.dart
│   ├── topic_list_screen.dart
│   ├── topic_screen.dart
│   ├── timetable_screen.dart
│   └── admin_screen.dart
├── services/       # All business logic
│   ├── ai_service.dart        # Groq / Claude API calls
│   ├── auth_service.dart      # Login, signup, admin check
│   ├── content_service.dart   # All database reads and writes
│   └── generation_service.dart # Orchestrates the Generate button
├── widgets/        # Reusable UI components
│   ├── ai_teacher_chat.dart
│   ├── html_iframe.dart
│   ├── quiz_view.dart
│   └── videos_view.dart
├── utils/
│   └── markdown.dart  # Pure-Dart markdown → HTML converter
└── theme/
    └── app_theme.dart
```

---

## Database schema (Supabase)

Ten tables, all with Row Level Security enabled:

| Table | Purpose |
|---|---|
| `exams` | Exam names (NUST NET, SAT, etc.) |
| `topics` | Topics under each exam |
| `topic_content` | All AI-generated content for a topic |
| `progress` | Which topics each student has completed |
| `bookmarks` | Student-saved topics |
| `quiz_attempts` | Score history per topic per student |
| `last_viewed` | "Continue where you left off" |
| `student_settings` | Study reminder toggle, daily goal, streak |
| `timetables` | Saved AI study timetable per student |
| `subscriptions` | Active subscription status per student |
| `payment_requests` | Manual payment submissions pending admin approval |

The SQL to create all tables and policies is in `docs/SETUP_GUIDE.md`.

---

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (tested on `3.24.0`)
- [VS Code](https://code.visualstudio.com)
- [Git](https://git-scm.com/downloads)
- A [Supabase](https://supabase.com) project (free)
- A [Groq](https://console.groq.com) API key (free)

### 1. Clone the repository

```bash
git clone https://github.com/mannas632006/THEETIFY-Entry_Test_Prep_App.git
cd THEETIFY-Entry_Test_Prep_App
```

### 2. Add your secret keys

Copy the example file and fill in your real values:

```bash
cp .env.example .env
```

Open `.env` and paste your keys:

```
AI_PROVIDER=groq
GROQ_API_KEY=your_groq_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
CLAUDE_API_KEY=          # leave blank until you switch providers
YOUTUBE_API_KEY=         # optional — enables video search
```

> **Note:** On Flutter Web, `.env` is included in the build output and is readable in the browser. Never put payment secret keys or private server credentials here. See the Security section below.

### 3. Run locally

```bash
flutter pub get
flutter run -d chrome
```

The app opens in Chrome. Changes hot-reload automatically.

### 4. Set up the database

Run the SQL in `docs/SETUP_GUIDE.md` inside your Supabase project's SQL Editor. This creates all tables, enables RLS, and sets the correct policies.

### 5. Deploy

Every push to `main` triggers a GitHub Actions build and deploys to GitHub Pages automatically. No manual step needed.

```bash
git add .
git commit -m "describe what you changed"
git push origin main
```

Check the **Actions** tab on GitHub to monitor the build. Builds take approximately 2 minutes.

---

## Admin dashboard

Navigate to `/admin` (or `/#/admin` on the live site). Only the account with the admin email configured in `AuthService.adminEmail` can access it.

**To publish new content:**

1. Type or select an exam name
2. Type or select a topic name
3. Press **Generate Everything** — the AI writes the lesson, notes, crash notes, quiz, and estimates the study time
4. Review the generated content in the expandable preview cards
5. Press **Publish** to make it live for students

**Maintenance panel:** The admin screen also has a button to backfill estimated study times for older topics that were published before that feature existed.

---

## Security

| Area | Current status |
|---|---|
| Admin route | Protected — email check on load, returns "Access Denied" for all other accounts |
| Database reads | Public for `exams` and `topics`. `topic_content` requires an active subscription (RLS enforced at the database level) |
| Database writes | Restricted to the admin email via Supabase RLS JWT check |
| Per-student data | All tracking tables use `auth.uid()` — users can only read and write their own rows |
| API keys | Currently in the client bundle (Flutter Web limitation). Moving AI calls to Supabase Edge Functions is the correct fix before commercial launch |
| Payment verification | Currently manual (admin approves each submission). Automated webhook verification requires an Edge Function — planned for a future version |

---

## Payments (current implementation)

The app uses a **manual approval flow**:

1. A student hits the paywall and sees your payment number and price
2. They send the money via EasyPaisa and submit the transaction ID through the app
3. The submission appears in the admin dashboard under **Payment Requests**
4. You verify it in your EasyPaisa app and press **Approve**, selecting a subscription duration
5. The student's content access is unlocked immediately

This works without a merchant account. When you have a merchant account and want automated verification, that logic moves to a Supabase Edge Function without changing the rest of the app.

---

## Roadmap

- [x] Student auth (sign up / log in)
- [x] Exam list and topic list (live from database)
- [x] Admin dashboard with AI content generation
- [x] Interactive lesson (sandboxed iframe)
- [x] Deep notes and crash notes (markdown rendered)
- [x] Quiz with scoring and history
- [x] AI Teacher chat (study-only, rate-limited)
- [x] Student home dashboard (progress, streak, bookmarks, weak areas)
- [x] AI-generated study timetable (saveable, printable)
- [x] Global topic search
- [x] Subscription paywall with manual payment approval
- [ ] Supabase Edge Functions (move AI keys server-side)
- [ ] Automated EasyPaisa merchant payment verification
- [ ] Mobile responsiveness pass
- [ ] Unit and widget tests

---

## Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter ^2.5.0` | Auth and database |
| `go_router ^14.0.0` | URL-based navigation |
| `flutter_dotenv ^5.1.0` | Load `.env` at runtime |
| `http ^1.2.0` | AI API calls |
| `flutter_widget_from_html ^0.15.1` | Render notes as HTML |
| `flutter_markdown ^0.7.3` | Markdown support |
| `youtube_player_iframe ^5.1.2` | YouTube integration |

---

## Contributing

This project was built as part of a documented public experiment studying AI-assisted development by a non-technical builder. The full write-up is on LinkedIn. Pull requests are welcome — please open an issue first to discuss any significant change.

---
