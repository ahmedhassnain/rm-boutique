# R&M Boutique

One Flutter app, three roles (Admin, Customer, Rider), Supabase backend.
CT124-3-2-MAE Part 2.

| Role | Owner | Their folder |
|---|---|---|
| Admin + foundation (database, core, auth) | Ahmed Hassnain | `lib/features/admin`, `lib/core`, `lib/shared`, `supabase/` |
| Customer | Maheen Zubair | `lib/features/customer` |
| Rider | Ahmad M.D Mousa | `lib/features/rider` |

## The order flow (agreed, do not change without telling everyone)

```
confirmed  ->  paid  ->  packed  ->  dispatched  ->  delivered
 (customer     (admin verifies   (admin)   (admin, needs     (rider, needs
  places it)    the payment)               a rider)          the photo)
```

The database enforces it (`supabase/schema.sql`, `guard_order_update`). The app
uses the enum in `lib/shared/order_status.dart`. Never type a status as a string.

## Folder map

```
supabase/       schema.sql, policies.sql, seed.sql      the database contract
lib/core/       theme, router, shared widgets            Ahmed owns
lib/shared/     models, order_status, repositories       THE CONTRACT: ask before changing
lib/features/   auth/  admin/  customer/  rider/         one folder per person
test/           shared/ admin/ customer/ rider/
docs/           PATTERNS.md (how to write a screen), report material
```

Rule of thumb: **work only inside your own `features/<role>` and `test/<role>` folders.**
Need something in `core/`, `shared/` or `supabase/`? Message Ahmed (or make the change in
a small separate PR and tell the group).

---

## A. One-time setup (Ahmed)

1. **Supabase project**: supabase.com -> New project (free plan).
   Authentication -> Providers -> Email -> turn **off** "Confirm email".
2. **Database**: SQL editor -> paste and run `supabase/schema.sql`, then `supabase/policies.sql`
   (in that order, each must finish without errors).
3. **Test users**: Authentication -> Users -> Add user (tick *Auto Confirm User*):
   `admin@rm-boutique.test`, `customer@rm-boutique.test`, `rider@rm-boutique.test`
   (password `Test1234!`). Then run `supabase/seed.sql` (promotes admin and rider, adds products).
4. **Keys**: Project Settings -> API. Copy the project URL and the `anon` public key.
   Never use or share the `service_role` key.
5. **Flutter platform folders** (this repo has the code but not `android/` and `ios/` yet).
   Commit first, so anything the command touches is visible and reversible:
   ```bash
   git init -b main
   git add . && git commit -m "Add project skeleton: schema, shared contract, role placeholders"
   flutter create --platforms=android,ios --project-name rm_boutique .
   rm test/widget_test.dart          # the generated counter test, not ours
   git status                        # should show new android/ and ios/ folders only
   git checkout -- lib pubspec.yaml  # restores our files if the command changed them
   ```
6. **Permissions**
   - `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
     `<uses-permission android:name="android.permission.INTERNET"/>` and
     `<uses-permission android:name="android.permission.CAMERA"/>`
   - `ios/Runner/Info.plist`: add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
     with a short text, e.g. "Used to attach order photos".
7. **Env + run**:
   ```bash
   cp .env.example .env      # then paste the URL and anon key
   flutter pub get
   flutter test
   flutter run
   ```
   Sign in as `admin@rm-boutique.test`: you should see an empty orders list.
   Sign in as `customer@...` and `rider@...` to check each role lands in its own area.
8. **Push** (section B).

Free Supabase projects pause after a week of inactivity: open the dashboard before the demo.

## B. Getting the code onto GitHub (Ahmed)

1. github.com -> New repository `rm-boutique`, **Private**, no README/.gitignore/licence (we have them).
2. Repo -> Settings -> Collaborators -> add Maheen and Ahmad with **Write** access.
3. In the project folder (step A5 already created the first commit):
   ```bash
   git add .
   git status                       # check .env is NOT listed
   git commit -m "Add android/ios platform folders and permissions"
   git remote add origin https://github.com/<your-username>/rm-boutique.git
   git push -u origin main
   ```
4. Settings -> Branches -> Add rule for `main`: require a pull request before merging.
   (On a free private repo this may be unavailable: then the rule is simply
   *nobody commits straight to main*.)
5. Edit `.github/CODEOWNERS`, replacing the three `@username` placeholders with your GitHub names.
6. Send in the group chat: the repo link, the Supabase URL + anon key (for their `.env`),
   and the three test logins.

## C. Teammates: first run

```bash
git clone https://github.com/<ahmed's-username>/rm-boutique.git
cd rm-boutique
cp .env.example .env              # paste the URL and anon key from the group chat
flutter pub get
flutter run
```

## D. Daily git routine

```bash
git checkout main && git pull                    # start of every work session
git checkout -b feature/customer-checkout        # new branch: feature/<role>-<thing>
# ...work, then:
git add lib/features/customer test/customer
git commit -m "Add checkout screen with address and payment upload"
git push -u origin feature/customer-checkout     # first push of the branch
```
Open a Pull Request on GitHub (base `main`), ask one teammate to glance at it, merge,
then **delete the branch**. Merge at least once a day; small PRs rarely conflict.

If `main` moved while you worked:
```bash
git checkout main && git pull
git checkout feature/customer-checkout
git merge main                                   # fix any conflicts, then commit
```

Never `git push --force` on `main`. Never commit `.env`.

## E. What "done" means for a feature

- It works against the real Supabase project (not dummy data).
- `flutter analyze` shows no errors; `flutter test` passes.
- It uses `StatusChip`, the theme colours and the repositories (no raw `supabase.from(...)` in screens).
- 3-5 tests for your role in `test/<role>/`.
