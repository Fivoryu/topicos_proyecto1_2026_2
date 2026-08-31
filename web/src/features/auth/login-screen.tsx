import { type FormEvent, useState } from "react";

import { useSession } from "../../app/auth/session-provider";

export function LoginScreen() {
  const { status, errorCode, errorMessage, notice, login } = useSession();
  const [loginName, setLoginName] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const isLoading = status === "authenticating";

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await login({ loginName, password });
  }

  const visibleError = errorCode
    ? `${errorCode}: ${errorMessage ?? "Authentication failed."}`
    : null;

  return (
    <main className="auth-page">
      <section className="auth-card" aria-labelledby="login-title">
        <p className="auth-eyebrow">Cuentas Claras</p>
        <h1 id="login-title">Sign in to Cuentas Claras</h1>
        <p className="auth-intro">
          Use your seeded account to access the group.
        </p>
        {notice && (
          <p className="auth-notice" role="status">
            {notice}
          </p>
        )}
        <form aria-label="Sign in" onSubmit={submit}>
          <div className="auth-field">
            <label htmlFor="login-name">Login name</label>
            <input
              id="login-name"
              name="login_name"
              type="text"
              autoComplete="username"
              value={loginName}
              onChange={(event) => setLoginName(event.target.value)}
              disabled={isLoading}
              required
            />
          </div>
          <div className="auth-field">
            <label htmlFor="login-password">Password</label>
            <div className="password-field">
              <input
                id="login-password"
                name="password"
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                disabled={isLoading}
                required
              />
              <button
                type="button"
                className="password-toggle"
                aria-label={showPassword ? "Hide password" : "Show password"}
                aria-pressed={showPassword}
                onClick={() => setShowPassword((visible) => !visible)}
                disabled={isLoading}
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
          </div>
          {visibleError && (
            <p className="auth-error" role="alert" aria-live="polite">
              {visibleError}
            </p>
          )}
          <button
            type="submit"
            className="auth-submit"
            disabled={isLoading}
            aria-busy={isLoading}
          >
            {isLoading ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </section>
    </main>
  );
}
