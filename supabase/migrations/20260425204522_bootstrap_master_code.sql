-- One-time bootstrap: insert a shared launch code so the very first
-- members can redeem it. Admin can rotate / disable in admin.html.
INSERT INTO invitations (token, created_by, expires_at, max_uses, is_active, label)
  VALUES ('WELCOME-2026', NULL, NULL, NULL, true, 'master')
  ON CONFLICT (token) DO UPDATE
    SET is_active = true, label = EXCLUDED.label, max_uses = EXCLUDED.max_uses;
